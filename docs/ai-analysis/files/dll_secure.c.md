# dll/secure.c — 安全 API Hook

防止沙箱进程通过特权操作突破沙箱边界。

## 核心 Hook

```c
SBIEDLL_HOOK(Secure, NtOpenProcess);           // 限制跨进程访问
SBIEDLL_HOOK(Secure, NtDuplicateObject);       // 限制句柄复制
SBIEDLL_HOOK(Secure, NtAdjustPrivilegesToken); // 阻止特权提升
SBIEDLL_HOOK(Secure, NtCreateDebugObject);     // 阻止调试
```

## 关键逻辑

- `NtOpenProcess`：目标为非沙箱进程时移除高权限位；`UseSecurityMode=y` 时完全阻止
- `NtDuplicateObject`：阻止强力句柄跨沙箱复制
- `NtAdjustPrivilegesToken`：阻止启用 SeDebug/SeTcb/SeLoadDriver

## 双重防御

用户态 Hook 是第一道防线；驱动层 ObRegisterCallbacks 是第二道，不可绕过。
