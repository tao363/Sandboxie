# dll/trace.c — 资源访问跟踪

## 概述

`trace.c` 实现沙箱进程的**资源访问跟踪**功能，记录文件、注册表、IPC 等访问事件，供 SandMan 的 TraceView 实时显示。

## 跟踪类型

| 配置项 | 跟踪内容 |
|--------|--------|
| `FileTrace=y` | 文件访问（路径、操作类型）|
| `KeyTrace=y` | 注册表访问 |
| `IpcTrace=y` | IPC/命名对象访问 |
| `PipeTrace=y` | 命名管道访问 |
| `GuiTrace=y` | 窗口/消息访问 |
| `NetTrace=y` | 网络连接 |

## 工作机制

各 Hook 模块在执行操作时调用 `Trace_xxx()` 函数记录事件：

```c
// file.c 中
if (proc->file_trace & TRACE_ALLOW)
    Trace_FileOpen(TruePath, CopyPath, status);
```

跟踪记录通过 `SbieApi_LogMessage(API_LOG_MESSAGE)` 写入驱动日志缓冲，SandMan TraceView 通过 `API_GET_MESSAGE` 轮询读取。

## 驱动侧跟踪（Session_MonitorPut）

驱动层的 `session.c` 也维护跟踪日志（`Session_MonitorPut`），记录内核层拦截的操作，与用户态跟踪形成完整的访问日志。
