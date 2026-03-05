# Sandboxie 驱动程序 - 进程管理模块详细分析

## 概述

进程管理模块是 Sandboxie 的核心，负责监控进程创建、管理沙箱进程、注入 DLL、以及控制进程生命周期。

## 1. process.c/h - 进程管理核心

### 数据结构

#### PROCESS 结构
```c
struct _PROCESS {
    HANDLE pid;                         // 进程 ID
    HANDLE starter_id;                  // 启动者进程 ID
    POOL *pool;                         // 进程专用内存池
    BOX *box;                           // 沙箱配置
    
    // 镜像信息
    WCHAR *image_path;                  // 完整路径
    WCHAR *image_name;                  // 文件名
    ULONG image_name_len;
    BOOLEAN image_from_box;             // 是否从沙箱内加载
    BOOLEAN image_sbie;                 // 是否为 Sandboxie 组件
    
    // 进程属性
    ULONG64 create_time;                // 创建时间
    ULONG integrity_level;              // 完整性级别
    void *primary_token;                // 主令牌
    
    // 线程管理
    PERESOURCE threads_lock;
    HASH_MAP thread_map;
    
    // 状态标志
    BOOLEAN initialized;                // 已初始化
    BOOLEAN terminated;                 // 已终止
    ULONG reason;                       // 终止原因
    BOOLEAN untouchable;                // 受保护进程
    BOOLEAN forced_process;             // 强制沙箱化
    BOOLEAN parent_was_sandboxed;       // 父进程已沙箱化
    
    // 配置选项
    BOOLEAN bAppCompartment;            // 应用隔离模式
    BOOLEAN use_security_mode;          // 安全模式
    BOOLEAN use_privacy_mode;           // 隐私模式
    BOOLEAN confidential_box;           // 机密沙箱
    
    // 资源锁和路径列表
    PERESOURCE file_lock;
    LIST open_file_paths;
    LIST closed_file_paths;
    LIST read_file_paths;
    LIST write_file_paths;
    
    PERESOURCE key_lock;
    LIST open_key_paths;
    LIST closed_key_paths;
    LIST read_key_paths;
    LIST write_key_paths;
    
    PERESOURCE ipc_lock;
    LIST open_ipc_paths;
    LIST closed_ipc_paths;
    
    PERESOURCE gui_lock;
    LIST open_win_classes;
    
    // 跟踪标志
    ULONG call_trace;
    ULONG file_trace;
    ULONG pipe_trace;
    ULONG key_trace;
    ULONG ipc_trace;
    ULONG gui_trace;
};
```

### 关键函数

#### Process_Init()
```c
BOOLEAN Process_Init(void)
```
**功能**：初始化进程管理子系统

**步骤**：
1. 初始化进程哈希表（`Process_Map`）
2. 初始化 DFP（禁用强制进程）哈希表
3. 初始化 FCP（强制子进程）哈希表
4. 创建进程列表锁（`Process_ListLock`）
5. 初始化底层进程操作（`Process_Low_Init`）
6. 注册进程通知回调
   - Windows 7+: `PsSetCreateProcessNotifyRoutineEx`
   - XP/Vista: `PsSetCreateProcessNotifyRoutine`
7. 注册镜像加载通知（`PsSetLoadImageNotifyRoutine`）
8. 设置系统调用处理程序（`CreateUserProcess`）
9. 注册 API 函数

**返回**：成功返回 TRUE，失败返回 FALSE

#### Process_NotifyProcessEx()
```c
void Process_NotifyProcessEx(PEPROCESS Process, HANDLE ProcessId, PPS_CREATE_NOTIFY_INFO CreateInfo)
```
**功能**：进程创建/终止通知回调（Windows 7+）

**进程创建时**：
1. 获取进程镜像路径（通过 `FltGetFileNameInformationUnsafe`）
2. 调用 `Process_NotifyProcess_Create`
3. 如果创建失败，设置 `CreateInfo->CreationStatus = STATUS_ACCESS_DENIED`

**进程终止时**：
1. 调用 `Process_NotifyProcess_Delete`
2. 清理进程资源

#### Process_NotifyProcess_Create()
```c
BOOLEAN Process_NotifyProcess_Create(HANDLE ProcessId, HANDLE ParentId, HANDLE CallerId, UNICODE_STRING* Name, ULONG NameLength, BOX *box)
```
**功能**：处理进程创建

