# 文件级分析：driver.c

## 1. 文件概述

**职责定位**：驱动程序的入口点和初始化管理器，负责整个 Sandboxie 内核驱动的启动、初始化和卸载流程。

**文件类型**：内核驱动入口 / 初始化模块

**文件路径**：`Sandboxie/core/drv/driver.c`

**所属模块**：内核驱动层 (SbieDrv.sys)

---

## 2. 公开接口（Public API）

| 名称 | 类型 | 签名/参数 | 返回值 | 简要说明 |
|------|------|----------|--------|----------|
| DriverEntry | 函数 | (DRIVER_OBJECT*, UNICODE_STRING*) | NTSTATUS | 驱动程序主入口点，初始化所有子系统 |
| Driver_CheckOsVersion | 静态函数 | (void) | BOOLEAN | 检查操作系统版本兼容性 |
| Driver_InitPublicSecurity | 静态函数 | (void) | BOOLEAN | 初始化公共安全描述符 |
| Driver_FindSystemRoot | 静态函数 | (void) | BOOLEAN | 查找系统根目录路径 |
| Driver_FindHomePath | 静态函数 | (UNICODE_STRING*) | BOOLEAN | 查找 Sandboxie 安装路径 |
| SbieDrv_DriverUnload | 静态函数 | (DRIVER_OBJECT*) | void | 驱动卸载处理函数 |

---

## 3. 核心逻辑

### 3.1 驱动初始化流程

```
DriverEntry()
    ↓
1. 初始化全局变量
   - Driver_Object = DriverObject
   - 设置 Driver_Altitude (过滤器高度)
    ↓
2. 检查操作系统版本
   Driver_CheckOsVersion()
   - 获取 Windows 版本号
   - 检查是否支持当前系统
    ↓
3. 创建内存池
   Pool_Create()
    ↓
4. 初始化安全描述符
   Driver_InitPublicSecurity()
    ↓
5. 查找系统路径
   Driver_FindSystemRoot()
   Driver_FindHomePath()
    ↓
6. 验证证书
   MyValidateCertificate()
    ↓
7. 初始化各子系统（按顺序）
   - Obj_Init()      // 对象管理
   - Conf_Init()     // 配置管理
   - Dll_Init()      // DLL 注入
   - Syscall_Init()  // 系统调用拦截
   - Session_Init()  // 会话管理
   - Token_Init()    // 令牌管理
   - Process_Init()  // 进程管理
   - Thread_Init()   // 线程管理
   - File_Init()     // 文件系统
   - Key_Init()      // 注册表
   - Ipc_Init()      // IPC
   - Gui_Init()      // GUI
   - Api_Init()      // API 接口
   - Wfp_Init()      // 网络过滤
    ↓
8. 设置卸载回调
   DriverObject->DriverUnload = SbieDrv_DriverUnload
    ↓
9. 返回 STATUS_SUCCESS
```

### 3.2 关键初始化步骤

**操作系统版本检查**：
- 支持 Windows 7 (6.1) 到 Windows 11 (10.0+)
- 检测测试签名模式
- 获取系统构建号

**路径初始化**：
- `Driver_SystemRootPathNt`: 系统根目录 (如 `\Device\HarddiskVolume1\Windows`)
- `Driver_HomePathNt`: Sandboxie 安装目录
- `Driver_HomePathDos`: DOS 格式的安装路径

**安全初始化**：
- 创建公共安全描述符 (允许所有用户访问)
- 创建低完整性级别安全描述符

---

## 4. 依赖关系

### 内部依赖（项目内）

| 依赖文件 | 用途 |
|---------|------|
| driver.h | 驱动程序头文件定义 |
| obj.h/obj.c | 对象管理子系统 |
| conf.h/conf.c | 配置管理子系统 |
| dll.h/dll.c | DLL 注入子系统 |
| syscall.h/syscall.c | 系统调用拦截 |
| process.h/process.c | 进程管理 |
| thread.h/thread.c | 线程管理 |
| file.h/file.c | 文件系统虚拟化 |
| key.h/key.c | 注册表虚拟化 |
| ipc.h/ipc.c | IPC 隔离 |
| gui.h/gui.c | GUI 管理 |
| api.h/api.c | IOCTL 接口 |
| wfp.h/wfp.c | 网络过滤 |
| token.h/token.c | 令牌管理 |
| util.h/util.c | 工具函数 |

### 外部依赖（Windows 内核）

| 依赖库/API | 用途 |
|-----------|------|
| ntddk.h | Windows 驱动开发工具包 |
| ExInitializeDriverRuntime | 初始化驱动运行时 |
| RtlInitUnicodeString | Unicode 字符串初始化 |
| ZwSetInformationToken | 令牌操作 |
| ZwCreateToken/ZwCreateTokenEx | 令牌创建 |
| MmCopyMemory | 内存复制 |
| PsIsWin32KFilterEnabledForProcess | Win32k 过滤检查 |

---

## 5. 数据模型 / 类型定义

### 全局变量

