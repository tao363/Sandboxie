# dll/terminal.c — 终端服务 Hook

## 概述

`terminal.c` 拦截终端服务（Terminal Services / Remote Desktop）相关 API，处理多会话环境下的沙箱隔离问题。

## 核心 Hook

```c
SBIEDLL_HOOK(Term, WTSOpenServerW);           // 控制 WTS 服务器连接
SBIEDLL_HOOK(Term, WTSEnumerateSessionsW);    // 过滤会话枚举
SBIEDLL_HOOK(Term, WTSQuerySessionInformationW); // 会话信息控制
```

## 处理逻辑

- `WTSEnumerateSessionsW`：只返回当前会话，防止沙箱进程枚举其他用户会话
- `WTSQuerySessionInformation`：过滤敏感会话信息
- 多会话环境下的沙箱路径包含 `Session_{N}` 以区分不同会话

## userenv.c — 用户环境 Hook

`userenv.c` 拦截用户环境加载 API：
```c
SBIEDLL_HOOK(Uenv, LoadUserProfileW);    // 配置文件加载控制
SBIEDLL_HOOK(Uenv, UnloadUserProfile);
SBIEDLL_HOOK(Uenv, GetUserProfileDirW); // 返回沙箱内用户目录
```

`GetUserProfileDirectory` 返回沙箱内的用户 profile 路径，确保程序将用户数据写入沙箱而非真实 profile 目录。
