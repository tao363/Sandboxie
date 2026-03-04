# Main 程序与 PipeServer 核心分析

## 1. main.cpp - 服务主程序

### 1.1 程序入口与服务架构

#### WinMain 函数
```cpp
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
```

**功能职责：**
- Windows 服务的主入口点
- 初始化全局模块句柄（Ntdll、Kernel32）
- 获取系统信息（CPU架构、页面大小等）
- 初始化 SID 缓存用于权限管理
- 处理多种代理模式的命令行参数

**代理模式检测：**
程序支持多种代理模式，通过命令行参数识别：

1. **ComProxy** (`SANDBOXIE_ComProxy`)
   - COM 组件代理模式
   - 用于跨沙箱边界的 COM 调用
   - 调用 `ComServer::RunSlave()`

2. **UacProxy** (`SANDBOXIE_UacProxy`)
   - UAC 提权代理模式
   - 处理需要管理员权限的操作
   - 调用 `ServiceServer::RunUacSlave()`

3. **NetProxy** (`SANDBOXIE_NetProxy`)
   - 网络 API 代理模式
   - 处理网络相关的系统调用
   - 调用 `NetApiServer::RunSlave()`

4. **GuiProxy** (`SANDBOXIE_GuiProxy`)
   - GUI 代理模式
   - 处理 UIPI（用户界面特权隔离）
   - 调用 `GuiServer::RunSlave()`

5. **UserProxy** (`SANDBOXIE_UserProxy`)
   - 用户会话代理模式
   - 处理用户相关的操作
   - 调用 `UserServer::RunWorker()`

**服务启动：**
```cpp
StartServiceCtrlDispatcher(myServiceTable)
```
- 将控制权交给 Windows 服务控制管理器
- 注册 `ServiceMain` 作为服务入口点

### 1.2 ServiceMain - 服务主函数

**服务状态管理：**
```cpp
ServiceStatus.dwServiceType = SERVICE_WIN32;
ServiceStatus.dwCurrentState = SERVICE_START_PENDING;
ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN;
```

**初始化流程：**
1. 注册服务控制处理器 `RegisterServiceCtrlHandlerEx`
2. 设置服务状态为 `SERVICE_START_PENDING`
3. 初始化事件日志 `InitializeEventLog()`
4. 初始化驱动助手 `DriverAssist::Initialize()`
5. 初始化管道服务器 `InitializePipe()`
6. 禁用 CHPE（ARM64 上的 x86 模拟）
7. 设置服务状态为 `SERVICE_RUNNING`

### 1.3 InitializePipe - 管道服务器初始化

**子服务器注册顺序：**
```cpp
new ProcessServer(pipeServer);      // 进程管理
new SbieIniServer(pipeServer);      // 配置管理
new ServiceServer(pipeServer);      // Windows 服务代理
new PStoreServer(pipeServer);       // 受保护存储
new TerminalServer(pipeServer);     // 终端服务
new NamedPipeServer(pipeServer);    // 命名管道
new FileServer(pipeServer);         // 文件操作
new ComServer(pipeServer);          // COM 组件
new IpHlpServer(pipeServer);        // IP 帮助器
new NetApiServer(pipeServer);       // 网络 API
new QueueServer(pipeServer);        // 消息队列
new MountManager(pipeServer);       // 挂载管理
new EpMapperServer(pipeServer);     // RPC 端点映射
```

每个子服务器都注册自己的消息处理器到 PipeServer。

### 1.4 ServiceHandlerEx - 服务控制处理

**处理的控制命令：**
- `SERVICE_CONTROL_STOP` - 停止服务
- `SERVICE_CONTROL_SHUTDOWN` - 系统关闭
- `SERVICE_CONTROL_INTERROGATE` - 查询状态

**关闭流程：**
1. 删除 PipeServer 实例（触发所有子服务器清理）
2. 恢复 CHPE 设置（ARM64）
3. 删除所有 COM 代理进程
4. 关闭驱动助手
5. 关闭挂载管理器
6. 设置服务状态为 `SERVICE_STOPPED`

### 1.5 辅助函数

#### LogEvent - 事件日志记录
```cpp
void LogEvent(ULONG msgid, ULONG level, ULONG detail)
```
- 记录错误和警告到 Windows 事件日志
- 支持格式化错误代码和状态信息

#### LogMessage_Event - 消息事件记录
```cpp
void LogMessage_Event(ULONG code, wchar_t* data, ULONG pid)
```
- 记录来自沙箱进程的消息
- 格式化消息文本并写入事件日志

