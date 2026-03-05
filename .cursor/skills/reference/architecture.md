# Sandboxie-Plus 架构详解

> 本文档是 AI 快速理解 Sandboxie 项目的核心参考。修改代码前务必先阅读相关章节。

---

## 1. 项目定位

Sandboxie-Plus 是 Windows 平台的应用隔离系统。它通过内核驱动 + DLL 注入的方式，
在不修改宿主系统的前提下，将应用程序的文件、注册表、IPC 等操作重定向到隔离的沙箱目录中。

**核心价值**：安全测试不可信程序、保护宿主系统不被修改、多实例运行应用。

**技术栈**：
- 语言：C（驱动/DLL/服务核心）、C++（API层/UI）
- UI 框架：Qt6（Plus 版）、MFC（Classic 版）
- 构建：Visual Studio 2019、WDK 10.0.19041、Qt 6.x + qmake
- 安装：InnoSetup
- 目标平台：Windows 7 — Windows 11，x86 + x64

---

## 2. 系统架构全景

### 2.1 组件层次

```
┌────────────────────────────────────────────────────────┐
│                    用户空间 (User Mode)                  │
│                                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │ SandMan.exe │  │ SbieCtrl.exe │  │  Start.exe    │ │
│  │ (Plus UI)   │  │ (Classic UI) │  │ (进程启动器)  │ │
│  │ Qt6 / C++   │  │ MFC / C++    │  │ C++           │ │
│  └──────┬──────┘  └──────┬───────┘  └──────┬────────┘ │
│         │                │                  │          │
│         └────────┬───────┘                  │          │
│                  ▼                          │          │
│  ┌──────────────────────────┐              │          │
│  │ QSbieAPI / SbiePlusAPI   │              │          │
│  │ (Qt C++ API 封装层)      │              │          │
│  └──────────┬───────────────┘              │          │
│             │                              │          │
│             ▼                              ▼          │
│  ┌──────────────────────────────────────────────────┐ │
│  │              SbieSvc.exe (Windows 服务)            │ │
│  │  - 管理驱动生命周期                                │ │
│  │  - 代理进程创建                                    │ │
│  │  - 读写 Sandboxie.ini 配置                         │ │
│  │  - WFPN 网络过滤代理                               │ │
│  └──────────────────────┬───────────────────────────┘ │
│                         │                              │
│  ┌──────────────────────┼──────────────────────────┐  │
│  │ 沙箱进程 (Sandboxed) │                          │  │
│  │  ┌───────────────────┴───────────────────────┐  │  │
│  │  │ SbieDll.dll (注入到每个沙箱进程)            │  │  │
│  │  │ - Hook Nt* / Win32 API                    │  │  │
│  │  │ - 文件/注册表/IPC/网络/GUI 重定向           │  │  │
│  │  └───────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────────┬───────────────────────────┘
                             │ IOCTL
┌────────────────────────────┼───────────────────────────┐
│                    内核空间 (Kernel Mode)                │
│  ┌─────────────────────────┴──────────────────────┐    │
│  │          SbieDrv.sys (内核驱动)                  │    │
│  │  - 系统调用拦截 (Syscall Hook)                   │    │
│  │  - 强制沙箱策略                                  │    │
│  │  - 进程令牌管理                                  │    │
│  │  - 文件/注册表/IPC/网络 过滤                     │    │
│  └─────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
```

### 2.2 进程启动流程（核心流程）

```
用户双击 "在沙箱中运行 X"
    │
    ▼
Start.exe 接收命令行参数
    │
    ├─→ 连接 SbieSvc（通过 LPC / Named Pipe）
    │
    ▼
SbieSvc 创建进程（CREATE_SUSPENDED 状态）
    │
    ├─→ 通知 SbieDrv 注册此进程为沙箱进程
    │
    ▼
SbieDrv 标记进程，设置令牌限制
    │
    ▼
SbieSvc 注入 LowLevel.dll → 加载 SbieDll.dll
    │
    ▼
SbieDll.dll 初始化：
    ├─→ 安装所有 API Hooks
    ├─→ 读取沙箱配置
    └─→ 恢复进程执行（ResumeThread）
    │
    ▼
进程正常运行，所有系统调用被 Hook 拦截和重定向
```

