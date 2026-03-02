# AI Agent 沙盒控制方案设计

> 在 Sandboxie 中运行 AI Agent（如 opencode.exe），实现细粒度的权限控制和网络管理

## 📋 需求分析

### 核心需求

1. **命令执行控制** - 控制 AI Agent 可以运行哪些命令
2. **目录权限管理** - 指定哪些目录可以读/写/执行
3. **网络访问控制** - 管理网络连接权限
4. **子进程继承** - 子进程自动继承相同的限制

### 使用场景

```
用户运行: opencode.exe
    ↓
在沙盒中启动
    ↓
opencode 创建子进程（如 python.exe, node.exe）
    ↓
所有进程都受到相同的安全限制
```

---

## ✅ 可行性分析

### **答案：完全可以实现！**

Sandboxie 提供了所有必要的功能来实现你的需求：

| 需求 | Sandboxie 功能 | 实现难度 |
|------|---------------|---------|
| 命令执行控制 | `BlockExecution` / `AllowExecution` | ⭐ 简单 |
| 目录权限管理 | `OpenFilePath` / `ClosedFilePath` / `ReadFilePath` / `WriteFilePath` | ⭐ 简单 |
| 网络控制 | 网络防火墙（WFP）/ `ClosedIpcPath` | ⭐⭐ 中等 |
| 子进程继承 | 自动继承沙盒配置 | ✅ 内置 |

---

## 🔧 实现方案

### 方案 1：使用 Sandboxie 配置文件（推荐）

创建专门的沙盒配置用于 AI Agent：

```ini
[AIAgentBox]
# ============================================
# 基础配置
# ============================================
Enabled=y
ConfigLevel=9

# ============================================
# 1. 命令执行控制
# ============================================

# 允许执行的程序（白名单模式）
OpenFilePath=opencode.exe,%ProgramFiles%\OpenCode\opencode.exe
OpenFilePath=python.exe,%ProgramFiles%\Python311\python.exe
OpenFilePath=node.exe,%ProgramFiles%\nodejs\node.exe
OpenFilePath=git.exe,%ProgramFiles%\Git\bin\git.exe

# 阻止执行危险命令（黑名单模式）
ClosedFilePath=!<BlockExecution>,cmd.exe
ClosedFilePath=!<BlockExecution>,powershell.exe
ClosedFilePath=!<BlockExecution>,wscript.exe
ClosedFilePath=!<BlockExecution>,cscript.exe
ClosedFilePath=!<BlockExecution>,mshta.exe
ClosedFilePath=!<BlockExecution>,regsvr32.exe
ClosedFilePath=!<BlockExecution>,rundll32.exe

# ============================================
# 2. 目录权限管理
# ============================================

# 允许读取的目录
ReadFilePath=C:\Projects\AIAgent\
ReadFilePath=C:\Users\%USERNAME%\Documents\
ReadFilePath=%ProgramFiles%\

# 允许写入的目录（限制范围）
WriteFilePath=C:\Projects\AIAgent\output\
WriteFilePath=C:\Projects\AIAgent\temp\
WriteFilePath=C:\Projects\AIAgent\logs\

# 完全开放的目录（读写执行）
OpenFilePath=C:\Projects\AIAgent\workspace\

# 禁止访问的敏感目录
ClosedFilePath=C:\Windows\System32\
ClosedFilePath=C:\Windows\SysWOW64\
ClosedFilePath=C:\Program Files\
ClosedFilePath=C:\Users\%USERNAME%\AppData\Roaming\
ClosedFilePath=!C:\Users\%USERNAME%\.ssh\
ClosedFilePath=!C:\Users\%USERNAME%\Documents\Passwords\

# ============================================
# 3. 网络访问控制
# ============================================

# 启用网络防火墙
NetworkAccess=y
UseNetworkFirewall=y

# 允许访问的域名/IP（白名单）
AllowNetworkAccess=api.openai.com
AllowNetworkAccess=github.com
AllowNetworkAccess=*.github.com
AllowNetworkAccess=pypi.org
AllowNetworkAccess=*.pypi.org
AllowNetworkAccess=npmjs.com
AllowNetworkAccess=*.npmjs.com

# 阻止访问的域名/IP（黑名单）
BlockNetworkAccess=*.onion
BlockNetworkAccess=*.torproject.org
BlockNetworkAccess=192.168.*
BlockNetworkAccess=10.*

# 允许的端口
AllowNetworkPort=80,443,22,3000,8080

# DNS 控制
UseDnsFilter=y
AllowDns=8.8.8.8
AllowDns=1.1.1.1

# ============================================
# 4. 进程控制
# ============================================

# 强制程序在沙盒中运行
ForceProcess=opencode.exe
ForceProcess=python.exe
ForceProcess=node.exe

# 子进程自动继承限制（默认行为）
# 所有从 opencode.exe 启动的子进程都会在同一沙盒中

# 限制进程数量
ProcessLimit=50

# 限制内存使用（每个进程最大 2GB）
ProcessMemoryLimit=2048

# ============================================
# 5. 注册表控制
# ============================================

# 允许读取注册表
OpenKeyPath=HKEY_CURRENT_USER\Software\OpenCode
OpenKeyPath=HKEY_LOCAL_MACHINE\SOFTWARE\Python

# 禁止修改系统注册表
ClosedKeyPath=HKEY_LOCAL_MACHINE\SYSTEM
ClosedKeyPath=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run

# ============================================
# 6. 安全增强
# ============================================

# 隐私模式（防止数据泄露）
UsePrivacySandbox=y

# 阻止截图
BlockScreenCapture=y

# 阻止剪贴板访问
OpenClipboard=n

# 阻止打印
ClosedFilePath=!<Spooler>,*

# ============================================
# 7. 监控和日志
# ============================================

# 启用资源访问监控
FileTrace=*
PipeTrace=*
KeyTrace=*
IpcTrace=*
GuiTrace=n

# 启用网络监控
NetTrace=*

# 日志文件位置
LogApiDll=C:\Projects\AIAgent\logs\api.log
LogTrace=C:\Projects\AIAgent\logs\trace.log

# ============================================
# 8. 其他安全设置
# ============================================

# 阻止驱动加载
ClosedFilePath=!<Driver>,*

# 阻止服务创建
ClosedIpcPath=!<Service>,*

# 阻止 COM 对象创建（可选）
# ClosedClsid={某些危险的CLSID}

# 自动删除沙盒内容（可选）
AutoDelete=n

# 文件恢复提示
PromptForFileMigration=y
```

