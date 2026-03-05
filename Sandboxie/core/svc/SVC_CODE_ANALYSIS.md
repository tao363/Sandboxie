# Sandboxie Core Service (SVC) 代码分析文档

## 目录概述

`Sandboxie\core\svc` 目录包含了 Sandboxie 服务 (SbieSvc.exe) 的核心实现代码。这是一个运行在 Windows 系统服务中的用户态程序，负责管理沙箱进程、处理进程间通信、协调驱动程序交互等关键功能。

---

## 核心架构

### 1. 主程序入口 (main.cpp)

**主要功能：**
- Windows 服务的入口点和生命周期管理
- 初始化各个子服务器组件
- 处理服务启动、停止和关闭事件

**关键函数：**

#### `WinMain()`
- 服务的主入口点
- 检测命令行参数，判断是否为代理进程模式：
  - `_ComProxy`: COM 代理进程
  - `_UacProxy`: UAC 代理进程
  - `_NetProxy`: 网络代理进程
  - `_GuiProxy`: GUI 代理进程
  - `_UserProxy`: 用户代理进程
- 启动服务控制分发器

#### `ServiceMain()`
- 注册服务控制处理程序
- 初始化事件日志
- 初始化驱动程序辅助功能
- 创建并启动管道服务器
- 初始化所有子服务器组件

#### `InitializePipe()`
创建并注册所有子服务器：
- **ProcessServer**: 进程管理
- **SbieIniServer**: 配置文件管理
- **ServiceServer**: Windows 服务管理
- **PStoreServer**: 受保护存储
- **TerminalServer**: 终端服务
- **NamedPipeServer**: 命名管道
- **FileServer**: 文件操作
- **ComServer**: COM 对象管理
- **IpHlpServer**: IP 辅助功能
- **NetApiServer**: 网络 API
- **QueueServer**: 消息队列
- **MountManager**: 挂载管理
- **EpMapperServer**: 端点映射

#### `RestrictToken()`
- 创建受限令牌，移除管理员权限
- 用于降低服务进程的权限级别

#### `IsHostPath()`
- 检查指定路径是否在沙箱外部（主机路径）
- 用于 BreakoutProcess 功能

---

### 2. 管道服务器 (PipeServer.cpp/h)

**核心作用：**
PipeServer 是整个服务的通信枢纽，使用 Windows LPC (Local Procedure Call) 机制实现高效的进程间通信。

**架构设计：**

#### 单例模式
```cpp
static PipeServer *m_instance;
PipeServer *GetPipeServer();
```

#### 消息处理流程
1. **连接建立** (`PortConnect`)
   - 接受来自沙箱进程的连接请求
   - 为每个客户端线程创建连接上下文
   - 支持新旧两种 LPC 实现方式

2. **请求处理** (`PortRequest`)
   - 接收客户端发送的请求消息
   - 根据消息 ID 路由到相应的子服务器
   - 支持大消息的分片传输

3. **回复发送** (`PortReply`)
   - 将处理结果返回给客户端
   - 支持分片回复大数据

4. **连接断开** (`PortDisconnect`)
   - 清理客户端连接资源
   - 通知所有子服务器进程已终止

**关键函数：**

#### `Register(ULONG serverId, void *context, Handler handler)`
- 注册子服务器的消息处理函数
- serverId: 消息 ID 范围（如 0x1200 表示 PROCESS 相关消息）
- handler: 处理函数指针

#### `CallTarget(MSG_HEADER *msg, ...)`
- 根据消息 ID 查找并调用对应的处理函数
- 设置线程本地存储 (TLS) 保存调用者信息
- 异常处理和错误恢复

#### `ImpersonateCaller()`
- 模拟调用者的安全上下文
- 用于权限检查和文件访问

#### `IsCallerAdmin()` / `IsCallerSigned()`
- 检查调用者是否具有管理员权限
- 检查调用者进程是否有有效签名