### 2.3 文件虚拟化流程

```
沙箱进程调用 NtCreateFile("C:\secret.txt")
    │
    ▼
SbieDll Hook 拦截
    │
    ├─ 检查访问规则（OpenFilePath? ClosedFilePath? ReadFilePath?）
    │
    ├─ 如果是写操作 → 重定向到沙箱目录:
    │   C:\Sandbox\User\BoxName\drive\C\secret.txt
    │   （"copy-on-write" 语义：首次写入时复制原文件）
    │
    ├─ 如果是读操作 → 先查沙箱目录，不存在则读原始路径
    │
    └─ 如果被策略阻止 → 返回 ACCESS_DENIED
```

---

## 3. 核心模块详解

### 3.1 SbieDrv — 内核驱动

**位置**：`Sandboxie/core/drv/`

**职责**：内核级隔离执行者，不可被用户态绕过。

**关键文件**：

| 文件 | 职责 |
|------|------|
| `driver.c` | 驱动入口 DriverEntry，初始化 |
| `api.c` | IOCTL API 分发 |
| `process.c` | 进程管理（注册/注销沙箱进程） |
| `token.c` | 令牌创建与限制 |
| `thread.c` | 线程管理 |
| `file.c` | 文件系统拦截核心 |
| `file_dir.c` | 目录操作合并（沙箱目录 + 原始目录） |
| `file_link.c` | 符号链接处理 |
| `file_copy.c` | Copy-on-Write 实现 |
| `key.c` | 注册表拦截核心 |
| `key_merge.c` | 注册表视图合并 |
| `ipc.c` | IPC 对象隔离（命名管道、事件等） |
| `ipc_port.c` | ALPC 端口隔离 |
| `gui.c` | 窗口/桌面隔离 |
| `net.c` | 网络过滤 |
| `obj.c` | 对象管理器 Hook |
| `syscall.c` | 系统调用号管理 |
| `conf.c` | 从 Sandboxie.ini 读取沙箱配置 |
| `log.c` | 驱动日志 |
| `verify.c` | 签名验证 |
| `box.h` | BOX 结构体定义 |
| `process.h` | PROCESS 结构体定义 |

**设计要点**：
- 驱动通过注册 Minifilter 回调拦截文件操作
- 通过 Syscall Hook 拦截其他操作（注册表、IPC 等）
- 每个沙箱进程在驱动中有一个 PROCESS 结构体
- 每个沙箱在驱动中有一个 BOX 结构体
- 配置通过 conf.c 读取，缓存在内核内存中

### 3.2 SbieSvc — 系统服务

**位置**：`Sandboxie/core/svc/`

**职责**：用户态与内核态之间的协调桥梁。

**关键子模块**：
- **DriverAssist**：加载/卸载驱动，监控驱动状态
- **ProcessServer**：代理沙箱内的进程创建请求
- **SbieIniServer**：管理 Sandboxie.ini 读写（确保原子性和权限）
- **PipeServer**：命名管道通信框架
- **NetworkServer**：WFP 网络过滤代理
- **ServiceServer**：管理沙箱内的模拟服务

**通信方式**：
- 对外（UI/Start.exe）：通过 LPC 端口 `\RPC Control\SbieSvcPort`
- 对内（驱动）：通过 IOCTL 到 `\Device\SandboxieDriverApi`
- 线格式：`SBIEINI_WIRE` 结构（见 `SbieIniWire.h`）

### 3.3 SbieDll — 注入 DLL

**位置**：`Sandboxie/core/dll/`

**职责**：注入到每个沙箱进程，通过 API Hook 实现用户态隔离。

**Hook 框架**（`hook.c`, `hook_tramp.c`）：
- 使用 Trampoline 技术 Hook Nt* 函数
- Hook 安装在进程初始化早期（LdrInitializeThunk 之后）
- 支持热补丁和延迟 Hook

