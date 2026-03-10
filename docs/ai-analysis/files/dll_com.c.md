# dll/com.c — COM Hook

拦截 COM 激活 API，将沙箱进程的 COM 创建请求代理给 SbieSvc ComServer。

## 核心 Hook

```c
SBIEDLL_HOOK(Com, CoCreateInstance);
SBIEDLL_HOOK(Com, CoCreateInstanceEx);
SBIEDLL_HOOK(Com, CoGetClassObject);
```

## 激活策略

- in-proc COM → 正常激活
- out-of-proc，在 OpenCOM 白名单 → SbieSvc 代理
- 其他 → 拒绝 `E_ACCESSDENIED`
