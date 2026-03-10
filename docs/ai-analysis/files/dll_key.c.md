# dll/key.c — 注册表 Hook（用户态）

## 概述

`dll/key.c` 拦截注册表 API，实现注册表写时复制虚拟化，将沙箱进程的注册表写操作重定向到沙箱蜂巢。

## 路径转换示例

```
TruePath:  \REGISTRY\MACHINE\SOFTWARE\Microsoft
CopyPath:  \REGISTRY\USER\Sandbox_SID_BoxName\machine\software\microsoft
```

## 关键函数

### `Key_GetName()`
解析注册表路径，处理 WoW64 重定向（`Wow6432Node`），构建 TruePath 和 CopyPath。

### `Key_NtOpenKeyImpl()` / `Key_NtCreateKeyImpl()`
1. 调用 `Key_GetName()` 解析路径
2. 读操作：先 CopyPath，不存在则 TruePath
3. 写操作：在 CopyPath 操作
4. 处理删除标记（`DELETE_MARK_HIGH/LOW`）

### `Key_NtDeleteKey()`
不真正删除，而是写入删除标记（类似文件删除标记）。

### `Key_NtEnumerateKey()` / `Key_NtEnumerateValueKey()`
合并枚举 CopyPath 和 TruePath 的键/值，过滤已删除项目。

## Hook 注册

```c
SBIEDLL_HOOK(Nt, OpenKey);
SBIEDLL_HOOK(Nt, OpenKeyEx);
SBIEDLL_HOOK(Nt, CreateKey);
SBIEDLL_HOOK(Nt, DeleteKey);
SBIEDLL_HOOK(Nt, SetValueKey);
SBIEDLL_HOOK(Nt, DeleteValueKey);
SBIEDLL_HOOK(Nt, QueryValueKey);
SBIEDLL_HOOK(Nt, EnumerateKey);
SBIEDLL_HOOK(Nt, EnumerateValueKey);
```
