# Sandboxie 模块映射表

> 快速定位功能对应的源文件

## 按功能查找文件

### 文件系统虚拟化

| 功能 | 驱动层 | DLL 层 | 说明 |
|------|--------|--------|------|
| 文件创建/打开 | `core/drv/file.c` | `core/dll/file.c` | NtCreateFile, NtOpenFile |
| 目录操作 | `core/drv/file_dir.c` | `core/dll/file_dir.c` | 目录枚举、合并 |
| 文件链接 | `core/drv/file_link.c` | `core/dll/file_link.c` | 符号链接、硬链接 |
| 写时复制 | `core/drv/file_copy.c` | - | Copy-on-Write 实现 |
| 文件删除 | `core/drv/file_del.c` | `core/dll/file_del.c` | 删除操作 |
| 文件重命名 | `core/drv/file_misc.c` | `core/dll/file_misc.c` | 重命名、移动 |
| 管道操作 | `core/drv/file_pipe.c` | `core/dll/file_pipe.c` | 命名管道 |
| 快照功能 | `core/drv/file_snapshot.c` | - | 快照管理 |

### 注册表虚拟化

| 功能 | 驱动层 | DLL 层 | 说明 |
|------|--------|--------|------|
| 注册表创建/打开 | `core/drv/key.c` | `core/dll/key.c` | NtCreateKey, NtOpenKey |
| 注册表合并 | `core/drv/key_merge.c` | `core/dll/key_merge.c` | 沙箱与系统注册表合并 |
| 注册表删除 | `core/drv/key_del.c` | `core/dll/key_del.c` | 删除键值 |

### 进程隔离

| 功能 | 驱动层 | DLL 层 | 服务层 | 说明 |
|------|--------|--------|--------|------|
| 进程管理 | `core/drv/process.c` | `core/dll/proc.c` | `core/svc/ProcessServer.cpp` | 进程创建、监控 |
| 令牌管理 | `core/drv/token.c` | `core/dll/proc_token.c` | - | 权限限制 |
| 线程管理 | `core/drv/thread.c` | `core/dll/thread.c` | - | 线程操作 |
| DLL 注入 | `core/drv/dll.c` | - | `core/svc/LowLevelServer.cpp` | 注入 SbieDll.dll |
| 进程启动 | - | - | `apps/start/start.cpp` | Start.exe 启动器 |

### IPC 隔离

| 功能 | 驱动层 | DLL 层 | 说明 |
|------|--------|--------|------|
| IPC 对象 | `core/drv/ipc.c` | `core/dll/ipc.c` | 事件、互斥体等 |
| ALPC 端口 | `core/drv/ipc_port.c` | `core/dll/ipc_port.c` | 高级 LPC |
| RPC 隔离 | `core/drv/ipc_spl.c` | `core/dll/ipc_spl.c` | RPC 特殊处理 |
| 动态端口 | `core/drv/ipc_dynamic.c` | `core/dll/ipc_dynamic.c` | 动态端口管理 |

### 网络隔离

| 功能 | 驱动层 | DLL 层 | 服务层 | 说明 |
|------|--------|--------|--------|------|
| 网络过滤 | `core/drv/net.c` | `core/dll/net.c` | - | 基础网络过滤 |
| WFP 过滤 | `core/drv/wfp.c` | - | `core/svc/NetworkServer.cpp` | Windows Filtering Platform |
| DNS 解析 | - | `core/dll/net_dns.c` | - | DNS 查询 |

### GUI 隔离

| 功能 | 驱动层 | DLL 层 | 说明 |
|------|--------|--------|------|
| 窗口管理 | `core/drv/gui.c` | `core/dll/gui.c` | 窗口隔离 |
| GDI 操作 | - | `core/dll/gdi.c` | 图形设备接口 |
| 剪贴板 | - | `core/dll/gui_clipboard.c` | 剪贴板隔离 |
| 桌面隔离 | `core/drv/gui_desktop.c` | - | 独立桌面 |

### Hook 框架

