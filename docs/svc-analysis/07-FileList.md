# 完整文件列表与功能说明

## 1. 核心文件

### 1.1 主程序文件

**main.cpp**
- 服务主入口点 `WinMain`
- 服务控制处理 `ServiceMain`、`ServiceHandlerEx`
- 代理模式检测（ComProxy、UacProxy、NetProxy、GuiProxy、UserProxy）
- 事件日志初始化
- 管道服务器初始化
- 辅助函数：`RestrictToken`、`CheckDropRights`、`IsProcessWoW64`、`IsHostPath`

**stdafx.cpp / stdafx.h**
- 预编译头文件
- 包含常用的 Windows 头文件
- 定义全局宏和常量

**includes.cpp**
- 强制包含所有头文件
- 确保编译依赖正确

---

## 2. 通信核心

### 2.1 PipeServer - LPC 通信服务器

**PipeServer.cpp / PipeServer.h**
- 单例模式的 LPC 服务器
- 端口创建和管理
- 客户端连接管理
- 消息路由和分发
- 大消息分片处理
- 子服务器注册机制
- 内存池管理
- 调用者信息获取（PID、TID、SessionID）
- 安全检查（IsCallerAdmin、IsCallerSigned）

**关键函数：**
- `GetPipeServer()` - 获取单例
- `Start()` - 启动服务器
- `Register()` - 注册子服务器
- `Thread()` - 工作线程主循环
- `PortConnect()` - 处理连接
- `PortDisconnect()` - 处理断开
- `PortRequest()` - 处理请求
- `PortReply()` - 发送响应
- `CallTarget()` - 调用子服务器
- `AllocMsg()` / `FreeMsg()` - 消息内存管理

---

## 3. 子服务器

### 3.1 ProcessServer - 进程管理

**ProcessServer.cpp / ProcessServer.h**
- 进程启动、终止、挂起、恢复
- 进程信息查询
- 设备映射管理
- 作业对象管理

**ProcessWire.h**
- 消息协议定义
- 请求/响应结构体

**关键函数：**
- `KillProcess()` - 终止进程
- `KillOneHandler()` - 终止单个进程
- `KillAllHandler()` - 终止所有进程
- `RunSandboxedHandler()` - 启动沙箱进程
- `SuspendOneHandler()` - 挂起/恢复进程
- `ProcInfoHandler()` - 获取进程信息

### 3.2 DriverAssist - 驱动助手

**DriverAssist.cpp / DriverAssist.h**
- 用户模式与内核驱动的桥梁
- 处理驱动发送的请求
- 内部 LPC 端口管理

**DriverAssistInject.cpp**
- 进程注入实现
- DLL 加载
- WoW64 处理

**DriverAssistStart.cpp**
- 进程启动处理
- 启动后初始化
- 环境配置

**DriverAssistSid.cpp**
- SID 查询和缓存
- 用户名解析
- 域名查询

**DriverAssistLog.cpp**
- 日志消息处理
- 事件日志记录
- 格式化输出

**关键函数：**
- `Initialize()` - 初始化驱动助手
- `InjectLow()` - 进程注入
- `LookupSid()` - SID 查询
- `LogMessage()` - 日志处理
- `ProcessStarted()` - 进程启动通知

### 3.3 GuiServer - GUI 代理

**GuiServer.cpp / GuiServer.h**
- GUI 操作代理
- UIPI 处理
- 作业对象管理
- 窗口钩子管理

**GuiWire.h**
- GUI 消息协议

**关键函数：**
- `InitProcess()` - 进程 GUI 初始化
- `StartSlave()` - 启动 GUI 代理进程
- `SendMessageToSlave()` - 发送消息到代理
- `RunSlave()` - 代理进程主函数
- DPI 感知处理
- DDE 支持

### 3.4 SbieIniServer - 配置管理

**sbieiniserver.cpp / sbieiniserver.h**
- INI 配置文件管理
- 配置读取和写入
- 配置重载
- 权限验证

**sbieiniwire.h**
- 配置消息协议

**关键函数：**
- 配置项查询
- 配置项设置
- 配置重载
- 用户信息获取

### 3.5 FileServer - 文件操作

**fileserver.cpp / fileserver.h**
- 文件操作代理
- 路径解析
- 文件重定向
- 访问控制

**filewire.h**
- 文件操作消息协议

**关键功能：**
- 文件打开
- 文件查询
- 文件迁移
- 路径映射

### 3.6 ComServer - COM 组件

**comserver.cpp / comserver.h**
- COM 组件代理
- CLSID 管理
- 接口封送

**comserver2.cpp**
- COM 代理进程实现
- COM 调用转发

**comwire.h**
- COM 消息协议

**关键功能：**
- COM 对象创建
- 接口查询
- 方法调用代理
- 代理进程管理

