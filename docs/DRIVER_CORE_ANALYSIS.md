# Sandboxie 驱动程序 - 核心模块详细分析

## 1. driver.c/h - 驱动程序入口和全局管理

### 主要功能
驱动程序的入口点和全局初始化/卸载管理。

### 关键函数

#### DriverEntry()
```c
NTSTATUS DriverEntry(DRIVER_OBJECT *DriverObject, UNICODE_STRING *RegistryPath)
```
**功能**：驱动程序入口点，负责初始化所有子系统
**流程**：
1. 检查操作系统版本（`Driver_CheckOsVersion`）
2. 创建驱动程序内存池（`Pool_Create`）
3. 初始化公共安全描述符（`Driver_InitPublicSecurity`）
4. 查找系统根目录和安装路径
5. 验证证书（`MyValidateCertificate`）
6. 初始化各个子系统（Obj, Conf, Dll, Syscall, Session, Token, Process, Thread, File, Key, Ipc, Gui, Api, WFP）
7. 记录成功日志

#### Driver_CheckOsVersion()
```c
BOOLEAN Driver_CheckOsVersion(void)
```
**功能**：检查操作系统版本是否受支持
**支持的版本**：
- Windows XP (5.1) - 32位
- Windows 2003 (5.2)
- Windows Vista (6.0)
- Windows 7 (6.1)
- Windows 8 (6.2)
- Windows 8.1 (6.3)
- Windows 10/11 (10.0)

#### Driver_InitPublicSecurity()
```c
BOOLEAN Driver_InitPublicSecurity(void)
```
**功能**：创建公共安全描述符，允许所有用户访问
**创建的 SID**：
- Authenticated Users (S-1-5-11)
- Everyone (S-1-1-0)
- Restricted (S-1-5-12)

#### Driver_FindSystemRoot()
```c
BOOLEAN Driver_FindSystemRoot()
```
**功能**：查找并解析 `\SystemRoot` 符号链接，获取 Windows 系统目录的完整路径

#### Driver_FindHomePath()
```c
BOOLEAN Driver_FindHomePath(UNICODE_STRING *RegistryPath)
```
**功能**：从注册表读取驱动程序路径，确定 Sandboxie 安装目录
**步骤**：
1. 打开驱动程序注册表项
2. 读取 ImagePath 值
3. 移除文件名，保留目录路径
4. 转换为 NT 路径格式

#### SbieDrv_DriverUnload()
```c
void SbieDrv_DriverUnload(DRIVER_OBJECT *DriverObject)
```
**功能**：卸载驱动程序，清理所有资源
**步骤**：
1. 设置 `Driver_Unloading = TRUE`
2. 卸载各个子系统（按相反顺序）
3. 释放内存池
4. 记录卸载日志

### 全局变量

```c
DRIVER_OBJECT *Driver_Object;           // 驱动程序对象
WCHAR *Driver_Version;                  // 版本字符串
ULONG Driver_OsVersion;                 // 操作系统版本
ULONG Driver_OsBuild;                   // 操作系统构建号
POOL *Driver_Pool;                      // 全局内存池
WCHAR *Driver_SystemRootPathNt;         // 系统根目录路径
WCHAR *Driver_HomePathNt;               // Sandboxie 安装路径
PSECURITY_DESCRIPTOR Driver_PublicSd;   // 公共安全描述符
```

---

## 2. api.c/h - 用户态通信 API 接口

### 主要功能
提供驱动程序与用户态服务（SbieSvc）和应用程序（SbieDll）之间的通信接口。

### 关键函数

#### Api_Init()
```c
BOOLEAN Api_Init(void)
```
**功能**：初始化 API 设备和通信机制
**步骤**：
1. 初始化日志缓冲区（`log_buffer_init`）
2. 创建资源锁
3. 创建 Fast I/O 调度表
4. 设置 IRP 处理函数（CREATE, CLEANUP）
5. 创建设备对象 `\Device\SandboxieDriverApi`
6. 注册 API 函数处理程序

