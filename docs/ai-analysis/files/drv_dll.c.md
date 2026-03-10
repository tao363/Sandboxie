# drv/dll.c — DLL 注入数据管理

## 概述

`dll.c` 管理驱动层的 **DLL 注入数据**，负责从磁盘读取 SbieDll.dll 和 LowLevel.dll 的相关信息，准备注入时需要的数据结构。

## 关键函数

### `Dll_Init()`

驱动初始化时调用：
1. 从注册表或配置读取 SbieDll.dll 路径
2. 验证 DLL 文件存在且版本匹配
3. 准备 `DLL_DATA` 结构（含 DLL 路径的 NT 和 DOS 格式）
4. 为不同架构（x64/x86/ARM64）分别准备 DLL 路径

### `Dll_GetImageType(ImageName)`

根据进程名返回 `DLL_IMAGE_TYPE` 枚举值，驱动层版本供 `process.c` 在进程创建时快速识别进程类型，决定是否需要特殊处理。

### `Dll_GetSbieDllPath(arch)`

返回指定架构的 SbieDll.dll 完整路径：
- x64：`Driver_HomePathNt\SbieDll.dll`
- x86（WoW64）：`Driver_HomePathNt\SbieDll32.dll`
- ARM64EC：`Driver_HomePathNt\SbieDllEC.dll`

## DLL_DATA 结构

```c
typedef struct _DLL_DATA {
    WCHAR *sbie_dll_path;      // SbieDll.dll NT 路径
    WCHAR *sbie_dll_path_dos;  // SbieDll.dll DOS 路径
    WCHAR *lowlevel_dll_path;  // LowLevel.dll 路径
    ULONG  sbie_dll_size;      // DLL 文件大小（用于完整性校验）
} DLL_DATA;
```