**决策流程**：
```
1. 获取进程镜像名称
2. 确定是否需要沙箱化：
   a. 如果 box 参数非空 -> 由 SbieSvc 启动
   b. 如果父进程已沙箱化 -> 继承沙箱
   c. 检查 DFP 列表 -> 禁用强制进程
   d. 检查强制进程列表 -> 强制沙箱化
3. 如果需要沙箱化：
   a. 创建 PROCESS 对象
   b. 初始化路径列表
   c. 注入 SbieDll.dll
4. 如果不需要沙箱化：
   a. 检查是否添加到 DFP 列表
```

**关键逻辑**：
```c
// 1. 由 SbieSvc 启动
if (ParentId == Api_ServiceProcessId) {
    add_process_to_job = TRUE;
}
// 2. 父进程已沙箱化
else if (parent_proc && !parent_proc->bHostInject) {
    box = Box_Clone(Driver_Pool, parent_proc->box);
}
// 3. 检查强制进程
else {
    box = Process_GetForcedStartBox(ProcessId, ParentId, ImagePath, &bHostInject, pSidString);
}
```

#### Process_Create()
```c
PROCESS *Process_Create(HANDLE ProcessId, const BOX *box, const WCHAR *image_path, KIRQL *out_irql)
```
**功能**：创建并初始化 PROCESS 对象

**步骤**：
1. 创建进程专用内存池
2. 分配 PROCESS 结构
3. 克隆沙箱配置（`Box_Clone`）
4. 获取进程对象和创建时间
5. 检查 Win32k 过滤器状态
6. 提取镜像名称
7. 检查镜像是否来自沙箱
8. 初始化配置选项：
   - `bAppCompartment` - 应用隔离模式
   - `use_security_mode` - 安全模式
   - `use_privacy_mode` - 隐私模式
   - `confidential_box` - 机密沙箱
9. 验证证书（如果使用高级功能）
10. 初始化资源锁（file_lock, key_lock, ipc_lock, gui_lock）
11. 初始化跟踪标志
12. 检查 `OpenWinClass=*`
13. 插入进程到全局哈希表

**证书验证**：
```c
if (!(Verify_CertInfo.active && Verify_CertInfo.opt_sec) && !proc->image_sbie) {
    if (proc->use_security_mode || proc->is_locked_down || ...) {
        Log_Msg_Process(MSG_6004, proc->box->name, exclusive_setting, ...);
        Process_ScheduleKill(proc, 5*60*1000); // 5分钟后终止
    }
}
```

#### Process_Find()
```c
PROCESS *Process_Find(HANDLE ProcessId, KIRQL *out_irql)
```
**功能**：查找进程对象

**参数**：
- `ProcessId` - 进程 ID（NULL 表示当前进程）
- `out_irql` - 输出 IRQL（如果非 NULL，保持锁定状态）

**返回值**：
- 进程对象指针
- `PROCESS_TERMINATED` - 进程正在终止
- NULL - 未找到或非沙箱进程

**逻辑**：
```c
if (!ProcessId) {
    if (ExGetPreviousMode() == KernelMode)
        return NULL;  // 内核模式调用者
    ProcessId = PsGetCurrentProcessId();
}

KeRaiseIrql(APC_LEVEL, &irql);
ExAcquireResourceSharedLite(Process_ListLock, TRUE);

proc = map_get(&Process_Map, ProcessId);
if (proc && proc->terminated) {
    proc = PROCESS_TERMINATED;  // 进程正在终止
}

if (!out_irql) {
    ExReleaseResourceLite(Process_ListLock);
    KeLowerIrql(irql);
}
```

#### Process_NotifyImage()
```c
void Process_NotifyImage(const UNICODE_STRING *FullImageName, HANDLE ProcessId, IMAGE_INFO *ImageInfo)
```
**功能**：镜像加载通知回调

**触发时机**：
- 进程主镜像加载（第一次）
- DLL 加载

**主镜像加载时的初始化**：
```c
if (!proc->initialized) {
    // 1. 创建沙箱路径
    File_CreateBoxPath(proc);
    Ipc_CreateBoxPath(proc);
    Key_MountHive(proc);
    
    // 2. 初始化过滤器
    WFP_InitProcess(proc);
    File_InitProcess(proc);
    Key_InitProcess(proc);
    Ipc_InitProcess(proc);
    Gui_InitProcess(proc);
    
    // 3. 初始化控制台
    Process_Low_InitConsole(proc);
    
    // 4. 替换主令牌
    Token_ReplacePrimary(proc);
    
    // 5. 初始化线程管理
    Thread_InitProcess(proc);
    
    proc->initialized = TRUE;
}
```

