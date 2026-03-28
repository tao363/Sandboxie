---
name: doc-init
description: "基于 OpenAI Harness Engineering + Anthropic 长应用 Harness Design 方法论的项目知识库初始化与维护技能。支持两种模式：init（首次初始化）和 garden（增量维护）。当用户希望让 AI agent 学习一个新项目、为项目生成结构化文档、创建导航文件、建立 docs/ 知识库体系时触发 init 模式。当项目已有文档体系但代码发生变更、需要更新文档、同步导航索引、检测陈旧文档时触发 garden 模式。典型触发语句包括：'让 AI 学习这个项目'、'初始化项目文档'、'生成架构文档'、'创建 CLAUDE.md'、'建立知识库'、'项目 onboarding'、'harness 初始化'、'agent-first 改造'（init 模式）；'更新文档'、'同步文档'、'文档维护'、'doc-gardening'、'检查文档是否过期'、'刷新导航'（garden 模式）。即使用户没有明确说这些词，只要涉及让 AI 更好地理解和参与一个代码项目，都应该使用此技能。"
---

# doc-init — Harness Engineering 项目知识库初始化与维护

> **角色：** 首席架构师 + 技术文档工程师 + Context Engineer
>
> **产出：** init 模式生成完整的 `docs/` 知识库 + 导航索引 + 校验基础设施 + 新鲜度注册表。
> garden 模式基于 git diff 增量更新陈旧文档 + 同步导航 + 刷新新鲜度注册表。
> 这不是一次性文档生成——它是让 AI agent 能够长期、高效、安全地参与项目开发的 **harness（治具）** 的地基和持续维护机制。

---

## 双来源方法论融合

本技能融合了两大前沿 AI 工程实践：

**OpenAI Harness Engineering** 的核心洞察：在 agent-first 工作流中，瓶颈不是 agent 写代码的能力，而是 agent 运行环境的质量。仓库即唯一真相来源——Slack 讨论、Google Docs、人脑中的知识对 agent 不可见。一切关键上下文必须物化为仓库内的版本化工件。文档需要像代码一样持续维护——定期扫描陈旧文档并开修复 PR（doc-gardening）。

**Anthropic Harness Design** 的核心洞察：长时程任务中上下文窗口是稀缺资源。Harness 必须实现渐进式披露（Progressive Disclosure）、生成与评估分离（Generator-Evaluator Separation）、以及结构化移交（Structured Handoff），防止 agent 因上下文溢出或自我过评而失败。

---

## 核心原则

### 1. 仓库即 Agent 的感知系统
Agent 只能看到 prompt 上下文、检索到的文档、工具输出。任何未物化到仓库的知识，对 agent 来说等于不存在。知识库的目标是把"隐性知识"转化为"版本化、可检索、可校验的工件"。

### 2. 导航文件是目录，不是百科全书
CLAUDE.md / AGENTS.md 控制在约 100 行。只做索引和导航，深层知识存储在 `docs/` 目录。单一大文件无法机械化校验，且会迅速腐化（rot）。

### 3. 渐进式披露（Progressive Disclosure）
Agent 从小而稳定的入口点开始，被教会"下一步去哪里看"，而不是一次性接收所有上下文。结构按三层组织：L0 导航索引 → L1 领域文档 → L2 详细规范/ADR。

### 4. 机械化校验优先于散文式规范
可被 linter、CI、结构化测试验证的规则，远胜于人类或 agent 靠"理解"来遵守的约定。架构约束应尽可能编码为可执行断言。

### 5. 状态外化与结构化移交
长任务跨多个上下文窗口时，每个 session 结束必须留下结构化的移交工件（progress file, git commit, handoff doc），让下一个 agent 能在全新上下文中快速恢复工作。

### 6. 生成与评估分离
Agent 对自己生成的内容容易"自我表扬"。在复杂任务中，负责构建的 agent 和负责评审的 agent 应该分离，或至少在 prompt 中明确要求"以评审者而非作者身份"进行自检。

