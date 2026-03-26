# Sandboxie-Plus — Agent Navigation Map

> **入口点。** 本文件约 100 行，仅作导航索引。深层知识存储在 `docs/` 目录中。
> 首先阅读本文，然后按需跳转到对应文档。

---

## 项目一句话描述

Sandboxie-Plus 是一个开源 Windows 沙箱隔离软件，通过内核驱动拦截系统调用，将进程的文件/注册表/IPC 操作重定向到沙箱目录，实现进程隔离而不影响用户体验。

---

## 三层核心架构

```
SbieDrv.sys (内核驱动) ← 系统调用拦截 & 强制隔离策略
    ↕ IOCTL
SbieSvc.exe (系统服务) ← 进程管理 & 配置 & 权限代理
    ↕ LPC / Named Pipe
SbieDll.dll (注入 DLL)  ← 用户态 Hook & 路径重定向
    ↕ 注入到每个沙箱进程
SandMan.exe (Qt GUI)    ← Plus 版管理界面
```

---

## 文档索引

| 文档 | 内容 | 何时阅读 |
|------|------|----------|
| [docs/architecture/overview.md](docs/architecture/overview.md) | 架构总览、系统图、组件清单 | 首次了解项目 |
| [docs/architecture/components.md](docs/architecture/components.md) | 各组件详细接口和数据结构 | 修改特定组件 |
| [docs/architecture/dependency-rules.md](docs/architecture/dependency-rules.md) | 分层依赖规则 | 新增模块或修改依赖 |
| [docs/architecture/build-system.md](docs/architecture/build-system.md) | 构建系统完整说明 | 构建项目 |
| [docs/architecture/security-model.md](docs/architecture/security-model.md) | 安全边界和敏感区域 | 修改安全相关代码 |
| [docs/guides/coding-conventions.md](docs/guides/coding-conventions.md) | 编码约定 | 编写代码 |
| [docs/guides/getting-started.md](docs/guides/getting-started.md) | 新贡献者入门指南 | 开始贡献 |
| [docs/guides/testing-guide.md](docs/guides/testing-guide.md) | 测试方法和策略 | 测试代码 |
| [docs/beliefs.md](docs/beliefs.md) | 核心信念和工程原则 | 面临设计决策 |
| [docs/quality.md](docs/quality.md) | 各域质量评级 | 了解项目现状 |
| [docs/domain-map.md](docs/domain-map.md) | 业务域划分 | 理解模块边界 |
| [docs/glossary.md](docs/glossary.md) | 项目术语表 | 理解专业术语 |
| [docs/plans/tech-debt.md](docs/plans/tech-debt.md) | 技术债务跟踪 | 规划改进工作 |

---

## 核心命令

### 构建

```powershell
# 构建核心组件
msbuild Sandboxie\Sandbox.sln /p:Configuration=Release /p:Platform=x64

# 构建 Plus GUI
msbuild SandboxiePlus\SandboxiePlus.sln /p:Configuration=Release /p:Platform=x64
```

### 测试

```powershell
# 启用测试签名模式（需要管理员权限）
bcdedit /set testsigning on

# 使用 DebugView 查看日志
# 下载: https://docs.microsoft.com/en-us/sysinternals/downloads/debugview
```

### 代码质量

```powershell
# 使用 Visual Studio 代码分析
msbuild Sandbox.sln /p:RunCodeAnalysis=true
```

---

## 关键规则

1. **必须通过 API 层访问核心功能** — GUI 禁止直接调用驱动
2. **必须验证所有来自沙箱进程的数据** — 沙箱进程不可信
3. **必须使用安全字符串函数** — 禁止 `strcpy`, `sprintf` 等
4. **内核代码禁止使用标准 C 运行时** — 使用内核专用函数
5. **敏感数据使用后必须清零** — 密码、密钥等
6. **禁止绕过权限检查** — 安全关键路径
7. **禁止在日志中输出敏感数据** — 密码、密钥等
8. **修改驱动代码需要安全审查** — 高风险区域

---

## 高风险区域

修改以下区域需要额外谨慎，建议使用 `/careful` 或 `/freeze`：

| 区域 | 路径 | 风险 |
|------|------|------|
| 内核驱动 | `Sandboxie/core/drv/` | 系统崩溃、安全漏洞 |
| Token 创建 | `Sandboxie/core/drv/token.c` | 权限提升 |
| 系统调用拦截 | `Sandboxie/core/drv/syscall*.c` | 隔离失效 |
| 加密实现 | `SandboxieTools/ImBox/dc/` | 数据泄露 |
| 注入代码 | `Sandboxie/core/dll/hook*.c` | 进程崩溃 |

---

## 提交规范

```
<type>(<scope>): <subject>

类型: feat | fix | docs | style | refactor | test | chore
范围: drv | dll | svc | gui | api | tools
```

---

## 相关技能

- `/sandboxie-analyzer` — 深度分析 Sandboxie 代码
- `/sandboxie-modifier` — 修改和测试 Sandboxie 核心模块
