---
name: sandboxie-modifier
description: >
  专门用于修改、优化和测试 Sandboxie 核心模块（Sandboxie/Sandboxie/）的 skill。
  当用户需要修改内核驱动（SbieDrv）、系统服务（SbieSvc）、注入 DLL（SbieDll）、
  经典 UI（SbieCtrl）或进行代码优化、性能改进、安全增强、bug 修复时使用。
  涵盖编译、测试、调试、部署的完整工作流。
  关键词：修改驱动、优化性能、修复 bug、增强安全、测试沙箱、编译 Sandboxie。
---

# Sandboxie 核心模块修改与优化 Skill

## 🎯 Skill 定位

本 skill 专注于 `F:\Project\AI\sanbox\Sandboxie\Sandboxie\` 目录下的核心模块：
- **内核驱动** (core/drv/) - SbieDrv.sys
- **系统服务** (core/svc/) - SbieSvc.exe  
- **注入 DLL** (core/dll/) - SbieDll.dll
- **经典 UI** (apps/control/) - SbieCtrl.exe
- **辅助工具** (apps/start/, apps/ini/ 等)

提供从代码分析、修改实施、编译构建到测试验证的完整工作流支持。

---

## 📚 前置知识：项目架构速览

### 三层架构

```
┌─────────────────────────────────────────────────┐
│  应用程序层 (被沙箱化的程序)                      │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│  SbieDll.dll (用户态 Hook 层)                    │
│  • API Hooking (CreateFile, RegSetValue...)     │
│  • 路径转换 (真实路径 ↔ 沙箱路径)                │
│  • 与 SbieSvc 通信 (LPC)                         │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼──────┐         ┌───────▼──────────┐
│  SbieSvc.exe │         │   SbieDrv.sys    │
│  (系统服务)   │◄────────┤   (内核驱动)      │
│              │  IOCTL  │                  │
└──────────────┘         └──────────────────┘
```

### 核心模块职责

| 模块 | 路径 | 职责 | 代码量 |
|-----|------|------|--------|
| **SbieDrv** | core/drv/ | 内核级系统调用拦截、文件/注册表虚拟化、进程隔离 | ~50,000 行 |
| **SbieSvc** | core/svc/ | 驱动管理、进程启动、配置管理、权限代理 | ~30,000 行 |
| **SbieDll** | core/dll/ | 用户态 API Hook、路径重定向、与服务通信 | ~40,000 行 |
| **SbieCtrl** | apps/control/ | 经典 MFC 界面、沙箱管理 | ~15,000 行 |

---

## 🔧 修改工作流

### 步骤 1：需求分析

**问题清单**：
1. 修改目标是什么？（功能增强/性能优化/bug 修复/安全加固）
2. 影响哪些层？（驱动/服务/DLL/UI）
3. 是否需要修改配置系统？
4. 是否需要更新 API 接口？
5. 向后兼容性要求？

**输出**：明确的修改范围和影响评估

---

### 步骤 2：代码定位与分析

#### 2.1 使用分析文档快速定位

参考已生成的分析文档：
- `docs/ai-analysis/00-PROJECT-OVERVIEW.md` - 项目全景
- `docs/ai-analysis/modules/01-kernel-driver-layer.md` - 驱动层详解
- `docs/ai-analysis/modules/02-service-layer.md` - 服务层详解
- `docs/ai-analysis/files/drv_*.md` - 具体文件分析

#### 2.2 快速定位表

| 修改类型 | 主要文件 | 辅助文件 |
|---------|---------|---------|
| **文件系统虚拟化** | core/drv/file.c | core/dll/file.c, core/drv/file_flt.c |
| **注册表虚拟化** | core/drv/key.c | core/dll/key.c, core/drv/key_flt.c |
| **进程隔离** | core/drv/process.c | core/dll/proc.c, core/drv/token.c |
| **系统调用拦截** | core/drv/syscall.c | core/drv/hook.c |
| **DLL 注入** | core/drv/dll.c | core/low/, core/dll/dllmain.c |
| **网络过滤** | core/drv/wfp.c | core/dll/net.c |
| **配置管理** | core/drv/conf.c | core/svc/sbieiniserver.cpp |
| **进程启动** | core/svc/ProcessServer.cpp | apps/start/start.cpp |
| **驱动通信** | core/svc/DriverAssist.cpp | core/drv/api.c |
| **UI 界面** | apps/control/ | apps/common/ |

#### 2.3 代码阅读策略

```bash
# 1. 搜索关键函数
rg "Function_Name" Sandboxie/core/