#### Process_Delete()
```c
void Process_Delete(HANDLE ProcessId)
```
**功能**：删除进程对象并清理资源

**步骤**：
1. 从进程哈希表移除
2. 从 DFP 和 FCP 列表移除
3. 清理 WFP 规则
4. 卸载注册表配置单元
5. 释放资源锁
6. 重置主令牌
7. 释放线程资源
8. 释放令牌资源
9. 删除内存池

#### Process_SetTerminated()
```c
void Process_SetTerminated(PROCESS *proc, ULONG reason)
```
**功能**：标记进程为终止状态

**效果**：
- 设置 `proc->terminated = TRUE`
- 设置终止原因
- 后续文件和注册表操作返回 `STATUS_PROCESS_IS_TERMINATING`

**终止原因**：
- 0 - 初始化失败
- 1 - 手动终止
- 2 - 注入失败
- 9 - 禁用硬错误
- 10 - 线程 ID 冲突
- 14 - 保护主机镜像违规

#### Process_TerminateProcess()
```c
BOOLEAN Process_TerminateProcess(PROCESS *proc)
```
**功能**：终止进程

**方法**：
1. 获取进程对象
2. 调用 `ZwTerminateProcess(ProcessHandle, STATUS_UNSUCCESSFUL)`
3. 关闭句柄

#### Process_ScheduleKill()
```c
BOOLEAN Process_ScheduleKill(PROCESS *proc, LONG delay_ms)
```
**功能**：延迟终止进程

**用途**：
- 评估版本超时
- 违规行为惩罚
- 许可证过期

**实现**：创建系统线程，延迟后调用 `Process_TerminateProcess`

---

## 2. process_api.c - 进程 API 函数

### Process_Api_Start()
```c
NTSTATUS Process_Api_Start(PROCESS *proc, ULONG64 *parms)
```
**功能**：启动沙箱进程（由 SbieSvc 调用）

**参数**：
- `box_name` - 沙箱名称
- `sid_string` - 用户 SID
- `session_id` - 会话 ID
- `process_id` - 进程 ID

**流程**：
1. 验证调用者（必须是 SbieSvc）
2. 创建 BOX 对象
3. 调用 `Process_NotifyProcess_Create`
4. 返回结果

### Process_Api_Query()
```c
NTSTATUS Process_Api_Query(PROCESS *proc, ULONG64 *parms)
```
**功能**：查询进程是否已沙箱化

**参数**：
- `process_id` - 进程 ID
- `box_name` - 输出沙箱名称
- `image_name` - 输出镜像名称
- `sid_string` - 输出 SID
- `session_id` - 输出会话 ID

### Process_Api_QueryInfo()
```c
NTSTATUS Process_Api_QueryInfo(PROCESS *proc, ULONG64 *parms)
```
**功能**：查询进程详细信息

**返回信息**：
- 进程 ID
- 父进程 ID
- 创建时间
- 镜像路径
- 沙箱名称
- 各种标志

### Process_Api_Enum()
```c
NTSTATUS Process_Api_Enum(PROCESS *proc, ULONG64 *parms)
```
**功能**：枚举沙箱中的进程

**参数**：
- `box_name` - 沙箱名称（NULL = 所有沙箱）
- `all_sessions` - 是否包含所有会话
- `session_id` - 会话 ID
- `pids` - 输出进程 ID 数组
- `count` - 输入/输出计数

### Process_Api_Kill()
```c
NTSTATUS Process_Api_Kill(PROCESS *proc, ULONG64 *parms)
```
**功能**：终止沙箱进程

**参数**：
- `process_id` - 进程 ID

---

## 3. process_force.c - 强制沙箱化

### Process_GetForcedStartBox()
```c
BOX *Process_GetForcedStartBox(HANDLE ProcessId, HANDLE ParentId, const WCHAR *ImagePath, BOOLEAN* pHostInject, const WCHAR *pSidString)
```
**功能**：检查进程是否应被强制沙箱化

**检查顺序**：
1. 检查 `ForceProcess` 配置
2. 检查 `ForceFolder` 配置
3. 检查 `LingerProcess` 配置