### 7. 文档是活的——持续 Gardening（新增）
文档不是写完就不管的一次性工件。每次代码变更都可能让文档陈旧。需要建立"新鲜度追踪 + diff 驱动的增量更新"机制，像垃圾回收一样持续修剪技术债。

---

## 模式选择（执行入口）

**在执行任何工作之前，先判断运行模式。**

```
1. 检查项目根目录是否存在 AGENTS.md 或 CLAUDE.md
2. 检查 docs/ 目录是否存在且包含内容文件（非空）
3. 检查 docs/.doc-meta.json 是否存在

判断逻辑：
- 如果 AGENTS.md/CLAUDE.md 都不存在 → init 模式
- 如果 docs/ 不存在或为空 → init 模式
- 如果用户明确说 "初始化"/"从头开始"/"重建" → init 模式
- 其他情况（文档体系已存在） → garden 模式
- 如果用户明确说 "更新"/"同步"/"gardening"/"刷新" → garden 模式
```

向用户确认检测到的模式，然后执行对应流程。

---

# ═══════════════════════════════════════
# MODE A：Init 模式 — 首次知识库初始化
# ═══════════════════════════════════════

### Phase 0：勘察（Reconnaissance）

在生成任何文档之前，先全面了解项目：

```
1. 运行 pwd，确认工作目录
2. 查看目录结构：ls -la, 扫描顶层和关键子目录
3. 检查是否已有文档体系：ls docs/ CLAUDE.md AGENTS.md README.md
4. 读取项目元数据（package.json / Cargo.toml / pyproject.toml / go.mod / *.sln 等）
5. 检查 git log --oneline -20 了解近期活动
6. 扫描技术栈：框架、语言、构建工具、测试框架、CI/CD 配置
7. 查看自动化配置（.github/ .gitlab-ci.yml Makefile CMakeLists.txt 等）
8. 识别已有的架构约束或规范（lint 配置、tsconfig、eslint 等）
9. 估算代码库规模（行数/文件数），确定项目规模等级
```

**输出一份内部勘察报告（不写入文件，在思维中整理）：**
- 项目类型和技术栈摘要
- 代码库规模和复杂度估计（小/中/大）
- 已有文档的质量和覆盖度
- 缺口分析：agent 需要但尚不存在的上下文有哪些
- 业务域识别：项目的主要功能域和模块划分

### Phase 1：知识库骨架（Skeleton）

根据勘察结果创建 `docs/` 目录结构。读取 `references/templates.md` 获取每个文件的模板。

**标准结构：**

```
docs/
├── architecture/          # 架构文档（按主题分文件）
│   ├── overview.md        # 系统架构概述（地图，非手册）
│   ├── components.md      # 组件详细说明
│   ├── dependency-rules.md # 分层依赖规则
│   └── security-model.md  # 安全边界（如适用）
├── guides/                # Agent 和开发者操作指南
│   ├── coding-conventions.md  # 编码约定与风格规范
│   ├── getting-started.md     # 新贡献者入门
│   └── testing-guide.md      # 测试策略与运行方式
├── design/                # 设计文档
│   └── _template.md       # 设计文档模板
├── adr/                   # 架构决策记录
│   └── 000-template.md    # ADR 模板
├── plans/                 # 执行计划
│   ├── _template.md       # 计划模板
│   ├── active/            # 进行中的计划
│   ├── completed/         # 已完成的计划
│   └── tech-debt.md       # 技术债务跟踪
├── beliefs.md             # 核心工程信念/黄金规则
├── domain-map.md          # 业务域划分与边界规则
├── glossary.md            # 项目术语表
├── quality.md             # 各域质量评级
└── .doc-meta.json         # 新鲜度注册表（机器可读）
```

**关键：** 不是每个项目都需要所有文件。根据勘察结果裁剪：
- **小型项目（< 5000 行）：** AGENTS.md + docs/architecture/overview.md + docs/guides/coding-conventions.md + .doc-meta.json
- **中型项目（5K-50K 行）：** 标准结构，按需添加 guides 和 adr
- **大型项目（> 50K 行）：** 完整结构 + 按域分割子目录 + 多级导航 + domain-map.md + quality.md