# 2. 查找配置项
rg "ConfigKey" Sandboxie/install/Templates.ini

# 3. 查找错误消息
rg "SBIE[0-9]{4}" Sandboxie/msgs/

# 4. 查找 API 调用
rg "API_.*" Sandboxie/core/drv/api.h
```

---

### 步骤 3：修改实施

#### 3.1 修改模板

**添加新的配置项**：

```c
// 1. 在 core/drv/conf.c 中添加配置读取
WCHAR *Conf_Get_MyNewSetting(BOX *box) {
    return Conf_Get(box, L"MyNewSetting", 0);
}

// 2. 在 core/drv/conf.h 中声明
WCHAR *Conf_Get_MyNewSetting(BOX *box);

// 3. 在使用处调用
WCHAR *setting = Conf_Get_MyNewSetting(proc->box);
if (setting && _wcsicmp(setting, L"y") == 0) {
    // 应用新功能
}

// 4. 在 install/Templates.ini 中添加默认值
[DefaultBox]
MyNewSetting=n

// 5. 在 msgs/Sbie-English-1033.txt 中添加说明
#define SBIE_CONF_MY_NEW_SETTING \
    "MyNewSetting: Enable new feature (y/n)"
```

**添加新的系统调用拦截**：

```c
// 1. 在 core/drv/syscall.c 中注册
if (!Syscall_Set1("MyNewSyscall", MyModule_MyNewSyscall))
    return FALSE;

// 2. 在对应模块实现处理函数
NTSTATUS MyModule_MyNewSyscall(
    PROCESS *proc, SYSCALL_ENTRY *syscall_entry, ULONG_PTR *user_args)
{
    // 检查进程是否在沙箱中
    if (!proc)
        return STATUS_SUCCESS;
    
    // 实现拦截逻辑
    // ...
    
    return STATUS_SUCCESS;
}

// 3. 在 core/dll/ 中添加对应的 Hook（如需要）
```

**优化性能热点**：

```c
// 示例：优化路径查找
// 原代码：每次都遍历列表
for (item = list->head; item; item = item->next) {
    if (wcscmp(item->path, target_path) == 0)
        return item;
}