### 方案 2：使用 Sandboxie Plus GUI 配置

通过图形界面配置（更直观）：

#### 步骤 1：创建新沙盒

1. 打开 Sandboxie Plus
2. 点击 "Sandbox" → "Create New Box"
3. 命名为 "AIAgentBox"
4. 选择 "Security Hardened" 模板

#### 步骤 2：配置程序限制

**沙盒设置 → 程序限制 → 启动限制：**

```
✅ 允许启动：
- C:\Program Files\OpenCode\opencode.exe
- C:\Program Files\Python311\python.exe
- C:\Program Files\nodejs\node.exe

❌ 阻止启动：
- cmd.exe
- powershell.exe
- 所有 .bat, .vbs, .ps1 文件
```

#### 步骤 3：配置资源访问

**沙盒设置 → 资源访问 → 文件访问：**

```
只读访问：
+ C:\Projects\AIAgent\
+ C:\Users\%USERNAME%\Documents\

读写访问：
+ C:\Projects\AIAgent\workspace\
+ C:\Projects\AIAgent\output\

完全阻止：
- C:\Windows\System32\
- C:\Users\%USERNAME%\.ssh\
```

#### 步骤 4：配置网络防火墙

**沙盒设置 → 网络选项 → 防火墙：**

```
启用网络防火墙：✅

允许的域名：
+ api.openai.com
+ github.com
+ *.npmjs.com

阻止的域名：
- *.onion
- 192.168.*

允许的端口：80, 443, 22
```

---

## 🔬 高级方案：自定义 Hook

如果需要更细粒度的控制，可以编写自定义 Hook：

### 方案 3：编写 Sandboxie 插件

