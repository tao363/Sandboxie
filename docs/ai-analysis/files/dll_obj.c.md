# dll/obj.c — 对象路径解析（用户态）

## 概述

`dll/obj.c` 提供用户态的**对象路径解析**辅助函数，帮助其他 Hook 模块将句柄转换为对象路径、解析符号链接等。

## 关键函数

### `Obj_GetObjectName(Handle)`
通过 `NtQueryObject(ObjectNameInformation)` 获取句柄对应的对象路径字符串。

### `Obj_NtOpenKey_Workaround()`
处理注册表路径解析的特殊情况（驱动符号链接、WoW64 重定向等）。

## dll/config.c — 用户态配置查询

`dll/config.c` 封装 SbieDll 对驱动配置 API 的查询：

```c
// 封装 SbieApi_QueryConf
BOOLEAN Config_GetSettingBool(section, name, def);
const WCHAR *Config_GetSettingStr(section, name, index);
```

各 Hook 模块通过 `Config_GetSettingBool(Dll_BoxName, L"OpenFilePath", 0)` 等调用读取沙箱配置，用于决定访问策略。
