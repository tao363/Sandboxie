# 文件级分析：file.c

## 1. 文件概述

**职责定位**：实现文件系统虚拟化的核心逻辑，包括路径重定向、写时复制（Copy-on-Write）、文件访问控制和沙箱目录管理。

**文件类型**：内核驱动 / 文件系统过滤器

**文件路径**：`Sandboxie/core/drv/file.c`

**所属模块**：内核驱动层 (SbieDrv.sys) - 文件系统子系统

---

## 2. 公开接口（Public API）

| 名称 | 类型 | 签名/参数 | 返回值 | 简要说明 |
|------|------|----------|--------|----------|
| File_Init | 函数 | (void) | BOOLEAN | 初始化文件系统虚拟化子系统 |
| File_Unload | 函数 | (void) | void | 卸载文件系统虚拟化子系统 |
| File_CreateBoxPath | 函数 | (PROCESS*) | BOOLEAN | 创建沙箱目录结构 |
| File_CreateBoxPath_2 | 静态函数 | (HANDLE) | void | 创建沙箱目录的 desktop.ini |
| File_AdjustBoxFilePath | 静态函数 | (PROCESS*, HANDLE) | void | 调整沙箱路径以处理重解析点 |
| File_InitPaths | 静态函数 | (PROCESS*, LIST*, ...) | BOOLEAN | 初始化进程的文件路径规则 |
| File_Generic_MyParseProc | 静态函数 | (PROCESS*, PVOID, ...) | NTSTATUS | 通用文件解析处理函数 |
| File_CreatePagingFile | 静态函数 | (PROCESS*, SYSCALL_ENTRY*, ...) | NTSTATUS | 创建分页文件的系统调用处理 |
| File_Api_Rename | API 函数 | (PROCESS*, ULONG64*) | NTSTATUS | 文件重命名 API |
| File_Api_GetName | API 函数 | (PROCESS*, ULONG64*) | NTSTATUS | 获取文件名 API |
| File_Api_RefreshPathList | API 函数 | (PROCESS*, ULONG64*) | NTSTATUS | 刷新路径列表 API |
| File_Api_Open | API 函数 | (PROCESS*, ULONG64*) | NTSTATUS | 打开文件 API |
| File_Api_CheckInternetAccess | API 函数 | (PROCESS*, ULONG64*) | NTSTATUS | 检查网络访问权限 API |
| File_Api_GetBlockedDll | API 函数 | (PROCESS*, ULONG64*) | NTSTATUS | 获取被阻止的 DLL 列表 API |

---

## 3. 核心逻辑

### 3.1 文件系统虚拟化架构

```
应用程序调用 CreateFile("C:\\test.txt")
    ↓
用户态 SbieDll.dll Hook
    ↓
内核态 NtCreateFile
    ↓
SbieDrv.sys 文件过滤器拦截
    ↓
File_Generic_MyParseProc() 解析路径
    ↓
路径转换决策：
  - 读取操作：检查沙箱路径 → 不存在则读取真实路径
  - 写入操作：重定向到沙箱路径 → 必要时复制文件
  - 删除操作：在沙箱中标记删除
    ↓
访问控制检查（OpenFilePath, ClosedFilePath, WriteFilePath）
    ↓
调用原始文件系统驱动
    ↓
返回结果给应用程序
```

### 3.2 初始化流程

```c
File_Init()
    ↓
1. 选择初始化方法
   - Windows Vista+: File_Init_Filter() (Minifilter)
   - Windows XP: File_Init_XpHook() (Parse Procedure Hook)
    ↓
2. 初始化重解析点
   File_InitReparsePoints(TRUE)
    ↓
3. 设置系统调用处理器
   Syscall_Set1("CreatePagingFile", File_CreatePagingFile)
    ↓
4. 注册 API 函数
   - API_RENAME_FILE → File_Api_Rename
   - API_GET_FILE_NAME → File_Api_GetName
   - API_REFRESH_FILE_PATH_LIST → File_Api_RefreshPathList
   - API_OPEN_FILE → File_Api_Open
   - API_CHECK_INTERNET_ACCESS → File_Api_CheckInternetAccess
   - API_GET_BLOCKED_DLL → File_Api_GetBlockedDll
    ↓
5. 返回 TRUE (成功)
```

### 3.3 沙箱目录创建流程

