# Sandboxie-Plus — 入门指南

本指南帮助新贡献者（人类或 AI）快速开始 Sandboxie-Plus 的开发工作。

---

## 环境准备

### 必需软件

| 软件 | 版本 | 下载链接 |
|------|------|----------|
| **Visual Studio 2022** | 17.14+ | [官网](https://visualstudio.microsoft.com/) |
| **Qt** | 6.8.3 | [官网](https://www.qt.io/) 或 aqtinstall |
| **Git** | 最新版 | [官网](https://git-scm.com/) |
| **Windows SDK** | 10.0.19041+ | VS 安装器 |

### Visual Studio 工作负载

安装 Visual Studio 时，选择以下工作负载：

- ✅ 使用 C++ 的桌面开发
- ✅ Windows 10/11 SDK
- ✅ C++ ATL for latest v143 build tools (可选)

### Qt 安装

推荐使用 aqtinstall：

```powershell
# 安装 aqtinstall
pip install aqtinstall

# 安装 Qt 6.8.3
aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 -O C:\Qt

# 设置环境变量
set Qt6_DIR=C:\Qt\6.8.3\msvc2022_64
set PATH=%Qt6_DIR%\bin;%PATH%
```

---

## 首次构建

### 1. 克隆仓库

```powershell
git clone https://github.com/sandboxie-plus/Sandboxie.git
cd Sandboxie
```

### 2. 构建核心组件

```powershell
# 打开 Visual Studio 开发者命令提示符
# 或在 PowerShell 中运行
& "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1"

# 构建核心组件
cd Sandboxie
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=x64
```

### 3. 构建 Plus GUI

```powershell
cd ..\SandboxiePlus
msbuild SandboxiePlus.sln /p:Configuration=Release /p:Platform=x64
```

### 4. 验证构建

```powershell
# 检查输出文件
dir Bin\x64\Release\

# 应该看到以下文件：
# SbieDrv.sys  - 内核驱动
# SbieDll.dll  - 注入 DLL
# SbieSvc.exe  - 系统服务
# SandMan.exe  - Plus GUI
```

---

## 项目导航

### 最重要的三个文件

1. **[Sandboxie/core/drv/driver.c](../../Sandboxie/core/drv/driver.c)**  
   驱动入口点，理解系统调用拦截的起点

2. **[Sandboxie/core/dll/dllmain.c](../../Sandboxie/core/dll/dllmain.c)**  
   DLL 入口点，理解用户态 Hook 的起点

3. **[SandboxiePlus/SandMan/SandMan.cpp](../../SandboxiePlus/SandMan/SandMan.cpp)**  
   Plus GUI 主窗口，理解用户界面的起点

### 关键目录

```
Sandboxie/
├── core/
│   ├── drv/      ← 内核驱动（最高风险区域）
│   ├── dll/      ← 注入 DLL
│   ├── svc/      ← 系统服务
│   └── low/      ← 低级注入代码
├── apps/
│   ├── control/  ← Classic GUI
│   └── start/    ← 启动器
└── common/       ← 共享定义

SandboxiePlus/
├── SandMan/      ← Plus GUI
├── QSbieAPI/     ← API 封装层
└── MiscHelpers/  ← 辅助库

SandboxieTools/
├── ImBox/        ← 加密沙箱工具
└── UpdUtil/      ← 更新工具
```

---

## 做你的第一个修改

### 示例：添加一个新的日志消息

这是一个安全的、端到端的修改示例。

#### 步骤 1：找到目标文件

假设我们要在驱动初始化时添加一条日志消息。

打开 `Sandboxie/core/drv/driver.c`

#### 步骤 2：添加日志消息

```c
// 在 DriverEntry 函数中添加
NTSTATUS DriverEntry(
    PDRIVER_OBJECT DriverObject,
    PUNICODE_STRING RegistryPath)
{
    // ... 现有代码 ...
    
    // 添加你的日志消息
    Log_Msg0(MSG_DRIVER_LOADED);  // 使用现有消息 ID
    
    // 或者使用自定义格式
    DbgPrint("Sandboxie: Driver loaded successfully\n");
    
    // ... 现有代码 ...
}
```

#### 步骤 3：重新构建

```powershell
msbuild Sandbox.sln /p:Configuration=Debug /p:Platform=x64
```

#### 步骤 4：测试

```powershell
# 启用测试签名模式（需要管理员权限）
bcdedit /set testsigning on

# 复制驱动到测试位置
copy Bin\x64\Debug\SbieDrv.sys C:\Windows\System32\drivers\

# 重启驱动
sc stop SbieDrv
sc start SbieDrv

# 使用 DebugView 查看日志
# 下载 DebugView: https://docs.microsoft.com/en-us/sysinternals/downloads/debugview
```

---

## 运行测试

### 测试框架

项目目前没有专门的单元测试框架。测试主要依赖：

1. **手动测试** — 使用 SandMan GUI 测试功能
2. **调试构建** — 使用 Debug 配置进行调试
3. **CI 测试** — GitHub Actions 自动构建测试

### 调试技巧

#### 调试驱动

```powershell
# 启用内核调试
bcdedit /debug on
bcdedit /dbgsettings serial debugport:1 baudrate:115200

# 使用 WinDbg 连接
windbg -k com:port=\\.\pipe\com_1,baud=115200,pipe
```

#### 调试 DLL

```cpp
// 在代码中添加断点
DebugBreak();

// 或使用 OutputDebugString
OutputDebugString(L"SbieDll: Hook installed\n");
```

#### 调试 GUI

```powershell
# 使用 Visual Studio 调试器
devenv /debugexe Bin\x64\Debug\SandMan.exe
```

---

## 提交规范

### Commit 消息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 重构 |
| `test` | 测试相关 |
| `chore` | 构建/工具相关 |

### 示例

```
feat(drv): add support for Windows 11 24H2

- Update syscall table for new kernel version
- Add compatibility checks in driver init

Closes #1234
```

### 分支命名

```
feature/add-new-feature
fix/fix-bug-1234
docs/update-readme
```

### PR 流程

1. Fork 仓库
2. 创建功能分支
3. 提交更改
4. 推送到 Fork
5. 创建 Pull Request
6. 等待代码审查

---

## 常见问题

### Q: 构建失败，找不到 Qt？

```powershell
# 设置 Qt 环境变量
set Qt6_DIR=C:\Qt\6.8.3\msvc2022_64
set PATH=%Qt6_DIR%\bin;%PATH%
```

### Q: 驱动加载失败？

```powershell
# 启用测试签名模式
bcdedit /set testsigning on
# 重启系统
```

### Q: 如何调试沙箱进程？

1. 使用 Debug 构建配置
2. 在 SandMan 中启用"调试选项"
3. 使用 WinDbg 或 x64dbg 附加到进程

### Q: 如何贡献翻译？

1. 编辑 `SandboxiePlus/SandMan/sandman_xx.ts` 文件
2. 使用 Qt Linguist 工具
3. 提交 PR

---

## 相关文档

- [架构总览](../architecture/overview.md) — 系统整体架构
- [编码约定](coding-conventions.md) — 代码风格指南
- [构建系统](../architecture/build-system.md) — 详细构建说明
- [安全模型](../architecture/security-model.md) — 安全开发规则