#### Api_FastIo_DEVICE_CONTROL()
```c
BOOLEAN Api_FastIo_DEVICE_CONTROL(...)
```
**功能**：处理来自用户态的 IOCTL 请求
**支持的控制码**：
- `API_SBIEDRV_CTLCODE` - 标准 API 调用
- `API_SBIEDRV_FILTERTOKEN_CTLCODE` - 内核模式令牌过滤
- `API_SBIEDRV_PFILTERTOKEN_CTLCODE` - 内核模式令牌过滤（私有）

**处理流程**：
1. 验证调用者权限（用户模式，PASSIVE_LEVEL）
2. 从用户缓冲区读取参数
3. 查找调用进程（`Process_Find`）
4. 根据功能码调用相应的 API 函数
5. 返回结果

#### Api_GetVersion()
```c
NTSTATUS Api_GetVersion(PROCESS *proc, ULONG64 *parms)
```
**功能**：返回驱动程序版本和 ABI 版本
**参数**：
- `string` - 版本字符串（如 "5.55.0"）
- `abi_ver` - ABI 版本号

#### Api_LogMessage()
```c
NTSTATUS Api_LogMessage(PROCESS *proc, ULONG64 *parms)
```
**功能**：记录来自用户态的日志消息
**参数**：
- `msgid` - 消息 ID
- `msgtext` - 消息文本
- `session_id` - 会话 ID
- `process_id` - 进程 ID

#### Api_AddMessage()
```c
void Api_AddMessage(NTSTATUS error_code, const WCHAR** strings, ULONG* lengths, ULONG session_id, ULONG process_id)
```
**功能**：添加消息到日志缓冲区
**格式**：`[session_id][process_id][error_code][string1]\0[string2]\0...`

#### Api_GetMessage()
```c
NTSTATUS Api_GetMessage(PROCESS *proc, ULONG64 *parms)
```
**功能**：从日志缓冲区读取消息（供 SbieSvc 使用）
**参数**：
- `msg_num` - 消息序列号（输入/输出）
- `msgid` - 消息 ID（输出）
- `msgtext` - 消息文本（输出）
- `session_id` - 过滤会话 ID
- `process_id` - 进程 ID（输出）

#### Api_SetServicePort()
```c
NTSTATUS Api_SetServicePort(PROCESS *proc, ULONG64 *parms)
```
**功能**：设置 SbieSvc 的 LPC 端口，用于驱动程序向服务发送消息
**验证**：
1. 检查调用者是否为系统进程
2. 验证调用者签名（`MyIsCallerSigned`）
3. 保存端口对象引用

#### Api_SendServiceMessage()
```c
BOOLEAN Api_SendServiceMessage(ULONG msgid, ULONG data_len, void *data)
```
**功能**：向 SbieSvc 发送 LPC 消息
**用途**：
- 通知服务进程事件
- 请求服务执行操作
- 传递状态信息

#### Api_ProcessExemptionControl()
```c
NTSTATUS Api_ProcessExemptionControl(PROCESS *proc, ULONG64 *parms)
```
**功能**：控制进程豁免标志
**支持的操作**：
- `'splr'` - 允许打印到文件
- `'inet'` - 允许互联网访问

#### Api_QueryDriverInfo()
```c
NTSTATUS Api_QueryDriverInfo(PROCESS* proc, ULONG64* parms)
```
**功能**：查询驱动程序信息和功能标志
**返回的标志**：
- `SBIE_FEATURE_FLAG_WFP` - WFP 支持
- `SBIE_FEATURE_FLAG_OB_CALLBACKS` - 对象回调支持
- `SBIE_FEATURE_FLAG_WIN32K_HOOK` - Win32k 钩子支持
- `SBIE_FEATURE_FLAG_CERTIFIED` - 已认证
- `SBIE_FEATURE_FLAG_SECURITY_MODE` - 安全模式
- `SBIE_FEATURE_FLAG_PRIVACY_MODE` - 隐私模式
- `SBIE_FEATURE_FLAG_ENCRYPTION` - 加密支持