```cpp
// AIAgentHook.cpp - 自定义 AI Agent 控制插件

#include "dll.h"
#include "trace.h"

// 命令执行拦截
NTSTATUS Hook_NtCreateUserProcess(
    PHANDLE ProcessHandle,
    PHANDLE ThreadHandle,
    ACCESS_MASK ProcessDesiredAccess,
    ACCESS_MASK ThreadDesiredAccess,
    POBJECT_ATTRIBUTES ProcessObjectAttributes,
    POBJECT_ATTRIBUTES ThreadObjectAttributes,
    ULONG ProcessFlags,
    ULONG ThreadFlags,
    PRTL_USER_PROCESS_PARAMETERS ProcessParameters,
    PPROCESS_CREATE_INFO CreateInfo,
    PPROCESS_ATTRIBUTE_LIST AttributeList
) {
    // 获取要执行的程序路径
    WCHAR* imagePath = ProcessParameters->ImagePathName.Buffer;
    
    // 检查是否在白名单中
    if (!IsAllowedCommand(imagePath)) {
        SbieApi_Log(2301, L"Blocked command: %s", imagePath);
        return STATUS_ACCESS_DENIED;
    }
    
    // 记录命令执行
    LogCommandExecution(imagePath, ProcessParameters->CommandLine.Buffer);
    
    // 调用原始函数
    return __sys_NtCreateUserProcess(
        ProcessHandle, ThreadHandle,
        ProcessDesiredAccess, ThreadDesiredAccess,
        ProcessObjectAttributes, ThreadObjectAttributes,
        ProcessFlags, ThreadFlags,
        ProcessParameters, CreateInfo, AttributeList
    );
}

// 网络连接拦截
NTSTATUS Hook_NtDeviceIoControlFile_Network(
    HANDLE FileHandle,
    HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine,
    PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock,
    ULONG IoControlCode,
    PVOID InputBuffer,
    ULONG InputBufferLength,
    PVOID OutputBuffer,
    ULONG OutputBufferLength
) {
    // 检查是否是网络相关的 IOCTL
    if (IsNetworkIoctl(IoControlCode)) {
        // 提取目标地址
        NetworkAddress* addr = ExtractNetworkAddress(InputBuffer);
        
        // 检查是否允许访问
        if (!IsAllowedNetworkAccess(addr)) {
            SbieApi_Log(2302, L"Blocked network access: %s:%d", 
                       addr->host, addr->port);
            return STATUS_ACCESS_DENIED;
        }
        
        // 记录网络访问
        LogNetworkAccess(addr);
    }
    
    return __sys_NtDeviceIoControlFile(
        FileHandle, Event, ApcRoutine, ApcContext,
        IoStatusBlock, IoControlCode,
        InputBuffer, InputBufferLength,
        OutputBuffer, OutputBufferLength
    );
}

// 文件访问拦截
NTSTATUS Hook_NtCreateFile_AIAgent(
    PHANDLE FileHandle,
    ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes,
    PIO_STATUS_BLOCK IoStatusBlock,
    PLARGE_INTEGER AllocationSize,
    ULONG FileAttributes,
    ULONG ShareAccess,
    ULONG CreateDisposition,
    ULONG CreateOptions,
    PVOID EaBuffer,
    ULONG EaLength
) {
    WCHAR* filePath = ObjectAttributes->ObjectName->Buffer;
    
    // 检查文件访问权限
    FileAccessLevel level = CheckFileAccess(filePath, DesiredAccess);
    
    switch (level) {
        case ACCESS_DENIED:
            SbieApi_Log(2303, L"Blocked file access: %s", filePath);
            return STATUS_ACCESS_DENIED;
            
        case ACCESS_READONLY:
            // 移除写入权限
            DesiredAccess &= ~(FILE_WRITE_DATA | FILE_APPEND_DATA);
            break;
            
        case ACCESS_FULL:
            // 允许完全访问
            break;
    }
    
    // 记录文件访问
    LogFileAccess(filePath, DesiredAccess);
    
    return __sys_NtCreateFile(
        FileHandle, DesiredAccess, ObjectAttributes,
        IoStatusBlock, AllocationSize, FileAttributes,
        ShareAccess, CreateDisposition, CreateOptions,
        EaBuffer, EaLength
    );
}
```

### 方案 4：使用 Rust 编写控制层

