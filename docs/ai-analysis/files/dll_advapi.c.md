# dll/advapi.c — 高级 API Hook

## 概述

`advapi.c` 拦截 `advapi32.dll` 中的安全和注册表高级 API，补充 `key.c` 和 `secure.c` 未覆盖的场景。

## 核心 Hook

```c
SBIEDLL_HOOK(Adv, RegConnectRegistryW);    // 阻止连接远程注册表
SBIEDLL_HOOK(Adv, RegOverridePredefKey);   // 控制预定义键覆盖
SBIEDLL_HOOK(Adv, InitiateSystemShutdown); // 阻止关机/重启
SBIEDLL_HOOK(Adv, InitiateShutdown);
SBIEDLL_HOOK(Adv, SetFileSecurityW);       // 安全描述符修改控制
SBIEDLL_HOOK(Adv, SetNamedSecurityInfoW);
```

## 关键处理

- `RegConnectRegistryW`：直接返回 `ERROR_ACCESS_DENIED`，阻止沙箱进程访问远程机器注册表
- `InitiateSystemShutdown`：返回 `ERROR_ACCESS_DENIED`，防止沙箱程序关机
- `SetFileSecurity`：重定向到沙箱 CopyPath 的安全描述符