#### Api_SetSecureParam() / Api_GetSecureParam()
```c
NTSTATUS Api_SetSecureParam(PROCESS* proc, ULONG64* parms)
NTSTATUS Api_GetSecureParam(PROCESS* proc, ULONG64* parms)
```
**功能**：安全参数的存储和检索（存储在注册表 `\REGISTRY\MACHINE\SECURITY\SBIE`）
**用途**：
- 存储加密密钥
- 存储许可证信息
- 存储配置数据

### API 函数注册

```c
Api_SetFunction(API_GET_VERSION,        Api_GetVersion);
Api_SetFunction(API_LOG_MESSAGE,        Api_LogMessage);
Api_SetFunction(API_GET_MESSAGE,        Api_GetMessage);
Api_SetFunction(API_GET_HOME_PATH,      Api_GetHomePath);
Api_SetFunction(API_SET_SERVICE_PORT,   Api_SetServicePort);
Api_SetFunction(API_UNLOAD_DRIVER,      Driver_Api_Unload);
Api_SetFunction(API_PROCESS_EXEMPTION_CONTROL, Api_ProcessExemptionControl);
Api_SetFunction(API_QUERY_DRIVER_INFO,  Api_QueryDriverInfo);
Api_SetFunction(API_SET_SECURE_PARAM,   Api_SetSecureParam);
Api_SetFunction(API_GET_SECURE_PARAM,   Api_GetSecureParam);
Api_SetFunction(API_VERIFY,             Api_Verify);
```

---

## 3. conf.c/h - 配置管理

### 主要功能
从注册表读取和管理沙箱配置。

### 关键函数

#### Conf_Init()
```c
BOOLEAN Conf_Init(void)
```
**功能**：初始化配置系统
**步骤**：
1. 创建配置缓存
2. 设置 API 函数（读取、写入、枚举配置）
3. 初始化配置锁

#### Conf_Read()
```c
const WCHAR *Conf_Get(const WCHAR *section, const WCHAR *setting, ULONG index)
```
**功能**：从注册表读取配置值
**参数**：
- `section` - 沙箱名称
- `setting` - 设置名称
- `index` - 索引（用于多值设置）

**配置路径**：`HKLM\SYSTEM\CurrentControlSet\Services\SbieDrv\Parameters`

#### Conf_Get_Boolean()
```c
BOOLEAN Conf_Get_Boolean(const WCHAR *section, const WCHAR *setting, ULONG index, BOOLEAN def)
```
**功能**：读取布尔配置值
**支持的值**：`y`, `yes`, `true`, `1` = TRUE；其他 = FALSE

#### Conf_Expand()
```c
WCHAR *Conf_Expand(POOL *pool, const WCHAR *value, const WCHAR *section)
```
**功能**：展开配置值中的变量
**支持的变量**：
- `%SANDBOX%` - 沙箱名称
- `%USER%` - 用户名
- `%SID%` - 用户 SID
- `%SESSION%` - 会话 ID
- `%PID%` - 进程 ID
- `%SBIE%` - Sandboxie 安装目录

### 配置示例

```ini
[DefaultBox]
Enabled=y
OpenFilePath=%USERPROFILE%\Downloads
ClosedFilePath=C:\Windows\System32
OpenKeyPath=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer
ClosedKeyPath=HKLM\Software
```

---

## 4. util.c/h - 通用工具函数

### 主要功能
提供各种实用工具函数。

### 关键函数

#### Util_GetProcessName()
```c
NTSTATUS Util_GetProcessName(PEPROCESS ProcessObject, WCHAR **OutName)
```
**功能**：获取进程的可执行文件名

#### Util_GetProcessPath()
```c
NTSTATUS Util_GetProcessPath(PEPROCESS ProcessObject, WCHAR **OutPath)
```
**功能**：获取进程的完整路径

