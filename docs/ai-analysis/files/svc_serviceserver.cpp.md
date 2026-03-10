# svc/serviceserver.cpp — 服务代理

## 概述

`serviceserver.cpp` 代理沙箱进程对 Windows 服务控制管理器（SCM）的操作，允许部分受控的服务启动/停止请求。

## 消息处理

| 消息 ID | 功能 |
|--------|------|
| `MSGID_SERVICE_START` | 代理启动系统服务 |
| `MSGID_SERVICE_QUERY` | 查询服务状态 |
| `MSGID_SERVICE_CUSTOM` | 自定义服务控制 |

## 访问控制

- 只允许启动配置中 `StartService` 白名单的服务
- 默认允许：`wuauserv`（Windows Update）、`BITS` 等
- 拒绝启动：驱动类服务、关键系统服务

## serviceserver2.cpp

包含服务代理的第二版实现，支持更细粒度的服务权限控制和 Vista+ 的服务 SID 机制。
