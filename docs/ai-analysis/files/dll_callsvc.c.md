# dll/callsvc.c — 服务调用封装

## 概述

`callsvc.c` 封装了 SbieDll 与 SbieSvc 之间的**命名管道通信**，提供 `CallSvc()` 函数供各 Hook 模块调用，将需要特权处理的操作转发给 SbieSvc。

## 通信协议

SbieDll 与 SbieSvc 之间使用命名管道通信：
- 管道名格式：`\\.\pipe\SbieSvc_{SessionId}_{TickCount}`
- 每次调用创建新连接（短连接模式）
- 消息格式：固定头部（msgid + length）+ 可变负载

## 关键函数

### `CallSvc(msgid, data, data_len)`

通用服务调用入口：
1. 通过驱动 `API_SET_SERVICE_PORT` 获取 SbieSvc 管道名
2. `CreateFile` 连接管道
3. `WriteFile` 发送请求消息
4. `ReadFile` 接收响应消息
5. 返回响应数据

### `CallSvc_Ex(msgid, in_data, in_len, out_data, out_len)`

扩展版本，支持分离的输入/输出缓冲区。

## 使用示例

```c
// file_recovery.c 中：请求 SbieSvc 恢复文件
FILE_RECOVER_REQ req;
req.msgid = MSGID_FILE_RECOVER_FILE;
wcsncpy(req.src_path, CopyPath, MAX_PATH);
wcsncpy(req.dst_path, TruePath, MAX_PATH);
CallSvc(MSGID_FILE_RECOVER_FILE, &req, sizeof(req));
```

## 安全性

管道有 ACL 保护：只允许当前用户和 SYSTEM 连接，防止其他用户冒充沙箱进程发送请求。