**消息 ID 定义 (msgids.h)：**
```
0x1100: PSTORE (受保护存储)
0x1200: PROCESS (进程管理)
0x1300: SERVICE (服务管理)
0x1400: TERMINAL (终端服务)
0x1500: NAMED_PIPE (命名管道)
0x1700: FILE (文件操作)
0x1800: SBIE_INI (配置管理)
0x1A00: NETAPI (网络 API)
0x1B00: COM (COM 对象)
0x1C00: IPHLP (IP 辅助)
0x1D00: IMBOX (镜像盒)
0x1E00: QUEUE (消息队列)
0x1F00: EPMAPPER (端点映射)
```

---

### 3. 进程服务器 (ProcessServer.cpp/h)

**主要职责：**
管理沙箱进程的生命周期，包括创建、终止、挂起/恢复等操作。

**核心功能：**

#### `RunSandboxedHandler()`
在沙箱中启动新进程的完整流程：

1. **参数解析**
   - 命令行、工作目录、环境变量
   - 启动标志和窗口显示模式

2. **令牌处理** (`RunSandboxedGetToken`)
   - 获取或创建适当的访问令牌
   - 特殊情况处理：
     - `*RPCSS*`: 以系统身份运行 RPC 服务
     - `*COMSRV*`: COM 服务器进程
     - 现代应用 (UWP): 使用会话令牌

3. **进程创建** (`RunSandboxedStartProcess`)
   - 使用 `CreateProcessAsUser` 创建进程
   - 通知驱动程序新进程信息
   - 支持 BreakoutProcess 功能（允许特定进程逃离沙箱）

4. **句柄处理** (`RunSandboxedDupAndCloseHandles`)
   - 复制进程/线程句柄到调用者
   - 根据需要过滤句柄权限
   - 恢复线程执行

#### `KillOneHandler()` / `KillAllHandler()`
- 终止单个或所有沙箱进程
- 权限检查：会话 ID 和沙箱名称匹配
- 支持使用 Job 对象批量终止

#### `ProcInfoHandler()`
获取进程详细信息：
- 基本信息：父进程 ID、WoW64 状态
- 权限信息：提升状态、系统进程、受限令牌
- 执行信息：挂起状态、线程计数
- 路径信息：映像路径、命令行、工作目录

#### `SuspendOneHandler()` / `SuspendAllHandler()`
- 挂起/恢复单个或所有沙箱进程
- 使用 `NtSuspendProcess` / `NtResumeProcess`

**安全机制：**

#### `RunSandboxedSetDacl()`
- 调整令牌的默认 DACL
- 允许沙箱进程访问以系统身份运行的服务进程

#### `RunSandboxedStripPrivileges()`
- 移除危险的系统特权
- 包括 `SE_TCB_NAME`, `SE_CREATE_TOKEN_NAME`

#### `GetPebString()`
- 从进程 PEB (Process Environment Block) 读取信息
- 支持 32 位和 64 位进程
- 支持 WoW64 进程

---

### 4. 配置服务器 (SbieIniServer.cpp/h)

**核心功能：**
管理 Sandboxie.ini 配置文件的读写操作。

**主要特性：**

#### 配置缓存
- 使用 `CIniFile` 类缓存配置内容
- 减少磁盘 I/O 操作
- 配置更新时自动刷新缓存

#### 用户设置管理
- 支持用户特定的配置节
- 格式：`UserSettings_<CRC32>`
- 自动计算用户 SID 的 CRC32 值

#### 密码保护
- 使用 SHA-1 哈希存储密码
- 支持密码验证和修改
- 管理员权限检查

**关键函数：**

#### `GetSetting()` / `SetSetting()`
- 读取/写入配置项
- 支持通配符删除整个节

#### `AddSetting()` / `DelSetting()`
- 添加/删除配置项（支持多值）
- 插入模式支持

#### `SetTemplate()`
- 应用配置模板
- 支持用户级和全局级模板

#### `RefreshConf()`
配置刷新流程：
1. 创建临时备份文件
2. 写入新配置到磁盘
3. 通知驱动程序重新加载
4. 失败时恢复备份

#### `RunSbieCtrl()`
- 启动 Sandboxie 控制程序
- 支持自动启动代理程序
- 会话隔离

#### `RC4Crypt()`
- 提供简单的机器绑定混淆
- 用于存储需要明文的密码
- 使用随机 64 位密钥

