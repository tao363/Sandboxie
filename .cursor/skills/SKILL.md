---
name: sandboxie-codebase
description: >
  Sandboxie-Plus 项目完整代码导航与分析指南。当用户需要理解、分析、查找、浏览 Sandboxie 项目代码时使用。
  覆盖所有模块：内核驱动（SbieDrv）、系统服务（SbieSvc）、注入 DLL（SbieDll）、
  Qt UI（SandMan）、API 层（QSbieAPI）、经典 UI（SbieCtrl）、安装器、COM 包装器等。
  提供项目架构总览、模块速查表、文件定位、代码导航、架构理解等功能。
  关键词：Sandboxie 架构、代码在哪、模块分析、项目结构、函数定位、沙箱原理。
  注意：如需修改、优化、测试代码，请使用 sandboxie-modifier skill。
---

# Sandboxie-Plus 项目代码导航 Skill

## 快速启动

当你收到关于 Sandboxie 项目的任何请求时，按以下顺序操作：

1. **先读架构总览**：`view` 本 skill 目录下的 `references/architecture.md` —— 它是项目的"地图"
2. **定位目标模块**：根据用户请求，参照下方的"模块速查表"确定要看哪些文件
3. **再读源码**：只读相关文件，不要试图一次性读完整个项目
4. **修改时遵循规范**：参照下方的"修改规范"章节

## 项目根目录结构

```
Sandboxie/                          # 项目根目录
├── Sandboxie/                      # ← 经典核心代码（C/C++，VS Solution）
│   ├── core/                       #    核心三件套
│   │   ├── drv/                    #    SbieDrv.sys  — 内核驱动
│   │   ├── svc/                    #    SbieSvc.exe  — 系统服务
│   │   ├── dll/                    #    SbieDll.dll  — 注入 DLL（Hook 引擎）
│   │   └── low/                    #    LowLevel.dll — 底层注入辅助
│   ├── apps/                       #    应用层
│   │   ├── control/                #    SbieCtrl.exe — 经典 MFC UI
│   │   ├── start/                  #    Start.exe    — 进程启动器
│   │   ├── ini/                    #    SbieIni.exe  — 配置工具
│   │   ├── common/                 #    common.lib   — 共享 GUI 组件
│   │   └── com/                    #    COM 包装器 (BITS/Crypto/RpcSs/WUAU/DcomLaunch)
│   ├── install/                    #    安装相关
│   │   ├── kmdutil/                #    KmdUtil.exe  — 驱动加载工具
│   │   └── release/                #    安装包打包
│   ├── msgs/                       #    消息定义文件（错误码、提示文本）
│   └── common/                     #    共享头文件（my_version.h 等）
│
├── SandboxiePlus/                  # ← Plus 版代码（C++ / Qt6）
│   ├── SandMan/                    #    SandMan.exe — Plus Qt UI 主程序
│   │   ├── SandMan.cpp/h           #    CSandMan 主窗口类
│   │   ├── SbiePlusAPI.cpp/h       #    CSbiePlusAPI — 扩展 API 封装
│   │   ├── Views/                  #    UI 视图（SbieView, TraceView...）
│   │   ├── Models/                 #    数据模型
│   │   ├── Windows/                #    对话框窗口
│   │   ├── Wizards/                #    向导（创建沙箱、浏览器模板...）
│   │   ├── Helpers/                #    辅助工具类
│   │   └── OnlineUpdater.cpp/h     #    在线更新
│   ├── QSbieAPI/                   #    底层 API 库（Qt 封装驱动通信）
│   │   ├── SbieAPI.cpp/h           #    CSbieAPI — 核心 API 类
│   │   ├── SbieUtils.cpp           #    工具函数
│   │   ├── Sandboxie/              #    沙箱对象模型
│   │   │   ├── SandBox.cpp/h       #    CSandBox
│   │   │   ├── BoxBorder.cpp/h     #    边框管理
│   │   │   └── SbieIni.cpp/h       #    INI 配置读写
│   │   └── Helpers/                #    辅助类
│   └── version.h                   #    Plus 版本号
│
├── SandboxieTools/                 # ← 工具集
│   └── ImBox/                      #    加密沙箱工具
│
├── Installer/                      # ← InnoSetup 安装脚本
│   └── Sandboxie-Plus.iss
│
└── CHANGELOG.md                    # 变更日志
```

## 模块速查表

根据用户意图，快速定位应该阅读的文件：

### 场景 → 文件映射

