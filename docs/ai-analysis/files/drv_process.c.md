# 文件级分析：process.c

## 1. 文件概述

**职责定位**：实现进程隔离和管理的核心逻辑，包括进程创建监控、沙箱化决策、进程对象管理和 DLL 注入触发。

**文件类型**：内核驱动 / 进程管理模块

**文件路径**：`Sandboxie/core/drv/process.c`

**所属模块**：内核驱动层 (SbieDrv.sys) - 进程管理子系统

---

## 2. 公开接口（Public API）

| 名称 | 类型 | 签名/参数 | 返回值 | 简要说明 |
|------|------|----------|--------|----------|
| Process_Init | 函数 | (void) | BOOLEAN | 初始化进程管理子系统 |
| Process_GetTraceFlag | 函数 | (PROCESS*, const WCHAR*) | ULONG | 获取进程跟踪标志 |
| Process_NotifyProcessEx | 回调函数 | (PEPROCESS, HANDLE, PPS_CREATE_NOTIFY_INFO) | void | 进程创建/终止通知回调（Win7+） |
| Process_NotifyProcess | 回调函数 | (HANDLE, HANDLE, BOOLEAN) | void | 进程创建/终止通知回调（XP/Vista） |
| Process_Create | 静态函数 | (HANDLE, const BOX*, const WCHAR*, KIRQL*) | PROCESS* | 创建进程对象 |
| Process_Delete | 静态函数 | (HANDLE) | void | 删除进程对象 |
| Process_NotifyProcess_Delete | 静态函数 | (HANDLE) | void | 处理进程终止通知 |
| Process_NotifyImage | 回调函数 | (const UNICODE_STRING*, HANDLE, IMAGE_INFO*) | void | 镜像加载通知回调 |
| Process_CreateUserProcess | 静态函数 | (PROCESS*, SYSCALL_ENTRY*, ULONG_PTR*) | NTSTATUS | 拦截 NtCreateUserProcess 系统调用 |
| Process_HookProcessNotify | 静态函数 | (PCREATE_PROCESS_NOTIFY_ROUTINE) | NTSTATUS | Hook 进程通知例程（XP 32位） |

---

## 3. 核心逻辑

### 3.1 进程管理架构

```
Windows 内核进程创建
    ↓
PsSetCreateProcessNotifyRoutineEx 回调
    ↓
Process_NotifyProcessEx() 被调用
    ↓
判断是否需要沙箱化：
  1. 父进程是否在沙箱中？
  2. 是否在强制进程列表中？
  3. 是否匹配启动规则？
    ↓
YES: 创建 PROCESS 对象
    ↓
Process_Create()
  - 分配进程结构
  - 初始化进程属性
  - 设置沙箱配置
  - 记录进程信息
    ↓
触发 DLL 注入
  - 通知 Dll_Init 子系统
  - 注入 LowLevel.dll
  - 加载 SbieDll.dll
    ↓
进程在沙箱中运行
    ↓
进程终止时
    ↓
Process_NotifyProcess_Delete()
    ↓
Process_Delete()
  - 清理进程资源
  - 从进程映射表中移除
  - 释放内存
```

### 3.2 初始化流程

```c
Process_Init()
    ↓
1. 初始化进程映射表
   map_init(&Process_Map, Driver_Pool)
   map_resize(&Process_Map, 128)  // 预分配 128 个桶
    ↓
2. 初始化 DFP 映射表（Deleted File Paths）
   map_init(&Process_MapDfp, Driver_Pool)
   map_resize(&Process_MapDfp, 128)
    ↓
3. 初始化 FCP 映射表（Forced Child Processes）
   map_init(&Process_MapFcp, Driver_Pool)
   map_resize(&Process_MapFcp, 128)
    ↓
4. 创建进程列表锁
   Mem_GetLockResource(&Process_ListLock, TRUE)
    ↓
5. 初始化低级进程管理
   Process_Low_Init()
    ↓
6. 注册进程通知回调
   - Windows 7+: PsSetCreateProcessNotifyRoutineEx()
   - XP/Vista: PsSetCreateProcessNotifyRoutine()
   - XP 32位特殊处理: Process_HookProcessNotify()
    ↓
7. 注册镜像加载通知回调
   PsSetLoadImageNotifyRoutine(Process_NotifyImage)
    ↓
8. 设置系统调用处理器
   Syscall_Set1("CreateUserProcess", Process_CreateUserProcess)
    ↓
9. 返回 TRUE (成功)
```

### 3.3 进程沙箱化决策流程

```
新进程创建事件
    ↓
Process_NotifyProcessEx(ParentId, ProcessId, CreateInfo)
    ↓
检查 1: 父进程是否在沙箱中？
    ↓ YES
继承父进程的沙箱
    ↓
检查 2: 是否在强制进程列表中？
    (ForceProcess=xxx.exe)
    ↓ YES
强制沙箱化
    ↓
检查 3: 是否匹配启动规则？
    (StartProgram, AutoExec 等)
    ↓ YES
应用启动规则
    ↓ NO (所有检查)
正常启动（不沙箱化）
```

### 3.4 进程对象生命周期