```c
File_CreateBoxPath(proc)
    ↓
1. 检查是否需要创建
   if (proc->parent_was_sandboxed) return TRUE;
    ↓
2. 循环创建目录（最多 64 次重试）
   while (retries < 64) {
       ↓
   3. 尝试创建沙箱路径
      ZwCreateFile(proc->box->file_path, FILE_OPEN_IF, FILE_DIRECTORY_FILE)
       ↓
   4. 处理结果
      - STATUS_OBJECT_PATH_NOT_FOUND:
        → 移除最后一个路径组件，重试
      - STATUS_SUCCESS:
        → 如果是新创建的目录，调用 File_CreateBoxPath_2()
        → 调整路径以处理重解析点
        → 关闭句柄
   }
    ↓
5. 返回成功/失败状态
```

### 3.4 写时复制（Copy-on-Write）机制

**原理**：
- 读取操作：优先读取沙箱文件，不存在则读取真实文件
- 写入操作：首次写入时复制文件到沙箱，后续写入直接修改沙箱文件
- 删除操作：在沙箱中标记删除，真实文件保持不变

**路径映射示例**：
```
真实路径: C:\Windows\System32\test.txt
沙箱路径: C:\Sandbox\DefaultBox\drive\C\Windows\System32\test.txt
```

---

## 4. 依赖关系

### 内部依赖（项目内）

| 依赖文件 | 用途 |
|---------|------|
| file.h | 文件系统头文件定义 |
| file_flt.c | Minifilter 实现（Vista+） |
| file_xp.c | Parse Procedure Hook 实现（XP） |
| obj.h/obj.c | 对象管理（文件对象） |
| api.h/api.c | IOCTL API 接口 |
| conf.h/conf.c | 配置管理（路径规则） |
| util.h/util.c | 工具函数 |
| session.h/session.c | 会话管理 |
| syscall.h/syscall.c | 系统调用拦截 |
| wfp.h/wfp.c | 网络过滤（网络访问检查） |
| common/pattern.h | 路径模式匹配 |

### 外部依赖（Windows 内核）

| 依赖 API | 用途 |
|---------|------|
| ZwCreateFile | 创建/打开文件 |
| ZwQueryInformationFile | 查询文件信息 |
| ZwSetInformationFile | 设置文件信息 |
| ZwWriteFile | 写入文件 |
| ZwClose | 关闭句柄 |
| RtlInitUnicodeString | 初始化 Unicode 字符串 |
| RtlStringCbPrintfA | 格式化字符串 |
| wcsrchr | 查找最后一个字符 |
| InitializeObjectAttributes | 初始化对象属性 |

---

## 5. 数据模型 / 类型定义

### 核心结构体

```c
// 文件操作上下文
typedef struct _MY_CONTEXT {
    KPROCESSOR_MODE AccessMode;          // 访问模式（内核/用户）
    BOOLEAN HaveContext;                 // 是否有上下文
    ULONG CreateDisposition;             // 创建配置
    ULONG CreateOptions;                 // 创建选项
    ULONG Options;                       // 其他选项
    ULONG OriginalDesiredAccess;         // 原始访问权限
} MY_CONTEXT;

// 被阻止的 DLL
typedef struct _BLOCKED_DLL {
    LIST_ELEM list_elem;                 // 链表元素
    ULONG path_len;                      // 路径长度
    WCHAR path[4];                       // 路径（可变长度）
} BLOCKED_DLL;
```

### 全局常量

```c
// 拒绝的访问权限（只允许读取）
#define FILE_DENIED_ACCESS ~(
    STANDARD_RIGHTS_READ | GENERIC_READ | SYNCHRONIZE | READ_CONTROL |
    FILE_READ_DATA | FILE_READ_EA | FILE_READ_ATTRIBUTES | FILE_EXECUTE)

// 目录连接点访问权限
#define DIRECTORY_JUNCTION_ACCESS (
    GENERIC_ALL | GENERIC_WRITE | MAXIMUM_ALLOWED |
    FILE_APPEND_DATA | FILE_WRITE_DATA | FILE_WRITE_ATTRIBUTES)

// 网络重定向器路径
const WCHAR *File_Redirector = L"\\Device\\LanmanRedirector";
const ULONG File_RedirectorLen = 24;

const WCHAR *File_MupRedir = L"\\Device\\Mup\\;LanmanRedirector";
const ULONG File_MupRedirLen = 29;

const WCHAR *File_DfsClientRedir = L"\\Device\\Mup\\DfsClient";
const ULONG File_DfsClientRedirLen = 21;

const WCHAR *File_HgfsRedir = L"\\Device\\Mup\\;hgfs";  // VMWare
const ULONG File_HgfsRedirLen = 17;

const WCHAR *File_Mup = L"\\Device\\Mup";
const ULONG File_MupLen = 11;

const WCHAR *File_Device = L"\\Device\\";

const WCHAR *File_NamedPipe = L"\\Device\\NamedPipe";
const ULONG File_NamedPipeLen = 17;

// Desktop.ini 文本内容
static char *File_DesktopIniText = NULL;
```

