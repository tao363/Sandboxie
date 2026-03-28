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
| **[架构概览](docs/architecture/overview.md)** | 系统架构、组件清单、数据流 | 理解整体设计 |
| **[组件详解](docs/architecture/components.md)** | 各组件职责、接口、关键文件 | 修改特定组件 |
| **[依赖规则](docs/architecture/dependency-rules.md)** | 分层架构、依赖方向、违规示例 | 添加新代码 |
| **[构建系统](docs/architecture/build-system.md)** | 编译环境、构建步骤、常见问题 | 编译项目 |
| **[安全模型](docs/architecture/security-model.md)** | 安全边界、威胁模型、敏感代码 | 安全相关修改 |

---

## 开发指南

| 文档 | 内容 | 何时阅读 |
|------|------|----------|
| **[入门指南](docs/guides/getting-started.md)** | 环境配置、首次编译、调试方法 | 新贡献者必读 |
| **[编码规范](docs/guides/coding-conventions.md)** | 代码风格、命名约定、注释规范 | 提交代码前 |
| **[测试指南](docs/guides/testing-guide.md)** | 测试策略、测试方法、覆盖率 | 添加测试 |

---

## 治理文档

| 文档 | 内容 | 何时阅读 |
|------|------|----------|
| **[核心理念](docs/beliefs.md)** | 工程原则、决策依据 | 理解项目价值观 |
| **[质量评级](docs/quality.md)** | 各域质量评分、改进方向 | 评估代码质量 |
| **[域地图](docs/domain-map.md)** | 业务域划分、边界定义 | 跨域修改 |
| **[术语表](docs/glossary.md)** | 项目术语、缩写解释 | 阅读代码时 |

---

## 计划与决策

| 目录 | 内容 | 何时阅读 |
|------|------|----------|
| **[docs/design/](docs/design/)** | 设计文档、RFC | 设计新功能 |
| **[docs/plans/](docs/plans/)** | 执行计划、进度追踪 | 了解进行中工作 |
| **[docs/adr/](docs/adr/)** | 架构决策记录 | 理解历史决策 |

---

## 关键源码路径

| 组件 | 路径 | 核心文件 |
|------|------|----------|
| 内核驱动 | `Sandboxie/core/drv/` | `driver.c`, `syscall.c` |
| 系统服务 | `Sandboxie/core/svc/` | `services.c`, `pipe.c` |
| 注入 DLL | `Sandboxie/core/dll/` | `dllmain.c`, `hook.c` |
| Qt GUI | `Sandboxie/plus/` | `SandMan.cpp`, `Views/` |
| 加密沙箱 | `Sandboxie/core/drv/crypto/` | `crypto.c` |

---

## 快速任务指南

| 任务 | 起点 |
|------|------|
| 修复 Bug | [组件详解](docs/architecture/components.md) → 定位组件 → 阅读源码 |
| 添加功能 | [设计模板](docs/design/_template.md) → 写设计 → [计划模板](docs/plans/_template.md) |
| 理解架构 | [架构概览](docs/architecture/overview.md) → [依赖规则](docs/architecture/dependency-rules.md) |
| 安全审计 | [安全模型](docs/architecture/security-model.md) → 敏感代码区域 |
| 新贡献者 | [入门指南](docs/guides/getting-started.md) → [编码规范](docs/guides/coding-conventions.md) |

---

## 技术债务

详见 [技术债务跟踪](docs/plans/tech-debt.md)。高优先级项：
- TD-001: 缺少单元测试框架
- TD-002: 内核驱动缺少安全审计
- TD-003: 加密沙箱缺少安全审计
