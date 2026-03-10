# dll/custom.c — 自定义兼容性补丁

## 概述

`custom.c` 包含针对特定应用程序的**兼容性补丁集合**，处理各种程序在沙箱环境下出现的兼容性问题，确保常用软件能在沙箱中正常运行。

## 补丁类型

### 进程类型特化（与 Dll_ImageType 配合）

```c
// 在 Dll_InitInjected 中根据进程类型应用对应补丁
switch (Dll_ImageType) {
case DLL_IMAGE_FIREFOX:
    Custom_Firefox();    // Firefox 专属补丁
    break;
case DLL_IMAGE_CHROME:
    Custom_Chrome();     // Chrome 专属补丁
    break;
case DLL_IMAGE_INTERNET_EXPLORER:
    Custom_IE();         // IE 专属补丁
    break;
case DLL_IMAGE_MSOFFICE:
    Custom_Office();     // Office 专属补丁
    break;
}
```

### 常见补丁场景

| 程序 | 问题 | 补丁方式 |
|------|------|--------|
| Firefox | 进程沙箱化检测 | 修改检测函数返回值 |
| Chrome | GPU 进程权限 | 调整 Job Object 权限 |
| Office | COM 注册 | 重定向注册表路径 |
| Acrobat | 保护模式冲突 | 禁用内置沙箱 |

## setup.c — 安装辅助

`setup.c` 处理程序安装场景下的特殊需求：
- 检测安装程序行为（`msiexec.exe`、`setup.exe` 等）
- 在安装模式下放宽部分限制（允许写入更多路径）
- `SeparateUserFolders=y` 时为不同用户创建隔离的沙箱子目录

## support.c — 支持函数库

`support.c` 提供各模块共用的辅助函数：
- 字符串处理（`Dll_AllocStr`、`Dll_DupStr` 等）
- 路径规范化（`Dll_NormalizePath`）
- 模块句柄缓存（`Dll_GetModuleHandle`）
