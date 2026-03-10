# dll/ldr.c + ldr_init.c — 加载器 Hook

## 概述

拦截 Windows 加载器（Ldr）API，修正沙箱环境下的 DLL 加载行为，确保程序在沙箱中正确加载和运行。

## 核心 Hook

```c
SBIEDLL_HOOK(Ldr, LdrLoadDll);              // DLL 加载控制
SBIEDLL_HOOK(Ldr, LdrUnloadDll);
SBIEDLL_HOOK(Ldr, LdrGetDllHandle);
SBIEDLL_HOOK(Ldr, NtOpenFile);              // 覆盖 DLL 搜索路径
SBIEDLL_HOOK(Ldr, LdrQueryImageFileExecOptions);
```

## ldr_init.c — 加载器初始化修复

`ldr_init.c` 在 `Dll_InitInjected` 早期调用，修复注入场景下的加载器状态：
- 解决 TLS（线程本地存储）初始化顺序问题
- 修复 WoW64 进程的加载器锁（LdrpLoaderLock）
- 修正进程环境块（PEB）中的模块列表

## DLL 搜索路径修正

沙箱进程加载 DLL 时，优先查找沙箱内的副本：
```
搜索顺序：
1. 沙箱 CopyPath 目录
2. 标准 DLL 搜索路径（System32 等）
3. TruePath（真实文件系统）
```

## SxS（并行程序集）支持

`sxs.c` 处理 Side-by-Side 程序集（manifest）相关的加载问题，确保沙箱进程能正确解析 WinSxS 依赖。