### 3.7 ServiceServer - Windows 服务

**serviceserver.cpp / serviceserver.h**
- Windows 服务代理
- 服务枚举
- 服务控制

**serviceserver2.cpp**
- UAC 代理进程实现
- 提权操作处理

**servicewire.h**
- 服务消息协议

**关键功能：**
- 服务查询
- 服务启动/停止
- UAC 提权代理

### 3.8 NamedPipeServer - 命名管道

**namedpipeserver.cpp / namedpipeserver.h**
- 命名管道管理
- 管道创建和连接
- 数据传输

**namedpipewire.h**
- 管道消息协议

### 3.9 TerminalServer - 终端服务

**terminalserver.cpp / terminalserver.h**
- 终端服务支持
- 会话管理
- 远程桌面支持

**terminalwire.h**
- 终端服务消息协议

### 3.10 IpHlpServer - IP 帮助器

**iphlpserver.cpp / iphlpserver.h**
- 网络配置查询
- 网络接口信息
- 路由表查询

**iphlpwire.h**
- IP 帮助器消息协议

### 3.11 NetApiServer - 网络 API

**netapiserver.cpp / netapiserver.h**
- 网络 API 代理
- 网络共享访问
- 域操作

**netapiwire.h**
- 网络 API 消息协议

### 3.12 QueueServer - 消息队列

**queueserver.cpp / queueserver.h**
- 进程间消息队列
- 队列管理
- 异步通信

**queuewire.h**
- 队列消息协议

### 3.13 PStoreServer - 受保护存储

**pstoreserver.cpp / pstoreserver.h**
- 受保护存储访问
- 凭据管理
- 加密存储

**pstorewire.h**
- 受保护存储消息协议

### 3.14 MountManager - 挂载管理

**MountManager.cpp / MountManager.h**
- 文件系统挂载
- 驱动器号管理
- 卷管理

**MountManagerWire.h**
- 挂载管理消息协议

**MountManagerHelpers.cpp**
- 挂载辅助函数
- 路径解析
- 卷信息查询

### 3.15 EpMapperServer - RPC 端点映射

**EpMapperServer.cpp / EpMapperServer.h**
- RPC 端点映射
- 端点注册和查询
- RPC 代理

**EpMapperWire.h**
- RPC 端点映射消息协议

### 3.16 UserServer - 用户服务

**UserServer.cpp / UserServer.h**
- 用户相关操作
- 用户信息查询
- 用户代理进程

**UserWire.h**
- 用户服务消息协议

---

## 4. 辅助文件

### 4.1 ProxyHandle - 代理句柄

**ProxyHandle.cpp / ProxyHandle.h**
- 句柄代理机制
- 跨进程句柄传递
- 句柄映射管理

### 4.2 HostInjectProcessUtil - 主机注入工具

**HostInjectProcessUtil.cpp**
- 主机进程注入工具
- 注入辅助函数
- 特殊注入场景处理

### 4.3 misc - 杂项工具

**misc.cpp / misc.h**
- 通用辅助函数
- 字符串处理
- 错误处理
- 日志记录

---

## 5. 消息定义

### 5.1 msgids.h
- 所有消息 ID 定义
- 消息 ID 范围分配
- 通知消息定义

**消息 ID 范围：**
```cpp
#define MSGID_PROCESS       0x0100  // ProcessServer
#define MSGID_SBIE_INI      0x0200  // SbieIniServer
#define MSGID_SERVICE       0x0300  // ServiceServer
#define MSGID_PSTORE        0x0400  // PStoreServer
#define MSGID_TERMINAL      0x0500  // TerminalServer
#define MSGID_NAMED_PIPE    0x0600  // NamedPipeServer
#define MSGID_FILE          0x0700  // FileServer
#define MSGID_COM           0x0800  // ComServer
#define MSGID_IPHLP         0x0900  // IpHlpServer
#define MSGID_NETAPI        0x0A00  // NetApiServer
#define MSGID_QUEUE         0x0B00  // QueueServer
#define MSGID_MOUNT         0x0C00  // MountManager
#define MSGID_EPMAPPER      0x0D00  // EpMapperServer
#define MSGID_GUI           0x0E00  // GuiServer
#define MSGID_USER          0x0F00  // UserServer
```

### 5.2 InteractiveWire.h
- 交互式消息协议
- 用户交互相关消息

---

## 6. 资源文件

### 6.1 resource2.h
- 资源 ID 定义
- 字符串资源
- 对话框资源

### 6.2 htiface7.h
- 主机注入接口定义
- 版本 7 接口

---

## 7. 文件统计

**总文件数：** 29 个 .cpp 文件 + 39 个 .h 文件

**代码行数估算：**
- 核心文件（main, PipeServer）：约 3,000 行
- 子服务器：约 15,000 行
- 辅助文件：约 2,000 行
- 头文件：约 5,000 行
- **总计：约 25,000 行代码**