```c
// 驱动对象
DRIVER_OBJECT *Driver_Object;

// 版本信息
WCHAR *Driver_Version;              // 版本字符串
ULONG Driver_OsVersion;             // 操作系统版本
ULONG Driver_OsBuild;               // 系统构建号
BOOLEAN Driver_OsTestSigning;       // 测试签名模式

// 内存池
POOL *Driver_Pool;

// 路径信息
WCHAR *Driver_SystemRootPathNt;     // 系统根目录 (NT 格式)
ULONG Driver_SystemRootPathNt_Len;  // 路径长度
WCHAR *Driver_HomePathDos;          // 安装目录 (DOS 格式)
WCHAR *Driver_HomePathNt;           // 安装目录 (NT 格式)
ULONG Driver_HomePathNt_Len;        // 路径长度

// 安全描述符
PSECURITY_DESCRIPTOR Driver_PublicSd;    // 公共安全描述符
PACL Driver_PublicAcl;                   // 公共 ACL
PSECURITY_DESCRIPTOR Driver_LowLabelSd;  // 低完整性级别 SD

// 状态标志
volatile BOOLEAN Driver_Unloading;  // 卸载标志
BOOLEAN Driver_FullUnload;          // 完全卸载标志

// 过滤器高度
UNICODE_STRING Driver_Altitude;
const WCHAR* Altitude_Str = FILTER_ALTITUDE;

// 进程标志
ULONG Process_Flags1;
ULONG Process_Flags2;
ULONG Process_Flags3;
```

### 常量定义

```c
const ULONG tzuk = 'xobs';  // 'sbox' 的小端表示

// 系统账户 SID
const WCHAR *Driver_S_1_5_18 = L"S-1-5-18";  // System
const WCHAR *Driver_S_1_5_19 = L"S-1-5-19";  // Local Service
const WCHAR *Driver_S_1_5_20 = L"S-1-5-20";  // Network Service

// 路径常量
const WCHAR *Driver_Sandbox = L"\\Sandbox";
const WCHAR *Driver_Empty = L"";
```

---

## 6. 潜在关注点

### 6.1 初始化顺序依赖

⚠️ **关键问题**：各子系统的初始化顺序是固定的，必须严格遵守。如果顺序错误，可能导致驱动崩溃。

**依赖关系**：
- `Obj_Init()` 必须最先初始化（其他模块依赖对象管理）
- `Conf_Init()` 必须在 `Dll_Init()` 之前（DLL 注入需要读取配置）
- `Syscall_Init()` 必须在 `Process_Init()` 之前（进程管理依赖系统调用拦截）

### 6.2 错误处理

⚠️ **观察**：初始化失败时，代码使用 `ok` 标志进行链式检查。如果任何步骤失败，后续步骤会被跳过。

**改进建议**：应该添加清理代码，释放已分配的资源。

### 6.3 版本兼容性

⚠️ **注意**：代码需要支持从 Windows 7 到 Windows 11 的多个版本，不同版本的内核 API 可能有差异。

**处理方式**：
- 使用 `Driver_OsVersion` 进行版本判断
- 动态获取函数指针（如 `ZwCreateToken`）
- ARM64 架构有特殊处理

### 6.4 安全性

⚠️ **证书验证**：`MyValidateCertificate()` 用于验证驱动证书，这是授权机制的一部分。

⚠️ **测试签名模式**：`Driver_OsTestSigning` 检测系统是否启用测试签名，这可能影响驱动加载。

### 6.5 内存管理

⚠️ **内存池**：所有驱动内存分配都通过 `Driver_Pool`，如果池创建失败，驱动无法运行。

### 6.6 卸载处理

⚠️ **卸载标志**：`Driver_Unloading` 是 volatile 变量，用于多线程环境下的卸载同步。

⚠️ **完全卸载**：`Driver_FullUnload` 控制是否完全卸载驱动（可能用于调试或热重载）。

---

## 7. 架构设计亮点

### 7.1 模块化设计

驱动采用高度模块化的设计，每个功能都是独立的子系统：
- 文件系统虚拟化 (File)
- 注册表虚拟化 (Key)
- 进程隔离 (Process)
- IPC 隔离 (Ipc)
- 网络过滤 (Wfp)

### 7.2 分层架构

```
应用层
    ↓
用户态 DLL (SbieDll.dll)
    ↓
系统服务 (SbieSvc.exe)
    ↓
内核驱动 (SbieDrv.sys) ← driver.c 是入口
    ↓
Windows 内核
```

### 7.3 跨平台支持

代码支持多种架构：
- x86 (32-bit)
- x64 (64-bit)
- ARM64

使用条件编译 (`#ifdef _M_ARM64`) 处理架构差异。

---

## 8. 代码质量评估

**优点**：
- ✅ 清晰的初始化流程
- ✅ 良好的模块化设计
- ✅ 详细的版本兼容性处理
- ✅ 使用 ALLOC_PRAGMA 优化内存

**改进空间**：
- ⚠️ 错误处理可以更完善（需要资源清理）
- ⚠️ 部分全局变量可以封装
- ⚠️ 缺少详细的内联注释

---

**分析完成时间**：2026-03-05  
**分析版本**：基于最新源代码
