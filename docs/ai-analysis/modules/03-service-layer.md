# 模块分析：系统服务层（SbieSvc.exe）

## 概述

SbieSvc.exe 是 Sandboxie 的**系统服务进程**，以 SYSTEM 权限运行，在用户态与内核驱动之间充当桥梁。它负责加载驱动、管理 DLL 注入、代理沙箱进程的特权操作，以及为 GUI 提供管理接口。

## 基本信息

| 属性 | 值 |
|------|----|
| 输出文件 | `SbieSvc.exe` |
| 运行权限 | SYSTEM（Windows 服务）|
| 服务名称 | `SbieSvc` |
| 通信方式 | 命名管道（← SbieDll/GUI）+ LPC（← SbieDrv）|
| 源码目录 | `Sandboxie/core/svc/` |

## 子组件架构

```mermaid
graph TB
    subgraph SVC[SbieSvc.exe]
        MAIN[main.cpp 服务入口]
        DA[DriverAssist 驱动辅助]
        PIPE[PipeServer 管道框架]
        PS[ProcessServer 进程管理]
        GS[GuiServer GUI服务]
        FS[FileServer 文件代理]
        IS[IniServer 配置服务]
        CS[ComServer COM代理]
        NS[NetworkServer 网络代理]
        SS[ServiceServer SCM代理]
    end
    MAIN --> DA
    MAIN --> PIPE
    PIPE --> PS
    PIPE --> GS
    PIPE --> FS
    PIPE --> IS
    PIPE --> CS
    PIPE --> NS
    PIPE --> SS
```

## 子组件职责

| 组件 | 文件 | 职责 |
|------|------|------|
| `DriverAssist` | `DriverAssist.cpp` + 系列 | 驱动加载、LPC 通信、DLL 注入协调 |
| `PipeServer` | `PipeServer.cpp` | 命名管道服务框架（消息路由）|
| `ProcessServer` | `ProcessServer.cpp` | 进程启动/终止/挂起 |
| `GuiServer` | `GuiServer.cpp` | Job Object、窗口站管理 |
| `FileServer` | `fileserver.cpp` | 文件特权操作代理 |
| `SbieIniServer` | `sbieiniserver.cpp` | 配置文件读写 |
| `ComServer` | `comserver.cpp` | COM 激活代理 |
| `IpHlpServer` | `iphlpserver.cpp` | IP Helper API 代理 |
| `ServiceServer` | `serviceserver.cpp` | SCM 服务访问代理 |
| `TerminalServer` | `terminalserver.cpp` | 终端服务代理 |
| `UserServer` | `UserServer.cpp` | 用户信息查询 |
| `MountManager` | `MountManager.cpp` | 磁盘挂载管理 |
| `QueueServer` | `queueserver.cpp` | 异步操作队列 |

## 通信架构

```mermaid
graph LR
    DRV[SbieDrv.sys] -->|LPC 端口| DA[DriverAssist]
    DLL[SbieDll.dll] -->|命名管道| PIPE[PipeServer]
    GUI[SandMan.exe] -->|命名管道| PIPE
    DA -->|IOCTL| DRV
    PIPE -->|路由| PS[ProcessServer]
    PIPE -->|路由| FS[FileServer]
    PIPE -->|路由| IS[IniServer]
```

## 进程启动代理时序

```mermaid
sequenceDiagram
    participant GUI as SandMan
    participant PS as ProcessServer
    participant DA as DriverAssist
    participant DRV as SbieDrv
    participant NP as 新进程

    GUI->>PS: MSGID_PROCESS_RUN_SANDBOXED(box, cmd)
    PS->>DRV: API_START_PROCESS IOCTL
    PS->>NP: CreateProcessAsUserW
    DRV->>DA: LPC SVC_INJECT_PROCESS
    DA->>NP: WriteProcessMemory + CreateRemoteThread
    NP->>NP: LowLevel→SbieDll 加载
    DA->>DRV: API_INJECT_COMPLETE
    PS-->>GUI: 进程启动完成
```

## 特权操作代理模式

沙箱进程需要某些特权操作时，通过 SbieSvc 代理执行：

| 操作 | 原因 | 代理组件 |
|------|------|--------|
| 创建/终止进程 | 需要 SeDebugPrivilege | ProcessServer |
| 挂载磁盘镜像 | 需要 SeManageVolumePrivilege | MountManager |
| 读写配置文件 | 配置文件访问保护 | IniServer |
| 启动系统服务 | SCM 访问限制 | ServiceServer |
| COM 服务激活 | COM 权限限制 | ComServer |
