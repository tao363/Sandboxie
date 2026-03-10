# drv/obj.c — 内核对象管理

## 概述

封装 Windows 对象管理器（ObManager）操作，为 IPC 隔离和线程保护提供对象名称查询支撑。

## 关联文件
- `obj_flt.c` — Vista+ ObRegisterCallbacks 对象过滤
- `obj_xp.c` — XP 对象回调（通过解析 ObpObjectTypes）

## 关键函数

### `Obj_Init()`
Vista+：通过 `ObRegisterCallbacks` 注册对象操作前回调。XP：解析内核 `ObpObjectTypes` 表安装钩子。

### `Obj_GetName(Object, Buffer, Length)`
查询内核对象的完整名称（NT 路径），封装 `ObQueryNameString`。

### `Obj_GetObjectType(TypeName)`
通过类型名称（如 `L"Event"`）查找 `OBJECT_TYPE*` 指针，供注册回调使用。

## 使用示例

```c
// ipc.c：查对象名判断是否在沙箱命名空间
OBJECT_NAME_INFORMATION *info;
Obj_GetName(Object, &info, &len);
if (wcsncmp(info->Name.Buffer, proc->box->ipc_path, ...) == 0)
    ; // 允许访问
```