// 优化：使用哈希表
HASH_MAP path_cache;
map_init(&path_cache, Driver_Pool);
// ... 使用 map_find() 进行 O(1) 查找
```

#### 3.2 修改检查清单

- [ ] 代码符合项目编码规范
- [ ] 添加了必要的注释
- [ ] 处理了错误情况
- [ ] 考虑了多线程安全
- [ ] 更新了相关的头文件
- [ ] 添加了配置项（如需要）
- [ ] 更新了消息文件（如需要）
- [ ] 考虑了向后兼容性
- [ ] x86 和 x64 都能编译

---

### 步骤 4：编译构建

#### 4.1 环境准备

**必需工具**：
- Visual Studio 2019/2022
- Windows SDK 10.0.19041.0+
- WDK (Windows Driver Kit)
- 管理员权限（用于驱动签名和安装）

#### 4.2 编译步骤

**编译驱动**：
```cmd
cd F:\Project\AI\sanbox\Sandboxie\Sandboxie
msbuild SandboxDrv.sln /p:Configuration=Release /p:Platform=x64
```

**编译服务和 DLL**：
```cmd
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=x64
```

**编译 32 位版本**：
```cmd
# 注意：必须先编译 LowLevel (Win32)
msbuild core\low\LowLevel.vcxproj /p:Configuration=Release /p:Platform=Win32
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=Win32
```

#### 4.3 常见编译问题

| 错误 | 原因 | 解决方案 |
|-----|------|---------|
| LNK2001 未解析的外部符号 | 缺少函数实现或库 | 检查函数声明和链接库 |
| C2065 未声明的标识符 | 缺少头文件 | 添加 #include |
| C4013 函数未定义 | 函数声明不匹配 | 检查函数签名 |
| 驱动签名失败 | 缺少证书或测试签名未启用 | 启用测试模式：bcdedit /set testsigning on |

---

### 步骤 5：测试验证

#### 5.1 测试环境准备

**推荐配置**：
- 虚拟机（VMware/VirtualBox/Hyper-V）
- Windows 10/11 测试系统
- 启用测试签名模式
- 安装调试工具（WinDbg/DebugView）

**启用测试签名**：
```cmd
bcdedit /set testsigning on
bcdedit /set nointegritychecks on
shutdown /r /t 0
```

#### 5.2 部署测试版本

**停止现有服务**：
```cmd
net stop SbieSvc
sc stop SbieDrv
```

**替换文件**：
```cmd
# 备份原文件
copy C:\Program Files\Sandboxie-Plus\SbieDrv.sys C:\Program Files\Sandboxie-Plus\SbieDrv.sys.bak
copy C:\Program Files\Sandboxie-Plus\SbieSvc.exe C:\Program Files\Sandboxie-Plus\SbieSvc.exe.bak
copy C:\Program Files\Sandboxie-Plus\SbieDll.dll C:\Program Files\Sandboxie-Plus\SbieDll.dll.bak

# 复制新文件
copy F:\Project\AI\sanbox\Sandboxie\Sandboxie\x64\Release\SbieDrv.sys "C:\Program Files\Sandboxie-Plus\"
copy F:\Project\AI\sanbox\Sandboxie\Sandboxie\x64\Release\SbieSvc.exe "C:\Program Files\Sandboxie-Plus\"
copy F:\Project\AI\sanbox\Sandboxie\Sandboxie\x64\Release\SbieDll.dll "C:\Program Files\Sandboxie-Plus\"
```

**启动服务**：
```cmd
sc start SbieDrv
net start SbieSvc
```

#### 5.3 测试用例

**基础功能测试**：
```
1. 创建新沙箱
2. 在沙箱中运行程序（notepad.exe）
3. 测试文件操作（创建、读取、写入、删除）
4. 测试注册表操作
5. 测试进程隔离（尝试访问沙箱外资源）
6. 测试网络访问
7. 清理沙箱
8. 删除沙箱
```

**性能测试**：
```
1. 启动时间测试
2. 文件 I/O 性能测试
3. 内存使用监控
4. CPU 使用监控
```

**安全测试**：
```
1. 路径逃逸测试
2. 权限提升测试
3. 进程注入测试
4. 符号链接攻击测试
```

#### 5.4 调试技巧

**内核调试**：
```cmd
# 启用内核调试
bcdedit /debug on
bcdedit /dbgsettings serial debugport:1 baudrate:115200

# 使用 WinDbg 连接
# 设置符号路径
.sympath srv*c:\symbols*https://msdl.microsoft.com/download/symbols

# 设置断点
bp SbieDrv!File_NtCreateFile

# 查看日志
!dbgprint
```

**用户态调试**：
```cmd
# 使用 DebugView 查看日志
# 在代码中添加调试输出
DbgPrint("Debug: value = %d\n", value);

# 或使用 Visual Studio 附加到进程
# 调试 → 附加到进程 → 选择 SbieSvc.exe
```

**日志分析**：
```cmd
# 启用详细日志
# 在 Sandboxie.ini 中添加
[GlobalSettings]
TraceLogLevel=*

# 查看日志文件
type "C:\Sandbox\DefaultBox\Trace.log"
```

---

## 🎯 常见修改场景

### 场景 1：修改授权机制

**目标**：移除或修改授权限制

**涉及文件**：
- `core/drv/verify.c` - 证书验证逻辑
- `core/drv/verify.h` - 证书结构定义

**修改步骤**：
```c
// 1. 在 verify.h 中添加宏
#ifndef FORCE_FULL_FEATURES
#define FORCE_FULL_FEATURES 1
#endif

