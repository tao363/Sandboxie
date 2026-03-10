# drv/process.c — 进程管理与沙箱化

## 概述

`process.c` 是 Sandboxie 最核心的文件之一，负责**监控所有进程的创建和销毁**，决定哪些进程需要进入沙箱，并为沙箱进程完成完整的隔离初始化。通过 `PsSetCreateProcessNotifyRoutineEx`、`PsSetLoadImageNotifyRoutine` 等内核回调实现全程进程生命周期监控。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/drv/process.c` |
| 所属模块 | SbieDrv.sys |
| 语言 | C（内核模式）|
| 核心职责 | 进程创建监控、沙箱化决策、进程列表管理、隔离初始化 |

## 全局变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `Process_Map` | `HASH_MAP` | PID → PROCESS 映射（主进程列表）|
| `Process_MapDfp` | `HASH_MAP` | 禁用强制沙箱的进程列表 |
| `Process_MapFcp` | `HASH_MAP` | 强制子进程沙箱的列表 |
| `Process_ListLock` | `PERESOURCE` | 进程列表读写锁 |
| `Process_ReadyToSandbox` | `volatile BOOLEAN` | 驱动初始化完成标志 |

## PROCESS 结构体关键字段

| 字段 | 含义 |
|------|------|
| `pid` | 进程 ID |
| `pool` | 进程专属内存池（退出时整体释放）|
| `box` | 所属沙箱描述符 BOX* |
| `image_path` | 可执行文件完整 NT 路径 |
| `image_name` | 可执行文件名（basename）|
| `create_time` | 创建时间（防 PID 复用攻击）|
| `initialized` | 沙箱初始化完成标志 |
| `terminated` | 进程终止标志 |
| `bAppCompartment` | 应用容器模式（NoSecurityIsolation=y）|
| `use_security_mode` | 安全模式（UseSecurityMode=y）|
| `forced_process` | 是否为强制进入沙箱的进程 |
| `bHostInject` | 仅注入 DLL 不真正沙箱化 |
| `open_file_paths` | 开放文件路径列表 |
| `closed_file_paths` | 封闭文件路径列表 |
