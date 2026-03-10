# drv/key_flt.c — 注册表过滤器核心

## 概述

`key_flt.c` 是 Vista+ 上注册表虚拟化的核心，包含 `CmRegisterCallbackEx` 注册的注册表回调函数，处理所有注册表操作的路径重定向。

## 关键回调

| 注册表操作 | 回调函数 | 处理 |
|-----------|---------|------|
| `RegNtPreOpenKey` / `RegNtPreOpenKeyEx` | `Key_PreOpenKey` | 路径重定向到 CopyPath |
| `RegNtPreCreateKey` / `RegNtPreCreateKeyEx` | `Key_PreCreateKey` | 重定向写操作 |
| `RegNtPreDeleteKey` | `Key_PreDeleteKey` | 写删除标记 |
| `RegNtPreSetValueKey` | `Key_PreSetValueKey` | 重定向到 CopyPath |
| `RegNtPreDeleteValueKey` | `Key_PreDeleteValueKey` | 写删除标记 |
| `RegNtPreQueryKey` | `Key_PreQueryKey` | 合并返回结果 |
| `RegNtPreEnumerateKey` | `Key_PreEnumerateKey` | 合并枚举结果 |

## 关键函数

### `Key_Callback(CallbackContext, Argument1, Argument2)`

统一入口回调，根据 `REG_NOTIFY_CLASS` 分发到具体处理函数：
1. 通过 `PsGetCurrentProcessId()` 找到对应 PROCESS
2. 调用 `Key_GetName()` 解析 TruePath/CopyPath
3. 执行路径替换或拦截

### `Key_PreOpenKey()`

注册表键打开重定向：
1. 若 CopyPath 存在 → 将请求对象改为 CopyPath
2. 若 CopyPath 不存在但有删除标记 → 返回 `STATUS_OBJECT_NAME_NOT_FOUND`
3. 否则 → 允许访问 TruePath

### `Key_PreCreateKey()`

注册表键创建：
- 确保 CopyPath 父键存在（逐级创建）
- 将创建目标改为 CopyPath

## 注册表回调注册

```c
CmRegisterCallbackEx(
    Key_Callback,      // 回调函数
    &altitude,         // 过滤器高度字符串
    DriverObject,
    NULL,
    &Key_CmCookie,     // 注销时使用的 cookie
    NULL
);
```
