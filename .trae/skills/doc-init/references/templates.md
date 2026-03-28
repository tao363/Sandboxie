# 文档模板参考

本文件包含 doc-init 技能生成的每个文档的详细模板和填写指南。在 Phase 1-3（init 模式）和 Phase G3-G4（garden 模式）中按需参考。

---

## docs/.doc-meta.json 模板（新鲜度注册表）

在 init 模式 Phase 4 中创建。Garden 模式依赖此文件追踪文档新鲜度。

```json
{
  "$schema": "doc-meta-v1",
  "last_gardened_commit": "[当前 HEAD commit hash]",
  "last_gardened_date": "[ISO 8601 时间戳]",
  "documents": {
    "docs/architecture/overview.md": {
      "content_hash": "sha256:[文件内容的 SHA-256 哈希]",
      "last_verified": "[ISO 8601 时间戳]",
      "verified_at_commit": "[commit hash]",
      "status": "fresh",
      "mapped_code_paths": [
        "[关联的代码路径 glob 模式]"
      ]
    }
  },
  "mappings": {
    "description": "代码路径到文档的映射。Garden 模式用此判断哪些文档可能受代码变更影响。",
    "rules": [
      {
        "code_pattern": "[glob 模式，如 src/core/**]",
        "affects_docs": ["[文档路径]"],
        "reason": "[映射原因]"
      }
    ]
  }
}
```

**生成方法：**
```bash
# 计算每个文档的 content_hash
sha256sum docs/architecture/overview.md | cut -d' ' -f1

# 获取当前 commit hash
git rev-parse HEAD
```

**字段说明：** 详见 `references/doc-gardening.md` 第 1 节。

---

## AGENTS.md 模板（导航索引）

```markdown
# [项目名称] — Agent Navigation Map

> **入口点。** 本文件约 100 行，仅作导航索引。深层知识存储在 `docs/` 目录中。

---

## 项目一句话描述

[一句话描述：这个项目解决什么问题，面向谁]

---

## 核心架构速览

[ASCII 或 Mermaid 架构图，3-5 行展示核心组件关系]

---

## 文档索引

| 文档 | 内容 | 何时阅读 |
|------|------|----------|
| [docs/architecture/overview.md](docs/architecture/overview.md) | 架构总览 | 首次了解项目 |
| [docs/architecture/components.md](docs/architecture/components.md) | 组件详细说明 | 修改特定组件 |
| [docs/architecture/dependency-rules.md](docs/architecture/dependency-rules.md) | 分层依赖规则 | 新增模块 |
| [docs/guides/coding-conventions.md](docs/guides/coding-conventions.md) | 编码约定 | 编写代码 |
| [docs/guides/getting-started.md](docs/guides/getting-started.md) | 新贡献者入门 | 开始贡献 |
| [docs/guides/testing-guide.md](docs/guides/testing-guide.md) | 测试策略 | 测试代码 |
| [docs/beliefs.md](docs/beliefs.md) | 核心信念 | 面临设计决策 |
| [docs/domain-map.md](docs/domain-map.md) | 业务域划分 | 理解模块边界 |
| [docs/glossary.md](docs/glossary.md) | 术语表 | 理解专业术语 |
| [docs/quality.md](docs/quality.md) | 质量评级 | 了解项目现状 |

---

## 核心命令

```bash
# 构建
[命令]

# 测试
[命令]

# 代码检查
[命令]
```

---

## 关键规则

<!-- 仅列出 5-10 条最关键的规则 -->

1. [规则1]
2. [规则2]
3. [规则3]
4. [规则4]
5. [规则5]

---

## 高风险区域

| 区域 | 路径 | 风险 |
|------|------|------|
| [区域名] | [路径] | [风险说明] |

---

## 提交规范

```
<type>(<scope>): <subject>