---

### 5. GUI 服务器 (GuiServer.cpp/h)

**核心作用：**
处理沙箱进程的 GUI 相关操作，解决 Windows 完整性级别 (IL) 限制。

**架构设计：**

#### 主从模式
- **主服务器**: 运行在 SbieSvc 中
- **从服务器**: 每个会话一个 GUI 代理进程
- 通过消息队列通信

#### Job 对象管理
- 为每个沙箱创建 Job 对象
- 设置 UI 限制：
  - 禁止退出 Windows
  - 限制句柄访问
  - 限制系统参数修改
  - 限制剪贴板读取
- 授予桌面窗口访问权限

**主要功能：**

#### `InitProcess()` / `InitProcessSlave()`
- 将新进程添加到 Job 对象
- 确保进程受到 UI 限制

#### `GetWindowStationSlave()`
- 创建虚拟窗口站和桌面
- 设置 NULL DACL 允许低完整性访问
- 复制句柄到沙箱进程

#### `CreateConsoleSlave()`
控制台创建流程：
1. 启动控制台辅助进程
2. 辅助进程创建控制台
3. 沙箱进程连接到控制台
4. 监控进程终止并清理

#### 窗口操作代理
- `QueryWindowSlave()`: 查询窗口信息
- `IsWindowSlave()`: 检查窗口状态
- `GetWindowLongSlave()`: 获取窗口属性
- `EnumWindowsSlave()`: 枚举窗口
- `FindWindowSlave()`: 查找窗口
- `SetWindowPosSlave()`: 设置窗口位置

#### 消息发送代理
- `SendPostMessageSlave()`: 发送/投递消息
- `SendCopyDataSlave()`: 发送 WM_COPYDATA
- 完整性级别检查
- OpenWinClass 规则验证

#### 剪贴板操作
- `CloseClipboardSlave()`: 调整剪贴板完整性级别
- `GetClipboardDataSlave()`: 获取剪贴板数据
- 支持位图和增强元文件

#### DDE 支持
- `DdeProxyThreadSlave()`: DDE 代理窗口
- 解决 DDE 的完整性级别问题
- 转换 DDE 消息为 WM_COPYDATA

**访问控制：**

#### `CheckWindowAccessible()`
检查窗口是否可访问：
1. 同一沙箱内的进程
2. 窗口类名匹配 OpenWinClass
3. 进程名匹配 $:OpenWinClass

#### `CompareIntegrityLevels()`
- 比较源进程和目标窗口的完整性级别
- 确保不违反 UIPI (User Interface Privilege Isolation)

#### `AllowSendPostMessage()`
消息过滤规则：
- 允许输入消息 (键盘/鼠标)
- 阻止危险的系统消息 (WM_DESTROY, WM_CLOSE 等)
- 特殊处理 Windows Explorer 窗口

---

### 6. 驱动程序辅助 (DriverAssist.cpp/h)

**核心功能：**
作为用户态服务和内核驱动之间的桥梁。

**通信机制：**

#### LPC 端口
- 创建内部 LPC 端口接收驱动消息
- 多线程处理消息队列
- 异步消息处理

**消息类型：**

#### `SVC_LOOKUP_SID`
- SID 到用户名的转换
- 维护 SID 缓存提高性能
- 支持从注册表查找

#### `SVC_INJECT_PROCESS`
- 低级别进程注入
- 详见 DriverAssistInject.cpp

#### `SVC_CANCEL_PROCESS`
- 终止进程请求
- 验证进程创建时间防止 PID 重用

#### `SVC_MOUNTED_HIVE`
- 注册表挂载通知
- 锁定沙箱根目录
- 检查 8.3 文件名支持

#### `SVC_UNMOUNT_HIVE`
- 注册表卸载请求
- 等待进程终止
- 清理挂载点

#### `SVC_LOG_MESSAGE`
- 日志消息转发
- 详见 DriverAssistLog.cpp

#### `SVC_CONFIG_UPDATED`
- 配置更新通知
- 刷新配置缓存
- 重启主机注入服务

