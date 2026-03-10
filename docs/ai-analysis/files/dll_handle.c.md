# dll/handle.c — 句柄管理

## 概述

`handle.c` 维护沙箱进程的**句柄映射表**，跟踪哪些句柄指向沙箱内对象，哪些指向沙箱外对象，为其他 Hook 模块提供句柄查询支持。

## 核心数据结构

```c
typedef struct _HANDLE_ENTRY {
    HANDLE handle;        // 句柄值
    ULONG  flags;         // 标志（HANDLE_FLAG_BOXED 等）
    WCHAR *path;          // 对象路径（可选）
} HANDLE_ENTRY;
```

## 关键函数

### `Handle_RegisterCloseHandler(type, handler)`
注册句柄关闭时的清理回调，用于释放与句柄关联的沙箱资源。

### `Handle_SetObjectType(handle, type)`
标记句柄的对象类型（文件/注册表/IPC 等），供其他模块判断。

### `Handle_IsBoxedObjectType(handle)`
检查句柄是否指向沙箱内对象，用于决定是否需要路径重定向。

## 使用场景

```c
// file.c 中：判断文件句柄是否来自沙箱
if (Handle_IsBoxedObjectType(FileHandle)) {
    // 直接操作，无需重定向
} else {
    // 需要检查路径规则
}
```
