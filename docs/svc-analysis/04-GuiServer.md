# GuiServer - GUI 代理服务器

## 1. 概述

GuiServer 负责处理沙箱进程的 GUI 相关操作，主要解决 UIPI（用户界面特权隔离）问题，管理作业对象，处理窗口钩子等。

**文件：**
- `GuiServer.cpp` / `GuiServer.h`
- `GuiWire.h` - 消息协议定义

**核心问题：**
- Windows Vista+ 引入 UIPI，限制低完整性进程访问高完整性进程的窗口
- 沙箱进程通常运行在低完整性级别
- 需要代理机制突破 UIPI 限制

## 2. 架构设计

### 2.1 代理模式

**主从架构：**
- **主服务（GuiServer）** - 运行在 SbieSvc 中
- **从进程（GuiProxy）** - 每个会话一个，运行在用户桌面

**通信机制：**
- 使用消息队列（QueueServer）
- 队列名称：`*GUIPROXY_{session_id}`
- 异步消息传递

### 2.2 核心数据结构

**从进程管理：**
```cpp
typedef struct _GUI_SLAVE {
    LIST_ELEM list_elem;
    HANDLE hProcess;      // 从进程句柄
    ULONG session_id;     // 会话 ID
} GUI_SLAVE;
```

**窗口钩子管理：**
```cpp
typedef struct _WND_HOOK {
    LIST_ELEM list_elem;
    ULONG pid;            // 进程 ID
    bool isWoW64;         // 是否 WoW64 进程
    DWORD hthread;        // 线程句柄
    ULONG64 hproc;        // 进程句柄
    int HookCount;        // 钩子计数
} WND_HOOK;
```

## 3. 核心功能

### 3.1 InitProcess - 进程初始化

**功能：**
- 将新进程加入作业对象
- 设置 UI 限制
- 配置 UIPI 策略

**流程：**

1. **检查作业对象状态**
   - Windows 8+ 允许进程属于多个作业
   - Windows 7 及以下需要检查是否已在作业中

2. **发送初始化消息**
   - 构造 `GUI_INIT_PROCESS_REQ` 消息
   - 通过队列发送到从进程
   - 等待完成

3. **启动从进程（如需要）**
   - 如果从进程不存在，启动新的
   - 重试发送消息

4. **验证作业对象**
   - 确认进程已加入作业
   - 检查作业限制是否生效

**作业对象配置：**
- `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` - 作业关闭时终止进程
- `JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION` - 未处理异常时终止
- UI 限制：禁止修改桌面、显示设置、系统参数

### 3.2 StartSlave - 启动从进程

**功能：**
- 在指定会话中启动 GuiProxy 进程
- 以用户身份运行
- 建立通信通道

**实现：**

1. **获取会话令牌**
   - 查询会话中的活动进程
   - 复制用户令牌
   - 调整令牌权限

2. **创建进程**
   - 命令行：`SbieSvc.exe SANDBOXIE_GuiProxy_{session_id}`
   - 使用 `CreateProcessAsUser`
   - 在用户桌面上运行

3. **注册从进程**
   - 添加到 `m_SlavesList`
   - 记录进程句柄和会话 ID

### 3.3 SendMessageToSlave - 发送消息

**功能：**
- 向从进程发送控制消息
- 使用队列机制
- 支持同步等待

**消息类型：**
- `GUI_INIT_PROCESS` - 初始化进程
- `GUI_CREATE_WINDOW` - 创建窗口
- `GUI_QUERY_WINDOW` - 查询窗口信息
- `GUI_SET_WINDOW_POS` - 设置窗口位置
- `GUI_SEND_MESSAGE` - 发送窗口消息

**实现：**
```cpp
QUEUE_PUTREQ_REQ *req = AllocMsg();
wsprintf(req->queue_name, L"*GUIPROXY_%08X", session_id);
req->event_handle = m_QueueEvent;
memcpy(req->data, data, data_len);

// 通过 QueueServer 发送
PipeServer::Call(req);

// 等待响应
WaitForSingleObject(m_QueueEvent, timeout);
```

### 3.4 RunSlave - 从进程主函数

**功能：**
- GuiProxy 进程的入口点
- 处理来自主服务的请求
- 执行 GUI 操作

**主循环：**
```cpp
while (true) {
    // 从队列获取消息
    msg = GetMessageFromQueue();
    
    switch (msg->msgid) {
        case GUI_INIT_PROCESS:
            HandleInitProcess(msg);
            break;
        case GUI_CREATE_WINDOW:
            HandleCreateWindow(msg);
            break;
        // ... 其他消息
    }
}
```

**处理函数：**

1. **HandleInitProcess**
   - 打开目标进程
   - 创建或打开作业对象
   - 将进程加入作业
   - 设置作业限制

2. **HandleCreateWindow**
   - 代理创建窗口
   - 返回窗口句柄
   - 建立窗口映射

3. **HandleQueryWindow**
   - 查询窗口属性
   - 获取窗口文本
   - 返回窗口信息

### 3.5 窗口钩子管理

**功能：**
- 安装窗口钩子
- 拦截窗口消息
- 处理跨进程窗口操作

**钩子类型：**
- `WH_CALLWNDPROC` - 窗口过程钩子
- `WH_GETMESSAGE` - 消息获取钩子
- `WH_CBT` - 计算机基础训练钩子