---

## 8. 依赖关系

### 8.1 核心依赖
```
main.cpp
  └─ PipeServer
       ├─ ProcessServer
       ├─ DriverAssist
       ├─ GuiServer
       ├─ SbieIniServer
       ├─ FileServer
       ├─ ComServer
       ├─ ServiceServer
       ├─ NamedPipeServer
       ├─ TerminalServer
       ├─ IpHlpServer
       ├─ NetApiServer
       ├─ QueueServer
       ├─ PStoreServer
       ├─ MountManager
       ├─ EpMapperServer
       └─ UserServer
```

### 8.2 子服务器间依赖
```
ProcessServer
  ├─ DriverAssist (进程注入)
  ├─ GuiServer (GUI 初始化)
  └─ SbieIniServer (配置查询)

GuiServer
  ├─ QueueServer (消息队列)
  └─ ProcessServer (进程管理)

ComServer
  ├─ ProcessServer (代理进程启动)
  └─ SbieIniServer (配置查询)

ServiceServer
  ├─ ProcessServer (UAC 代理启动)
  └─ SbieIniServer (配置查询)
```

---

## 9. 编译配置

### 9.1 预处理器定义
- `_WIN32` / `_WIN64` - 平台标识
- `_M_ARM64` - ARM64 架构
- `USE_NEW_LPC_IMPL` - 新 LPC 实现（可选）
- `DEBUG` - 调试模式

### 9.2 链接库
- `ntdll.lib` - NT 内核 API
- `kernel32.lib` - Windows 内核
- `user32.lib` - 用户界面
- `advapi32.lib` - 高级 API（服务、注册表）
- `psapi.lib` - 进程状态 API
- `wtsapi32.lib` - 终端服务 API
- `userenv.lib` - 用户环境
- `netapi32.lib` - 网络 API
- `iphlpapi.lib` - IP 帮助器 API

---

## 10. 关键数据流

### 10.1 进程启动流程
```
Client (SbieCtrl/Start.exe)
  ↓ MSGID_PROCESS_RUN_SANDBOXED
ProcessServer
  ↓ CreateProcessAsUser
Windows
  ↓ 进程创建通知
DriverAssist
  ↓ SVC_INJECT_PROCESS
DriverAssist::InjectLow
  ↓ CreateRemoteThread
Target Process (加载 SbieDll.dll)
  ↓ DllMain
SbieDll 初始化
  ↓ 连接到驱动
Sandboxed Process Running
```

### 10.2 配置查询流程
```
Sandboxed Process
  ↓ SbieApi_QueryConf
SbieDll
  ↓ LPC 消息
PipeServer
  ↓ 路由到 SbieIniServer
SbieIniServer
  ↓ 读取 Sandboxie.ini
  ↓ 查找配置项
  ↓ 返回结果
PipeServer
  ↓ LPC 响应
SbieDll
  ↓ 返回给应用
Sandboxed Process
```

### 10.3 文件访问流程
```
Sandboxed Process
  ↓ CreateFile (被钩子拦截)
SbieDll Hook
  ↓ 检查路径
  ↓ 应用重定向规则
  ↓ 如需代理
  ↓ LPC 消息
PipeServer
  ↓ 路由到 FileServer
FileServer
  ↓ 路径映射
  ↓ 权限检查
  ↓ 执行操作
  ↓ 返回结果
PipeServer
  ↓ LPC 响应
SbieDll
  ↓ 返回句柄
Sandboxed Process
```

---

## 11. 性能特征

### 11.1 内存使用
- 服务进程：约 10-20 MB
- 每个代理进程：约 5-10 MB
- 内存池：预分配 4 MB
- 消息缓冲区：动态分配

### 11.2 CPU 使用
- 空闲时：< 1%
- 进程启动时：5-10%
- 高负载时：10-20%

### 11.3 响应时间
- LPC 消息往返：< 1 ms
- 进程启动：100-500 ms
- 配置查询：< 1 ms
- 文件操作：1-10 ms

---

## 12. 安全特性

### 12.1 权限隔离
- 服务运行在 SYSTEM 账户
- 代理进程运行在用户账户
- 沙箱进程运行在低完整性级别

### 12.2 通信安全
- LPC 端口限制性 DACL
- 调用者身份验证
- 消息签名验证

### 12.3 代码完整性
- 数字签名验证
- 缓冲区溢出保护
- 异常处理

---

## 13. 可维护性

### 13.1 代码组织
- 模块化设计
- 清晰的接口定义
- 统一的错误处理

### 13.2 调试支持
- 详细的日志记录
- 调试输出
- 事件日志集成

### 13.3 扩展性
- 插件式子服务器
- 消息协议可扩展
- 配置驱动