类型: feat | fix | docs | style | refactor | test | chore
```

---

## Agent 工作流程

### 接到新任务时
1. 读取本文件确认整体上下文
2. 读取 `git log --oneline -10` 了解最新状态
3. 根据任务类型读取对应文档
4. 实施变更，遵守关键约定
5. 运行测试确认无破坏
6. 提交 git commit（描述性 message）

### Session 移交协议
每次工作结束前：
1. 确保代码处于可工作状态
2. `git commit` 所有变更
3. 留下清晰的 commit message 说明进度
```

---

## docs/ARCHITECTURE.md 模板

```markdown
# 架构概述

## 系统定位
[一段话描述系统的职责边界：做什么、不做什么]

## 高层架构

<!-- 用文字描述或 ASCII/Mermaid 图 -->

```
[客户端] → [API 层] → [业务逻辑层] → [数据层]
                ↕                          ↕
          [认证/授权]              [外部服务集成]
```

## 模块职责

| 模块/目录 | 职责 | 关键依赖 | 入口文件 |
|-----------|------|---------|---------|
| src/api/ | HTTP 路由和请求处理 | [框架] | src/api/index.ts |
| src/services/ | 核心业务逻辑 | - | - |
| src/models/ | 数据模型和数据库交互 | [ORM] | - |
| ... | ... | ... | ... |

## 数据流

[描述核心数据如何在系统中流动，关键路径是什么]

### 典型请求流程
1. [请求入口]
2. [中间件处理]
3. [业务逻辑]
4. [数据持久化]
5. [响应返回]

## 关键设计决策

[列出影响全局的架构决策，详细分析见 docs/ADR/]

- **[决策1]**: [简要原因] → 详见 ADR-001
- **[决策2]**: [简要原因] → 详见 ADR-002

## 边界与约束

- [性能约束：如 "P99 延迟 < 200ms"]
- [可用性要求：如 "99.9% uptime"]
- [安全约束：如 "所有用户数据加密存储"]
- [规模约束：如 "支持 10K 并发连接"]
```

---

## docs/CONVENTIONS.md 模板

```markdown
# 编码约定

## 命名规范

| 元素 | 风格 | 示例 |
|------|------|------|
| 文件名（组件） | [PascalCase/kebab-case/...] | `UserProfile.tsx` |
| 文件名（工具） | [camelCase/kebab-case/...] | `formatDate.ts` |
| 变量 | [camelCase/snake_case/...] | `userName` |
| 常量 | [UPPER_SNAKE_CASE] | `MAX_RETRY_COUNT` |
| 类型/接口 | [PascalCase] | `UserProfile` |
| 数据库字段 | [snake_case] | `created_at` |

## 文件组织

[描述文件应该如何组织，是按功能还是按层级]

## 错误处理

[描述统一的错误处理模式：自定义错误类、错误码、日志格式]

## 注释和文档

- 公共 API 必须有 [JSDoc/docstring/注释]
- 复杂逻辑用行内注释解释 WHY，不解释 WHAT
- TODO 格式：`// TODO(作者): 描述 - 日期`

## Git 约定

- Commit message 格式：`type(scope): description`
  - type: feat / fix / docs / refactor / test / chore
- 分支命名：`feature/xxx`, `fix/xxx`, `docs/xxx`
- PR 必须包含：变更描述、测试方式、截图（UI 变更）

## 导入顺序

[描述 import/require 的分组和排序规则]

## 依赖管理

- 添加新依赖前检查 docs/STACK.md，确认无替代
- 优先使用项目已有依赖解决问题
- [版本锁定策略]
```

---

## docs/STACK.md 模板

```markdown
# 技术栈

## 核心技术

| 层级 | 技术 | 版本 | 选择原因 |
|------|------|------|---------|
| 语言 | [TypeScript/Python/...] | [版本] | [原因] |
| 框架 | [Next.js/FastAPI/...] | [版本] | [原因] |
| 数据库 | [PostgreSQL/...] | [版本] | [原因] |
| ORM | [Prisma/SQLAlchemy/...] | [版本] | [原因] |
| 测试 | [Jest/Pytest/...] | [版本] | [原因] |
| CI/CD | [GitHub Actions/...] | - | [原因] |