**按领域分类的 Hook**：
- **文件**：NtCreateFile, NtOpenFile, NtQueryDirectoryFile, NtSetInformationFile...
- **注册表**：NtCreateKey, NtOpenKey, NtQueryValueKey, NtSetValueKey...
- **进程**：NtCreateProcess, NtCreateUserProcess, NtTerminateProcess...
- **IPC**：NtCreatePort, NtConnectPort, NtCreateEvent, NtCreateMutant...
- **网络**：WSA*, connect, bind, listen, DNS 相关...
- **GUI**：CreateWindowEx, SetWindowPos, 剪贴板操作...
- **COM**：CoCreateInstance, OLE 相关...
- **安全**：令牌操作, 权限检查...

**导出函数**（`sbiedll.h`）：
- `SbieApi_Call` — 通用驱动 API 调用
- `SbieApi_QueryProcess` — 查询沙箱进程信息
- `SbieApi_QueryBoxPath` — 获取沙箱路径
- `SbieApi_EnumBoxes` — 枚举所有沙箱
- `SbieApi_EnumProcessEx` — 枚举沙箱内进程

### 3.4 QSbieAPI — Qt API 封装层

**位置**：`SandboxiePlus/QSbieAPI/`

**职责**：将底层驱动/服务通信封装为 Qt 友好的 C++ API。

**核心类**：
- `CSbieAPI` — 主 API 类，管理驱动连接、沙箱枚举、进程监控
- `CSandBox` — 沙箱对象，代表一个沙箱实例
- `CSbieProcess` — 进程对象，代表沙箱内一个进程
- `CSbieIni` — INI 配置读写封装

**通信机制**：
- 通过 `NtDeviceIoControlFile` 直接与驱动通信（IOCTL）
- 驱动设备路径：`\Device\SandboxieDriverApi`
- 服务端口：`\RPC Control\SbieSvcPort`

### 3.5 SandMan — Plus Qt UI

**位置**：`SandboxiePlus/SandMan/`

**职责**：Plus 版的现代图形界面。

**核心类**：
- `CSandMan` (`SandMan.cpp/h`) — 主窗口，菜单/工具栏/系统托盘
- `CSbiePlusAPI` (`SbiePlusAPI.cpp/h`) — 扩展 API，继承自 CSbieAPI
- `CSbieView` (`Views/SbieView.cpp`) — 沙箱列表主视图
- `CTraceView` (`Views/TraceView.cpp`) — 追踪日志视图
- `COptionsWindow` (`Windows/OptionsWindow.cpp`) — 沙箱设置对话框
- `CSettingsWindow` (`Windows/SettingsWindow.cpp`) — 全局设置
- `CBoxAssistant` (`Wizards/BoxAssistant.cpp`) — 故障排查向导
- `CAddonManager` (`Helpers/AddonManager.cpp`) — 插件管理

**数据流**：
```
UI 事件 → CSandMan 处理 → CSbiePlusAPI 调用 → CSbieAPI 驱动通信 → 结果回调更新 UI
```

---

## 4. 配置系统

### 4.1 Sandboxie.ini 结构

```ini
[GlobalSettings]
FileRootPath=C:\Sandbox\%USER%\%SANDBOX%
# 全局设置，不属于任何沙箱

[DefaultBox]
Enabled=y
# 每个 [SectionName] 代表一个沙箱
# 支持的配置项数百个，参见 msgs/Sbie-English-1033.txt

[UserSettings_XXXXXXXX]
SbieCtrl_UserName=xxx
# 用户界面状态，按用户分节
```

### 4.2 配置读取链路

```
Sandboxie.ini 文件
    │
    ├──→ SbieSvc (SbieIniServer) 读取并缓存
    │       │
    │       └──→ 通过 IOCTL 传递给 SbieDrv
    │               │
    │               └──→ conf.c 解析并缓存到 BOX 结构体
    │
    ├──→ SbieDll 通过 SbieApi 查询当前沙箱的配置
    │
    └──→ QSbieAPI/CSbieIni 通过服务端口读写配置
```

