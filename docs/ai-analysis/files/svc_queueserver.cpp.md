# svc/queueserver.cpp — 异步队列服务

## 概述

`queueserver.cpp` 实现**异步操作队列**，允许沙箱进程向 SbieSvc 提交异步任务（如文件恢复、后台清理），SbieSvc 在后台处理并将结果通知回调用者。

## 消息处理

| 消息 ID | 功能 |
|--------|------|
| `MSGID_QUEUE_CREATE` | 创建命名队列 |
| `MSGID_QUEUE_PUTREQ` | 提交请求到队列 |
| `MSGID_QUEUE_GETREQ` | 从队列取出请求（服务端）|
| `MSGID_QUEUE_PUTRPL` | 提交请求处理结果 |
| `MSGID_QUEUE_GETRPL` | 获取处理结果（客户端）|

## 使用场景

### 文件恢复通知
```
沙箱进程 → QueueServer(PUTREQ, recover_path)
                ↓ 异步
SandMan GUI ← QueueServer(GETREQ) → 显示恢复对话框
SandMan GUI → QueueServer(PUTRPL, user_choice)
                ↓
沙箱进程 ← QueueServer(GETRPL, result)
```

### 立即恢复（Auto Recover）
程序保存文件时，通过队列机制异步通知 GUI 显示恢复提示，不阻塞文件写入操作。

## svc/namedpipeserver.cpp — 命名管道代理

`namedpipeserver.cpp` 代理沙箱进程创建和访问命名管道：
- 沙箱进程创建的命名管道路径被重定向到沙箱命名空间
- 允许沙箱内进程间通过命名管道通信
- 阻止沙箱进程创建与外部程序通信的命名管道（除非配置 `OpenPipePath`）
