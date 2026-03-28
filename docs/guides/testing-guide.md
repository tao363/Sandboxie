# Sandboxie-Plus — 测试指南

本文档描述 Sandboxie-Plus 的测试方法和策略。

---

## 测试框架

### 当前状态

**项目目前没有专门的单元测试框架。**

测试主要依赖以下方式：

1. **手动功能测试** — 通过 SandMan GUI 测试功能
2. **调试构建** — 使用 Debug 配置进行调试
3. **CI 构建** — GitHub Actions 自动构建验证
4. **社区测试** — 发布测试版本供用户测试

### 建议改进

| 优先级 | 建议 | 说明 |
|--------|------|------|
| **高** | 添加单元测试框架 | Google Test 或 Catch2 |
| **高** | 添加集成测试 | 测试核心隔离功能 |
| **中** | 添加架构测试 | 验证依赖规则 |
| **低** | 添加性能测试 | 测试性能回归 |

---

## 测试分类

### 手动测试场景

| 场景 | 步骤 | 预期结果 |
|------|------|----------|
| **基本隔离** | 在沙箱中运行记事本，保存文件 | 文件保存在沙箱目录 |
| **注册表隔离** | 在沙箱中运行 regedit，创建键 | 键创建在沙箱注册表 |
| **进程终止** | 终止沙箱中所有进程 | 所有进程被终止 |
| **快照功能** | 创建快照，修改文件，恢复快照 | 文件恢复到快照状态 |
| **加密沙箱** | 创建加密沙箱，运行程序 | 数据被加密存储 |

### 兼容性测试

| 测试项 | 说明 |
|--------|------|
| **Windows 版本** | Windows 7, 8.1, 10, 11 |
| **架构** | x86, x64 |
| **安全软件** | 杀毒软件、防火墙兼容性 |
| **常见应用** | 浏览器、Office、游戏 |

---

## 调试方法

### 驱动调试

```powershell
# 1. 启用内核调试
bcdedit /debug on
bcdedit /dbgsettings serial debugport:1 baudrate:115200

# 2. 启用测试签名
bcdedit /set testsigning on

# 3. 使用 WinDbg 连接
windbg -k com:port=\\.\pipe\com_1,baud=115200,pipe
```

### DLL 调试

```cpp
// 方法 1：使用 DebugBreak
if (debug_condition) {
    DebugBreak();
}

// 方法 2：使用 OutputDebugString
OutputDebugString(L"SbieDll: Debug message\n");

// 方法 3：使用项目日志
Log_Debug(L"Debug message: %s", value);
```

### GUI 调试

```powershell
# 使用 Visual Studio 调试器附加
devenv /debugexe Bin\x64\Debug\SandMan.exe

# 或在 VS 中直接启动调试
# 设置 SandMan.vcxproj 为启动项目
```

### 日志收集

```powershell
# 启用驱动日志
sc config SbieDrv start= demand

# 使用 DebugView 查看日志
# 下载: https://docs.microsoft.com/en-us/sysinternals/downloads/debugview

# 启用 SbieSvc 日志
# 在 Sandboxie.ini 中添加:
[GlobalSettings]
DebugTrace=y
```

---

## 测试环境

### 推荐测试环境

```
┌─────────────────────────────────────────┐
│           虚拟机测试环境                │
│  ┌─────────────────────────────────┐   │
│  │     Windows 11 (主测试)         │   │
│  │     - 最新功能测试              │   │
│  │     - 回归测试                  │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │     Windows 10 (兼容性)         │   │
│  │     - 广泛兼容性测试            │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │     Windows 7 (遗留)            │   │
│  │     - 最小系统支持测试          │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 虚拟机快照策略

| 快照名称 | 用途 |
|----------|------|
| `Clean` | 干净系统，未安装 Sandboxie |
| `Installed` | 已安装稳定版 Sandboxie |
| `Dev` | 已安装开发版 Sandboxie |

---

## 测试清单

### 发布前测试清单

- [ ] 所有平台构建成功 (x86, x64)
- [ ] 驱动正常加载
- [ ] 服务正常启动
- [ ] GUI 正常显示
- [ ] 基本隔离功能正常
- [ ] 文件重定向正常
- [ ] 注册表重定向正常
- [ ] 进程终止功能正常
- [ ] 快照功能正常
- [ ] 加密沙箱功能正常
- [ ] 网络过滤功能正常
- [ ] 更新功能正常

### 回归测试清单

- [ ] 已知 Bug 未重现
- [ ] 新功能不影响现有功能
- [ ] 性能无明显下降
- [ ] 内存使用无明显增加

---

## 自动化测试建议

### 单元测试框架建议

```cpp
// 使用 Google Test 示例
#include <gtest/gtest.h>

TEST(PathTest, NormalizePath) {
    EXPECT_EQ(NormalizePath(L"C:\\test\\..\\file.txt"), 
              L"C:\\file.txt");
}

TEST(BoxTest, CreateBox) {
    CSandBoxPtr box = CreateTestBox();
    EXPECT_TRUE(box != nullptr);
    EXPECT_EQ(box->GetName(), L"TestBox");
}
```

### 架构测试建议

```cpp
// 验证依赖规则
TEST(ArchitectureTest, NoUpwardDependency) {
    // SandMan 不应直接依赖 SbieDrv
    EXPECT_FALSE(HasDependency("SandMan.exe", "SbieDrv.sys"));
}

TEST(ArchitectureTest, NoCircularDependency) {
    EXPECT_FALSE(HasCircularDependency());
}
```

### 集成测试建议

```cpp
// 测试基本隔离功能
TEST(IntegrationTest, FileIsolation) {
    // 创建测试沙箱
    CSandBoxPtr box = CreateTestBox();
    
    // 在沙箱中创建文件
    RunInSandbox(box, L"cmd /c echo test > C:\\test.txt");
    
    // 验证文件在沙箱目录
    EXPECT_TRUE(FileExists(box->GetFileRoot() + L"\\C\\test.txt"));
    
    // 验证文件不在真实目录
    EXPECT_FALSE(FileExists(L"C:\\test.txt"));
}
```

---

## CI 测试

### GitHub Actions 工作流

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [master, experimental]
  pull_request:
    branches: [master]

jobs:
  build:
    runs-on: windows-2022
    steps:
      - uses: actions/checkout@v4
      
      - name: Build
        run: |
          msbuild Sandboxie/Sandbox.sln /p:Configuration=Release /p:Platform=x64
          msbuild SandboxiePlus/SandboxiePlus.sln /p:Configuration=Release /p:Platform=x64
      
      - name: Run Tests
        run: |
          # TODO: 添加测试命令
          echo "Tests not implemented yet"
```

---

## 测试报告

### Bug 报告模板

```markdown
## 问题描述
[简短描述问题]

## 复现步骤
1. [步骤 1]
2. [步骤 2]
3. [步骤 3]

## 预期结果
[描述预期行为]

## 实际结果
[描述实际行为]

## 环境信息
- Windows 版本:
- Sandboxie 版本:
- 其他安全软件:

## 日志/截图
[附上相关日志或截图]
```

---

## 相关文档

- [入门指南](getting-started.md) — 开发环境设置
- [构建系统](../architecture/build-system.md) — 构建说明
- [安全模型](../architecture/security-model.md) — 安全测试注意事项
