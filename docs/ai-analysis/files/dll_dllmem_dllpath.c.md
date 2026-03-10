# dll/dllmem.c / dllpath.c — DLL 内存与路径管理

## 概述

`dllmem.c` 管理 SbieDll 内部的**内存分配**；`dllpath.c` 管理**沙箱路径变量**（BoxFilePath、BoxKeyPath、BoxIpcPath 等）的初始化和查询。

## dllmem.c

### 内存分配函数

```c
void *Dll_Alloc(ULONG size);           // HeapAlloc 包装，失败时直接终止进程
void *Dll_AllocTemp(ULONG size);       // 临时分配（使用线程本地堆）
void  Dll_Free(void *ptr);             // HeapFree 包装
WCHAR *Dll_AllocStr(const WCHAR *str); // 字符串复制分配
```

### 内存保护

`Dll_Alloc` 在分配失败时调用 `ExitProcess`，因为 SbieDll 中内存不足意味着严重错误，继续运行可能导致不可预料的行为。

## dllpath.c

### 路径初始化

在 `Dll_InitInjected()` 阶段，通过驱动 `API_QUERY_PROCESS_INFO` 获取以下路径并存储为全局变量：

| 变量 | 示例值 |
|------|-------|
| `Dll_BoxFilePath` | `C:\Sandbox\User\DefaultBox` |
| `Dll_BoxKeyPath` | `\REGISTRY\USER\Sandbox_SID_DefaultBox` |
| `Dll_BoxIpcPath` | `\Sandbox\SID\Session_1\DefaultBox` |
| `Dll_HomeNtPath` | `\Device\HarddiskVolume3\SbPlus` |
| `Dll_HomeDosDrive` | `C` |

### 路径辅助函数

```c
BOOLEAN Dll_IsBoxedPath(const WCHAR *path);     // 检查是否在沙箱文件路径下
BOOLEAN Dll_IsBoxedKeyPath(const WCHAR *path);  // 检查是否在沙箱注册表路径下
BOOLEAN Dll_IsSystemPath(const WCHAR *path);    // 检查是否为系统路径
```
