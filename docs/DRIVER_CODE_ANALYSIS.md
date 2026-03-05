# Sandboxie 驱动程序代码分析

## 目录概述

`Sandboxie\core\drv` 目录包含 Sandboxie 的内核模式驱动程序代码，这是整个沙箱系统的核心组件。该驱动程序负责在内核层面拦截和重定向系统调用，实现进程隔离和资源虚拟化。

## 架构概述

Sandboxie 驱动程序采用分层架构设计：

1. **驱动程序核心层** - 驱动程序初始化、卸载和全局管理
2. **进程管理层** - 进程创建、监控和生命周期管理
3. **资源拦截层** - 文件系统、注册表、IPC 对象的拦截
4. **安全层** - 令牌过滤、权限控制
5. **通信层** - 与用户态服务的通信接口

## 主要模块分类

### 1. 核心驱动模块
- `driver.c/h` - 驱动程序入口和全局管理
- `api.c/h` - 用户态通信 API 接口
- `conf.c/h` - 配置管理
- `util.c/h` - 通用工具函数
- `mem.c/h` - 内存管理
- `log.c/h` - 日志系统
- `log_buff.c/h` - 日志缓冲区

### 2. 进程管理模块
- `process.c/h` - 进程管理核心
- `process_api.c` - 进程相关 API
- `process_force.c` - 强制沙箱化
- `process_hook.c` - 进程钩子
- `process_low.c` - 底层进程操作
- `process_util.c` - 进程工具函数
- `thread.c/h` - 线程管理
- `thread_token.c` - 线程令牌管理

### 3. 文件系统模块
- `file.c/h` - 文件系统拦截核心
- `file_flt.c` - 文件系统过滤器（Vista+）
- `file_xp.c` - Windows XP 文件系统钩子
- `file_ctrl.c` - 文件控制操作
- `file_xlat.c` - 文件路径转换

### 4. 注册表模块
- `key.c/h` - 注册表拦截核心
- `key_flt.c` - 注册表过滤器（Vista+）
- `key_xp.c` - Windows XP 注册表钩子

### 5. IPC 和对象管理模块
- `ipc.c/h` - 进程间通信拦截
- `ipc_lsa.c` - LSA 端点处理
- `ipc_sam.c` - SAM 端点处理
- `ipc_port.c` - LPC/ALPC 端口处理
- `ipc_spl.c` - 打印后台处理程序
- `obj.c/h` - 对象管理
- `obj_flt.c` - 对象过滤器
- `obj_xp.c` - Windows XP 对象钩子

### 6. 安全和令牌模块
- `token.c/h` - 访问令牌管理
- `verify.c/h` - 证书验证

### 7. GUI 和会话模块
- `gui.c/h` - GUI 相关拦截
- `gui_xp.c` - Windows XP GUI 钩子
- `session.c/h` - 会话管理

### 8. 系统调用模块
- `syscall.c/h` - 系统调用拦截框架
- `syscall_32.c` - 32位系统调用
- `syscall_64.c` - 64位系统调用
- `syscall_open.c` - 系统调用开放接口
- `syscall_util.c` - 系统调用工具
- `syscall_win32.c` - Win32k 系统调用

### 9. 钩子和底层操作模块
- `hook.c/h` - 钩子管理
- `hook_32.c` - 32位钩子
- `hook_64.c` - 64位钩子
- `dll.c/h` - DLL 管理

### 10. 网络和防火墙模块
- `wfp.c/h` - Windows 过滤平台集成

### 11. 辅助模块
- `box.c/h` - 沙箱配置
- `dyn_data.c/h` - 动态数据
- `includes.c` - 包含文件

## 详细模块分析

详细的模块分析请参考以下文档：

1. [核心驱动模块分析](./DRIVER_CORE_ANALYSIS.md)
2. [进程管理模块分析](./DRIVER_PROCESS_ANALYSIS.md)
3. [文件系统模块分析](./DRIVER_FILE_ANALYSIS.md)
4. [注册表模块分析](./DRIVER_KEY_ANALYSIS.md)
5. [IPC 模块分析](./DRIVER_IPC_ANALYSIS.md)
6. [安全模块分析](./DRIVER_SECURITY_ANALYSIS.md)
7. [系统调用模块分析](./DRIVER_SYSCALL_ANALYSIS.md)

## 工作原理

### 1. 驱动程序加载流程

