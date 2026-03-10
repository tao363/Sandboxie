# drv/gui.c — GUI 隔离

## 概述

`gui.c` 实现 **GUI 隔离**，防止沙箱进程通过窗口消息、剪贴板等与外部交互。Vista+ 依赖 UIPI；XP 使用 win32k 钩子。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/drv/gui.c` |
| 所属模块 | SbieDrv.sys |
| 核心职责 | 窗口隔离、消息过滤、剪贴板控制 |
| 关联文件 | `gui_xp.c`（XP 专用 win32k 钩子）|

## 关键函数

### `Gui_Init()`
- Vista+：注册 `API_INIT_GUI` 和 `API_GUI_CLIPBOARD` IOCTL 处理函数
- XP/32-bit：调用 `Gui_Init_XpHook()` 安装 win32k 钩子
- 最终设置 `Process_ReadyToSandbox = TRUE`

### `Gui_Api_Init()`
SbieDll 初始化时调用，确认 GUI 子系统就绪，触发 `Process_ReadyToSandbox = TRUE`。

### `Gui_Api_Clipboard()`
根据 `OpenClipboard` 配置控制沙箱进程的剪贴板读写权限。

### `Gui_InitProcess(PROCESS*)`
读取 `OpenWinClass` 配置，构建允许的窗口类访问列表。`OpenWinClass=*` 时设置 `open_all_win_classes = TRUE`。

## Vista+ UIPI 保护原理

通过低完整性令牌激活 UIPI（用户界面特权隔离）：
- 低完整性进程无法向高完整性进程发送窗口消息
- 无法调用 `SetWindowsHookEx` 钩入高完整性进程
- 无法通过 `SendInput` 模拟其他进程输入

Sandboxie 在 `Token_ReplacePrimary` 中设置低完整性级别激活此保护。

## XP GUI 隔离

`gui_xp.c` 中通过 win32k 钩子拦截：
- `PostThreadMessage` — 阻止跨进程消息
- `SendInput` — 阻止输入模拟
- `SetWindowsHookEx` — 阻止钩子安装
