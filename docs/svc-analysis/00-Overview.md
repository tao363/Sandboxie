# 总体架构概述

## 目录简介

`Sandboxie\core\svc` 目录包含 Sandboxie 服务 (SbieSvc.exe) 的完整实现。这是一个运行在 Windows 系统服务中的用户态程序，作为整个沙箱系统的控制中心。

## 文件组织

### 核心文件 (9 个)
- **main.cpp** - 服务入口点和生命周期管理
- **PipeServer.cpp/h** - LPC 通信服务器（核心通信枢纽）
- **msgids.h** - 消息 ID 定义
- **misc.h/cpp** - 辅助函数和工具
- **stdafx.h/cpp** - 预编译头文件

### 服务器组件 (26 个 .cpp 文件)

#### 主要服务器
1. **ProcessServer** - 进程管理（启动、终止、挂起/恢复）
2. **SbieIniServer** - 配置文件管理
3. **GuiServer** - GUI 操作代理
4. **DriverAssist** - 驱动程序通信桥梁
5. **ServiceServer** - Windows 服务管理

#### 通信服务器
6. **NamedPipeServer** - 命名管道代理
7. **QueueServer** - 消息队列服务
8. **ComServer** - COM 对象代理

#### 系统服务器
9. **FileServer** - 文件系统操作
10. **TerminalServer** - 终端服务
11. **NetApiServer** - 网络 API
12. **IpHlpServer** - IP 辅助功能
13. **PStoreServer** - 受保护存储
14. **MountManager** - 镜像盒挂载管理
15. **EpMapperServer** - RPC 端点映射
16. **UserServer** - 用户相关操作

### 协议定义文件 (14 个 *Wire.h)
定义各服务器的请求/响应消息结构：
- ProcessWire.h, GuiWire.h, ServiceWire.h 等

### 辅助文件
- **ProxyHandle.cpp/h** - 句柄代理管理
- **DriverAssistInject.cpp** - 进程注入
- **DriverAssistLog.cpp** - 日志处理
- **DriverAssistStart.cpp** - 启动辅助
- **DriverAssistSid.cpp** - SID 处理
- **MountManagerHelpers.cpp** - 挂载辅助
- **HostInjectProcessUtil.cpp** - 主机注入工具

## 架构设计

### 1. 分层架构

```
┌─────────────────────────────────────────┐
│         应用层 (沙箱进程)                  │
└──────────────┬──────────────────────────┘
               │ LPC 消息
┌──────────────▼──────────────────────────┐
│      PipeServer (消息路由层)              │
│  - 接收/分发消息                          │
│  - 线程池管理                             │
│  - 客户端连接管理                         │
└──────────────┬──────────────────────────┘
               │ 函数调用
┌──────────────▼──────────────────────────┐
│      服务器组件层                         │
│  - ProcessServer                         │
│  - GuiServer                             │
│  - SbieIniServer                         │
│  - 其他 13+ 服务器                        │
└──────────────┬──────────────────────────┘
               │ 系统调用/驱动通信
┌──────────────▼──────────────────────────┐
│    Windows 系统 / SbieDrv.sys            │
└─────────────────────────────────────────┘
```

### 2. 通信模型

#### LPC (Local Procedure Call)
- **端口类型**: 服务器端口 + 客户端连接端口
- **消息大小**: 最大 MAX_PORTMSG_LENGTH (约 256 字节)
- **大消息处理**: 自动分片传输
- **线程模型**: 多线程工作池 (CPU 核心数 × 2)

#### 消息流程
```
客户端进程                    SbieSvc 服务
    │                              │
    │  1. NtConnectPort           │
    ├─────────────────────────────▶│
    │                              │ 2. 创建连接上下文
    │  3. 连接确认                 │
    │◀─────────────────────────────┤
    │                              │
    │  4. 发送请求消息              │
    ├─────────────────────────────▶│
    │                              │ 5. 路由到处理函数
    │                              │ 6. 执行操作
    │  7. 返回响应                 │
    │◀─────────────────────────────┤
    │                              │
```

### 3. 服务器注册机制

每个服务器组件在初始化时向 PipeServer 注册：

```cpp
// 在构造函数中注册
ProcessServer::ProcessServer(PipeServer *pipeServer)
{
    pipeServer->Register(MSGID_PROCESS, this, Handler);
}

// PipeServer 维护注册表
std::unordered_map<ULONG, SPipeTarget> m_Targets;
```

### 4. 消息 ID 分配

消息 ID 采用分段设计：
- **高 24 位**: 服务器 ID (如 0x1200 表示 PROCESS)
- **低 8 位**: 具体操作 (如 0x01 表示 CHECK_INIT)
- **特殊值 0xFF**: 通知消息

示例：
- `0x1201` = PROCESS_CHECK_INIT_COMPLETE
- `0x1203` = PROCESS_KILL_ONE
- `0x1205` = PROCESS_RUN_SANDBOXED