| 功能 | 位置 | 说明 |
|------|------|------|
| Hook 引擎 | `core/dll/hook.c` | Trampoline Hook |
| Hook 跳板 | `core/dll/hook_tramp.c` | 跳板代码生成 |
| 底层注入 | `core/low/` | LowLevel.dll |
| 注入辅助 | `core/low/inject.c` | 注入实现 |

### 驱动框架

| 功能 | 位置 | 说明 |
|------|------|------|
| 驱动入口 | `core/drv/driver.c` | DriverEntry |
| API 分发 | `core/drv/api.c` | IOCTL 处理 |
| 系统调用 | `core/drv/syscall.c` | Syscall Hook |
| 配置管理 | `core/drv/conf.c` | 配置读取 |
| 日志系统 | `core/drv/log.c` | 驱动日志 |
| 内存管理 | `core/drv/mem.c` | 内存分配 |
| 对象管理 | `core/drv/obj.c` | 内核对象 |
| 签名验证 | `core/drv/verify.c` | 证书验证 |

### 服务框架

| 功能 | 位置 | 说明 |
|------|------|------|
| 服务入口 | `core/svc/main.cpp` | 服务主函数 |
| 驱动助手 | `core/svc/DriverAssist.cpp` | 驱动管理 |
| 进程服务器 | `core/svc/ProcessServer.cpp` | 进程创建代理 |
| 配置服务器 | `core/svc/SbieIniServer.cpp` | INI 管理 |
| 管道服务器 | `core/svc/PipeServer.cpp` | 通信框架 |
| 网络服务器 | `core/svc/NetworkServer.cpp` | 网络代理 |
| 文件服务器 | `core/svc/FileServer.cpp` | 文件操作代理 |
| GUI 服务器 | `core/svc/GuiServer.cpp` | GUI 操作代理 |

### API 层

| 功能 | 位置 | 说明 |
|------|------|------|
| 核心 API | `QSbieAPI/SbieAPI.cpp` | CSbieAPI 类 |
| 沙箱对象 | `QSbieAPI/Sandboxie/SandBox.cpp` | CSandBox 类 |
| 进程对象 | `QSbieAPI/Sandboxie/BoxedProcess.cpp` | CSbieProcess 类 |
| 配置管理 | `QSbieAPI/Sandboxie/SbieIni.cpp` | CSbieIni 类 |
| 边框管理 | `QSbieAPI/Sandboxie/BoxBorder.cpp` | 窗口边框 |

### GUI 层（Plus）

| 功能 | 位置 | 说明 |
|------|------|------|
| 主窗口 | `SandMan/SandMan.cpp` | CSandMan 类 |
| Plus API | `SandMan/SbiePlusAPI.cpp` | CSbiePlusAPI 类 |
| 沙箱视图 | `SandMan/Views/SbieView.cpp` | 沙箱列表 |
| 追踪视图 | `SandMan/Views/TraceView.cpp` | 日志追踪 |
| 选项窗口 | `SandMan/Windows/OptionsWindow.cpp` | 沙箱设置 |
| 设置窗口 | `SandMan/Windows/SettingsWindow.cpp` | 全局设置 |
| 快照窗口 | `SandMan/Windows/SnapshotWindow.cpp` | 快照管理 |
| 恢复窗口 | `SandMan/Windows/RecoveryWindow.cpp` | 文件恢复 |

### GUI 层（Classic）

| 功能 | 位置 | 说明 |
|------|------|------|
| 主窗口 | `apps/control/SbieCtrl.cpp` | 经典 UI |
| 消息窗口 | `apps/control/MessageDialog.cpp` | 消息对话框 |
| 设置对话框 | `apps/control/SettingsDialog.cpp` | 设置界面 |

### 辅助工具

| 功能 | 位置 | 说明 |
|------|------|------|
| 进程启动器 | `apps/start/start.cpp` | Start.exe |
| 配置工具 | `apps/ini/SbieIni.cpp` | SbieIni.exe |
| 驱动加载器 | `install/kmdutil/kmdutil.c` | KmdUtil.exe |

### COM 包装器

