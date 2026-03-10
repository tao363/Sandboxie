# drv/process_api.c — 进程 IOCTL 处理

## 概述

实现进程管理相关的 IOCTL 处理函数，供用户态通过驱动 API 查询和控制沙箱进程。

## IOCTL 处理函数

| 功能代码 | 函数 | 说明 |
|---------|------|------|
| `API_START_PROCESS` | `Process_Api_Start` | SbieSvc 通知驱动准备接收新沙箱进程 |
| `API_QUERY_PROCESS` | `Process_Api_Query` | 查询 PID 的沙箱归属信息 |
| `API_ENUM_PROCESSES` | `Process_Api_Enum` | 枚举沙箱内所有进程 PID |
| `API_QUERY_PROCESS_INFO` | `Process_Api_QueryInfo` | 查询进程详细信息 |
| `API_OPEN_PROCESS` | `Process_Api_OpenProcess` | 安全打开沙箱进程句柄 |
| `API_INJECT_COMPLETE` | `Process_Api_InjectComplete` | SbieSvc 通知注入完成 |
| `API_MONITOR_CONTROL` | `Process_Api_MonitorControl` | 资源访问监控开关 |

## 关键函数

### `Process_Api_Start`
SbieSvc 在 `CreateProcessAsUserW` **之前**调用，传入目标沙箱名，让驱动提前准备好上下文。

### `Process_Api_Query`
返回 PID 对应的沙箱名、路径、`initialized`/`terminated` 标志、创建时间（防 PID 复用）。

### `Process_Api_InjectComplete`
SbieSvc 注入完成后调用，驱动设置 `proc->initialized = TRUE`，允许进程 `ResumeThread`。
