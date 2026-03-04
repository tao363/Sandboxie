# Sandboxie 项目技术原理深度分析

> 本文档详细分析 Sandboxie 沙箱系统的核心技术原理和实现机制

## 📋 目录

1. [项目概述](#1-项目概述)
2. [核心架构](#2-核心架构)
3. [内核驱动层详解](#3-内核驱动层详解)
4. [用户态DLL层详解](#4-用户态dll层详解)
5. [服务层详解](#5-服务层详解)
6. [关键技术原理](#6-关键技术原理)
7. [执行流程分析](#7-执行流程分析)
8. [安全机制](#8-安全机制)

---

## 1. 项目概述

### 1.1 什么是 Sandboxie

Sandboxie 是一个基于沙箱隔离技术的 Windows 安全软件，通过创建隔离的虚拟环境来运行应用程序，防止程序对系统造成永久性修改。

**核心特性：**
- ✅ 文件系统虚拟化（写时复制）
- ✅ 注册表虚拟化
- ✅ 进程隔离和访问控制
- ✅ IPC（进程间通信）隔离
- ✅ 网络过滤和控制
- ✅ COM 对象隔离

### 1.2 技术栈

```
编程语言: C/C++
内核驱动: WDM (Windows Driver Model)
用户界面: Qt 6 (Plus版) / MFC (Classic版)
构建工具: Visual Studio 2022
支持系统: Windows 7 - Windows 11 (x64/ARM64)
```

---

## 2. 核心架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────┐
│                    应用程序层                              │
│              (被沙箱化的应用程序)                          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                 SbieDll.dll                              │
│            (用户态 Hook 和重定向)                         │
│  • API Hooking (CreateFile, RegSetValue...)             │
│  • 路径转换 (真实路径 ↔ 沙箱路径)                         │
│  • 与 SbieSvc 通信 (LPC)                                 │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼──────┐         ┌───────▼──────────┐
│  SbieSvc.exe │         │   SbieDrv.sys    │
│  (系统服务)   │◄────────┤   (内核驱动)      │
│              │  IOCTL  │                  │
└──────────────┘         └──────────────────┘
        │                         │
        │                         │
┌───────▼─────────────────────────▼──────────────────────┐
│              Windows 操作系统内核                         │
│  • 文件系统 (NTFS)                                       │
│  • 注册表 (Registry)                                     │
│  • 进程管理 (Process Manager)                            │
│  • 对象管理 (Object Manager)                             │
└─────────────────────────────────────────────────────────┘
```

### 2.2 三层架构详解

#### 第一层：内核驱动层 (SbieDrv.sys)

**职责：**
- 系统调用拦截（Syscall Hooking）
- 文件系统过滤（Minifilter）
- 进程创建监控
- 内核对象访问控制

**关键技术：**
- SSDT Hook (Windows XP/Vista)
- Inline Hook (Windows 7+)
- Minifilter Framework (文件系统)
- Process/Thread Notify Callbacks

#### 第二层：用户态DLL层 (SbieDll.dll)

**职责：**
- Windows API Hooking
- 路径重定向和转换
- 与服务层通信
- 特殊功能实现（COM、GUI等）

**关键技术：**
- IAT (Import Address Table) Hook
- Inline Hook (Detours-like)
- LPC (Local Procedure Call)

#### 第三层：服务层 (SbieSvc.exe)

**职责：**
- 沙箱配置管理
- 进程启动和管理
- 权限提升代理
- 文件恢复服务

---

## 3. 内核驱动层详解

### 3.1 驱动初始化流程

```c
DriverEntry()
  ├─ Driver_CheckOsVersion()        // 检查操作系统版本
  ├─ Pool_Create()                  // 创建内存池
  ├─ Driver_InitPublicSecurity()    // 初始化安全描述符
  ├─ Driver_FindSystemRoot()        // 查找系统根目录
  ├─ Driver_FindHomePath()          // 查找安装路径
  ├─ MyValidateCertificate()        // 验证证书
  ├─ Obj_Init()                     // 对象管理初始化
  ├─ Conf_Init()                    // 配置管理初始化
  ├─ Dll_Init()                     // DLL注入初始化
  ├─ Syscall_Init()                 // 系统调用拦截初始化
  ├─ Session_Init()                 // 会话管理初始化
  ├─ Token_Init()                   // 令牌管理初始化
  ├─ Process_Init()                 // 进程管理初始化
  ├─ Thread_Init()                  // 线程管理初始化
  ├─ File_Init()                    // 文件系统初始化
  ├─ Key_Init()                     // 注册表初始化
  ├─ Ipc_Init()                     // IPC初始化
  ├─ Gui_Init()                     // GUI初始化
  ├─ Api_Init()                     // API接口初始化
  └─ Wfp_Init()                     // 网络过滤初始化
```

### 3.2 系统调用拦截机制

**原理：** 拦截 Windows 系统调用，在执行前进行权限检查和路径重定向。

**实现方式（Windows 10+）：**

```
用户态应用调用 ntdll!NtCreateFile
         ↓
    syscall 指令
         ↓
内核态 nt!NtCreateFile
         ↓
Sandboxie Hook 检测到调用
         ↓
    检查进程是否在沙箱中
         ↓
    YES: 调用 File_NtCreateFile (Sandboxie处理)
         ↓
    路径重定向 + 权限检查
         ↓
    调用原始 NtCreateFile
         ↓
    返回结果
```

**拦截的关键系统调用：**

| 类别 | 系统调用 | 用途 |
|------|---------|------|
| 文件 | NtCreateFile, NtOpenFile | 文件创建/打开 |
| 注册表 | NtCreateKey, NtOpenKey | 注册表操作 |
| 进程 | NtCreateUserProcess | 进程创建 |
| 线程 | NtCreateThread | 线程创建 |
| IPC | NtCreateEvent, NtCreateMutant | 同步对象 |
| 端口 | NtAlpcConnectPort | ALPC通信 |

### 3.3 文件系统虚拟化

**核心原理：写时复制（Copy-on-Write）**

```
真实文件系统:
C:\Windows\System32\test.txt

沙箱文件系统:
C:\Sandbox\DefaultBox\drive\C\Windows\System32\test.txt
```

**操作流程：**

1. **读取操作：**
   ```
   应用读取 C:\test.txt
   → 检查沙箱目录是否存在
   → 存在: 读取沙箱文件
   → 不存在: 读取真实文件
   ```

2. **写入操作：**
   ```
   应用写入 C:\test.txt
   → 检查沙箱目录是否存在
   → 不存在: 复制真实文件到沙箱
   → 写入沙箱文件
   → 真实文件保持不变
   ```

3. **删除操作：**
   ```
   应用删除 C:\test.txt
   → 在沙箱中标记为已删除
   → 真实文件保持不变
   ```

### 3.4 进程隔离机制

**进程创建监控：**

```c
// 注册进程通知回调
PsSetCreateProcessNotifyRoutineEx(Process_NotifyProcessEx, FALSE);

// 回调函数
void Process_NotifyProcessEx(
    PEPROCESS Process,
    HANDLE ProcessId,
    PPS_CREATE_NOTIFY_INFO CreateInfo)
{
    if (CreateInfo) {
        // 进程创建
        // 1. 判断是否需要沙箱化
        // 2. 创建 PROCESS 对象
        // 3. 注入 SbieDll.dll
    } else {
        // 进程终止
        // 清理资源
    }
}
```

**沙箱化决策流程：**

```
新进程创建
    ↓
父进程是否在沙箱中？
    ↓ YES
继承父进程沙箱
    ↓ NO
是否在强制进程列表中？
    ↓ YES
强制沙箱化
    ↓ NO
正常启动（不沙箱化）
```

---

## 4. 用户态DLL层详解

### 4.1 DLL注入机制

**注入时机：** 进程创建时，在第一条用户态代码执行前

**注入方法：**

1. **LowLevel 注入（主要方法）：**
   ```
   内核驱动在进程创建时
   → 分配用户态内存
   → 写入 LowLevel.dll 代码
   → 修改进程入口点
   → LowLevel.dll 加载 SbieDll.dll
   ```

2. **AppInit_DLLs（备用方法）：**
   ```
   修改注册表
   HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows
   AppInit_DLLs = SbieDll.dll
   ```

### 4.2 API Hooking 技术

**Hook 方法：**

```c
// 1. IAT Hook (Import Address Table)
原始: CreateFileW -> kernel32!CreateFileW
Hook: CreateFileW -> SbieDll!File_CreateFileW
                  -> kernel32!CreateFileW

// 2. Inline Hook (函数开头跳转)
原始函数:
  mov edi, edi
  push ebp
  mov ebp, esp
  ...

Hook后:
  jmp SbieDll!Hook_Function
  nop
  nop
  ...
```

**关键 Hook 函数：**

| API | Hook函数 | 用途 |
|-----|---------|------|
| CreateFileW | File_CreateFileW | 文件路径重定向 |
| RegCreateKeyExW | Key_CreateKeyExW | 注册表重定向 |
| CreateProcessW | Proc_CreateProcessW | 子进程沙箱化 |
| LoadLibraryW | Ldr_LoadLibraryW | DLL加载控制 |

### 4.3 路径转换机制

**转换函数：**

```c
// 真实路径 → 沙箱路径
NTSTATUS File_GetName(
    HANDLE FileHandle,
    WCHAR **OutTruePath,
    WCHAR **OutCopyPath,
    ULONG *OutFlags)
{
    // 1. 获取真实路径
    // 2. 检查访问规则
    // 3. 生成沙箱路径
    // 4. 返回转换结果
}
```

**路径映射示例：**

```
真实路径                          沙箱路径
─────────────────────────────────────────────────────────
C:\Windows\test.txt          →   C:\Sandbox\Box\drive\C\Windows\test.txt
C:\Users\User\Desktop        →   C:\Sandbox\Box\user\current\Desktop
\\Server\Share\file.doc      →   C:\Sandbox\Box\share\Server\Share\file.doc
HKCU\Software\App            →   HKCU\Software\Sandboxie\Box\user\Software\App
```

---

## 5. 服务层详解

### 5.1 SbieSvc 架构

```
SbieSvc.exe (主进程)
    ├─ PipeServer (LPC通信服务器)
    │   ├─ 监听端口: \RPC Control\SbieSvcPort
    │   ├─ 工作线程池
    │   └─ 消息路由
    │
    ├─ ProcessServer (进程管理)
    │   ├─ RunSandboxed (启动沙箱进程)
    │   ├─ TerminateAll (终止所有进程)
    │   └─ QueryProcess (查询进程信息)
    │
    ├─ SbieIniServer (配置管理)
    │   ├─ GetSetting (读取配置)
    │   ├─ SetSetting (写入配置)
    │   └─ ReloadConf (重新加载配置)
    │
    ├─ GuiServer (GUI代理)
    │   ├─ OpenWindow (打开窗口)
    │   ├─ QueryWindow (查询窗口)
    │   └─ ClipboardOp (剪贴板操作)
    │
    └─ DriverAssist (驱动辅助)
        ├─ InjectDll (注入DLL)
        ├─ GetLog (获取日志)
        └─ SetConf (设置配置)
```

### 5.2 LPC 通信机制

**通信流程：**

```
沙箱进程 (SbieDll.dll)          SbieSvc.exe
    │                              │
    │  1. NtConnectPort            │
    ├──────────────────────────────>│
    │                              │ 2. 接受连接
    │  3. 连接成功                  │
    │<──────────────────────────────┤
    │                              │
    │  4. 发送请求 (SBIELOW_CALL)   │
    ├──────────────────────────────>│
    │                              │ 5. 处理请求
    │                              │ 6. 调用相应服务器
    │  7. 返回结果                  │
    │<──────────────────────────────┤
```

**消息结构：**

```c
typedef struct _SBIELOW_CALL {
    PORT_MESSAGE h;              // LPC消息头
    ULONG msgid;                 // 消息ID
    ULONG session_id;            // 会话ID
    ULONG process_id;            // 进程ID
    ULONG64 parms[8];            // 参数数组
} SBIELOW_CALL;
```

---

## 6. 关键技术原理

### 6.1 写时复制（Copy-on-Write）

**原理：** 只在首次写入时复制文件，读取操作直接访问原文件。

**优势：**
- 节省磁盘空间
- 提高性能
- 快速启动

**实现：**

```c
NTSTATUS File_NtCreateFile(...) {
    // 1. 解析路径
    File_GetName(handle, &true_path, &copy_path, &flags);
    
    // 2. 检查访问类型
    if (DesiredAccess & FILE_WRITE_DATA) {
        // 写入操作
        if (!FileExists(copy_path)) {
            // 首次写入，复制文件
            File_CopyFile(true_path, copy_path);
        }
        // 打开沙箱文件
        return NtCreateFile(copy_path, ...);
    } else {
        // 只读操作
        if (FileExists(copy_path)) {
            return NtCreateFile(copy_path, ...);
        } else {
            return NtCreateFile(true_path, ...);
        }
    }
}
```

### 6.2 注册表虚拟化

**实现方式：**

```
真实注册表:
HKEY_CURRENT_USER\Software\MyApp

虚拟注册表:
HKEY_CURRENT_USER\Software\Sandboxie\DefaultBox\user\Software\MyApp
```

**合并视图：**

```
读取 HKCU\Software\MyApp\Setting
    ↓
1. 检查虚拟注册表
    ↓ 存在
返回虚拟值
    ↓ 不存在
2. 检查真实注册表
    ↓
返回真实值
```

### 6.3 进程令牌限制

**令牌修改：**

```c
Token_CreateToken() {
    // 1. 复制原始令牌
    // 2. 降低完整性级别 (Medium → Low)
    // 3. 移除管理员权限
    // 4. 添加受限 SID
    // 5. 限制特权
}
```

**权限限制：**

```
原始令牌:
- Integrity: High
- Admin: Yes
- Privileges: SeDebugPrivilege, SeBackupPrivilege...

沙箱令牌:
- Integrity: Low/Untrusted
- Admin: No
- Privileges: (受限)
- Restricted SIDs: S-1-15-2-1 (Sandboxie)
```

### 6.4 网络过滤（WFP）

**Windows Filtering Platform 集成：**

```c
Wfp_Init() {
    // 1. 注册过滤引擎
    FwpmEngineOpen(...);
    
    // 2. 添加过滤层
    // - FWPM_LAYER_ALE_AUTH_CONNECT_V4
    // - FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4
    
    // 3. 设置过滤规则
    // - 允许/阻止特定IP
    // - 允许/阻止特定端口
    // - 允许/阻止特定程序
}
```

---

## 7. 执行流程分析

### 7.1 启动沙箱程序完整流程

```
1. 用户操作
   用户点击 "在沙箱中运行" notepad.exe
        ↓
2. SandMan.exe (GUI)
   发送启动请求到 SbieSvc
        ↓
3. SbieSvc.exe (服务)
   ProcessServer::RunSandboxed()
   ├─ 读取沙箱配置
   ├─ 通知驱动准备启动
   └─ 调用 CreateProcess
        ↓
4. SbieDrv.sys (驱动)
   Process_NotifyProcessEx() 回调
   ├─ 检测到新进程创建
   ├─ 创建 PROCESS 对象
   ├─ 设置沙箱标记
   └─ 注入 LowLevel.dll
        ↓
5. LowLevel.dll (注入代码)
   ├─ 加载 SbieDll.dll
   ├─ 初始化 Hook
   └─ 跳转到程序入口点
        ↓
6. SbieDll.dll (用户态Hook)
   Dll_InitInjected()
   ├─ Hook Windows API
   ├─ 连接到 SbieSvc
   ├─ 初始化路径转换
   └─ 设置环境变量
        ↓
7. notepad.exe (应用程序)
   正常运行，所有操作被拦截和重定向
```

### 7.2 文件操作流程示例

**场景：** 沙箱中的程序创建文件 `C:\test.txt`

```
1. 应用调用
   CreateFileW(L"C:\\test.txt", GENERIC_WRITE, ...)
        ↓
2. SbieDll Hook
   File_CreateFileW() 拦截
   ├─ 转换路径: C:\test.txt
   │   → C:\Sandbox\Box\drive\C\test.txt
   ├─ 检查访问规则
   └─ 调用原始 CreateFileW
        ↓
3. 内核态
   ntdll!NtCreateFile
        ↓
4. SbieDrv 拦截
   File_NtCreateFile()
   ├─ 验证路径转换
   ├─ 检查权限
   ├─ 创建沙箱目录
   └─ 调用原始 NtCreateFile
        ↓
5. 文件系统
   创建文件: C:\Sandbox\Box\drive\C\test.txt
        ↓
6. 返回句柄
   应用程序获得文件句柄，继续操作
```

---

## 8. 安全机制

### 8.1 多层防护

```
┌─────────────────────────────────────┐
│  应用层防护                          │
│  - API Hook                         │
│  - 路径重定向                        │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  内核层防护                          │
│  - 系统调用拦截                      │
│  - 对象访问控制                      │
│  - 进程隔离                          │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  配置层防护                          │
│  - 访问规则                          │
│  - 黑白名单                          │
│  - 网络过滤                          │
└─────────────────────────────────────┘
```

### 8.2 安全特性

**1. 进程隔离**
- 沙箱进程无法访问其他进程
- 无法注入代码到外部进程
- 无法读取外部进程内存

**2. 文件系统保护**
- 写操作重定向到沙箱
- 敏感目录只读访问
- 可配置访问规则

**3. 注册表保护**
- 注册表修改虚拟化
- 系统注册表只读
- 隔离应用配置

**4. 网络控制**
- 基于 WFP 的防火墙
- IP/端口过滤
- DNS 重定向

**5. 权限降级**
- 降低完整性级别
- 移除管理员权限
- 限制系统特权

---

## 9. 配置示例

### 9.1 基本沙箱配置

```ini
[DefaultBox]
# 沙箱类型
BoxNameTitle=默认沙箱
Enabled=y

# 文件访问
OpenFilePath=%UserProfile%\Downloads
ClosedFilePath=C:\Windows\System32
WriteFilePath=C:\Temp

# 注册表访问
OpenKeyPath=HKCU\Software\MyApp
ClosedKeyPath=HKLM\System

# IPC访问
OpenIpcPath=\BaseNamedObjects\MyEvent
ClosedIpcPath=\RPC Control

# 进程限制
ForceProcess=iexplore.exe
ForceProcess=chrome.exe

# 网络限制
NetworkAccess=y
AllowNetworkAccess=192.168.1.0/24,80
BlockNetworkAccess=*,443
```

### 9.2 高安全性配置

```ini
[SecureBox]
# 安全增强
UseSecurityMode=y
UsePrivacyMode=y
DropAdminRights=y

# 严格隔离
ClosedFilePath=C:\
OpenFilePath=%UserProfile%\Downloads
ReadFilePath=C:\Program Files

# 网络隔离
NetworkAccess=n

# 进程限制
ForceChildren=y
```

---

## 10. 总结

Sandboxie 通过多层技术实现了强大的沙箱隔离：

1. **内核驱动层** - 系统调用拦截和底层隔离
2. **用户态DLL层** - API Hook 和路径重定向
3. **服务层** - 配置管理和进程控制

核心技术包括：
- ✅ 写时复制文件系统
- ✅ 注册表虚拟化
- ✅ 进程令牌限制
- ✅ 网络过滤
- ✅ IPC 隔离

这些技术共同构建了一个安全、高效、灵活的沙箱环境。

---

**文档版本：** 1.0  
**最后更新：** 2024  
**作者：** Sandboxie 技术分析团队