### 4.3 Templates.ini

位于 `Sandboxie/install/Templates.ini`，定义了预设的应用兼容性模板。
例如 Firefox、Chrome、Edge 等浏览器的沙箱规则模板。
沙箱可以通过 `Template=TemplateName` 引用这些模板。

---

## 5. 构建系统

### 5.1 经典核心（Sandboxie/ 目录）

- **工具**：Visual Studio 2019 + WDK 10.0.19041
- **解决方案**：`Sandboxie/Sandbox.sln`
- **注意**：编译 x64 前需先编译 x86 的 LowLevel 项目
- **驱动签名**：开发时需要开启 Windows 测试签名模式

### 5.2 Plus UI（SandboxiePlus/ 目录）

- **工具**：Qt 6.x + qmake（或通过 VS Qt 插件）
- **项目文件**：`SandboxiePlus/SandMan/SandMan.pro`
- **依赖**：Qt6 Core, Gui, Widgets, Network, WinExtras

### 5.3 安装器

- **工具**：InnoSetup
- **脚本**：`Installer/Sandboxie-Plus.iss`

---

## 6. 错误码与消息系统

**消息文件**：`Sandboxie/msgs/Sbie-English-1033.txt`

**编号规则**：
| 范围 | 含义 |
|------|------|
| SBIE1xxx | 一般信息/警告 |
| SBIE2xxx | 驱动相关消息 |
| SBIE3xxx | 服务相关消息 |
| SBIE9xxx | 严重错误 |

添加新消息时：在消息文件中添加条目，然后通过 `msgs/` 下的 Parse 工具生成头文件。

---

## 7. 版本管理

| 组件 | 版本定义位置 | 当前格式 |
|------|-------------|---------|
| 核心组件（驱动/服务/DLL） | `Sandboxie/common/my_version.h` | 5.x.x |
| Plus UI | `SandboxiePlus/version.h` | 1.x.x |
| ABI 兼容版本 | `my_version.h` 中的宏 | 0xNNNNN |

ABI 版本确保驱动与用户态组件版本匹配，不匹配时会弹出 SBIE9154 错误。

---

## 8. 常见修改模式速查

### 8.1 "我想拦截一个新的 Windows API"

1. 确定该 API 属于哪个领域（文件/注册表/IPC/网络/GUI）
2. 在 `core/dll/` 对应领域文件中添加 Hook 函数
3. 在该文件的初始化函数中注册 Hook（参考同文件已有的模式）
4. 如果内核层也需要拦截，在 `core/drv/` 对应文件中添加
5. 测试：在沙箱中运行使用该 API 的程序

### 8.2 "我想添加一个新的沙箱设置选项"

1. `msgs/Sbie-English-1033.txt` — 添加设置名和描述
2. `core/drv/conf.c` — 添加驱动侧读取逻辑
3. `core/dll/XXX.c` — 在 DLL 中读取并应用
4. `install/Templates.ini` — 如果某些模板需要此设置
5. `QSbieAPI/Sandboxie/SbieIni.*` — API 层暴露
6. `SandMan/Windows/OptionsWindow.*` — Plus UI 添加复选框/输入框

### 8.3 "我想在 UI 中添加新功能"

1. 确定功能的数据来源（驱动 API？配置文件？进程信息？）
2. 在 `QSbieAPI/` 中确认或添加数据获取接口
3. 如需扩展，在 `SbiePlusAPI` 中添加封装
4. 在 `SandMan/` 的对应 View/Window 中添加 UI 元素
5. 连接信号/槽完成数据绑定

### 8.4 "我想修复某个程序在沙箱中的兼容性问题"

1. 用 SandMan 的 Trace View 追踪该程序的 API 调用
2. 找到被错误拦截或遗漏的 API 调用
3. 通常是在 `core/dll/` 的 Hook 中添加特殊处理
4. 或者在 `Templates.ini` 中添加该程序的兼容性模板
5. 常见的兼容性设置：`OpenFilePath`, `OpenKeyPath`, `OpenIpcPath`
