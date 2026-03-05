# Sandboxie 驱动程序 - IPC 模块详细分析

## 概述

IPC（进程间通信）模块负责拦截和隔离各种 IPC 机制，包括命名对象、LPC/ALPC 端口等。

## 主要功能

1. **命名对象隔离** - 事件、互斥体、信号量等
2. **LPC/ALPC 端口控制** - 限制端口连接
3. **作业对象管理** - 控制作业对象使用
4. **剪贴板隔离** - 隔离剪贴板数据

## 命名对象类型

- Event（事件）
- Mutant（互斥体）
- Semaphore（信号量）
- Section（共享内存）
- Timer（定时器）
- KeyedEvent（键控事件）
- JobObject（作业对象）

## 路径重定向

```
真实路径: \BaseNamedObjects\MyEvent
沙箱路径: \Sandbox\<SID>\Session_<N>\<BoxName>\BaseNamedObjects\MyEvent
```

## 配置选项

```ini
OpenIpcPath=\BaseNamedObjects\*
ClosedIpcPath=\RPC Control\*
ReadIpcPath=\KnownDlls\*
```

## 关键函数

- `Ipc_Init()` - 初始化 IPC 拦截
- `Ipc_CreateBoxPath()` - 创建沙箱 IPC 路径
- `Ipc_CheckGenericObject()` - 检查命名对象访问
- `Ipc_CheckPortObject()` - 检查端口对象访问

详细分析请参考完整文档。