**配置示例**：
```ini
ForceProcess=iexplore.exe
ForceProcess=firefox.exe
ForceFolder=C:\Downloads
LingerProcess=chrome.exe
```

**返回值**：
- BOX 对象 - 应该使用的沙箱
- (BOX *)-1 - 应该拒绝启动
- NULL - 不需要强制沙箱化

### Process_DfpInsert()
```c
BOOLEAN Process_DfpInsert(HANDLE ParentId, HANDLE ProcessId)
```
**功能**：添加进程到禁用强制进程列表

**用途**：
- 用户明确选择不沙箱化某个进程
- 该进程的子进程也不会被强制沙箱化

### Process_DfpCheck()
```c
BOOLEAN Process_DfpCheck(HANDLE ProcessId, BOOLEAN *silent)
```
**功能**：检查进程是否在 DFP 列表中

### Process_FcpInsert() / Process_FcpCheck()
```c
VOID Process_FcpInsert(HANDLE ProcessId, const WCHAR* boxname)
BOOLEAN Process_FcpCheck(HANDLE ProcessId, WCHAR* boxname)
```
**功能**：强制子进程列表管理

**用途**：
- 强制特定进程的所有子进程进入指定沙箱
- 用于浏览器插件进程等场景

---

## 4. process_low.c - 底层进程操作

### Process_Low_Inject()
```c
BOOLEAN Process_Low_Inject(HANDLE process_id, ULONG session_id, ULONG64 create_time, const WCHAR *image_name, BOOLEAN add_process_to_job, BOOLEAN bHostInject)
```
**功能**：注入 SbieDll.dll 到目标进程

**步骤**：
1. 打开目标进程
2. 分配远程内存
3. 写入 DLL 路径和参数
4. 创建远程线程执行 `LdrLoadDll`
5. 等待注入完成

**注入参数**：
```c
struct {
    WCHAR dll_path[MAX_PATH];
    ULONG64 create_time;
    BOOLEAN add_to_job;
    BOOLEAN host_inject;
} inject_params;
```

### Process_Low_InitConsole()
```c
BOOLEAN Process_Low_InitConsole(PROCESS *proc)
```
**功能**：初始化控制台进程

**处理**：
- 检测控制台进程（csrss.exe 子进程）
- 设置特殊标志
- 调整控制台行为

---

## 5. process_util.c - 进程工具函数

### Process_GetProcessName()
```c
void Process_GetProcessName(POOL *pool, ULONG_PTR idProcess, void **out_buf, ULONG *out_len, WCHAR **out_ptr)
```
**功能**：获取进程名称

**方法**：
1. 打开进程
2. 查询 `ProcessImageFileName`
3. 提取文件名部分

### Process_GetCommandLine()
```c
void Process_GetCommandLine(HANDLE ProcessId, WCHAR **OutBuffer, ULONG *OutLength)
```
**功能**：获取进程命令行

**方法**：
1. 打开进程
2. 读取 PEB（进程环境块）
3. 读取 `ProcessParameters->CommandLine`

### Process_IsSbieImage()
```c
VOID Process_IsSbieImage(const WCHAR *image_path, BOOLEAN *image_sbie, BOOLEAN *is_start_exe)
```
**功能**：检查镜像是否为 Sandboxie 组件

**检查**：
- 路径是否在 Sandboxie 安装目录
- 文件名是否为 Start.exe

### Process_MatchImage()
```c
BOOLEAN Process_MatchImage(BOX *box, const WCHAR *pat_str, ULONG pat_len, const WCHAR *test_str, ULONG depth)
```
**功能**：匹配进程镜像名称模式

**支持的模式**：
- `*` - 匹配任意字符
- `?` - 匹配单个字符
- `<ProcessName>` - 精确匹配

### Process_MatchPath()
```c
const WCHAR *Process_MatchPath(POOL *pool, const WCHAR *path, ULONG path_len, LIST *open_list, LIST *closed_list, BOOLEAN *is_open, BOOLEAN *is_closed)
```
**功能**：匹配路径规则

**返回**：
- 匹配的规则源字符串
- `is_open` - 是否匹配开放路径
- `is_closed` - 是否匹配关闭路径

### Process_MatchPathEx()
```c
ULONG Process_MatchPathEx(PROCESS *proc, const WCHAR *path, ULONG path_len, WCHAR path_code, LIST *normal_list, LIST *open_list, LIST *closed_list, LIST *read_list, LIST *write_list, const WCHAR** patsrc)
```
**功能**：增强的路径匹配（支持优先级）