```
DriverEntry (driver.c)
  ├─> Driver_CheckOsVersion() - 检查操作系统版本
  ├─> Driver_InitPublicSecurity() - 初始化安全描述符
  ├─> Driver_FindSystemRoot() - 查找系统根目录
  ├─> Driver_FindHomePath() - 查找 Sandboxie 安装路径
  ├─> Obj_Init() - 初始化对象管理
  ├─> Conf_Init() - 初始化配置系统
  ├─> Dll_Init() - 初始化 DLL 管理
  ├─> Syscall_Init() - 初始化系统调用拦截
  ├─> Session_Init() - 初始化会话管理
  ├─> Token_Init() - 初始化令牌管理
  ├─> Process_Init() - 初始化进程管理
  ├─> Thread_Init() - 初始化线程管理
  ├─> File_Init() - 初始化文件系统拦截
  ├─> Key_Init() - 初始化注册表拦截
  ├─> Ipc_Init() - 初始化 IPC 拦截
  ├─> Gui_Init() - 初始化 GUI 拦截
  ├─> Api_Init() - 初始化 API 设备
  └─> WFP_Init() - 初始化网络过滤
```

### 2. 进程沙箱化流程

```
Process_NotifyProcessEx (process.c)
  ├─> Process_NotifyProcess_Create()
  │   ├─> Process_GetForcedStartBox() - 检查是否需要强制沙箱化
  │   ├─> Process_Create() - 创建进程对象
  │   │   ├─> Box_Clone() - 克隆沙箱配置
  │   │   ├─> File_InitProcess() - 初始化文件路径
  │   │   ├─> Key_InitProcess() - 初始化注册表路径
  │   │   └─> Ipc_InitProcess() - 初始化 IPC 路径
  │   └─> Process_Low_Inject() - 注入 SbieDll.dll
  └─> Process_NotifyImage() - 镜像加载通知
      ├─> File_CreateBoxPath() - 创建沙箱文件路径
      ├─> Ipc_CreateBoxPath() - 创建沙箱 IPC 路径
      ├─> Key_MountHive() - 挂载注册表配置单元
      ├─> File_InitProcess() - 初始化文件过滤
      ├─> Key_InitProcess() - 初始化注册表过滤
      ├─> Ipc_InitProcess() - 初始化 IPC 过滤
      ├─> Gui_InitProcess() - 初始化 GUI 过滤
      └─> Token_ReplacePrimary() - 替换主令牌
```

### 3. 文件访问拦截流程

```
File_PreOperation (file_flt.c) - Vista+
  ├─> Process_Find() - 查找进程对象
  ├─> File_Generic_MyParseProc() - 解析文件路径
  │   ├─> Box_IsBoxedPath() - 检查是否在沙箱内
  │   ├─> Process_MatchPathEx() - 匹配路径规则
  │   │   ├─> 检查 NormalFilePath
  │   │   ├─> 检查 OpenFilePath
  │   │   ├─> 检查 ClosedFilePath
  │   │   ├─> 检查 ReadFilePath
  │   │   └─> 检查 WriteFilePath
  │   └─> File_TranslateTruePath() - 转换真实路径
  └─> 返回 FLT_PREOP_SUCCESS_WITH_CALLBACK 或拒绝访问
```

### 4. 注册表访问拦截流程

```
Key_Callback (key_flt.c) - Vista+
  ├─> Process_Find() - 查找进程对象
  ├─> Key_MyParseProc_2() - 解析注册表路径
  │   ├─> Box_IsBoxedPath() - 检查是否在沙箱内
  │   ├─> Process_MatchPathEx() - 匹配路径规则
  │   │   ├─> 检查 NormalKeyPath
  │   │   ├─> 检查 OpenKeyPath
  │   │   ├─> 检查 ClosedKeyPath
  │   │   ├─> 检查 ReadKeyPath
  │   │   └─> 检查 WriteKeyPath
  │   └─> 重定向到沙箱注册表配置单元
  └─> 返回 STATUS_SUCCESS 或拒绝访问
```

### 5. 系统调用拦截流程

```
Syscall_Init (syscall.c)
  ├─> Syscall_Init_List() - 扫描 ntdll.dll 导出
  │   ├─> 分析每个 ZwXxx 函数
  │   ├─> 提取系统调用号
  │   └─> 创建 SYSCALL_ENTRY 结构
  ├─> Syscall_Init_Table() - 构建系统调用表
  └─> Syscall_Set1/Set2() - 设置处理程序
      ├─> handler1_func - 前置处理（替换系统调用）
      ├─> handler2_func - 对象打开处理
      └─> handler3_func - 支持 Procmon 的处理
```