#### RestrictToken - 令牌限制
```cpp
bool RestrictToken(void)
```
- 创建受限的安全令牌
- 禁用管理员和 Power Users 组
- 使用 `NtFilterToken` 创建过滤令牌
- 用于降低权限的场景

#### CheckDropRights - 检查权限降级
```cpp
bool CheckDropRights(const WCHAR *BoxName, const WCHAR *ExeName)
```
- 检查沙箱配置是否要求降低管理员权限
- 支持 `UseSecurityMode` 和 `DropAdminRights` 配置

#### IsProcessWoW64 - WoW64 检测
```cpp
bool IsProcessWoW64(HANDLE pid)
```
- 检测进程是否运行在 WoW64 模式（32位进程在64位系统上）
- 用于确定注入和钩子的正确架构

#### IsHostPath - 主机路径验证
```cpp
bool IsHostPath(HANDLE idProcess, WCHAR* dos_path)
```
- 验证路径是否在沙箱外部（主机文件系统）
- 使用 `GetFinalPathNameByHandleW` 获取真实路径
- 比较路径与沙箱根目录
- 排除网络共享路径

---

## 2. PipeServer.cpp/h - LPC 通信核心

### 2.1 架构概述

PipeServer 是整个服务的通信核心，实现了基于 Windows LPC（本地过程调用）的客户端-服务器架构。

**设计模式：**
- 单例模式（Singleton）
- 观察者模式（子服务器注册）
- 线程池模式（多个工作线程）

### 2.2 核心数据结构

#### 客户端管理（传统实现）
```cpp
typedef struct tagCLIENT_PROCESS {
    HANDLE idProcess;              // 进程 ID
    LARGE_INTEGER CreateTime;      // 进程创建时间
    HASH_MAP thread_map;           // 线程映射表
} CLIENT_PROCESS;

typedef struct tagCLIENT_THREAD {
    HANDLE idThread;               // 线程 ID
    BOOLEAN replying;              // 是否正在回复
    volatile BOOLEAN in_use;       // 是否正在使用
    UCHAR sequence;                // 序列号
    HANDLE hPort;                  // 端口句柄
    MSG_HEADER *buf_hdr;           // 消息缓冲区头
    UCHAR *buf_ptr;                // 消息缓冲区指针
} CLIENT_THREAD;
```

#### 新实现（USE_NEW_LPC_IMPL）
```cpp
struct SClient {
    HANDLE idThread;
    BOOLEAN replying;
    volatile BOOLEAN in_use;
    UCHAR sequence;
    HANDLE hPort;
    MSG_HEADER *buf_hdr;
    UCHAR *buf_ptr;
};
typedef std::shared_ptr<SClient> SClientPtr;

std::unordered_map<void*, SClientPtr> m_Clients;  // 使用 PortContext 作为键
```

#### 目标服务器注册
```cpp
struct SPipeTarget {
    ULONG serverId;                // 服务 ID（如 MSGID_PROCESS）
    void *context;                 // 上下文指针
    PipeServer::Handler handler;   // 处理函数
};
```

### 2.3 初始化流程

#### GetPipeServer - 单例获取
```cpp
PipeServer *PipeServer::GetPipeServer()
```
1. 分配 TLS 索引用于线程本地存储
2. 创建 PipeServer 实例
3. 初始化内存池 `Pool_Create()`
4. 初始化客户端映射表

#### Start - 启动服务器
```cpp
bool PipeServer::Start()
```
1. 创建安全描述符（NULL DACL，允许任何进程连接）
2. 调用 `NtCreatePort` 创建 LPC 端口
3. 端口名称：`\RPC Control\SbieSvcPort`
4. 创建多个工作线程（NUMBER_OF_THREADS）
5. 每个线程运行 `Thread()` 函数

### 2.4 线程处理循环

#### Thread - 主工作循环
```cpp
void PipeServer::Thread()
```

**核心循环：**
```cpp
while (1) {
    status = NtReplyWaitReceivePort(hReplyPort, &PortContext, ReplyMsg, msg);
    
    if (msg->u2.s2.Type == LPC_CONNECTION_REQUEST) {
        PortConnect(msg);
    }
    else if (msg->u2.s2.Type == LPC_REQUEST) {
        PortRequest(client->hPort, msg, client);
        PortReply(msg, client);
    }
    else if (msg->u2.s2.Type == LPC_PORT_CLOSED || 
             msg->u2.s2.Type == LPC_CLIENT_DIED) {
        PortDisconnect(PortContext);
    }
}
```

