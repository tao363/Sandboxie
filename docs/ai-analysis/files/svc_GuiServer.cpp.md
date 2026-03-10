# svc/GuiServer.cpp — GUI 服务

## 概述

`GuiServer.cpp` 处理沙箱进程的 **GUI 相关服务请求**，包括 Job Object 分配（用于进程组隔离）、窗口访问控制、桌面管理等。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/svc/GuiServer.cpp` |
| 所属模块 | SbieSvc.exe |
| 核心职责 | Job Object 管理、GUI 访问控制 |

## 关键功能

### Job Object 管理

每个沙箱实例对应一个 Windows Job Object：
- 进程创建时通过 `GetJobObjectForAssign` 获取（或创建）Job
- 将新进程 `AssignProcessToJobObject` 加入 Job
- Job 限制：`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`（Job 关闭时杀死所有进程）
- `JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK`（允许子进程脱离 Job，由驱动重新分配）

### InitProcess

新沙箱进程初始化时调用：
1. 分配 Job Object
2. 设置 Window Station / Desktop 访问权限
3. 配置 AppContainer 相关权限（Win8+）

## 消息处理

| 消息 ID | 功能 |
|--------|------|
| `MSGID_GUI_GET_WINDOW_STATION` | 获取窗口站 |
| `MSGID_GUI_INIT_PROCESS` | 初始化进程 GUI 环境 |
| `MSGID_GUI_GET_JOB_OBJECT` | 获取 Job Object 句柄 |
| `MSGID_GUI_MONITOR_CONTROL` | 资源监控控制 |