```
创建阶段:
Process_Create(ProcessId, box, image_path, &irql)
    ↓
1. 分配 PROCESS 结构
   proc = Mem_Alloc(Driver_Pool, sizeof(PROCESS))
    ↓
2. 初始化进程属性
   - proc->pid = ProcessId
   - proc->box = box
   - proc->image_name = image_path
   - proc->create_time = current_time
    ↓
3. 插入进程映射表
   map_insert(&Process_Map, ProcessId, proc, irql)
    ↓
4. 设置沙箱标志
   - proc->is_sandboxed = TRUE
   - proc->parent_was_sandboxed = (parent in sandbox)
    ↓
5. 返回 PROCESS 指针

运行阶段:
- 进程在沙箱中执行
- 所有操作被拦截和重定向
- 进程对象保存在 Process_Map 中

终止阶段:
Process_Delete(ProcessId)
    ↓
1. 从映射表中查找进程
   proc = map_find(&Process_Map, ProcessId)
    ↓
2. 清理进程资源
   - 释放路径列表
   - 清理 IPC 对象
   - 释放令牌
    ↓
3. 从映射表中移除
   map_remove(&Process_Map, ProcessId)
    ↓
4. 释放进程结构
   Mem_Free(proc, sizeof(PROCESS))
```

---

## 4. 依赖关系

### 内部依赖（项目内）

| 依赖文件 | 用途 |
|---------|------|
| process.h | 进程管理头文件定义 |
| util.h/util.c | 工具函数 |
| conf.h/conf.c | 配置管理（读取进程规则） |
| key.h/key.c | 注册表虚拟化 |
| file.h/file.c | 文件系统虚拟化 |
| ipc.h/ipc.c | IPC 隔离 |
| api.h/api.c | IOCTL API 接口 |
| dll.h/dll.c | DLL 注入管理 |
| hook.h/hook.c | 内核 Hook（非 ARM64） |
| session.h/session.c | 会话管理 |
| gui.h/gui.c | GUI 管理 |
| token.h/token.c | 令牌管理 |
| thread.h/thread.c | 线程管理 |
| wfp.h/wfp.c | 网络过滤 |
| verify.h | 证书验证 |
| dyn_data.h | 动态数据 |

### 外部依赖（Windows 内核）

| 依赖 API | 用途 |
|---------|------|
| PsSetCreateProcessNotifyRoutineEx | 注册进程通知回调（Win7+） |
| PsSetCreateProcessNotifyRoutine | 注册进程通知回调（XP/Vista） |
| PsSetLoadImageNotifyRoutine | 注册镜像加载通知回调 |
| PsRemoveCreateThreadNotifyRoutine | 移除线程通知回调 |
| PsRemoveLoadImageNotifyRoutine | 移除镜像加载通知回调 |
| PsGetProcessId | 获取进程 ID |
| PsGetProcessImageFileName | 获取进程镜像文件名 |
| KeAcquireSpinLock | 获取自旋锁 |
| KeReleaseSpinLock | 释放自旋锁 |

---

## 5. 数据模型 / 类型定义

### 全局变量

```c
// 进程映射表（ProcessId → PROCESS*）
HASH_MAP Process_Map;

// 删除文件路径映射表
HASH_MAP Process_MapDfp;

// 强制子进程映射表
HASH_MAP Process_MapFcp;

// 进程列表锁（读写锁）
PERESOURCE Process_ListLock;

// 通知回调安装标志
static BOOLEAN Process_NotifyImageInstalled = FALSE;
static BOOLEAN Process_NotifyProcessInstalled = FALSE;

// 准备沙箱化标志
volatile BOOLEAN Process_ReadyToSandbox = FALSE;

// XP 32位特殊处理
#ifdef XP_SUPPORT
#ifndef _WIN64
static PCREATE_PROCESS_NOTIFY_ROUTINE *Process_pOldNotifyProcess = NULL;
#endif
#endif
```

### PROCESS 结构体（推测）

```c
typedef struct _PROCESS {
    HANDLE pid;                      // 进程 ID
    const BOX *box;                  // 所属沙箱
    WCHAR *image_name;               // 镜像文件名
    LARGE_INTEGER create_time;       // 创建时间
    BOOLEAN is_sandboxed;            // 是否沙箱化
    BOOLEAN parent_was_sandboxed;    // 父进程是否沙箱化
    ULONG trace_flags;               // 跟踪标志
    LIST *open_file_paths;           // 打开文件路径列表
    LIST *closed_file_paths;         // 关闭文件路径列表
    LIST *read_file_paths;           // 只读文件路径列表
    LIST *write_file_paths;          // 写入文件路径列表
    // ... 更多字段
} PROCESS;
```

### BOX 结构体（推测）

```c
typedef struct _BOX {
    WCHAR *name;                     // 沙箱名称
    WCHAR *file_path;                // 沙箱文件路径
    WCHAR *key_path;                 // 沙箱注册表路径
    ULONG flags;                     // 沙箱标志
    // ... 配置选项
} BOX;
```

---

## 6. 潜在关注点

### 6.1 进程通知回调的兼容性