#if FORCE_FULL_FEATURES
#define CERT_IS_LEVEL(cert,l) (1)
#define CERT_HAS_FEATURE(cert,f) (1)
#else
#define CERT_IS_LEVEL(cert,l) (cert.active && cert.level >= (unsigned long)(l))
#define CERT_HAS_FEATURE(cert,f) (cert.f)
#endif

// 2. 在 verify.c 的 Verify_CertInfo 初始化后添加
#ifdef FORCE_FULL_FEATURES
    Verify_CertInfo.type = eCertEternal;
    Verify_CertInfo.level = eCertMaxLevel;
    Verify_CertInfo.opt_desk = 1;
    Verify_CertInfo.opt_net = 1;
    Verify_CertInfo.opt_enc = 1;
    Verify_CertInfo.opt_sec = 1;
    Verify_CertInfo.expirers_in_sec = 0x7FFFFFFF;
#endif
```

**测试**：
- 编译驱动
- 部署并重启服务
- 验证所有高级功能可用

---

### 场景 2：优化文件系统性能

**目标**：减少文件操作延迟

**涉及文件**：
- `core/drv/file.c` - 文件系统虚拟化核心

**优化策略**：
```c
// 1. 添加路径缓存
static HASH_MAP File_PathCache;

// 2. 在 File_Init 中初始化
map_init(&File_PathCache, Driver_Pool);
map_resize(&File_PathCache, 256);

// 3. 在路径解析时使用缓存
WCHAR *cached_path = map_find(&File_PathCache, original_path);
if (cached_path) {
    return cached_path;
}

// 4. 解析后添加到缓存
map_insert(&File_PathCache, original_path, resolved_path, &irql);
```

**测试**：
- 使用文件 I/O 基准测试
- 对比优化前后的性能
- 监控内存使用

---

### 场景 3：增强安全性

**目标**：防止路径逃逸攻击

**涉及文件**：
- `core/drv/file.c` - 路径解析和验证

**增强措施**：
```c
// 1. 添加路径验证函数
BOOLEAN File_ValidatePath(const WCHAR *path) {
    // 检查路径中的危险模式
    if (wcsstr(path, L"..\\") || wcsstr(path, L"../")) {
        return FALSE;  // 拒绝包含 .. 的路径
    }
    
    // 检查符号链接
    if (File_IsSymbolicLink(path)) {
        // 验证符号链接目标
        WCHAR target[512];
        if (File_ResolveSymbolicLink(path, target, 512)) {
            if (!File_IsPathInSandbox(target)) {
                return FALSE;  // 拒绝指向沙箱外的符号链接
            }
        }
    }
    
    return TRUE;
}

// 2. 在文件操作前调用验证
if (!File_ValidatePath(user_path)) {
    return STATUS_ACCESS_DENIED;
}
```

**测试**：
- 尝试各种路径逃逸技术
- 测试符号链接攻击
- 验证正常路径不受影响

---

### 场景 4：添加新的 Hook

**目标**：拦截新的 Windows API

**涉及文件**：
- `core/dll/hook.c` - Hook 框架
- `core/dll/XXX.c` - 对应功能模块

**实现步骤**：
```c
// 1. 声明 Hook 函数
typedef NTSTATUS (*P_NtMyNewApi)(
    HANDLE Handle,
    PVOID Buffer,
    ULONG Length);

P_NtMyNewApi __sys_NtMyNewApi = NULL;

// 2. 实现 Hook 函数
NTSTATUS MyModule_NtMyNewApi(
    HANDLE Handle,
    PVOID Buffer,
    ULONG Length)
{
    // 检查是否在沙箱中
    if (!Dll_IsBoxedProcess)
        return __sys_NtMyNewApi(Handle, Buffer, Length);
    
    // 实现拦截逻辑
    // ...
    
    // 调用原始函数
    return __sys_NtMyNewApi(Handle, Buffer, Length);
}