**安装流程：**
```cpp
HHOOK InstallHook(ULONG pid, int hookType) {
    DWORD tid = GetMainThreadId(pid);
    HHOOK hook = SetWindowsHookEx(
        hookType,
        HookProc,
        hDll,
        tid
    );
    
    // 记录钩子信息
    WND_HOOK *wnd_hook = AllocHook();
    wnd_hook->pid = pid;
    wnd_hook->hthread = tid;
    wnd_hook->HookCount++;
    
    return hook;
}
```

### 3.6 DPI 感知处理

**功能：**
- 处理高 DPI 显示
- 设置 DPI 感知级别
- 避免模糊显示

**实现：**
```cpp
if (__sys_SetThreadDpiAwarenessContext) {
    __sys_SetThreadDpiAwarenessContext(
        DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
    );
}

if (__sys_SetProcessDpiAwarenessContext) {
    __sys_SetProcessDpiAwarenessContext(
        DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
    );
}
```

**DPI 级别：**
- `DPI_AWARENESS_CONTEXT_UNAWARE` - 不感知
- `DPI_AWARENESS_CONTEXT_SYSTEM_AWARE` - 系统感知
- `DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE` - 每监视器感知
- `DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2` - 增强版

### 3.7 DDE 支持

**功能：**
- 处理动态数据交换（DDE）
- 支持 DDE 对话
- 代理 DDE 消息

**实现：**
- 创建隐藏的代理窗口
- 接收 DDE 消息
- 转发到目标进程

## 4. 作业对象管理

### 4.1 作业对象创建

**配置：**
```cpp
JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits;
limits.BasicLimitInformation.LimitFlags = 
    JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE |
    JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION |
    JOB_OBJECT_LIMIT_BREAKAWAY_OK;

SetInformationJobObject(hJob, 
    JobObjectExtendedLimitInformation, 
    &limits, sizeof(limits));
```

### 4.2 UI 限制

**限制类型：**
```cpp
JOBOBJECT_BASIC_UI_RESTRICTIONS ui;
ui.UIRestrictionsClass = 
    JOB_OBJECT_UILIMIT_DESKTOP |           // 禁止切换桌面
    JOB_OBJECT_UILIMIT_DISPLAYSETTINGS |   // 禁止修改显示设置
    JOB_OBJECT_UILIMIT_EXITWINDOWS |       // 禁止注销/关机
    JOB_OBJECT_UILIMIT_GLOBALATOMS |       // 限制全局原子
    JOB_OBJECT_UILIMIT_HANDLES |           // 限制句柄访问
    JOB_OBJECT_UILIMIT_READCLIPBOARD |     // 限制剪贴板读取
    JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS |  // 禁止修改系统参数
    JOB_OBJECT_UILIMIT_WRITECLIPBOARD;     // 限制剪贴板写入

SetInformationJobObject(hJob, 
    JobObjectBasicUIRestrictions, 
    &ui, sizeof(ui));
```

### 4.3 进程加入

**流程：**
```cpp
HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
BOOL ok = AssignProcessToJobObject(hJob, hProcess);
if (!ok) {
    // 处理错误
    // Windows 8+ 可能需要特殊处理
}
```

## 5. UIPI 处理

### 5.1 UIPI 概述

**问题：**
- 低完整性进程无法向高完整性进程发送消息
- 无法访问高完整性进程的窗口
- 限制跨完整性级别的 UI 操作

**解决方案：**
- 使用高完整性的代理进程
- 代理执行 UI 操作
- 返回结果给沙箱进程

### 5.2 消息过滤

**允许的消息：**
- `WM_NULL`
- `WM_MOVE`
- `WM_SIZE`
- 等安全消息

**禁止的消息：**
- `WM_COPYDATA`
- `WM_SETTEXT`
- 等危险消息

### 5.3 窗口访问

**代理访问：**
```cpp
HWND GetWindowProxy(HWND hwnd) {
    // 检查窗口完整性级别
    if (IsHighIntegrityWindow(hwnd)) {
        // 通过代理访问
        return SendToProxy(GUI_GET_WINDOW, hwnd);
    }
    return hwnd;
}
```

## 6. 错误处理

### 6.1 从进程崩溃
- 检测从进程退出
- 自动重启从进程
- 重新建立连接

### 6.2 通信超时
- 设置超时时间
- 重试机制
- 降级处理

### 6.3 作业对象失败
- 记录错误日志
- 尝试备用方法
- 通知用户

## 7. 性能优化

### 7.1 消息批处理
- 合并多个消息
- 减少通信次数
- 提高吞吐量

### 7.2 异步处理
- 不等待响应
- 后台处理
- 提高响应速度

### 7.3 缓存
- 缓存窗口信息
- 减少查询次数
- 降低延迟

## 8. 安全考虑

### 8.1 权限验证
- 检查调用者身份
- 验证目标进程
- 防止权限提升

### 8.2 消息验证
- 验证消息来源
- 检查消息内容
- 防止注入攻击

### 8.3 资源限制
- 限制作业对象资源
- 防止资源耗尽
- 保护系统稳定

## 9. 配置选项

- `NoAddProcessToJob` - 禁用作业对象
- `NoSecurityIsolation` - 禁用安全隔离
- `DropAdminRights` - 降低管理员权限

## 10. 与其他组件的交互

- **ProcessServer** - 进程创建协作
- **QueueServer** - 消息队列通信
- **DriverAssist** - 进程注入
- **SbieIniServer** - 配置查询