### Phase 2：导航索引（AGENTS.md / CLAUDE.md）

这是 agent 每次启动时首先读取的文件。保持精简、高信噪比。

**AGENTS.md 结构（约 80-120 行），需包含：**

1. 项目一句话描述
2. 核心架构速览图（ASCII 或 Mermaid）
3. 文档索引表（文档路径 | 内容 | 何时阅读）
4. 核心命令（构建/测试/检查）
5. 关键规则（5-10 条，违反即 break build 的）
6. 高风险区域表（路径 | 风险说明）
7. 提交规范
8. 相关技能链接

**大型项目额外需要：**
- 按域分组的文档索引（而非平铺列表）
- 多级导航：AGENTS.md → domain-map.md → 各域详细文档
- 每个域一个入口文档，域内文档形成自包含子系统

读取 `references/templates.md` 获取详细模板。

### Phase 3：内容填充

按照以下优先级填充文档内容：

**P0（必填，直接影响 agent 工作质量）：**
- architecture/overview.md — 从代码结构推断架构，画出模块关系
- guides/coding-conventions.md — 从现有代码和 lint 配置提取约定
- AGENTS.md 的关键约定和常用命令

**P1（重要，显著提升效率）：**
- architecture/components.md — 各组件详细接口
- architecture/dependency-rules.md — 分层架构和依赖方向
- guides/getting-started.md — 新贡献者入门流程
- guides/testing-guide.md — 测试命令、覆盖策略

**P2（有帮助，长期维护）：**
- beliefs.md — 核心工程信念和黄金规则
- domain-map.md — 业务域划分和边界规则
- glossary.md — 术语对齐
- quality.md — 各域质量评级
- plans/tech-debt.md — 技术债务跟踪
- adr/ — 已有的架构决策考古

### Phase 4：新鲜度注册表初始化

创建 `docs/.doc-meta.json`，记录每个文档的初始状态。读取 `references/doc-gardening.md` 获取格式规范。

```bash
# 为每个文档计算内容哈希并记录
# 格式见 references/doc-gardening.md 中的 freshness registry 规范
```

**注册表记录：**
- 每个文档的路径
- 最后验证日期
- 对应的 git commit hash
- 关联的代码路径（domain-to-doc 映射）
- 文档内容的 SHA-256 哈希

### Phase 5：Domain-to-Doc 映射

为 garden 模式建立代码路径到文档的映射关系。写入 `docs/.doc-meta.json` 的 `mappings` 字段。

```
映射示例：
  src/core/drv/**  → docs/architecture/overview.md, docs/architecture/security-model.md
  src/core/dll/**  → docs/architecture/components.md
  src/gui/**       → docs/architecture/components.md (GUI 部分)
  *.sln, CMake*    → docs/architecture/build-system.md
  tests/**         → docs/guides/testing-guide.md
```

这个映射使 garden 模式能快速定位"代码变了 → 哪些文档可能陈旧"。

### Phase 6：机械化校验基础设施

把约定从"散文"变成"可执行检查"。根据项目情况选择性实施：

**结构校验（低成本高收益）：**
- 文档交叉引用检查：导航文件中引用的文件是否都存在
- 目录结构合规检查：关键目录/文件是否存在
- ADR 编号连续性检查

**生成校验脚本：**
```bash
#!/bin/bash
# scripts/verify-docs.sh
# 检查导航文件中引用的所有文件路径是否存在
# 检查 .doc-meta.json 中注册的文件是否都存在
# 检查文档中的交叉引用链接是否有效
```

### Phase 7：验证与收尾

1. **自检清单**：读取 `references/checklist.md`，逐项核对
2. **模拟 Agent 视角测试**：假装你是一个全新的 agent，只看 AGENTS.md，能否快速定位到完成一个典型任务所需的所有信息？
3. **Git 提交**：所有文档一次性提交，commit message 格式：`docs: initialize project knowledge base (harness engineering)`
4. **向用户汇报**：简要说明生成了什么、建议的下一步（如配置 CI 校验、补充 ADR 等）

