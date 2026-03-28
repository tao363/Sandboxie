# Sandboxie-Plus — 架构总览

> **一句话描述：** Sandboxie-Plus 是一个开源 Windows 沙箱隔离软件，通过内核驱动拦截系统调用，将进程的文件/注册表/IPC 操作重定向到沙箱目录，实现进程隔离而不影响用户体验。

---

## 系统架构图

```mermaid
graph TD
    User([用户 / 管理员]) --> SandMan[SandMan.exe\nQt GUI 管理界面]
    User --> SbieCtrl[SbieCtrl.exe\n经典 MFC UI]

    SandMan --> QSbieAPI[QSbieAPI.dll\nAPI 封装层]
    SbieCtrl --> QSbieAPI
    QSbieAPI -->|IOCTL\n\\Device\\SandboxieDriverApi| SbieDrv
    QSbieAPI -->|LPC\n\\RPC Control\\SbieSvcPort| SbieSvc

    App([沙箱内应用程序]) --> SbieDll[SbieDll.dll\n注入到每个沙箱进程]
    SbieDll -->|命名管道| SbieSvc
    SbieDll -->|直接系统调用| SbieDrv

    SbieSvc[SbieSvc.exe\n系统服务] -->|IOCTL| SbieDrv[SbieDrv.sys\n内核驱动]
    SbieDrv --> WinKernel([Windows 内核])

    subgraph "用户态"
        SandMan
        SbieCtrl
        QSbieAPI
        SbieSvc
        SbieDll
        App
    end

    subgraph "内核态"
        SbieDrv
        WinKernel
    