## 关键依赖

[列出核心第三方依赖及用途]

## 本地开发环境

- Node.js >= [版本]
- [其他系统依赖]

## 不使用的技术（明确排除）

[列出团队明确不使用的技术及原因，防止 agent 引入]
```

---

## docs/TESTING-STRATEGY.md 模板

```markdown
# 测试策略

## 测试分层

| 层级 | 工具 | 覆盖范围 | 运行命令 |
|------|------|---------|---------|
| 单元测试 | [Jest/Pytest/...] | 函数/方法级 | `[命令]` |
| 集成测试 | [工具] | API/服务级 | `[命令]` |
| E2E 测试 | [Playwright/Cypress/...] | 用户流程级 | `[命令]` |

## 测试约定

- 新功能必须附带 [单元/集成] 测试
- Bug 修复必须附带回归测试
- 测试文件位置：[与源文件同目录 / __tests__/ / tests/]
- 命名格式：[xxx.test.ts / test_xxx.py / ...]

## Agent 测试清单

完成功能后，依次执行：
1. `[运行单元测试命令]`
2. `[运行 lint 命令]`
3. `[运行类型检查命令]`
4. [如有 UI 变更] 用浏览器工具验证视觉效果
5. 确认无回归
```

---

## docs/ADR/000-template.md 模板

```markdown
# ADR-[编号]: [标题]

- **状态**: [proposed | accepted | deprecated | superseded by ADR-XXX]
- **日期**: [YYYY-MM-DD]
- **决策者**: [人员/团队]

## 背景

[什么场景下需要做这个决策？]

## 决策

[最终选择了什么方案？]

## 备选方案

1. **[方案A]**: [优缺点]
2. **[方案B]**: [优缺点]

## 后果

- 正面：[...]
- 负面：[...]
- 风险：[...]
```

---

## docs/CONTEXT-BUDGET.md 模板

```markdown
# 上下文预算管理

## 文档分级

### L0 — 每次 Session 必读（总计 < 2000 tokens）
- CLAUDE.md（导航索引）
- progress.md（最新进度）

### L1 — 按任务类型选读（每个 < 3000 tokens）
- docs/ARCHITECTURE.md — 架构变更、新功能
- docs/CONVENTIONS.md — 任何代码变更
- docs/TESTING-STRATEGY.md — 测试相关任务
- docs/GUIDES/[对应指南].md — 按任务类型

### L2 — 按需深入（无限制）
- docs/ADR/ — 理解历史决策时
- docs/DOMAIN-GLOSSARY.md — 遇到不熟悉的业务术语时
- docs/STACK.md — 引入新依赖或技术选型时

## Session 启动协议

```bash
# Agent 每次开始工作时执行
1. cat CLAUDE.md                           # 导航索引
2. cat progress.md                         # 最新状态
3. git log --oneline -10                   # 最近变更
4. # 根据任务类型读取 L1 文档
5. # 开始工作
```

## Session 移交协议

```bash
# Agent 每次结束 session 前执行
1. git add -A && git commit -m "type(scope): description"
2. # 更新 progress.md（JSON 格式）
3. # 如任务未完成，在 progress.md 写明接手指南
```

## progress.md 格式

使用 JSON 防止 agent 随意修改结构：