**SID 缓存：**
```cpp
static std::map<std::wstring, std::wstring> m_SidCache;
```
- 减少 `LookupAccountSid` 调用
- 线程安全访问

---

### 7. 其他服务器组件

#### ServiceServer (serviceserver.cpp)
- Windows 服务管理
- 服务启动/停止/查询
- UAC 提升支持

#### FileServer (fileserver.cpp)
- 文件属性设置
- 注册表项加载
- 重解析点操作
- WoW64 注册表访问

#### ComServer (comserver.cpp)
- COM 对象代理
- 跨沙箱 COM 调用
- COM 服务器进程管理

#### NamedPipeServer (namedpipeserver.cpp)
- 命名管道操作
- LPC/ALPC 连接
- 管道通知

#### TerminalServer (terminalserver.cpp)
- 终端服务查询
- 会话信息获取
- 用户令牌获取

#### NetApiServer (netapiserver.cpp)
- 网络 API 代理
- 网络共享访问

#### IpHlpServer (iphlpserver.cpp)
- IP 辅助功能
- ICMP Echo 请求

#### QueueServer (queueserver.cpp)
- 消息队列管理
- 进程间异步通信

#### MountManager (MountManager.cpp)
- 镜像盒挂载管理
- VHD/VHDX 支持
- 挂载点锁定

#### EpMapperServer (EpMapperServer.cpp)
- RPC 端点映射
- 端口名称解析

---

## 关键技术点

### 1. 进程间通信 (IPC)

**LPC (Local Procedure Call):**
- 高性能的内核对象
- 支持同步和异步调用
- 消息大小限制：MAX_PORTMSG_LENGTH

**消息队列:**
- 用于 GUI 代理通信
- 支持请求/响应模式
- 事件通知机制

### 2. 安全模型

**令牌操作:**
- 令牌复制和过滤
- 完整性级别调整
- 特权移除

**访问控制:**
- 会话隔离
- 沙箱隔离
- 管理员权限检查

### 3. 进程注入

**低级别注入 (SbieLow):**
- 在进程初始化早期注入
- 挂钩系统调用
- 详见 DriverAssistInject.cpp

### 4. GUI 完整性级别处理

**问题:**
- Windows Vista+ 的 UIPI 限制
- 低完整性进程无法访问高完整性窗口

**解决方案:**
- GUI 代理进程（正常完整性）
- 消息转发和过滤
- Job 对象 UI 限制

### 5. 配置管理

**INI 文件格式:**
- 节 (Section) 和键值对
- 支持多值配置项
- 模板系统

**缓存机制:**
- 内存中的配置树
- 延迟加载
- 原子更新

---

## 错误处理和日志

### 事件日志
- 使用 Windows 事件日志系统
- 消息 ID 定义在 msgs/msgs.h
- 支持多语言

### 错误代码
- NTSTATUS 状态码
- Win32 错误码
- 自定义错误级别

---

## 性能优化

### 多线程设计
- 工作线程池
- 异步消息处理
- 线程本地存储 (TLS)

### 缓存策略
- SID 缓存
- 配置缓存
- 路径列表缓存

### 资源管理
- 内存池 (Pool)
- 对象重用
- 及时清理

---

## 兼容性考虑

### Windows 版本
- Windows XP 到 Windows 11
- WoW64 支持 (32 位进程在 64 位系统)
- ARM64 支持

### 特殊应用
- Office 应用
- 浏览器
- 游戏
- 开发工具

---

## 总结

`Sandboxie\core\svc` 目录实现了 Sandboxie 的核心服务功能，是整个沙箱系统的控制中心。它通过以下方式实现沙箱隔离：

1. **进程管理**: 控制沙箱进程的生命周期
2. **通信代理**: 处理沙箱内外的进程间通信
3. **权限控制**: 实施安全策略和访问限制
4. **GUI 支持**: 解决 Windows 完整性级别限制
5. **配置管理**: 提供灵活的配置系统
6. **驱动协调**: 与内核驱动紧密配合

整个架构采用模块化设计，每个子服务器负责特定功能，通过 PipeServer 统一协调，实现了高效、安全、可扩展的沙箱服务。