---

## 6. 潜在关注点

### 6.1 路径解析复杂性

⚠️ **关键问题**：文件路径解析涉及多种格式和特殊情况：
- DOS 路径 (`C:\Windows`)
- NT 路径 (`\Device\HarddiskVolume1\Windows`)
- UNC 路径 (`\\Server\Share`)
- 重解析点（符号链接、挂载点）
- 网络重定向器路径

**风险**：路径解析错误可能导致文件泄漏到沙箱外部。

### 6.2 写时复制的性能影响

⚠️ **性能考虑**：首次写入大文件时需要完整复制，可能导致：
- 磁盘 I/O 峰值
- 延迟增加
- 磁盘空间消耗

**优化建议**：可以考虑增量复制或延迟复制策略。

### 6.3 重解析点处理

⚠️ **复杂性**：`File_AdjustBoxFilePath()` 需要处理重解析点（Reparse Points），如：
- 符号链接（Symbolic Links）
- 挂载点（Mount Points）
- 目录连接点（Junction Points）

**风险**：重解析点可能导致路径逃逸，需要仔细验证。

### 6.4 并发访问

⚠️ **线程安全**：多个进程可能同时访问同一个沙箱文件。

**处理方式**：依赖 Windows 文件系统的锁机制。

### 6.5 Desktop.ini 创建

⚠️ **观察**：`File_CreateBoxPath_2()` 在新创建的沙箱目录中创建 `desktop.ini` 文件，用于：
- 设置文件夹图标（指向 SbieCtrl.exe）
- 显示提示信息
- 标记为只读

**用途**：提供用户友好的视觉标识。

### 6.6 访问控制规则

⚠️ **配置依赖**：文件访问控制依赖配置文件中的规则：
- `OpenFilePath`: 允许访问的路径
- `ClosedFilePath`: 禁止访问的路径
- `ReadFilePath`: 只读访问的路径
- `WriteFilePath`: 允许写入的路径

**风险**：配置错误可能导致安全漏洞或功能异常。

### 6.7 网络文件系统支持

⚠️ **特殊处理**：代码支持多种网络文件系统：
- SMB/CIFS (LanmanRedirector)
- DFS (Distributed File System)
- VMWare HGFS (Host-Guest File System)

**复杂性**：网络路径的处理比本地路径更复杂。

### 6.8 分页文件处理

⚠️ **系统调用拦截**：`File_CreatePagingFile` 拦截分页文件创建。

**原因**：沙箱进程不应该创建系统级分页文件。

---

## 7. 架构设计亮点

### 7.1 双模式支持

代码支持两种文件系统过滤模式：
- **Minifilter**（Vista+）：现代的文件系统过滤框架
- **Parse Procedure Hook**（XP）：传统的钩子方法

使用函数指针动态选择实现：
```c
P_File_Init_2 p_File_Init_2 = File_Init_Filter;
if (Driver_OsVersion < DRIVER_WINDOWS_VISTA) {
    p_File_Init_2 = File_Init_XpHook;
}
```

### 7.2 分层路径处理

```
应用层路径 (C:\test.txt)
    ↓
DOS 路径转换
    ↓
NT 路径 (\Device\HarddiskVolume1\test.txt)
    ↓
沙箱路径映射
    ↓
物理路径 (\Device\HarddiskVolume1\Sandbox\Box\drive\C\test.txt)
```

### 7.3 灵活的访问控制

支持多种访问控制策略：
- 路径级别控制（精确匹配、通配符）
- 操作级别控制（读、写、删除）
- 进程级别控制（不同进程不同规则）

---

## 8. 代码质量评估

**优点**：
- ✅ 完善的错误处理（重试机制）
- ✅ 支持多种 Windows 版本
- ✅ 清晰的模块化设计
- ✅ 详细的路径处理逻辑

**改进空间**：
- ⚠️ 代码文件较大（2772 行），可以进一步拆分
- ⚠️ 部分函数较长，可读性可以提升
- ⚠️ 需要更多内联注释说明复杂逻辑
- ⚠️ 性能优化空间（缓存、延迟加载）

---

## 9. 安全性分析

### 9.1 路径逃逸防护

**防护措施**：
- 严格的路径解析和验证
- 重解析点检测和处理
- 符号链接跟踪限制

### 9.2 访问权限控制

**机制**：
- 基于配置的访问控制列表
- 运行时权限检查
- 拒绝危险的访问模式

### 9.3 隔离保证

**保证**：
- 写操作强制重定向到沙箱
- 删除操作不影响真实文件
- 进程间文件隔离

---

**分析完成时间**：2026-03-05  
**分析版本**：基于最新源代码  
**文件大小**：2772 行