---

# ═══════════════════════════════════════
# MODE B：Garden 模式 — 增量文档维护
# ═══════════════════════════════════════

> **核心理念：** 文档维护如同垃圾回收——持续、小量、自动化。
> 技术债是高利贷，每天偿还一点比积攒到爆发要好得多。

### Phase G0：预检与范围确定

```
1. 确认 docs/ 目录存在且有内容
2. 确认 AGENTS.md / CLAUDE.md 存在
3. 读取 docs/.doc-meta.json（新鲜度注册表）
   - 如果不存在，先执行 Phase 4（新鲜度注册表初始化）
4. 确定 diff 基准：
   - 优先使用 docs/.doc-meta.json 中的 last_gardened_commit
   - 回退到 git merge-base HEAD main/master
   - 回退到 HEAD~20
```

### Phase G1：Diff 分析

分析代码变更，确定哪些文档可能受影响。

```bash
# 1. 获取变更文件列表
git diff <base>...HEAD --name-only

# 2. 获取变更统计
git diff <base>...HEAD --stat

# 3. 获取 commit 历史
git log <base>..HEAD --oneline

# 4. 检查新增/删除的文件
git diff <base>...HEAD --diff-filter=AD --name-only
```

**变更分类：**

| 变更类型 | 影响的文档 |
|---------|----------|
| 新增源代码文件 | architecture/components.md, domain-map.md |
| 删除源代码文件 | architecture/components.md, domain-map.md |
| 修改构建配置 | architecture/build-system.md |
| 修改测试文件 | guides/testing-guide.md |
| 新增依赖 | architecture/overview.md (技术栈部分) |
| 修改 API 接口 | architecture/components.md |
| 修改安全相关代码 | architecture/security-model.md |
| 修改/新增文档 | 导航索引(AGENTS.md), .doc-meta.json |

读取 `references/doc-gardening.md` 获取完整的 domain-to-doc 映射规则。

使用 `docs/.doc-meta.json` 中的 `mappings` 字段，将变更文件映射到受影响的文档列表。

**输出：** "分析了 N 个文件变更，涉及 M 个 commit。识别出 K 个文档可能需要更新。"

### Phase G2：新鲜度扫描

对比 `docs/.doc-meta.json` 中的记录与当前状态：

```
对每个注册的文档：
1. 检查文档文件是否仍然存在
2. 计算当前内容哈希，对比注册表中的哈希
3. 检查关联代码路径是否有变更（通过 Phase G1 的 diff 结果）
4. 标记状态：
   - FRESH — 文档和关联代码都未变更
   - STALE_CODE — 关联代码有变更，文档未更新
   - STALE_DOC — 文档已修改但未重新验证
   - MISSING — 文档文件不存在（被删除）
   - ORPHAN — 注册表中有记录但文件不存在
   - NEW — 有新文档但未注册
```

**输出新鲜度报告：**

```
文档新鲜度扫描结果：
  docs/architecture/overview.md     [STALE_CODE] — core/drv/ 有 5 个文件变更
  docs/architecture/components.md   [FRESH]
  docs/guides/coding-conventions.md [FRESH]
  docs/domain-map.md                [STALE_CODE] — 新增了 2 个模块
  ...
需要更新的文档：3 个
```

### Phase G3：定向更新

对每个标记为 STALE 的文档，执行定向更新：

**步骤：**

```
对每个 STALE 文档：
1. 读取文档全文
2. 读取关联的代码变更 diff
3. 交叉比对，识别需要更新的部分
4. 分类更新类型：
   a. 自动更新（Auto-update）：
      - 事实性修正（路径变更、文件重命名、计数更新）
      - 新增项目到表格或列表
      - 更新代码示例以反映最新 API
      - 修正交叉引用链接
   b. 需要用户确认（Ask-user）：
      - 架构叙述性变更
      - 安全模型描述修改
      - 删除整个章节
      - 大幅重写（> 10 行）
      - 模糊的变更关联
5. 执行自动更新，记录每个变更
6. 对需要确认的变更，使用 AskUserQuestion 询问用户
```