// 3. 在初始化时注册 Hook
SBIEDLL_HOOK(MyModule_NtMyNewApi);
```

**测试**：
- 编写测试程序调用该 API
- 验证 Hook 被正确触发
- 检查功能是否正常

---

## 📊 性能分析工具

### 内核性能分析

```cmd
# 使用 Windows Performance Analyzer
xperf -on PROC_THREAD+LOADER+PROFILE -stackwalk Profile
# 运行测试
xperf -d trace.etl
# 使用 WPA 分析 trace.etl
```

### 用户态性能分析

```cmd
# 使用 Visual Studio Profiler
# 性能分析器 → 附加到进程 → 选择 SbieSvc.exe
```

### 内存泄漏检测

```c
// 在代码中添加内存跟踪
#ifdef _DEBUG
#define Mem_Alloc(pool, size) Mem_Alloc_Debug(pool, size, __FILE__, __LINE__)
#define Mem_Free(ptr, size) Mem_Free_Debug(ptr, size, __FILE__, __LINE__)
#endif
```

---

## 🔍 代码审查清单

### 安全性
- [ ] 输入验证（用户态传入的指针、路径、大小）
- [ ] 缓冲区溢出检查
- [ ] 整数溢出检查
- [ ] 权限检查（TOCTOU 问题）
- [ ] 路径规范化（防止逃逸）

### 性能
- [ ] 避免不必要的内存分配
- [ ] 使用缓存减少重复计算
- [ ] 优化热路径代码
- [ ] 减少锁竞争
- [ ] 异步处理耗时操作

### 可靠性
- [ ] 错误处理完整
- [ ] 资源清理（内存、句柄）
- [ ] 异常处理
- [ ] 日志记录
- [ ] 断言检查（调试版本）

### 可维护性
- [ ] 代码注释清晰
- [ ] 函数职责单一
- [ ] 命名规范一致
- [ ] 避免魔术数字
- [ ] 代码复用

---

## 📝 提交规范

### Commit Message 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type**：
- `feat`: 新功能
- `fix`: Bug 修复
- `perf`: 性能优化
- `refactor`: 代码重构
- `docs`: 文档更新
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例**：
```
feat(drv): add path validation to prevent escape attacks

- Add File_ValidatePath() function
- Check for ".." patterns in paths
- Validate symbolic link targets
- Add configuration option "StrictPathValidation"

Closes #1234
```

---

## 🚀 快速参考

### 关键文件速查

| 功能 | 驱动层 | DLL 层 | 服务层 |
|-----|--------|--------|--------|
| 文件 | core/drv/file.c | core/dll/file.c | core/svc/fileserver.cpp |
| 注册表 | core/drv/key.c | core/dll/key.c | - |
| 进程 | core/drv/process.c | core/dll/proc.c | core/svc/ProcessServer.cpp |
| 网络 | core/drv/wfp.c | core/dll/net.c | core/svc/iphlpserver.cpp |
| 配置 | core/drv/conf.c | - | core/svc/sbieiniserver.cpp |

### 常用命令

```cmd
# 编译
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=x64

# 停止服务
net stop SbieSvc
sc stop SbieDrv

# 启动服务
sc start SbieDrv
net start SbieSvc

# 查看日志
type "C:\Sandbox\DefaultBox\Trace.log"

# 启用测试签名
bcdedit /set testsigning on
```

---

## 📚 参考资源

### 内部文档
- `docs/ai-analysis/` - 完整的项目分析文档
- `docs/SANDBOXIE_TECHNICAL_ANALYSIS.md` - 技术原理分析
- `docs/LICENSE_REMOVAL_GUIDE.md` - 授权机制分析

### 外部资源
- [Windows Driver Kit Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/)
- [Windows Internals Book](https://docs.microsoft.com/en-us/sysinternals/resources/windows-internals)
- [Sandboxie GitHub](https://github.com/sandboxie-plus/Sandboxie)

---

**Skill 版本**：1.0  
**最后更新**：2026-03-05  
**适用范围**：Sandboxie/Sandboxie/ 核心模块