**消息类型处理：**
1. **LPC_CONNECTION_REQUEST** - 新客户端连接
2. **LPC_REQUEST** - 客户端请求
3. **LPC_PORT_CLOSED** - 端口关闭
4. **LPC_CLIENT_DIED** - 客户端进程终止

### 2.5 连接管理

#### PortConnect - 处理连接请求
```cpp
void PipeServer::PortConnect(PORT_MESSAGE *msg)
```

**传统实现流程：**
1. 查找或创建 `CLIENT_PROCESS` 结构
2. 创建 `CLIENT_THREAD` 结构
3. 记录进程创建时间（用于断开连接验证）
4. 调用 `NtAcceptConnectPort` 接受连接
5. 调用 `NtCompleteConnectPort` 完成连接
6. 将客户端信息存储到哈希映射表

**新实现流程：**
1. 创建 `SClient` 智能指针
2. 使用 `PortContext` 作为客户端标识
3. 接受并完成连接
4. 存储到 `m_Clients` 映射表

#### PortDisconnect - 处理断开连接
```cpp
void PipeServer::PortDisconnect(PORT_MESSAGE *msg)
```

**特殊情况处理（Windows Vista+）：**
- 某些断开消息不包含 ClientId
- 仅包含进程创建时间戳
- 需要通过时间戳查找并清理客户端

**清理步骤：**
1. 等待客户端线程完成当前操作
2. 关闭端口句柄
3. 释放消息缓冲区
4. 从映射表中移除
5. 通知所有子服务器进程已结束

### 2.6 请求处理

#### PortRequest - 处理请求消息
```cpp
void PipeServer::PortRequest(HANDLE PortHandle, PORT_MESSAGE *msg, CLIENT_THREAD *client)
```

**大消息处理机制：**
LPC 消息大小限制为 `MAX_PORTMSG_LENGTH`（约 256 字节），大消息需要分片传输。

**分片协议：**
1. 第一个消息包含：
   - 总长度（msg_Data[0]）
   - 消息 ID（msg_Data[1]）
   - 序列号（msg_Data[3]）
2. 后续消息包含数据片段
3. 服务器重组完整消息

**处理流程：**
```cpp
if (!client->buf_hdr) {
    // 第一个片段：分配缓冲区
    client->buf_hdr = AllocMsg(buf_len);
    client->buf_ptr = (UCHAR *)client->buf_hdr;
}
// 复制数据片段
memcpy(client->buf_ptr, msg->Data, msg->u1.s1.DataLength);
client->buf_ptr += msg->u1.s1.DataLength;

if (buf_len >= client->buf_hdr->length) {
    // 接收完整，调用目标处理器
    buf_ptr = CallTarget(client->buf_hdr, PortHandle, msg);
}
```

#### CallTarget - 调用目标服务器
```cpp
MSG_HEADER *PipeServer::CallTarget(MSG_HEADER *msg, HANDLE PortHandle, PORT_MESSAGE *PortMessage)
```

**路由机制：**
1. 从消息 ID 提取服务 ID（高 24 位）
2. 在注册表中查找对应的处理器
3. 设置 TLS 数据（PortHandle、PortMessage）
4. 调用处理器函数
5. 异常保护（__try/__except）
6. 清理并返回响应

**消息 ID 格式：**
```
[31:8] - 服务 ID (serverId)
[7:0]  - 功能 ID (0xFF 表示通知消息)
```

#### PortReply - 发送回复消息
```cpp
void PipeServer::PortReply(PORT_MESSAGE *msg, CLIENT_THREAD *client)
```

**分片发送：**
1. 计算剩余数据长度
2. 每次最多发送 `MSG_DATA_LEN` 字节
3. 第一个片段包含序列号
4. 继续发送直到完成
5. 释放缓冲区并清除 replying 标志

### 2.7 子服务器管理

#### Register - 注册子服务器
```cpp
void PipeServer::Register(ULONG serverId, void *context, Handler handler)
```
- 子服务器在构造函数中调用此方法
- 注册消息 ID 范围和处理函数
- 支持多个子服务器共存