**更新原则：**
- **保守更新：** 只改变 diff 明确支持的内容
- **不臆造：** 如果不确定变更的含义，标记为需要用户确认
- **一次一个：** 每个文档独立更新，避免跨文档的级联修改
- **以评审者视角自检：** 更新完后，问自己"如果我是另一个 agent，这个更新合理吗？"

### Phase G4：导航同步

检查并更新导航索引和元文档：

**4a. 导航文件同步（AGENTS.md / CLAUDE.md）**

```
1. 读取当前导航文件
2. 扫描 docs/ 目录的实际文件列表
3. 对比导航文件中的索引：
   - 是否有新文档未被索引？
   - 是否有已删除的文档仍在索引中？
   - 索引中的描述是否仍然准确？
4. 如果有差异，更新导航文件
5. 验证所有交叉引用链接有效
```

**4b. Domain-map 同步**

```
1. 如果 docs/domain-map.md 存在：
   - 检查是否有新增模块/目录未被映射
   - 检查是否有已删除模块仍在映射中
   - 检查域间交互图是否仍然准确
2. 如果有显著变更，更新 domain-map.md
```

**4c. 质量评级更新**

```
1. 如果 docs/quality.md 存在：
   - 基于代码变更评估是否有质量等级变化
   - 新增测试 → 可能提升测试覆盖评级
   - 新增文档 → 可能提升文档评级
   - 重大重构 → 可能影响代码质量评级
2. 只在有明确依据时更新评级，否则标记为"待评估"
```

### Phase G5：新鲜度注册表更新与收尾

```
1. 更新 docs/.doc-meta.json：
   - 更新已验证文档的 content_hash
   - 更新 last_verified 日期
   - 更新 verified_at_commit 为当前 HEAD
   - 更新 last_gardened_commit 为当前 HEAD
   - 添加新文档的注册记录
   - 移除已删除文档的注册记录

2. 自检：读取 references/checklist.md 的 garden 模式部分，逐项核对

3. Git 提交（如果有变更）：
   commit message: "docs(garden): update N docs for [变更摘要]"

4. 输出 garden 报告：
```

**Garden 报告格式：**

```
## Doc-Gardening 完成

### 变更范围
- 分析 commit 范围：<base>..<HEAD>（N 个 commit）
- 扫描文档：X 个
- 识别为陈旧：Y 个

### 更新明细
| 文档 | 状态 | 变更说明 |
|------|------|---------|
| docs/architecture/overview.md | 已更新 | 更新了模块列表，新增 X 组件 |
| docs/domain-map.md | 已更新 | 新增 Y 域 |
| AGENTS.md | 已更新 | 同步了文档索引 |

### 新鲜度状态
- FRESH: X 个文档
- 本次更新: Y 个文档
- 跳过（用户选择）: Z 个
- 下次 gardening 基准: <commit-hash>

### 建议
[如有需要手动关注的事项列出]
```

---

## 关键反模式（避免）

| 反模式 | 为什么有害 | 正确做法 |
|--------|-----------|----------|
| 一个巨大的 CLAUDE.md | 挤占上下文，agent 无法区分优先级 | 目录+索引，深层内容分文件 |
| 纯散文式规范 | 无法机械校验，必然腐化 | 尽可能编码为 lint 规则/CI 检查 |
| 过早过细的技术规范 | 错误会级联到下游实现 | Planner 层面保持高层次 |
| Agent 自评自己的文档 | 自我表扬偏差，质量虚高 | 分离生成与评审，或以"批评者"视角自检 |
| 不维护的进度文件 | 下一个 session 的 agent 迷失 | JSON 格式 + 每次 session 强制更新 |
| 复制粘贴全量上下文 | 浪费 token，降低推理质量 | 渐进式披露 + 按需加载 |
| 写完文档就不管 | 文档腐化，误导 agent | 定期 garden + 新鲜度追踪 |
| 人工追踪文档状态 | 不可扩展，必然遗漏 | 机器可读的 .doc-meta.json |

