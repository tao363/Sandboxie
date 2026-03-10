# svc/sbieiniserver.cpp — 配置服务

## 概述

`sbieiniserver.cpp` 为沙箱进程和 GUI 提供**配置文件读写服务**。由于 `Sandboxie.ini` 需要权限保护（只有 SbieSvc 和管理员可写），普通沙箱进程通过此服务代理读写配置。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/svc/sbieiniserver.cpp` |
| 所属模块 | SbieSvc.exe |
| 核心职责 | 配置文件代理读写 |

## 消息处理

| 消息 ID | 功能 |
|--------|------|
| `MSGID_SBIE_INI_GET_WAIT` | 等待配置就绪 |
| `MSGID_SBIE_INI_GET_VERSION` | 获取配置版本 |
| `MSGID_SBIE_INI_GET_SETTING` | 读取单个配置项 |
| `MSGID_SBIE_INI_SET_SETTING` | 写入单个配置项 |
| `MSGID_SBIE_INI_DEL_SETTING` | 删除配置项 |
| `MSGID_SBIE_INI_GET_SECTIONS` | 枚举所有节 |

## 权限控制

写操作需要验证：
1. 请求来自管理员进程，或
2. 请求来自具有 `EditAdminOnly=n` 的沙箱进程（且配置允许）
3. 通过后调用驱动通知配置变更（`IOCTL_SBIE_INI_CHANGED`）