## 关键设计模式

### 1. 单例模式
多个服务器使用单例模式确保全局唯一：
```cpp
static PipeServer *m_instance;
static PipeServer *GetPipeServer();
```

### 2. 工厂模式
消息处理函数通过函数指针表动态分发：
```cpp
typedef MSG_HEADER *(*Handler)(void *context, MSG_HEADER *msg);
```

### 3. 代理模式
- **ProxyHandle**: 管理跨进程句柄
- **GUI 代理进程**: 解决完整性级别限制
- **命名管道代理**: 访问系统管道

### 4. 观察者模式
- 进程终止通知
- 配置更新通知
- 队列事件通知

## 线程安全

### 同步机制
1. **临界区 (Critical Section)**
   - 保护共享数据结构
   - 自旋计数优化

2. **互锁操作 (Interlocked)**
   - 原子计数器
   - 指针交换

3. **事件对象 (Event)**
   - 异步操作通知
   - 线程同步

### 线程本地存储 (TLS)
存储调用者上下文信息：
```cpp
typedef struct tagCLIENT_TLS_DATA {
    HANDLE PortHandle;
    PORT_MESSAGE *PortMessage;
} CLIENT_TLS_DATA;
```

## 错误处理

### 状态码
- **NTSTATUS**: 内核级错误码
- **Win32 错误码**: 用户态错误
- **自定义错误级别**: 用于日志记录

### 日志系统
- **事件日志**: Windows 事件查看器
- **调试输出**: OutputDebugString
- **驱动日志**: 通过 SbieApi_Log

## 性能优化

### 1. 内存管理
- **内存池**: 减少分配开销
- **预分配缓冲区**: 避免频繁分配
- **对象重用**: 连接和请求对象

### 2. 缓存策略
- **SID 缓存**: 减少 LookupAccountSid 调用
- **配置缓存**: 内存中的 INI 树
- **路径列表缓存**: OpenWinClass 规则

### 3. 并发优化
- **多线程工作池**: 充分利用多核
- **无锁数据结构**: 某些场景使用
- **异步 I/O**: 命名管道和文件操作

## 安全考虑

### 1. 权限检查
- 验证调用者身份
- 会话 ID 匹配
- 沙箱名称验证

### 2. 输入验证
- 消息长度检查
- 路径验证
- 参数范围检查

### 3. 权限隔离
- 令牌模拟
- 受限令牌创建
- Job 对象限制

## 兼容性

### Windows 版本支持
- **Windows XP**: 基础支持
- **Windows Vista/7**: UIPI 处理
- **Windows 8+**: ALPC 支持
- **Windows 10/11**: 现代应用支持

### 架构支持
- **x86**: 32 位原生
- **x64**: 64 位原生
- **WoW64**: 32 位进程在 64 位系统
- **ARM64**: 实验性支持

## 依赖关系

### 系统库
- ntdll.dll - NT 系统调用
- kernel32.dll - Win32 API
- advapi32.dll - 安全和服务
- user32.dll - GUI 操作
- shell32.dll - Shell 功能

### 内部依赖
- SbieDrv.sys - 内核驱动
- SbieDll.dll - 客户端库
- common/ - 共享代码

## 启动流程

```
1. WinMain()
   ├─ 检查命令行参数
   ├─ 判断是否为代理进程
   └─ 启动服务控制分发器

2. ServiceMain()
   ├─ 注册服务控制处理程序
   ├─ InitializeEventLog()
   ├─ DriverAssist::Initialize()
   └─ InitializePipe()
       ├─ PipeServer::GetPipeServer()
       ├─ 创建所有服务器实例
       └─ PipeServer::Start()
           ├─ 创建 LPC 端口
           └─ 启动工作线程

3. 工作线程循环
   ├─ NtReplyWaitReceivePort()
   ├─ 处理连接请求
   ├─ 路由消息到服务器
   └─ 发送响应
```

## 关闭流程

```
1. ServiceHandlerEx(SERVICE_CONTROL_STOP)
   ├─ 设置服务状态为 STOPPING
   ├─ 删除 PipeServer
   │   ├─ 关闭 LPC 端口
   │   ├─ 唤醒所有工作线程
   │   └─ 等待线程退出
   ├─ ComServer::DeleteAllSlaves()
   ├─ DriverAssist::Shutdown()
   └─ MountManager::Shutdown()

2. 清理资源
   ├─ 关闭所有句柄
   ├─ 释放内存
   └─ 删除临界区
```

## 下一步

- 阅读 [01-Main-PipeServer.md](01-Main-PipeServer.md) 了解主程序和通信机制
- 查看 [07-MessageProtocol.md](07-MessageProtocol.md) 了解消息协议
- 参考 [09-TechnicalDetails.md](09-TechnicalDetails.md) 获取实现细节
