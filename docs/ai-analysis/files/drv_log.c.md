# drv/log.c — 内核日志

## 概述

`log.c` 提供驱动层的**日志记录功能**，将内核事件（进程创建失败、初始化错误、安全告警等）写入 Windows 系统事件日志（Event Log）和驱动内部环形缓冲区（`Api_LogBuffer`），供 SbieSvc 和 GUI 读取显示。

## 关键函数

### `Log_Msg(msgid, str1, str2)` 系列

- `Log_Msg0(msgid)` — 无参数消息
- `Log_Msg1(msgid, str1)` — 一个字符串参数
- `Log_Msg2(msgid, str1, str2)` — 两个字符串参数
- `Log_Msg_Process(msgid, str1, str2, session_id, pid)` — 带进程信息
- `Log_Status(msgid, tag, status)` — NTSTATUS 状态消息

所有这些函数最终调用：
1. `Api_AddMessage()` — 写入驱动环形日志缓冲（供 UI 读取）
2. `Log_Event_Msg()` — 写入 Windows 系统事件日志

### `Log_Event_Msg(error_code, str1, str2)`
使用 `IoAllocateErrorLogEntry` / `IoWriteErrorLogEntry` 向 Windows 事件日志写入条目。

### `Log_Popup_MsgEx()`
触发弹出式通知消息（在 UI 中显示提示框）。

## 消息 ID 系统

所有消息 ID 定义在 `msgs/Sbie-English-1033.txt`：

| 范围 | 类型 |
|------|------|
| MSG_1xxx | 驱动通用消息 |
| MSG_2xxx | 驱动安全/访问消息 |
| MSG_6xxx | 功能限制消息（证书相关）|
| MSG_9xxx | 服务错误消息 |