```json
{
  "last_updated": "2026-03-26T10:00:00Z",
  "current_session": {
    "goal": "实现用户认证模块",
    "completed": ["设计数据库 schema", "实现注册 API"],
    "in_progress": "实现登录 API",
    "blocked_by": null
  },
  "next_steps": [
    "完成登录 API 和 token 刷新",
    "添加密码重置功能",
    "集成前端认证流程"
  ],
  "known_issues": [
    "邮件发送服务尚未配置，注册验证邮件暂时跳过"
  ],
  "session_history": [
    {
      "date": "2026-03-25",
      "summary": "初始化项目结构，配置数据库连接",
      "commits": ["abc1234", "def5678"]
    }
  ]
}
```
```

---

## docs/GUIDES/NEW-FEATURE.md 模板

```markdown
# 新功能开发指南

## 开始之前
1. 读取 CLAUDE.md 和 docs/ARCHITECTURE.md 确认全局上下文
2. 确认新功能在哪个模块实现
3. 检查是否有相关 ADR

## 开发步骤
1. 创建功能分支：`git checkout -b feature/[功能名]`
2. 如涉及架构变更，先写 ADR
3. 实现功能代码
4. 编写测试（参照 docs/TESTING-STRATEGY.md）
5. 运行全套测试确认无回归
6. 更新文档（如有接口变更，更新 ARCHITECTURE.md）
7. 提交 PR

## 检查清单
- [ ] 代码符合 docs/CONVENTIONS.md
- [ ] 有对应测试
- [ ] 无 lint 错误
- [ ] 无类型错误
- [ ] 文档已更新（如需要）
- [ ] progress.md 已更新
```

---

## docs/GUIDES/BUG-FIX.md 模板

```markdown
# Bug 修复指南

## 开始之前
1. 复现 bug（明确复现步骤）
2. 定位根因（读日志、加断点、查相关代码）

## 修复步骤
1. 创建分支：`git checkout -b fix/[简述]`
2. 先写失败的测试用例（回归测试）
3. 修复代码
4. 确认测试通过
5. 运行全套测试确认无回归
6. 提交 PR

## 检查清单
- [ ] Bug 已复现并记录复现步骤
- [ ] 有回归测试
- [ ] 修复不引入新问题
- [ ] progress.md 已更新
```

---

## AGENTS.md 模板（多 Agent 协作场景）

```markdown
# 多 Agent 协作协议

## Agent 角色

### Planner
- **职责**: 接收用户高层需求，展开为详细产品规格和 sprint 计划
- **输入**: 用户 prompt（1-4 句话）
- **输出**: `plan.md`（产品规格 + 功能列表 + sprint 分解）
- **原则**: 保持产品层面思考，不过早指定技术细节

### Generator（Coding Agent）
- **职责**: 按 sprint 实现功能，每次聚焦一个 feature
- **输入**: `plan.md` + 当前代码库
- **输出**: 可工作的代码 + git commit + progress.md 更新
- **原则**: 增量进步，每次 session 结束留下干净状态

### Evaluator（QA Agent）
- **职责**: 以用户视角测试应用，发现 bug 和体验问题
- **输入**: 运行中的应用 + sprint 验收标准
- **输出**: QA 报告（通过/失败 + 具体发现）
- **原则**: 保持怀疑态度，不因"看起来不错"就通过

## 通信协议

Agent 之间通过文件通信，不直接对话：
- Planner → Generator: `plan.md`
- Generator → Evaluator: `sprint-N-handoff.md`（实现摘要 + 验收标准）
- Evaluator → Generator: `sprint-N-qa-report.md`（测试结果 + 反馈）

## Sprint 合同

每个 Sprint 开始前，Generator 和 Evaluator 协商"Sprint 合同"：
1. Generator 提出：要构建什么 + 如何验证成功
2. Evaluator 审核：验证标准是否充分、是否遗漏场景
3. 双方达成一致后 Generator 开始实施
```

---

## docs/domain-map.md 模板

```markdown
# [项目名称] — 业务域划分

本文档定义项目的业务域及其边界。

---

## 域清单

| 域 | 路径 | 职责 | 核心组件 |
|----|------|------|----------|
| **[域名1]** | `[路径]` | [职责描述] | [组件列表] |
| **[域名2]** | `[路径]` | [职责描述] | [组件列表] |