---

## 参考文件

在执行过程中，按需读取以下参考文件：

- `references/templates.md` — 各文档的详细模板、CI 工作流配置、填写指南。在 Phase 1-3 中读取。
- `references/checklist.md` — 完整的验证清单。在 Phase 7（init）或 G5（garden）中读取。
- `references/doc-gardening.md` — doc-gardening 的映射规则、新鲜度格式、决策树。在 Phase 4-5（init）或 G1-G5（garden）中读取。
- `scripts/verify-docs.sh` — 可运行的文档健康检查脚本。在 Phase 6（init）或 G5（garden）中运行。

---

## 自动化触发配置

### 方式一：Claude Code Hook（推荐）

在项目的 `.claude/settings.json` 中添加 hook，让 Claude Code 在每次代码提交后自动提醒运行 garden 模式：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "command": "bash -c 'if echo \"$TOOL_INPUT\" | grep -q \"git commit\"; then echo \"💡 代码已提交。如果修改了核心代码，建议运行 /doc-init 更新文档。\"; fi'",
        "description": "git commit 后提醒文档更新"
      }
    ]
  }
}
```

### 方式二：Git Hook

在 `.git/hooks/post-commit` 中添加新鲜度检查：

```bash
#!/bin/bash
# .git/hooks/post-commit — 提交后检查文档新鲜度

META_FILE="docs/.doc-meta.json"
if [ ! -f "$META_FILE" ]; then
    exit 0
fi

# 获取上次 gardening 的 commit
LAST_COMMIT=$(python3 -c "import json; print(json.load(open('$META_FILE')).get('last_gardened_commit',''))" 2>/dev/null || exit 0)
CURRENT_COMMIT=$(git rev-parse HEAD)

if [ "$LAST_COMMIT" = "$CURRENT_COMMIT" ]; then
    exit 0
fi

# 计算落后多少个 commit
BEHIND=$(git rev-list --count "$LAST_COMMIT..HEAD" 2>/dev/null || echo "0")

if [ "$BEHIND" -gt 10 ]; then
    echo ""
    echo "📄 文档落后 $BEHIND 个 commit，建议运行 doc-init garden 模式更新文档。"
    echo "   运行: bash .cursor/skills/doc-init/scripts/verify-docs.sh"
    echo ""
fi
```

### 方式三：CI 集成

在 PR 流程中自动检查文档新鲜度。参见 `references/templates.md` 中的 GitHub Actions 工作流模板。

### 触发策略建议

| 项目规模 | 建议触发频率 | 方式 |
|---------|------------|------|
| 小型（< 5K 行） | 每 20+ commit | Git Hook 提醒 |
| 中型（5K-50K 行） | 每 PR | CI 检查 |
| 大型（> 50K 行） | 每 PR + 每周定时 | CI + 定时 gardening Issue |

---

## 适配不同规模的项目

**小型项目（< 5000 行代码）：**
Init: 只需 AGENTS.md + docs/architecture/overview.md + docs/guides/coding-conventions.md + .doc-meta.json。跳过 domain-map、quality、beliefs。
Garden: 简化流程——直接 diff 扫描 + 更新导航 + 刷新注册表。

**中型项目（5000-50000 行）：**
Init: 标准结构。按需添加 guides 和 adr。
Garden: 标准流程，domain-to-doc 映射使用默认规则。

**大型项目（> 50000 行）：**
Init: 完整结构 + 按域分割子文档 + 多级导航 + domain-map.md + quality.md。可能需要多个域级 architecture-{domain}.md。
Garden: 完整流程 + 域级导航同步 + quality 评级更新。

**Monorepo：**
根目录 AGENTS.md 做全局导航，各子包内各自维护局部导航文件，层级化索引。每个子包有自己的 .doc-meta.json。