**返回标志**：
```c
#define TRUE_PATH_CLOSED_FLAG    0x00
#define TRUE_PATH_READ_FLAG      0x10
#define TRUE_PATH_WRITE_FLAG     0x20
#define TRUE_PATH_OPEN_FLAG      0x30
#define TRUE_PATH_MASK           0x30

#define COPY_PATH_CLOSED_FLAG    0x00
#define COPY_PATH_READ_FLAG      0x01
#define COPY_PATH_WRITE_FLAG     0x02
#define COPY_PATH_OPEN_FLAG      0x03
#define COPY_PATH_MASK           0x03
```

**优先级**：Normal > Open > Write > Read > Closed

---

## 6. process_hook.c - 进程钩子

### Process_CreateUserProcess()
```c
NTSTATUS Process_CreateUserProcess(PROCESS *proc, SYSCALL_ENTRY *syscall_entry, ULONG_PTR *user_args)
```
**功能**：拦截 `NtCreateUserProcess` 系统调用

**用途**：
- 检测进程创建
- 实施 `ProtectHostImages` 策略

**逻辑**：
```c
if (proc->protect_host_images) {
    thrd = Thread_GetOrCreate(proc, NULL, TRUE);
    thrd->create_process_in_progress = TRUE;
}

NTSTATUS status = Syscall_Invoke(syscall_entry, user_args);

if (thrd)
    thrd->create_process_in_progress = FALSE;
```

---

## 7. thread.c/h - 线程管理

### 数据结构

#### THREAD 结构
```c
struct _THREAD {
    HANDLE tid;                         // 线程 ID
    void *token_object;                 // 模拟令牌
    BOOLEAN create_process_in_progress; // 正在创建进程
};
```

### 关键函数

#### Thread_Init()
```c
BOOLEAN Thread_Init(void)
```
**功能**：初始化线程管理

**步骤**：
1. 注册线程通知回调（`PsSetCreateThreadNotifyRoutine`）
2. 初始化匿名令牌
3. 设置系统调用处理程序
4. 设置对象打开处理程序
5. 注册 API 函数

#### Thread_Notify()
```c
void Thread_Notify(HANDLE ProcessId, HANDLE ThreadId, BOOLEAN Create)
```
**功能**：线程创建/终止通知回调

**线程创建时**：
- 检查线程 ID 是否已存在（不应该）

**线程终止时**：
- 从线程哈希表移除
- 释放模拟令牌
- 释放 THREAD 结构

#### Thread_GetOrCreate()
```c
THREAD *Thread_GetOrCreate(PROCESS *proc, HANDLE tid, BOOLEAN create)
```
**功能**：获取或创建线程对象

**参数**：
- `proc` - 进程对象
- `tid` - 线程 ID（NULL = 当前线程）
- `create` - 如果不存在是否创建

#### Thread_CheckProcessObject()
```c
NTSTATUS Thread_CheckProcessObject(PROCESS *proc, void *Object, UNICODE_STRING *Name, ULONG Operation, ACCESS_MASK GrantedAccess)
```
**功能**：检查进程对象访问

**限制**：
- 禁止访问其他沙箱的进程
- 禁止访问非沙箱进程（除非配置允许）
- 限制危险访问权限（PROCESS_VM_WRITE, PROCESS_CREATE_THREAD 等）

#### Thread_CheckThreadObject()
```c
NTSTATUS Thread_CheckThreadObject(PROCESS *proc, void *Object, UNICODE_STRING *Name, ULONG Operation, ACCESS_MASK GrantedAccess)
```
**功能**：检查线程对象访问

**限制**：
- 类似进程对象限制
- 限制线程注入

---

## 总结

进程管理模块实现了以下核心功能：

1. **进程监控**：通过进程和镜像通知回调监控所有进程创建
2. **沙箱决策**：决定哪些进程需要沙箱化（继承、强制、手动）
3. **进程初始化**：创建进程对象、初始化路径列表、注入 DLL
4. **资源管理**：管理进程专用资源（内存池、锁、令牌）
5. **生命周期管理**：跟踪进程状态、处理终止、清理资源
6. **线程管理**：跟踪线程、管理模拟令牌
7. **访问控制**：限制跨沙箱进程/线程访问
8. **API 接口**：提供用户态查询和控制接口

这些功能共同确保了进程的正确隔离和沙箱化。
