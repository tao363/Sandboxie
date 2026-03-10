# drv/file_flt.c — 文件系统微过滤器核心

## 概述

`file_flt.c` 是 Vista+ 上文件系统虚拟化的核心实现，包含 FltMgr 微过滤器的所有回调函数，处理 `IRP_MJ_CREATE`、`IRP_MJ_SET_INFORMATION`（删除）等关键 IRP。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/drv/file_flt.c` |
| 所属模块 | SbieDrv.sys |
| 核心职责 | FltMgr PreOperation/PostOperation 回调 |

## 注册的 IRP 回调

| IRP 类型 | 回调 | 阶段 |
|---------|------|------|
| `IRP_MJ_CREATE` | `File_PreCreate` / `File_PostCreate` | Pre+Post |
| `IRP_MJ_SET_INFORMATION` | `File_PreSetInfo` | Pre |
| `IRP_MJ_CLEANUP` | `File_PreCleanup` | Pre |
| `IRP_MJ_NETWORK_QUERY_OPEN` | `File_PreNetworkQueryOpen` | Pre |

## 关键函数

### `File_PreCreate(Data, FltObjects, CompletionContext)`

最核心的回调，在文件创建/打开时触发：
1. 检查操作进程是否在沙箱中
2. 调用 `File_GetFileName()` 获取完整路径
3. 检查路径规则（Open/Closed/ReadOnly）
4. 决定是否重定向：修改 `Data->Iopb->TargetFileObject` 或 `FileName`
5. 若需要重定向，标记 `FLT_PREOP_SYNCHRONIZE` 在 PostCreate 中处理

### `File_PostCreate(Data, FltObjects, CompletionContext, Flags)`

PreCreate 重定向后的后处理：
- 若 CopyPath 父目录不存在则创建（`File_CreatePath`）
- 处理文件从 TruePath 复制到 CopyPath（Copy-on-Write 触发点）

### `File_PreSetInfo()`

拦截文件删除（`FileDispositionInformation`）：
- 将删除操作转为在 CopyPath 写入 `.delete` 标记文件
- 阻止对 TruePath 的实际删除

## FltMgr 过滤器注册参数

```c
FLT_REGISTRATION FilterRegistration = {
    sizeof(FLT_REGISTRATION),
    FLT_REGISTRATION_VERSION,
    FLTFL_REGISTRATION_DO_NOT_SUPPORT_SERVICE_STOP,
    NULL,               // ContextRegistration
    Callbacks,          // OperationRegistration
    File_Unload,        // FilterUnloadCallback
    File_InstanceSetup, // InstanceSetupCallback
    ...
};
```