| 功能 | 位置 | 说明 |
|------|------|------|
| BITS 服务 | `apps/com/BITS/BITS.cpp` | 后台传输 |
| 加密服务 | `apps/com/Crypto/Crypto.cpp` | 加密 API |
| RPC 服务 | `apps/com/RpcSs/RpcSs.cpp` | RPC 端点映射 |
| 更新服务 | `apps/com/WUAU/WUAU.cpp` | Windows Update |
| DCOM 启动 | `apps/com/DcomLaunch/DcomLaunch.cpp` | DCOM 服务 |

## 按问题查找代码

### 程序无法启动

**可能原因**：
1. DLL 注入失败 → `core/drv/dll.c`, `core/low/inject.c`
2. 进程创建被阻止 → `core/drv/process.c`, `core/svc/ProcessServer.cpp`
3. 权限不足 → `core/drv/token.c`
4. Hook 安装失败 → `core/dll/hook.c`

### 文件操作失败

**可能原因**：
1. 路径转换错误 → `core/dll/file.c` 中的路径转换逻辑
2. 权限检查失败 → `core/drv/file.c` 中的权限检查
3. 写时复制失败 → `core/drv/file_copy.c`
4. 配置规则错误 → 检查 `OpenFilePath`, `ClosedFilePath` 配置

### 注册表操作失败

**可能原因**：
1. 注册表合并错误 → `core/drv/key_merge.c`, `core/dll/key_merge.c`
2. 权限检查失败 → `core/drv/key.c`
3. 配置规则错误 → 检查 `OpenKeyPath`, `ClosedKeyPath` 配置

### 网络连接失败

**可能原因**：
1. 网络被完全阻止 → 检查 `ClosedFilePath=!<pipe>,\\Device\\Afd`
2. WFP 规则错误 → `core/drv/wfp.c`, `core/svc/NetworkServer.cpp`
3. DNS 解析失败 → `core/dll/net_dns.c`

### 进程间通信失败

**可能原因**：
1. IPC 对象被隔离 → `core/drv/ipc.c`, `core/dll/ipc.c`
2. 命名管道被阻止 → `core/drv/file_pipe.c`
3. RPC 调用失败 → `core/drv/ipc_spl.c`, `apps/com/RpcSs/`

### GUI 显示异常

**可能原因**：
1. 窗口隔离问题 → `core/drv/gui.c`, `core/dll/gui.c`
2. GDI 操作失败 → `core/dll/gdi.c`
3. 剪贴板隔离 → `core/dll/gui_clipboard.c`

### 性能问题

**可能原因**：
1. 文件操作频繁 → 检查 `core/drv/file.c` 中的缓存机制
2. 注册表查询慢 → 检查 `core/drv/key_merge.c` 合并逻辑
3. Hook 开销大 → 检查 `core/dll/hook.c` Hook 数量
4. 日志过多 → 检查 `core/drv/log.c` 日志级别

### 内存泄漏

**可能原因**：
1. 驱动内存泄漏 → 检查 `core/drv/mem.c` 分配和释放
2. 进程对象未释放 → 检查 `core/drv/process.c` 清理逻辑
3. 沙箱对象未释放 → 检查 `core/drv/box.c` 清理逻辑

### 崩溃问题

**可能原因**：
1. 空指针访问 → 检查各模块的指针使用
2. 缓冲区溢出 → 检查字符串操作
3. 竞态条件 → 检查锁的使用
4. 栈溢出 → 检查递归调用

## 按配置项查找代码

### 文件系统配置

| 配置项 | 处理位置 | 说明 |
|--------|---------|------|
| `FileRootPath` | `core/drv/conf.c` | 沙箱根路径 |
| `OpenFilePath` | `core/drv/file.c` | 允许直接访问 |
| `ClosedFilePath` | `core/drv/file.c` | 禁止访问 |
| `ReadFilePath` | `core/drv/file.c` | 只读访问 |
| `WriteFilePath` | `core/drv/file.c` | 可写访问 |
| `NormalFilePath` | `core/drv/file.c` | 正常重定向 |

### 注册表配置

| 配置项 | 处理位置 | 说明 |
|--------|---------|------|
| `OpenKeyPath` | `core/drv/key.c` | 允许直接访问 |
| `ClosedKeyPath` | `core/drv/key.c` | 禁止访问 |
| `ReadKeyPath` | `core/drv/key.c` | 只读访问 |
| `WriteKeyPath` | `core/drv/key.c` | 可写访问 |