⚠️ **版本差异**：不同 Windows 版本使用不同的进程通知 API：
- **Windows 7+**: `PsSetCreateProcessNotifyRoutineEx` (扩展版本)
- **XP/Vista**: `PsSetCreateProcessNotifyRoutine` (基础版本)
- **XP 32位特殊情况**: 如果注册失败，使用 Hook 方式

**风险**：API 差异可能导致兼容性问题。

### 6.2 进程映射表的并发访问

⚠️ **线程安全**：`Process_Map` 被多个线程并发访问：
- 进程创建回调（任意线程）
- 进程终止回调（任意线程）
- IOCTL 处理（用户请求）

**保护机制**：使用 `Process_ListLock` 读写锁保护。

**性能考虑**：预分配 128 个桶以减少哈希冲突。

### 6.3 进程对象的生命周期管理

⚠️ **内存泄漏风险**：如果进程异常终止，可能导致：
- 进程对象未被清理
- 资源泄漏

**保护措施**：
- 进程终止回调保证清理
- 使用引用计数（如果实现）

### 6.4 DLL 注入时机

⚠️ **关键时机**：DLL 必须在进程执行第一条用户态代码之前注入。

**实现方式**：
- 在进程创建回调中触发注入
- 使用 `CreateInfo` 参数控制进程启动

**风险**：注入失败会导致进程无法沙箱化。

### 6.5 强制进程列表

⚠️ **配置依赖**：`ForceProcess` 配置项决定哪些进程被强制沙箱化。

**示例**：
```ini
[DefaultBox]
ForceProcess=iexplore.exe
ForceProcess=chrome.exe
```

**风险**：配置错误可能导致系统进程被沙箱化，引发系统不稳定。

### 6.6 父子进程关系

⚠️ **继承机制**：子进程默认继承父进程的沙箱。

**特殊情况**：
- `parent_was_sandboxed` 标志用于优化
- 某些进程可能需要突破沙箱（如提权进程）

### 6.7 镜像加载通知

⚠️ **用途**：`Process_NotifyImage` 回调监控 DLL 加载。

**应用场景**：
- 检测恶意 DLL
- 阻止特定 DLL 加载
- 记录加载日志

### 6.8 系统调用拦截

⚠️ **NtCreateUserProcess**：现代 Windows 使用此系统调用创建进程。

**拦截目的**：
- 在系统调用层面控制进程创建
- 修改进程创建参数
- 注入初始化代码

---

## 7. 架构设计亮点

### 7.1 多层防护

```
应用层: CreateProcess() API
    ↓
用户态 DLL: SbieDll Hook
    ↓
系统调用: NtCreateUserProcess
    ↓
内核驱动: Process_CreateUserProcess() 拦截
    ↓
进程通知: Process_NotifyProcessEx() 回调
    ↓
镜像加载: Process_NotifyImage() 回调
```

### 7.2 高效的进程查找

使用哈希映射表 (`HASH_MAP`) 实现 O(1) 查找：
```c
PROCESS *proc = map_find(&Process_Map, ProcessId);
```

预分配桶以减少动态扩容：
```c
map_resize(&Process_Map, 128);
```

### 7.3 灵活的沙箱化策略

支持多种沙箱化触发方式：
- **继承式**：子进程继承父进程沙箱
- **强制式**：配置文件指定强制沙箱化
- **手动式**：用户通过 GUI 启动

### 7.4 跨版本兼容性

代码支持从 Windows XP 到 Windows 11：
```c
if (Driver_OsVersion >= DRIVER_WINDOWS_7) {
    // 使用新 API
} else {
    // 使用旧 API
}
```

---

## 8. 代码质量评估

**优点**：
- ✅ 清晰的进程生命周期管理
- ✅ 完善的错误处理
- ✅ 良好的版本兼容性
- ✅ 高效的数据结构（哈希表）
- ✅ 详细的日志记录

**改进空间**：
- ⚠️ 部分全局变量可以封装
- ⚠️ 需要更多内联注释
- ⚠️ 可以添加更多的断言检查
- ⚠️ 性能监控和统计

---

## 9. 安全性分析

### 9.1 进程隔离保证

**机制**：
- 每个沙箱进程有独立的 PROCESS 对象
- 进程间无法直接访问彼此的资源
- 父子进程关系被严格控制

### 9.2 权限控制

**实现**：
- 进程令牌被修改（降低权限）
- 完整性级别被降低
- 特权被移除

### 9.3 进程注入防护

**防护**：
- 沙箱外进程无法注入沙箱内进程
- 沙箱内进程无法注入沙箱外进程
- 跨沙箱注入被阻止

---

## 10. 性能优化

### 10.1 哈希表预分配

```c
map_resize(&Process_Map, 128);  // 预分配 128 个桶
```

**效果**：减少动态扩容，提高查找性能。

### 10.2 读写锁

使用 `ERESOURCE` 读写锁而非互斥锁：
- 允许多个读操作并发
- 写操作独占访问

### 10.3 缓存优化

`parent_was_sandboxed` 标志避免重复检查父进程。

---

**分析完成时间**：2026-03-05  
**分析版本**：基于最新源代码  
**复杂度**：高（核心安全模块）