#### NotifyTargets - 通知进程结束
```cpp
void PipeServer::NotifyTargets(HANDLE idProcess)
```
- 当客户端断开连接时调用
- 向所有子服务器发送通知消息（msgid | 0xFF）
- 允许子服务器清理进程相关资源

### 2.8 内存管理

#### AllocMsg - 分配消息缓冲区
```cpp
MSG_HEADER *PipeServer::AllocMsg(ULONG length)
```
- 使用内存池分配
- 添加保护标记（tzuk 签名）
- 初始化消息头

#### FreeMsg - 释放消息缓冲区
```cpp
void PipeServer::FreeMsg(MSG_HEADER *msg)
```
- 验证保护标记
- 检测缓冲区溢出
- 返回内存池

### 2.9 调用者信息获取

#### GetCallerProcessId
```cpp
ULONG PipeServer::GetCallerProcessId()
```
- 从 TLS 获取 PORT_MESSAGE
- 返回 ClientId.UniqueProcess

#### GetCallerThreadId
```cpp
ULONG PipeServer::GetCallerThreadId()
```
- 返回 ClientId.UniqueThread

#### GetCallerSessionId
```cpp
ULONG PipeServer::GetCallerSessionId()
```
- 调用 `ProcessIdToSessionId`
- 返回会话 ID

#### ImpersonateCaller - 模拟调用者
```cpp
ULONG PipeServer::ImpersonateCaller(MSG_HEADER **pmsg)
```
- 调用 `NtImpersonateClientOfPort`
- 允许服务器以客户端身份执行操作
- 用于权限检查和文件访问

### 2.10 安全检查

#### IsCallerAdmin - 检查管理员权限
```cpp
bool PipeServer::IsCallerAdmin()
```
1. 获取调用者进程 ID
2. 打开进程令牌
3. 调用 `SbieIniServer::TokenIsAdmin`
4. 返回是否具有管理员权限

#### IsCallerSigned - 检查签名
```cpp
bool PipeServer::IsCallerSigned()
```
1. 获取调用者进程路径
2. 调用 `VerifyFileSignature`
3. 验证数字签名
4. 用于信任验证

### 2.11 内部调用

#### Call - 内部消息调用
```cpp
MSG_HEADER *PipeServer::Call(MSG_HEADER *msg)
```
- 允许服务内部组件直接调用其他子服务器
- 不通过 LPC 端口
- 设置虚拟的 PORT_MESSAGE
- 直接调用 CallTarget

---

## 3. 关键技术点

### 3.1 LPC 通信机制
- 使用 Windows 内核 LPC（本地过程调用）
- 比命名管道更高效
- 支持异步消息传递
- 内核级别的安全性

### 3.2 线程池设计
- 多个工作线程并发处理请求
- 使用 `NtReplyWaitReceivePort` 实现高效等待
- 线程安全的客户端管理

### 3.3 大消息分片
- 突破 LPC 消息大小限制
- 透明的分片和重组
- 序列号防止消息混淆

### 3.4 进程生命周期管理
- 跟踪客户端进程和线程
- 进程创建时间验证
- 自动清理断开的连接

### 3.5 安全性设计
- NULL DACL 允许沙箱进程连接
- 调用者身份验证
- 模拟机制支持权限检查
- 数字签名验证

---

## 4. 性能优化

### 4.1 内存池
- 减少频繁的内存分配
- 提高分配速度
- 减少内存碎片

### 4.2 哈希映射
- 快速查找客户端信息
- O(1) 时间复杂度
- 预分配桶提高性能

### 4.3 临界区优化
- 使用自旋计数（1000）
- 减少内核模式切换
- 细粒度锁定

### 4.4 TLS 使用
- 避免全局锁
- 线程本地存储调用者信息
- 提高并发性能

---

## 5. 错误处理

### 5.1 异常保护
- 所有处理器调用都在 __try/__except 块中
- 捕获访问违规和其他异常
- 返回错误状态而不是崩溃

### 5.2 缓冲区保护
- 消息缓冲区添加保护标记
- 检测缓冲区溢出
- 调试断点辅助诊断

### 5.3 状态验证
- 检查消息长度
- 验证客户端状态
- 防止无效操作

---

## 6. 调试支持

### 6.1 事件日志
- 记录初始化错误
- 记录关键操作
- 便于故障排查

### 6.2 调试输出
- 条件编译的调试代码
- 进程连接/断开跟踪
- 性能监控点

### 6.3 断点支持
- 缓冲区溢出检测断点
- 异常情况断点
- 便于开发调试