| 用户意图 | 首先阅读 | 然后阅读 |
|----------|---------|---------|
| 文件系统虚拟化/重定向 | `core/drv/file*.c` | `core/dll/file*.c` |
| 注册表虚拟化 | `core/drv/key*.c` | `core/dll/key*.c` |
| 进程隔离/令牌管理 | `core/drv/process*.c`, `core/drv/token*.c` | `core/dll/proc*.c` |
| API Hook 机制 | `core/dll/dll*.c`, `core/dll/hook*.c` | `core/low/` |
| IPC/COM 隔离 | `core/drv/ipc*.c` | `core/dll/ipc*.c`, `apps/com/` |
| 网络隔离/防火墙 | `core/drv/net*.c` | `core/dll/net*.c` |
| GUI 隔离（窗口边框） | `core/drv/gui*.c` | `core/dll/gui*.c`, `QSbieAPI/.../BoxBorder.*` |
| UI 界面修改（Plus） | `SandboxiePlus/SandMan/` | `SandboxiePlus/QSbieAPI/` |
| UI 界面修改（Classic）| `Sandboxie/apps/control/` | `Sandboxie/apps/common/` |
| 沙箱配置/INI 设置 | `QSbieAPI/Sandboxie/SbieIni.*` | `install/Templates.ini`, `msgs/` |
| 快照功能 | `QSbieAPI/Sandboxie/SandBox.cpp` 中搜 `Snapshot` | `SandMan/Windows/SnapshotWindow.*` |
| 进程启动流程 | `apps/start/start.cpp` | `core/svc/` 中的 ProcessServer |
| 安装/驱动加载 | `install/kmdutil/`, `Installer/` | `core/svc/` 中的驱动管理 |
| 错误码/消息 | `msgs/Sbie-English-1033.txt` | `common/my_version.h` |
| 在线更新/证书 | `SandMan/OnlineUpdater.*` | `SandMan/SbiePlusAPI.*` |
| 加密沙箱 | `SandboxieTools/ImBox/` | — |

### 核心三件套的内部结构

**SbieDrv（内核驱动）** — `Sandboxie/core/drv/`
```
驱动入口:     api.c, driver.c
进程管理:     process.c, token.c, thread.c
文件虚拟化:   file.c, file_dir.c, file_link.c, file_copy.c
注册表虚拟化: key.c, key_merge.c
IPC 隔离:     ipc.c, ipc_port.c, ipc_spl.c
网络:         net.c
GUI:          gui.c, gui_xxx.c
内存/句柄:    obj.c, syscall.c
配置读取:     conf.c
日志:         log.c
```

**SbieSvc（系统服务）** — `Sandboxie/core/svc/`
```
服务入口:     *_main.c / main.cpp
进程创建:     ProcessServer, SbieSvc_ProcessServer.*
驱动通信:     DriverAssist.*
INI 管理:     SbieIniServer.*
消息管道:     PipeServer.*
WFPN 网络:    NetProxy / NetworkServer
```

**SbieDll（注入 DLL）** — `Sandboxie/core/dll/`
```
DLL 入口:     dllmain.c, dll.c
Hook 框架:    hook.c, hook_tramp.c
文件 Hook:    file.c, file_dir.c, file_pipe.c
注册表 Hook:  key.c, key_merge.c
进程 Hook:    proc.c, proc_token.c
IPC Hook:     ipc.c, ipc_start.c
网络 Hook:    net.c
GUI Hook:     gui.c, gdi.c
COM Hook:     com.c
安全:         secure.c
SbieDll API:  sbiedll.h (供外部调用的导出函数)
```

## 核心架构概念（修改前必读）

### 三层隔离模型

```
┌─────────────────────────────────────────────────┐
│  用户进程 (沙箱内)                                │
│  ┌─────────────────────────────────────────────┐ │
│  │ SbieDll.dll (注入到每个沙箱进程)              │ │
│  │ - 拦截 Nt* 系统调用                          │ │
│  │ - 重定向文件/注册表操作到沙箱目录              │ │
│  │ - 与 SbieSvc 通信请求服务                     │ │
│  └────────────────────┬────────────────────────┘ │
└───────────────────────┼─────────────────────────┘
                        │ LPC / Named Pipe
┌───────────────────────┼─────────────────────────┐
│  SbieSvc.exe (系统服务, SYSTEM 权限)              │
│  - 管理沙箱生命周期                               │
│  - 代理特权操作（创建进程、加载配置）              │
│  - 与驱动通信 (IOCTL)                             │
└───────────────────────┼─────────────────────────┘
                        │ IOCTL
┌───────────────────────┼─────────────────────────┐
│  SbieDrv.sys (内核驱动)                           │
│  - 在内核层拦截/过滤系统调用                      │
│  - 强制执行沙箱策略（不可绕过）                   │
│  - 管理沙箱进程令牌                               │
└─────────────────────────────────────────────────┘
```