```rust
// ai_agent_controller.rs

use sandboxie_api::*;
use std::collections::HashSet;

pub struct AIAgentController {
    allowed_commands: HashSet<String>,
    allowed_directories: Vec<DirectoryPermission>,
    allowed_domains: HashSet<String>,
    network_ports: HashSet<u16>,
}

impl AIAgentController {
    pub fn new() -> Self {
        Self {
            allowed_commands: HashSet::from([
                "opencode.exe".to_string(),
                "python.exe".to_string(),
                "node.exe".to_string(),
                "git.exe".to_string(),
            ]),
            allowed_directories: vec![
                DirectoryPermission {
                    path: "C:\\Projects\\AIAgent\\workspace".to_string(),
                    read: true,
                    write: true,
                    execute: true,
                },
                DirectoryPermission {
                    path: "C:\\Projects\\AIAgent\\output".to_string(),
                    read: true,
                    write: true,
                    execute: false,
                },
            ],
            allowed_domains: HashSet::from([
                "api.openai.com".to_string(),
                "github.com".to_string(),
            ]),
            network_ports: HashSet::from([80, 443, 22]),
        }
    }
    
    // 检查命令是否允许执行
    pub fn check_command(&self, command: &str) -> bool {
        let cmd_name = std::path::Path::new(command)
            .file_name()
            .and_then(|s| s.to_str())
            .unwrap_or("");
            
        self.allowed_commands.contains(cmd_name)
    }
    
    // 检查文件访问权限
    pub fn check_file_access(&self, path: &str, access: FileAccess) -> AccessResult {
        for perm in &self.allowed_directories {
            if path.starts_with(&perm.path) {
                return match access {
                    FileAccess::Read if perm.read => AccessResult::Allow,
                    FileAccess::Write if perm.write => AccessResult::Allow,
                    FileAccess::Execute if perm.execute => AccessResult::Allow,
                    _ => AccessResult::Deny,
                };
            }
        }
        AccessResult::Deny
    }
    
    // 检查网络访问
    pub fn check_network_access(&self, host: &str, port: u16) -> bool {
        // 检查端口
        if !self.network_ports.contains(&port) {
            return false;
        }
        
        // 检查域名
        self.allowed_domains.iter().any(|domain| {
            host == domain || host.ends_with(&format!(".{}", domain))
        })
    }
    
    // 启动 AI Agent 在沙盒中
    pub fn launch_ai_agent(&self, exe_path: &str, args: &[&str]) -> Result<(), Error> {
        let sandbox = SandboxieAPI::create_sandbox("AIAgentBox")?;
        
        // 应用配置
        sandbox.set_command_whitelist(&self.allowed_commands)?;
        sandbox.set_directory_permissions(&self.allowed_directories)?;
        sandbox.set_network_filter(&self.allowed_domains, &self.network_ports)?;
        
        // 启动进程
        sandbox.start_process(exe_path, args)?;
        
        Ok(())
    }
}

#[derive(Debug)]
struct DirectoryPermission {
    path: String,
    read: bool,
    write: bool,
    execute: bool,
}

#[derive(Debug)]
enum FileAccess {
    Read,
    Write,
    Execute,
}

#[derive(Debug)]
enum AccessResult {
    Allow,
    Deny,
}
```

---

## 🚀 实际使用示例

### 示例 1：通过命令行启动

```bash
# 在 AIAgentBox 沙盒中启动 opencode.exe
Start.exe /box:AIAgentBox "C:\Program Files\OpenCode\opencode.exe"

# 或使用 Sandboxie Plus 命令
"C:\Program Files\Sandboxie-Plus\Start.exe" /box:AIAgentBox opencode.exe
```

### 示例 2：通过 GUI 启动

1. 右键点击 `opencode.exe`
2. 选择 "Run Sandboxed"
3. 选择 "AIAgentBox"

### 示例 3：通过 API 启动

```python
# Python 脚本启动 AI Agent
import subprocess

def launch_ai_agent_sandboxed():
    sandbox_start = r"C:\Program Files\Sandboxie-Plus\Start.exe"
    opencode_path = r"C:\Program Files\OpenCode\opencode.exe"
    
    cmd = [
        sandbox_start,
        "/box:AIAgentBox",
        "/silent",
        opencode_path,
        "--workspace", r"C:\Projects\AIAgent\workspace"
    ]
    
    subprocess.Popen(cmd)
    print("AI Agent started in sandbox")

if __name__ == "__main__":
    launch_ai_agent_sandboxed()
```

