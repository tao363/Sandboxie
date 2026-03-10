# drv/session.c — 会话管理

## 概述

`session.c` 管理 Windows Terminal Services（多用户/远程桌面）会话，跟踪每个会话中的沙箱状态，处理会话登录/注销事件。

## 关键函数

### `Session_Init()`
初始化会话管理，注册 `PsSetLoadImageNotifyRoutine` 的会话相关处理。

### `Session_GetLeaderProcess(session_id)`
获取指定会话的「领导进程」（首个沙箱进程），用于确定会话级别的资源归属。

### `Session_Cancel(proc)`
进程退出时调用，若是会话最后一个进程则清理会话级资源。

### `Session_MonitorPut/Get()`
资源访问监控接口，记录沙箱进程的文件/注册表访问事件，供 TraceView 显示。

## SESSION 结构体

```c
typedef struct _SESSION {
    LIST_ELEM list_elem;
    ULONG session_id;         // Terminal Services 会话 ID
    BOOLEAN monitor_on;       // 监控开关
    LIST monitor_log;         // 监控日志条目列表
    PERESOURCE monitor_lock;  // 日志访问锁
} SESSION;
```