### 通信协议

| 通信路径 | 协议 | 关键标识 |
|----------|------|---------|
| UI ↔ 驱动 | IOCTL | `\Device\SandboxieDriverApi` |
| UI ↔ 服务 | LPC | `\RPC Control\SbieSvcPort` |
| 沙箱DLL ↔ 服务 | Named Pipe | `PipeServer` |
| 沙箱DLL ↔ 驱动 | 直接系统调用 | 通过 SbieDll 内部 |

### 关键数据结构

- `PROCESS` — 驱动中的进程控制块（`core/drv/process.h`）
- `BOX` — 驱动中的沙箱实例（`core/drv/box.h`）  
- `CSandBox` / `CSandBoxPlus` — API 层的沙箱对象
- `CSbieAPI` — API 层核心类，管理驱动通信
- `SBIEINI_WIRE` — 服务通信的线格式（`core/svc/SbieIniWire.h`）

## 修改规范

### 通用原则

1. **双端一致性**：修改驱动层（drv）的拦截逻辑时，通常也需要修改 DLL 层（dll）的对应 Hook
2. **配置驱动**：新功能应该通过 `Sandboxie.ini` 的配置项控制，而非硬编码
3. **错误码注册**：新增错误消息需在 `msgs/Sbie-English-1033.txt` 中注册
4. **版本兼容**：修改驱动 API 时需更新 `common/my_version.h` 中的 ABI 版本号
5. **双架构**：代码需同时支持 x86 和 x64，注意 `#ifdef _WIN64` 分支

### 添加新的沙箱配置项

```
1. msgs/Sbie-English-1033.txt      — 添加设置描述文本
2. install/Templates.ini           — 如果需要模板默认值
3. core/drv/conf.c                 — 驱动侧读取配置
4. core/dll/XXX.c                  — DLL 侧读取并应用配置
5. QSbieAPI/Sandboxie/SbieIni.*    — API 层暴露配置读写
6. SandMan/Windows/OptionsWindow.* — UI 添加配置界面（如需要）
```

### 添加新的 API Hook

```
1. core/dll/hook.c / hook_tramp.c  — 了解 Hook 框架
2. core/dll/XXX.c                  — 在对应领域文件中添加 Hook
3. core/dll/dllmain.c              — 注册 Hook 初始化
4. core/drv/XXX.c                  — 如果内核层也需要拦截
```

### 修改 UI（Plus 版）

```
1. SandboxiePlus/SandMan/          — Qt6 主程序
2. 使用 Qt Designer 的 .ui 文件或纯代码布局
3. 遵循现有的 CSandMan → Views/Windows 结构
4. 数据通过 CSbiePlusAPI/CSbieAPI 获取，不直接访问驱动
```

## 关键命名约定

| 前缀/后缀 | 含义 |
|-----------|------|
| `Sbie` / `Sbx` | Sandboxie 缩写 |
| `SbieDrv` | 内核驱动模块 |
| `SbieSvc` | 系统服务模块 |
| `SbieDll` | 注入 DLL 模块 |
| `File_` | 文件系统相关 |
| `Key_` | 注册表相关 |
| `Ipc_` | IPC 相关 |
| `Process_` | 进程管理相关 |
| `Thread_` | 线程管理相关 |
| `Token_` | 令牌/权限相关 |
| `Gui_` | GUI/窗口相关 |
| `Net_` | 网络相关 |
| `Conf_` | 配置相关 |
| `Api_` | API 调用相关 |
| `SBIE1xxx` | 一般消息 |
| `SBIE2xxx` | 驱动消息 |
| `SBIE9xxx` | 服务错误 |

## 分析策略

面对用户的具体修改需求时：

1. **先确认影响范围**：这个修改涉及哪些层？（驱动 / 服务 / DLL / API / UI）
2. **查阅架构文档**：读 `references/architecture.md` 中的相关模块章节
3. **阅读关联源码**：用上面的速查表定位文件，只读必要的部分
4. **检查配置系统**：看 Templates.ini 和消息文件中是否已有相关配置
5. **小范围修改优先**：尽量在最少的文件中完成修改，避免不必要的跨层改动
6. **测试注意事项**：涉及驱动的修改需要重新编译+重启服务，涉及 DLL 的修改需要重启沙箱进程

## 进阶：如何生成项目的完整分析文档

如果用户要求对整个项目或某个模块进行深度分析，请读取 `references/analysis-prompts.md`，
其中包含分层分析的完整 Prompt 模板（文件级 → 模块级 → 项目级）。