---

## 域间交互图

[Mermaid 或 ASCII 图展示域间交互关系]

---

## 域详细说明

### 1. [域名]

**路径：** `[路径]`

**职责：**
- [职责1]
- [职责2]

**子域：**

| 子域 | 路径 | 说明 |
|------|------|------|
| [子域名] | [路径] | [说明] |

**边界规则：**
- [规则1]
- [规则2]

---

## 域边界规则

### 允许的交互
[列出允许的域间交互方向]

### 禁止的交互
[列出禁止的域间交互]

---

## 相关文档

- [架构总览](architecture/overview.md)
- [依赖规则](architecture/dependency-rules.md)
```

---

## docs/quality.md 模板

```markdown
# [项目名称] — 质量评级

最后更新: [YYYY-MM-DD]

---

## 各域质量评级

| 域 | 代码质量 | 测试覆盖 | 文档 | 总评 | 主要差距 |
|----|----------|----------|------|------|----------|
| **[域名]** | [A-F] | [A-F] | [A-F] | [A-F] | [差距说明] |

---

## 评级标准

| 等级 | 说明 |
|------|------|
| **A** | 生产就绪，边缘情况已覆盖，文档完备 |
| **B** | 功能完整，少量已知 gap |
| **C** | 核心功能工作，但有显著 gap |
| **D** | 最小可行，需要重大改进 |
| **F** | 不可靠或不存在 |

---

## 优先改进项

### 高优先级
[列出最紧急的改进项]

### 中优先级
[列出次要改进项]

---

## 相关文档

- [测试指南](guides/testing-guide.md)
- [技术债务](plans/tech-debt.md)
```

---

## docs/beliefs.md 模板

```markdown
# [项目名称] — 核心信念

这些信念指导 AI agent 在本项目中的所有决策。当遇到模糊情况时，回到这些信念来做判断。

---

## 工程原则

### 1. [原则名]
**[一句话核心陈述]**
- [具体规则1]
- [具体规则2]

---

## 黄金规则

### 代码层面
1. **[规则]** — [原因]

### 架构层面
1. **[规则]** — [原因]

---

## 禁止事项

- ❌ [禁止项1]
- ❌ [禁止项2]

---

## 决策框架

当面临设计决策时，按以下顺序考虑：
1. **[维度1]** — [判断标准]
2. **[维度2]** — [判断标准]
```

---

## Garden 报告模板

garden 模式完成后输出的报告格式：

```markdown
## Doc-Gardening 完成

### 变更范围
- 分析 commit 范围：<base>..<HEAD>（N 个 commit）
- 扫描文档：X 个
- 识别为陈旧：Y 个

### 更新明细
| 文档 | 状态 | 变更说明 |
|------|------|---------|
| [文档路径] | [已更新/跳过/用户确认] | [具体变更] |

### 新鲜度状态
- FRESH: X 个文档
- 本次更新: Y 个文档
- 跳过（用户选择）: Z 个
- 下次 gardening 基准: <commit-hash>

### 建议
[如有需要手动关注的事项列出]
```

---

## GitHub Actions CI 工作流模板

在 init 模式 Phase 6 或 garden 模式完成后，建议将以下 CI 配置添加到项目中。

### 基础版：PR 文档检查

```yaml
# .github/workflows/doc-check.yml
name: Documentation Health Check

on:
  pull_request:
    paths:
      - 'docs/**'
      - 'AGENTS.md'
      - 'CLAUDE.md'
      - 'src/**'        # 代码变更也可能影响文档
      - 'Sandboxie/**'  # 根据项目调整

