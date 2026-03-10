# 模块分析：内核驱动层（SbieDrv.sys）

## 概述

SbieDrv.sys 是 Sandboxie 的内核驱动，运行于 Ring 0，是沙箱安全隔离的根基。通过注册系统回调、文件系统过滤器、注册表过滤器、系统调用拦截，在进程级别强制执行沙箱策略。

## 基本信息

| 属性 | 值 |
|------|----|
| 输出文件 | `SbieDrv.sys` |
| 运行级别 | 内核态（Ring 0）|
| 加载方式 | SbieSvc 通过 SCM 加载 |
| 通信方式 | IOCTL + LPC |
| 源码目录 | `Sandboxie/core/drv/` |
| 支持架构 | x86、x64、ARM64 |

## 子模块职责

| 子模块 | 主文件 | 职责 |
|--------|--------|------|
| 驱动入口 | `driver.c` | 初始化/卸载 |
| API 接口 | `api.c` | IOCTL 分发、日志缓冲 |
| 进程管理 | `process.c` | 进程监控、沙箱化决策 |
| 文件虚拟化 | `file.c` + `file_flt.c` | Copy-on-Write |
| 注册表虚拟化 | `key.c` + `key_flt.c` | Copy-on-Write |
| IPC 隔离 | `ipc.c` | 命名对象访问控制 |
| GUI 隔离 | `gui.c` | UIPI/窗口消息保护 |
| 令牌管理 | `token.c` | 进程降权 |
| 线程管理 | `thread.c` | 跨进程访问保护 |
| 系统调用 | `syscall.c` | 系统调用拦截 |
| 网络过滤 | `wfp.c` | WFP 网络连接控制 |
| 配置系统 | `conf.c` | INI 配置解析 |
| Hook 框架 | `hook.c` | Inline Hook 基础设施 |
| 沙箱描述 | `box.c` | BOX 结构体管理 |
| 证书验证 | `verify.c` | 功能授权控制 |

## 架构图

```mermaid
graph TB
    subgraph USER[用户态]
        SVC[SbieSvc.exe]
        DLL[SbieDll.dll]
        GUI[SandMan.exe]
    end
    subgraph KERNEL[内核态 SbieDrv.sys]
        API[api.c IOCTL接口]
        PROC[process.c 进程管理]
        FILE[file.c 文件虚拟化]
        KEY[key.c 注册表虚拟化]
        IPC[ipc.c IPC隔离]
        TOKEN[token.c 令牌管理]
        WFP[wfp.c 网络过滤]
    end
    GUI -->|IOCTL| API
    SVC -->|IOCTL+LPC| API
    DLL -->|IOCTL| API
    API -->|LPC| SVC
    PROC --> FILE
    PROC --> KEY
    PROC --> IPC
    PROC --> TOKEN
    PROC --> WFP
```

## 关键内核回调

| 回调 API | 处理函数 | 用途 |
|---------|----------|------|
| `PsSetCreateProcessNotifyRoutineEx` | `Process_NotifyProcessEx` | 进程创建/销毁 |
| `PsSetLoadImageNotifyRoutine` | `Process_NotifyImage` | 映像加载 |
| `PsSetCreateThreadNotifyRoutine` | `Thread_Notify` | 线程创建 |
| `FltRegisterFilter` | `File_PreOperation` | 文件系统过滤 |
| `CmRegisterCallbackEx` | `Key_Callback` | 注册表过滤 |
| `ObRegisterCallbacks` | `Thread_CheckProcessObject` | 对象访问保护 |
| `FwpsCalloutRegister` | `WFP_ClassifyFn` | 网络过滤 |

## 进程沙箱化完整时序

```mermaid
sequenceDiagram
    participant K as Windows内核
    participant PN as Process_NotifyProcessEx
    participant PR as Process_Create
    participant IMG as Process_NotifyImage
    participant SVC as SbieSvc
    participant P as 新进程

    K->>PN: 进程创建通知
    PN->>PN: 沙箱化决策
    PN->>PR: 创建PROCESS结构体
    PR->>PR: 读取INI配置
    PR->>PR: 初始化锁和规则
    PN->>SVC: Process_Low_Inject 通知注入
    SVC->>P: 注入LowLevel.dll+SbieDll.dll
    K->>IMG: 映像加载通知(ntdll)
    IMG->>IMG: File_CreateBoxPath
    IMG->>IMG: Key_MountHive
    IMG->>IMG: Token_ReplacePrimary
    IMG->>IMG: proc.initialized=TRUE
    P->>P: Dll_InitInjected Hook初始化
```

## 文件/注册表虚拟化原理

```mermaid
flowchart LR
    A[沙箱进程 IO 请求] --> B{路径类型判断}
    B -->|OpenFilePath| C[允许访问真实路径]
    B -->|ClosedFilePath| D[拒绝访问]
    B -->|读取其他路径| E{CopyPath存在?}
    E -->|是| F[读CopyPath]
    E -->|否| G[读TruePath]
    B -->|写入| H[写CopyPath]
    B -->|删除| I[在CopyPath写删除标记]
```