#### MyIsCallerMyServiceProcess()
```c
BOOLEAN MyIsCallerMyServiceProcess(void)
```
**功能**：检查调用者是否为 SbieSvc 服务进程
**验证**：
1. 检查进程路径是否在 Sandboxie 安装目录
2. 检查进程名是否为 SbieSvc.exe

#### MyIsCallerSigned()
```c
BOOLEAN MyIsCallerSigned(void)
```
**功能**：验证调用者的数字签名
**用途**：防止未授权的进程调用特权 API

#### DisableWriteProtect() / EnableWriteProtect()
```c
void DisableWriteProtect(void)
void EnableWriteProtect(void)
```
**功能**：临时禁用/启用内存写保护（用于修改只读内存）

---

## 5. mem.c/h - 内存管理

### 主要功能
提供内存分配和资源锁管理。

### 关键函数

#### Mem_Alloc()
```c
void *Mem_Alloc(POOL *pool, ULONG size)
```
**功能**：从指定池分配内存

#### Mem_Free()
```c
void Mem_Free(void *ptr, ULONG size)
```
**功能**：释放内存

#### Mem_AllocString()
```c
WCHAR *Mem_AllocString(POOL *pool, const WCHAR *string)
```
**功能**：分配并复制字符串

#### Mem_GetLockResource()
```c
BOOLEAN Mem_GetLockResource(PERESOURCE *ppResource, BOOLEAN InitialOwner)
```
**功能**：创建 ERESOURCE 锁

#### Mem_FreeLockResource()
```c
void Mem_FreeLockResource(PERESOURCE *ppResource)
```
**功能**：释放 ERESOURCE 锁

---

## 6. log.c/h - 日志系统

### 主要功能
记录驱动程序事件和错误。

### 关键函数

#### Log_Msg()
```c
void Log_Msg(ULONG msgid, const WCHAR *str1, const WCHAR *str2)
```
**功能**：记录消息

#### Log_Status()
```c
void Log_Status(ULONG msgid, ULONG code, NTSTATUS status)
```
**功能**：记录状态码

#### Log_Msg_Process()
```c
void Log_Msg_Process(ULONG msgid, const WCHAR *str1, const WCHAR *str2, ULONG session_id, HANDLE process_id)
```
**功能**：记录与进程相关的消息

### 消息 ID 范围

- `MSG_1xxx` - 驱动程序初始化和错误
- `MSG_2xxx` - 进程和线程事件
- `MSG_3xxx` - 文件系统事件
- `MSG_4xxx` - 注册表事件
- `MSG_5xxx` - IPC 事件
- `MSG_6xxx` - 安全和许可证事件

---

## 7. log_buff.c/h - 日志缓冲区

### 主要功能
实现循环日志缓冲区，用于高效的日志存储和检索。

### 关键函数

#### log_buffer_init()
```c
LOG_BUFFER* log_buffer_init(LOG_BUFFER_SIZE_T size)
```
**功能**：初始化日志缓冲区

#### log_buffer_push_entry()
```c
CHAR* log_buffer_push_entry(LOG_BUFFER_SIZE_T entry_size, LOG_BUFFER* log, BOOLEAN overwrite)
```
**功能**：向缓冲区添加条目

#### log_buffer_get_next()
```c
CHAR* log_buffer_get_next(LOG_BUFFER_SEQ_T seq_number, LOG_BUFFER* log)
```
**功能**：从缓冲区读取下一条消息

### 缓冲区结构

```
[Header: size, seq_num][Data...][Header: size, seq_num][Data...]...
```

- 循环缓冲区，旧消息被新消息覆盖
- 每条消息有序列号，用于跟踪
- 支持多读者单写者模式

---

## 总结

核心驱动模块提供了以下关键功能：

1. **驱动程序生命周期管理**：初始化、运行、卸载
2. **用户态通信**：API 设备和 IOCTL 处理
3. **配置管理**：从注册表读取沙箱配置
4. **工具函数**：通用实用函数
5. **内存管理**：内存分配和资源锁
6. **日志系统**：事件记录和诊断

这些模块共同构成了驱动程序的基础设施，为其他功能模块提供支持。
