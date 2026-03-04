# ProcessServer - 进程管理服务器

## 1. 概述

ProcessServer 是 Sandboxie 服务中负责进程管理的核心组件，处理进程的启动、终止、挂起、恢复以及进程信息查询等操作。

**文件：**
- `ProcessServer.cpp` / `ProcessServer.h`
- `ProcessWire.h` - 消息协议定义

**消息 ID 范围：** `MSGID_PROCESS` (0x0100)

## 2. 核心功能

### 2.1 构造函数
```cpp
ProcessServer::ProcessServer(PipeServer *pipeServer)
{
    pipeServer->Register(MSGID_PROCESS, this, Handler);
}
```
- 注册到 PipeServer
- 处理所有 `MSGID_PROCESS` 范围的消息

### 2.2 消息路由 - Handler

**支持的消息类型：**

| 消息 ID | 功能 | 说明 |
|---------|------|------|
| `MSGID_PROCESS_CHECK_INIT_COMPLETE` | 检查初始化完成 | 验证驱动是否就绪 |
| `MSGID_PROCESS_KILL_ONE` | 终止单个进程 | 终止指定 PID 的进程 |
| `MSGID_PROCESS_KILL_ALL` | 终止所有进程 | 终止沙箱中的所有进程 |
| `MSGID_PROCESS_SET_DEVICE_MAP` | 设置设备映射 | 配置进程的设备命名空间 |
| `MSGID_PROCESS_OPEN_DEVICE_MAP` | 打开设备映射 | 获取设备映射句柄 |
| `MSGID_PROCESS_RUN_SANDBOXED` | 运行沙箱进程 | 在沙箱中启动新进程 |
| `MSGID_PROCESS_RUN_UPDATER` | 运行更新程序 | 启动 Sandboxie 更新程序 |
| `MSGID_PROCESS_GET_INFO` | 获取进程信息 | 查询进程详细信息 |
| `MSGID_PROCESS_SUSPEND_RESUME_ONE` | 挂起/恢复单个进程 | 暂停或恢复进程执行 |
| `MSGID_PROCESS_SUSPEND_RESUME_ALL` | 挂起/恢复所有进程 | 批量操作沙箱进程 |

## 3. 详细功能分析

### 3.1 CheckInitCompleteHandler - 初始化检查

**功能：**
- 检查 Sandboxie 驱动是否已加载并就绪
- 用于启动前的健康检查
- 返回 `STATUS_SUCCESS` 或 `STATUS_DEVICE_NOT_READY`

### 3.2 KillProcess - 进程终止核心函数

**终止流程：**

1. **打开进程句柄**
   - 请求 `PROCESS_TERMINATE` 和 `PROCESS_QUERY_LIMITED_INFORMATION` 权限

2. **验证进程是否仍在沙箱中**
   - PID 可能被重用
   - 必须在持有句柄时验证
   - 防止误杀非沙箱进程

3. **检查关键进程保护**
   - 检查进程是否标记为关键进程
   - 关键进程终止会导致系统崩溃
   - 跳过关键进程的终止

4. **驱动级别终止（备用方案）**
   - 如果用户模式终止失败
   - 通过驱动强制终止

### 3.3 KillOneHandler - 终止单个进程

**权限检查：**

1. **会话 ID 匹配**
   - 只能终止同一会话的进程
   - 管理员可以跨会话终止

2. **沙箱名称匹配**
   - 沙箱内进程只能终止同一沙箱的进程
   - 防止跨沙箱攻击

### 3.4 KillAllHandler - 终止所有进程

**终止策略：**

1. **作业对象终止（推荐）**
   - 配置项：`TerminateJobObject=y`
   - 前提：进程已加入作业对象
   - 不适用于 `NoAddProcessToJob=y` 的沙箱

2. **逐个终止（备用）**
   - 用于不支持作业对象的场景
   - 处理 RPCSS 等特殊进程

### 3.5 RunSandboxedHandler - 启动沙箱进程

这是最复杂的功能之一，负责在沙箱中启动新进程。

**启动流程：**

1. **权限验证**
   - 检查调用者是否有权限在指定沙箱中启动进程
   - 验证沙箱配置

2. **令牌处理**
   - 使用提供的令牌或调用者的令牌
   - 支持以不同用户身份运行

3. **进程创建**
   - 以挂起状态创建
   - 允许注入和配置

4. **沙箱注入**
   - 通知驱动进程需要沙箱化
   - 注入 SbieDll.dll
   - 设置沙箱环境

5. **GUI 初始化**
   - 将进程加入作业对象
   - 设置 UI 限制
   - 配置 UIPI

6. **恢复执行**

### 3.6 其他功能

- **SetDeviceMap** - 设置设备映射
- **OpenDeviceMap** - 打开设备映射
- **RunUpdaterHandler** - 运行更新程序
- **ProcInfoHandler** - 获取进程信息
- **SuspendOneHandler** - 挂起/恢复单个进程
- **SuspendAllHandler** - 挂起/恢复所有进程

## 4. 安全考虑

### 4.1 PID 重用防护
- 在持有句柄时验证进程
- 检查进程创建时间
- 防止误操作

### 4.2 权限隔离
- 严格的会话检查
- 沙箱边界验证
- 管理员权限要求

### 4.3 关键进程保护
- 检查 `ProcessBreakOnTermination`
- 跳过系统关键进程
- 防止系统崩溃

## 5. 与其他组件的交互

- **DriverAssist** - 进程注入、驱动级别终止
- **GuiServer** - GUI 初始化、作业对象管理
- **SbieIniServer** - 配置查询、权限检查
- **FileServer** - 路径解析、文件访问验证