jobs:
  doc-verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # 需要完整历史来计算 diff

      - name: Run doc verification
        run: |
          bash .cursor/skills/doc-init/scripts/verify-docs.sh
        continue-on-error: true

      - name: Check doc freshness
        run: |
          if [ -f docs/.doc-meta.json ]; then
            # 获取 PR base commit
            BASE_COMMIT=$(git merge-base origin/${{ github.base_ref }} HEAD)

            # 检查是否有代码变更影响了文档关联的路径
            CHANGED_FILES=$(git diff --name-only "$BASE_COMMIT"...HEAD)

            echo "## 文档新鲜度报告" >> $GITHUB_STEP_SUMMARY
            echo "" >> $GITHUB_STEP_SUMMARY

            # 使用 python 检查映射
            python3 -c "
import json, fnmatch, sys

with open('docs/.doc-meta.json') as f:
    meta = json.load(f)

changed = '''$CHANGED_FILES'''.strip().split('\n')
stale_docs = []

for doc_path, doc_info in meta.get('documents', {}).items():
    for code_path in doc_info.get('mapped_code_paths', []):
        for changed_file in changed:
            if fnmatch.fnmatch(changed_file, code_path):
                stale_docs.append((doc_path, changed_file, code_path))
                break

if stale_docs:
    print('⚠️ 以下文档可能需要更新：')
    print('')
    print('| 文档 | 触发变更 | 映射规则 |')
    print('|------|---------|---------|')
    seen = set()
    for doc, trigger, rule in stale_docs:
        if doc not in seen:
            seen.add(doc)
            print(f'| {doc} | {trigger} | {rule} |')
    print('')
    print('建议运行 doc-init 技能的 garden 模式更新文档。')
    sys.exit(1)
else:
    print('✅ 所有文档新鲜度正常')
" >> $GITHUB_STEP_SUMMARY
          else
            echo "ℹ️ docs/.doc-meta.json 不存在，跳过新鲜度检查" >> $GITHUB_STEP_SUMMARY
          fi

      - name: Comment on PR
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '📄 **文档健康检查发现问题**\n\n代码变更可能影响了部分文档，请运行 `doc-init` 技能的 garden 模式更新文档。\n\n查看 [检查详情](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})。'
            })
```

### 进阶版：定时 doc-gardening 检查

```yaml
# .github/workflows/doc-gardening.yml
name: Scheduled Doc Gardening

on:
  schedule:
    - cron: '0 9 * * 1'  # 每周一 9:00 UTC
  workflow_dispatch:       # 手动触发

jobs:
  gardening-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check doc staleness
        id: check
        run: |
          if [ ! -f docs/.doc-meta.json ]; then
            echo "has_stale=false" >> $GITHUB_OUTPUT
            exit 0
          fi

          LAST_COMMIT=$(python3 -c "import json; print(json.load(open('docs/.doc-meta.json')).get('last_gardened_commit',''))")
          CURRENT_COMMIT=$(git rev-parse HEAD)

          if [ "$LAST_COMMIT" = "$CURRENT_COMMIT" ]; then
            echo "has_stale=false" >> $GITHUB_OUTPUT
          else
            BEHIND=$(git rev-list --count "$LAST_COMMIT..HEAD" 2>/dev/null || echo "many")
            echo "has_stale=true" >> $GITHUB_OUTPUT
            echo "commits_behind=$BEHIND" >> $GITHUB_OUTPUT
          fi

      - name: Create gardening issue
        if: steps.check.outputs.has_stale == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            const behind = '${{ steps.check.outputs.commits_behind }}';
            // 检查是否已有 open 的 gardening issue
            const issues = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: 'doc-gardening',
              state: 'open'
            });
            if (issues.data.length === 0) {
              await github.rest.issues.create({
                owner: context.repo.owner,
                repo: context.repo.repo,
                title: `📄 文档需要 gardening（落后 ${behind} 个 commit）`,
                body: `文档自上次 gardening 以来已有 ${behind} 个新 commit。\n\n建议运行 \`doc-init\` 技能的 garden 模式来更新文档。`,
                labels: ['doc-gardening']
              });
            }
```
