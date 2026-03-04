# DriverAssist - 驱动助手服务

## 1. 概述

DriverAssist 是用户模式服务与内核驱动之间的桥梁，负责处理驱动发送的请求，包括进程注入、SID 查询、日志记录等。

**文件：**
- `DriverAssist.cpp` / `DriverAssist.h`
- `DriverAssistInject.cpp` - 进程注入
- `DriverAssistStart.cpp` - 进程启动
- `DriverAssistSid.cpp` - SID 管理
- `DriverAssistLog.cpp` - 日志处理

## 2. 核心架构

### 2.1 通信机制

**LPC 端口：**
- 创建内部 LPC 端口供驱动连接
- 端口名称：`\RPC Control\SbieSvcPort-internal-{tickcount}`
- 使用 `NtCreatePort` 创建
- 限制性 DACL（仅系统账户）

**消息类型：**
- `SVC_LOOKUP_SID` - SID 查询
- `SVC_INJECT_PROCESS` - 进程注入
- `SVC_CANCEL_PROCESS` - 取消进程
- `SVC_MOUNTED_HIVE` - 注册表挂载
- `SVC_LOG_MESSAGE` - 日志消息
- `SVC_PROCESS_STARTED` - 进程启动通知

### 2.2 线程池

**工作线程：**
- 创建多个工作线程（NUMBER_OF_THREADS）
- 每个线程运行 `Thread()` 函数
- 使用 `NtReplyWaitReceivePort` 等待消息

**消息处理：**
- 接收到消息后分发到对应处理函数
- 支持异步处理
- 使用线程池提高并发性

## 3. 核心功能

### 3.1 进程注入 (InjectLow)

**功能：**
- 将 SbieDll.dll 注入到新创建的沙箱进程
- 支持 32 位和 64 位进程
- 支持 WoW64 进程

**注入流程：**

1. **打开目标进程**
   - 获取进程句柄
   - 验证进程状态

2. **分配内存**
   - 在目标进程中分配内存
   - 写入 DLL 路径

3. **创建远程线程**
   - 调用 `LoadLibrary` 加载 DLL
   - 等待加载完成

4. **初始化沙箱环境**
   - 设置环境变量
   - 配置钩子
   - 建立与驱动的通信

**特殊处理：**
- WoW64 进程需要注入 32 位 DLL
- 系统进程需要特殊权限
- 处理注入失败的重试逻辑

### 3.2 SID 查询 (LookupSid)

**功能：**
- 将 SID 转换为用户名和域名
- 缓存查询结果
- 提供给驱动使用

**实现：**

1. **检查缓存**
   - 使用 `std::map` 缓存 SID 到名称的映射
   - 避免重复查询

2. **查询系统**
   - 调用 `LookupAccountSid`
   - 获取用户名和域名

3. **更新缓存**
   - 存储查询结果
   - 返回给驱动

**缓存管理：**
- 使用临界区保护
- 定期清理过期条目
- 限制缓存大小

### 3.3 日志处理 (LogMessage)

**功能：**
- 接收驱动发送的日志消息
- 格式化并记录到事件日志
- 支持多种日志级别

**日志类型：**
- 错误日志
- 警告日志
- 信息日志
- 调试日志

**处理流程：**
1. 接收日志消息
2. 格式化消息文本
3. 添加时间戳和进程信息
4. 写入 Windows 事件日志

### 3.4 进程启动通知 (ProcessStarted)

**功能：**
- 驱动通知服务进程已启动
- 执行启动后的初始化
- 配置进程环境

**处理：**
- 设置进程令牌
- 配置资源限制
- 初始化 GUI 环境

### 3.5 注册表挂载 (HiveMounted)

**功能：**
- 处理注册表配置单元挂载
- 同步注册表更改
- 管理注册表隔离

## 4. 辅助功能

### 4.1 SID 缓存管理

**初始化：**
```cpp
void DriverAssist::InitializeSidCache()
{
    InitializeCriticalSection(&m_SidCache_CritSec);
}
```

**销毁：**
```cpp
void DriverAssist::DestroySidCache()
{
    DeleteCriticalSection(&m_SidCache_CritSec);
    m_SidCache.clear();
}
```

### 4.2 驱动就绪检查

**功能：**
- 检查驱动是否已加载
- 验证驱动版本
- 确保通信正常

**实现：**
```cpp
bool DriverAssist::IsDriverReady()
{
    return m_instance && m_instance->m_DriverReady;
}
```

### 4.3 异步启动

**功能：**
- 异步启动驱动通信
- 不阻塞服务启动
- 后台初始化

**实现：**
- 创建独立线程
- 执行 `StartDriverAsync`
- 完成后设置就绪标志

## 5. 错误处理

### 5.1 注入失败
- 记录错误日志
- 尝试备用注入方法
- 通知驱动失败

### 5.2 通信中断
- 检测端口关闭
- 重新建立连接
- 清理未完成的请求

### 5.3 资源不足
- 限制并发请求
- 释放未使用的资源
- 降级服务

## 6. 性能优化

### 6.1 SID 缓存
- 减少系统调用
- 提高查询速度
- 降低 CPU 使用

### 6.2 线程池
- 并发处理请求
- 减少线程创建开销
- 提高吞吐量

### 6.3 异步处理
- 不阻塞驱动
- 提高响应速度
- 改善用户体验

## 7. 安全考虑

### 7.1 端口安全
- 限制性 DACL
- 仅系统账户可连接
- 防止未授权访问

### 7.2 注入安全
- 验证目标进程
- 检查 DLL 签名
- 防止恶意注入

### 7.3 权限检查
- 验证调用者身份
- 检查操作权限
- 记录敏感操作

## 8. 与其他组件的交互

- **内核驱动** - 主要通信对象
- **ProcessServer** - 进程管理协作
- **GuiServer** - GUI 初始化
- **SbieIniServer** - 配置查询
