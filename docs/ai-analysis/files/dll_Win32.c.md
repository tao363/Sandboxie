# dll/Win32.c — Win32k 系统调用（用户态）

## 概述

`Win32.c` 处理 `win32u.dll`（Win32k 用户态接口）中的系统调用 Hook，拦截不经过 ntdll 而直接调用 win32k 驱动的 GUI 系统调用。

## 背景

Windows 8.1+ 中，许多 GUI 操作（如 `NtUserSendMessage`、`NtUserCreateWindowEx`）通过 `win32u.dll` 发出，绕过了 ntdll 路径。`Win32.c` 补充 Hook 这部分系统调用。

## 核心 Hook

```c
SBIEDLL_HOOK(Win32, NtUserCreateWindowEx);    // 窗口创建控制
SBIEDLL_HOOK(Win32, NtUserFindWindowEx);      // 窗口查找过滤
SBIEDLL_HOOK(Win32, NtUserBuildHwndList);     // 窗口列表过滤
SBIEDLL_HOOK(Win32, NtUserSendMessage);       // 消息发送控制
SBIEDLL_HOOK(Win32, NtUserPostMessage);
SBIEDLL_HOOK(Win32, NtUserSetWindowsHookEx);  // 阻止全局Hook
SBIEDLL_HOOK(Win32, NtUserRegisterRawInputDevices); // 输入设备控制
```

## gdi.c — GDI Hook

`gdi.c` 拦截 GDI 相关操作：
```c
SBIEDLL_HOOK(Gdi, GetClipboardData);    // 剪贴板访问控制
SBIEDLL_HOOK(Gdi, SetClipboardData);
SBIEDLL_HOOK(Gdi, OpenClipboard);
```
剪贴板访问受 `OpenClipboard` 配置控制，与驱动层 `API_GUI_CLIPBOARD` IOCTL 配合工作。

## sysinfo.c — 系统信息 Hook

`sysinfo.c` 拦截系统信息查询：
```c
SBIEDLL_HOOK(Si, NtQuerySystemInformation);  // 过滤系统信息
SBIEDLL_HOOK(Si, GlobalMemoryStatusEx);      // 内存信息
```
防止沙箱进程通过 `SystemProcessInformation` 枚举所有系统进程。