### IPC 配置

| 配置项 | 处理位置 | 说明 |
|--------|---------|------|
| `OpenIpcPath` | `core/drv/ipc.c` | 允许访问的 IPC |
| `ClosedIpcPath` | `core/drv/ipc.c` | 禁止访问的 IPC |
| `OpenPipePath` | `core/drv/file_pipe.c` | 允许访问的管道 |

### GUI 配置

| 配置项 | 处理位置 | 说明 |
|--------|---------|------|
| `OpenWinClass` | `core/drv/gui.c` | 允许访问的窗口类 |
| `BlockPassword` | `core/dll/gui.c` | 阻止密码窗口 |

### 进程配置

| 配置项 | 处理位置 | 说明 |
|--------|---------|------|
| `ForceProcess` | `core/drv/process.c` | 强制沙箱化 |
| `LingerProcess` | `core/drv/process.c` | 进程保持 |
| `LeaderProcess` | `core/drv/process.c` | 领导进程 |

## 按数据结构查找代码

### 驱动层结构体

| 结构体 | 定义位置 | 使用位置 | 说明 |
|--------|---------|---------|------|
| `PROCESS` | `core/drv/process.h` | `core/drv/process.c` | 进程控制块 |
| `BOX` | `core/drv/box.h` | `core/drv/box.c` | 沙箱实例 |
| `THREAD` | `core/drv/thread.h` | `core/drv/thread.c` | 线程信息 |
| `FILE` | `core/drv/file.h` | `core/drv/file.c` | 文件对象 |
| `KEY` | `core/drv/key.h` | `core/drv/key.c` | 注册表键 |
| `SYSCALL_ENTRY` | `core/drv/syscall.h` | `core/drv/syscall.c` | 系统调用表项 |

### API 层类

| 类名 | 定义位置 | 说明 |
|------|---------|------|
| `CSbieAPI` | `QSbieAPI/SbieAPI.h` | 核心 API 类 |
| `CSandBox` | `QSbieAPI/Sandboxie/SandBox.h` | 沙箱对象 |
| `CSbieProcess` | `QSbieAPI/Sandboxie/BoxedProcess.h` | 进程对象 |
| `CSbieIni` | `QSbieAPI/Sandboxie/SbieIni.h` | 配置管理 |

### GUI 层类

| 类名 | 定义位置 | 说明 |
|------|---------|------|
| `CSandMan` | `SandMan/SandMan.h` | 主窗口 |
| `CSbiePlusAPI` | `SandMan/SbiePlusAPI.h` | Plus API |
| `CSbieView` | `SandMan/Views/SbieView.h` | 沙箱视图 |
| `COptionsWindow` | `SandMan/Windows/OptionsWindow.h` | 选项窗口 |

## 快速参考

### 最常修改的文件

1. **添加新的文件路径规则** → `core/drv/file.c`, `core/dll/file.c`
2. **添加新的注册表规则** → `core/drv/key.c`, `core/dll/key.c`
3. **修改进程启动逻辑** → `core/svc/ProcessServer.cpp`
4. **添加新的 Hook** → `core/dll/hook.c`, `core/dll/XXX.c`
5. **修改 GUI 界面** → `SandMan/Windows/XXX.cpp`
6. **添加新的配置项** → `core/drv/conf.c`, `msgs/Sbie-English-1033.txt`

### 调试入口点

1. **驱动调试** → `core/drv/driver.c::DriverEntry()`
2. **DLL 调试** → `core/dll/dll.c::Dll_InitInjected()`
3. **服务调试** → `core/svc/main.cpp::_tmain()`
4. **GUI 调试** → `SandMan/main.cpp::main()`

### 日志位置

1. **驱动日志** → `core/drv/log.c::Log_Msg()`
2. **DLL 日志** → `core/dll/debug.c::SbieApi_Log()`
3. **服务日志** → `core/svc/debug.cpp::SbieApi_Log()`
4. **GUI 日志** → Qt 日志系统
