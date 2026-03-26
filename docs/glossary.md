# Sandboxie-Plus — 术语表

本文档定义项目中使用的专业术语和缩写。

---

## 核心术语

| 术语 | 定义 | 出现位置 |
|------|------|----------|
| **沙箱 (Sandbox)** | 一个隔离的执行环境，进程在其中运行时无法直接影响宿主系统 | 全项目 |
| **沙箱化 (Sandboxed)** | 进程在沙箱中运行的状态 | 文档、代码注释 |
| **隔离 (Isolation)** | 将进程与宿主系统分离的安全机制 | 文档 |
| **重定向 (Redirect)** | 将文件/注册表操作从真实路径映射到沙箱路径 | 核心代码 |
| **注入 (Injection)** | 将 DLL 加载到目标进程地址空间的技术 | core/dll, core/low |
| **Hook** | 拦截函数调用并替换为自定义实现的技术 | core/dll |

---

## 组件名称

| 术语 | 定义 | 出现位置 |
|------|------|----------|
| **SbieDrv** | Sandboxie 内核驱动 (SbieDrv.sys) | core/drv |
| **SbieDll** | Sandboxie 注入 DLL (SbieDll.dll) | core/dll |
| **SbieSvc** | Sandboxie 系统服务 (SbieSvc.exe) | core/svc |
| **SandMan** | Sandboxie Plus GUI 管理界面 | SandboxiePlus/SandMan |
| **SbieCtrl** | Sandboxie Classic GUI 控制程序 | apps/control |
| **QSbieAPI** | Qt 封装的 Sandboxie API 库 | SandboxiePlus/QSbieAPI |
| **LowLevel** | 低级注入代码，用于早期进程注入 | core/low |
| **ImBox** | 加密沙箱镜像管理工具 | SandboxieTools/ImBox |

---

## 技术术语

| 术语 | 定义 | 出现位置 |
|------|------|----------|
| **IOCTL** | I/O Control，用户态与内核态通信的机制 | 驱动代码 |
| **LPC** | Local Procedure Call，进程间通信机制 | 服务代码 |
| **SSDT** | System Service Descriptor Table，系统调用表 | 驱动代码 |
| **Token** | Windows 安全令牌，包含进程权限信息 | token.c |
| **SID** | Security Identifier，安全标识符 | 驱动、服务代码 |
| **APC** | Asynchronous Procedure Call，异步过程调用 | 注入代码 |
| **PEB** | Process Environment Block，进程环境块 | DLL 代码 |
| **TEB** | Thread Environment Block，线程环境块 | DLL 代码 |

---

## 配置术语

| 术语 | 定义 | 出现位置 |
|------|------|----------|
| **Sandboxie.ini** | Sandboxie 主配置文件 | 配置管理 |
| **BoxName** | 沙箱名称，用于标识不同的沙箱 | 配置、代码 |
| **Template** | 预定义的配置模板，用于常见应用 | 配置文件 |
| **Force Process** | 强制在沙箱中运行的进程列表 | 配置 |
| **OpenFilePath** | 允许沙箱进程直接访问的路径 | 配置 |
| **ClosedFilePath** | 禁止沙箱进程访问的路径 | 配置 |
| **ReadFilePath** | 只读访问路径 | 配置 |
| **WriteFilePath** | 写入重定向路径 | 配置 |

---

## 沙箱类型

| 术语 | 定义 | 出现位置 |
|------|------|----------|
| **Default Box** | 默认沙箱，标准隔离模式 | 配置、UI |
| **Privacy Enhanced** | 隐私增强沙箱，保护用户数据 | Plus 功能 |
| **Application Compartment** | 应用隔离沙箱，更宽松的隔离 | Plus 功能 |
| **Encrypted Box** | 加密沙箱，数据加密存储 | ImBox |

---

## 缩写

| 缩写 | 全称 | 说明 |
|------|------|------|
| **Sbie** | Sandboxie | 项目简称 |
| **Drv** | Driver | 驱动 |
| **Svc** | Service | 服务 |
| **Dll** | Dynamic Link Library | 动态链接库 |
| **GUI** | Graphical User Interface | 图形用户界面 |
| **API** | Application Programming Interface | 应用程序接口 |
| **IPC** | Inter-Process Communication | 进程间通信 |
| **WFP** | Windows Filtering Platform | Windows 过滤平台 |
| **COM** | Component Object Model | 组件对象模型 |
| **RPC** | Remote Procedure Call | 远程过程调用 |

---

## 文件扩展名

| 扩展名 | 说明 |
|--------|------|
| `.sys` | Windows 内核驱动 |
| `.dll` | 动态链接库 |
| `.exe` | 可执行文件 |
| `.vcxproj` | Visual Studio 项目文件 |
| `.sln` | Visual Studio 解决方案文件 |
| `.ts` | Qt 翻译文件 |
| `.iss` | Inno Setup 脚本 |

---

## 相关文档

- [架构总览](architecture/overview.md) — 系统整体架构
- [组件详解](architecture/components.md) — 各组件的详细接口