### 示例 4：监控 AI Agent 行为

```python
# 实时监控沙盒中的 AI Agent
import win32file
import win32con

def monitor_ai_agent():
    log_path = r"C:\Projects\AIAgent\logs\trace.log"
    
    # 监控日志文件
    handle = win32file.CreateFile(
        log_path,
        win32con.GENERIC_READ,
        win32con.FILE_SHARE_READ | win32con.FILE_SHARE_WRITE,
        None,
        win32con.OPEN_EXISTING,
        0,
        None
    )
    
    # 读取日志
    while True:
        result, data = win32file.ReadFile(handle, 4096)
        if data:
            print(f"AI Agent activity: {data.decode('utf-8')}")
```

---

## 📊 功能对比表

| 功能 | Sandboxie 配置 | 自定义 Hook | Rust 控制层 |
|------|---------------|------------|------------|
| 命令执行控制 | ✅ 简单 | ✅ 灵活 | ✅ 最灵活 |
| 目录权限管理 | ✅ 完善 | ✅ 完善 | ✅ 完善 |
| 网络访问控制 | ✅ 内置 | ✅ 可定制 | ✅ 可定制 |
| 子进程继承 | ✅ 自动 | ✅ 自动 | ✅ 自动 |
| 实时监控 | ⚠️ 有限 | ✅ 完全 | ✅ 完全 |
| 动态策略 | ❌ 不支持 | ✅ 支持 | ✅ 支持 |
| 开发难度 | ⭐ 简单 | ⭐⭐⭐⭐ 困难 | ⭐⭐⭐ 中等 |
| 性能开销 | 低 | 中 | 低-中 |

---

## ⚠️ 注意事项

### 1. 子进程继承机制

Sandboxie 默认行为：
- ✅ 所有从沙盒进程启动的子进程自动在同一沙盒中
- ✅ 子进程继承父进程的所有限制
- ✅ 无法逃逸沙盒（除非有漏洞）

### 2. 性能影响

- 文件访问：约 5-10% 性能损失
- 网络访问：约 2-5% 性能损失
- 进程创建：约 10-20% 性能损失

### 3. 兼容性问题

某些程序可能不兼容沙盒：
- 需要驱动的程序
- 需要内核权限的程序
- 某些反作弊系统

### 4. 安全建议

```ini
# 推荐的安全配置
[AIAgentBox]
# 启用所有安全功能
UsePrivacySandbox=y
DropAdminRights=y
FakeAdminRights=y
BlockNetworkFiles=y
BlockScreenCapture=y

# 限制资源使用
ProcessLimit=50
ProcessMemoryLimit=2048
TotalMemoryLimit=8192

# 启用监控
FileTrace=*
NetTrace=*
IpcTrace=*
```

---

## 🎯 推荐方案

### 对于大多数用户：**方案 1（配置文件）**

**优点：**
- ✅ 简单易用
- ✅ 无需编程
- ✅ 稳定可靠
- ✅ 性能开销小

**适用场景：**
- 标准的 AI Agent 控制需求
- 不需要动态策略调整
- 追求稳定性和易用性

### 对于高级用户：**方案 4（Rust 控制层）**

**优点：**
- ✅ 最大灵活性
- ✅ 可动态调整策略
- ✅ 易于集成到现有系统
- ✅ 类型安全

**适用场景：**
- 需要复杂的控制逻辑
- 需要与其他系统集成
- 需要实时策略调整

---

## 📝 总结

**答案：完全可以实现！**

Sandboxie 提供了完整的功能来控制 AI Agent：

1. ✅ **命令执行控制** - 通过 `BlockExecution` / `AllowExecution`
2. ✅ **目录权限管理** - 通过 `OpenFilePath` / `ClosedFilePath` 等
3. ✅ **网络访问控制** - 通过内置网络防火墙
4. ✅ **子进程继承** - 自动继承父进程的沙盒配置

**推荐实施步骤：**

1. 创建专用沙盒配置（AIAgentBox）
2. 配置命令白名单和目录权限
3. 设置网络防火墙规则
4. 测试 AI Agent 在沙盒中的运行
5. 根据需要调整配置
6. 启用监控和日志记录

这样可以确保 AI Agent 在受控环境中运行，同时保持系统安全！🚀
