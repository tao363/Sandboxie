# svc/UserServer.cpp — 用户信息服务

## 概述

`UserServer.cpp` 为沙箱进程提供用户账户信息查询代理，处理需要特权访问的用户/组信息请求。

## 消息处理

| 消息 ID | 功能 |
|--------|------|
| `MSGID_USER_GET_INFO` | 获取用户账户信息 |
| `MSGID_USER_GET_GROUPS` | 获取用户组列表 |
| `MSGID_USER_CHECK_MEMBERSHIP` | 检查组成员资格 |

## 用途

沙箱进程的令牌已被过滤（删除了部分组），但某些程序需要查询原始用户信息（如判断是否管理员）。`UserServer` 根据配置决定返回真实信息还是过滤后的信息：
- `FakeAdminRights=y`：返回包含 Administrators 组的假信息
- 默认：返回真实用户信息（不含已删除的组）

## DriverAssistSid.cpp

`DriverAssistSid.cpp` 是 DriverAssist 的 SID 辅助模块，提供：
- 当前用户 SID 查询
- SID 字符串转换
- 登录 SID 获取
这些数据用于构建沙箱路径中的 `{SID}` 部分。