## 关键技术

### 1. 文件系统虚拟化

- **写时复制（Copy-on-Write）**：首次写入时从真实位置复制到沙箱
- **路径重定向**：将沙箱外路径映射到沙箱内路径
- **符号链接处理**：正确处理重解析点和符号链接

### 2. 注册表虚拟化

- **配置单元挂载**：为每个沙箱挂载独立的注册表配置单元
- **路径重写**：将注册表访问重定向到沙箱配置单元
- **快照隔离**：保持注册表修改的隔离性

### 3. 进程隔离

- **令牌过滤**：降低进程权限，移除管理员权限
- **对象访问控制**：限制对其他进程和线程的访问
- **作业对象**：使用作业对象限制进程行为

### 4. IPC 隔离

- **命名对象重定向**：将命名对象创建到沙箱命名空间
- **LPC/ALPC 端口过滤**：控制端口连接
- **剪贴板隔离**：隔离剪贴板数据

### 5. 网络过滤

- **WFP 集成**：使用 Windows 过滤平台控制网络访问
- **规则匹配**：根据配置允许或拒绝网络连接

## 安全特性

### 1. 权限降级

```c
Token_FilterPrimary() - 过滤主令牌
  ├─> 移除管理员组
  ├─> 移除特权
  ├─> 添加受限 SID
  └─> 设置低完整性级别（Vista+）
```

### 2. 资源访问控制

- **OpenFilePath/ClosedFilePath**：控制文件访问
- **OpenKeyPath/ClosedKeyPath**：控制注册表访问
- **OpenIpcPath/ClosedIpcPath**：控制 IPC 对象访问

### 3. 进程保护

- **进程终止保护**：防止沙箱进程终止外部进程
- **线程注入保护**：防止跨沙箱线程注入
- **句柄访问限制**：限制对外部对象的句柄访问

## 性能优化

1. **路径缓存**：缓存路径匹配结果
2. **哈希表**：使用哈希表快速查找进程和线程
3. **资源锁优化**：使用读写锁减少锁竞争
4. **延迟初始化**：按需初始化资源

## 兼容性

### 支持的操作系统

- Windows XP (32位)
- Windows Vista/7/8/8.1/10/11 (32位和64位)
- Windows Server 2003/2008/2012/2016/2019/2022

### 架构支持

- x86 (32位)
- x64 (64位)
- ARM64 (实验性)

### 版本差异处理

- **XP/2003**：使用解析过程钩子（Parse Procedure Hook）
- **Vista+**：使用微过滤器（Minifilter）和注册表回调
- **Win8+**：支持 AppContainer 和 Win32k 过滤

## 调试和诊断

### 跟踪标志

- `CallTrace` - 系统调用跟踪
- `FileTrace` - 文件操作跟踪
- `PipeTrace` - 管道操作跟踪
- `KeyTrace` - 注册表操作跟踪
- `IpcTrace` - IPC 操作跟踪
- `GuiTrace` - GUI 操作跟踪

### 日志系统

```c
Log_Msg() - 记录消息
Log_Status() - 记录状态码
Api_AddMessage() - 添加消息到日志缓冲区
Api_GetMessage() - 从日志缓冲区获取消息
```

## 配置系统

配置存储在注册表中：`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SbieDrv`

主要配置项：
- 沙箱定义
- 路径规则（Open/Closed/Read/Write）
- 强制进程列表
- 网络规则
- 安全选项

## 总结

Sandboxie 驱动程序是一个复杂的内核模式组件，通过以下技术实现应用程序沙箱化：

1. **系统调用拦截**：拦截和重定向关键系统调用
2. **文件系统虚拟化**：提供隔离的文件系统视图
3. **注册表虚拟化**：提供隔离的注册表视图
4. **进程和线程隔离**：限制跨沙箱交互
5. **安全令牌过滤**：降低进程权限
6. **网络访问控制**：控制网络连接

这些技术共同工作，创建了一个安全、隔离的执行环境，保护主机系统免受潜在恶意软件的影响。

## 相关文档

- [LICENSE_REMOVAL_GUIDE.md](../LICENSE_REMOVAL_GUIDE.md) - 许可证移除指南
- [构建说明](../BUILD.md) - 如何构建驱动程序
- [配置指南](../CONFIG.md) - 配置选项说明
