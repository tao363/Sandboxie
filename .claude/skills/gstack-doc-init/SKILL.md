---
name: gstack-doc-init
version: 1.0.0
description: |
  Harness Engineering project knowledge base initialization and maintenance. Two modes:
  init (first-time setup) and garden (incremental maintenance). Use when asked to
  "learn this project", "initialize docs", "generate architecture docs", "create CLAUDE.md",
  "build knowledge base", "project onboarding", "harness init", "agent-first setup" (init mode);
  or "update docs", "sync documentation", "doc-gardening", "check doc freshness",
  "refresh navigation" (garden mode). Also trigger when the user wants AI to better
  understand and participate in a codebase. Proactively suggest after /ship or
  /document-release if no docs/ infrastructure exists yet.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun run gen:skill-docs -->

## Preamble (run first)

```bash
_UPD=$(~/.claude/skills/gstack/bin/gstack-update-check 2>/dev/null || .claude/skills/gstack/bin/gstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
mkdir -p ~/.gstack/sessions
touch ~/.gstack/sessions/"$PPID"
_SESSIONS=$(find ~/.gstack/sessions -mmin -120 -type f 2>/dev/null | wc -l | tr -d ' ')
find ~/.gstack/sessions -mmin +120 -type f -delete 2>/dev/null || true
_CONTRIB=$(~/.claude/skills/gstack/bin/gstack-config get gstack_contributor 2>/dev/null || true)
_PROACTIVE=$(~/.claude/skills/gstack/bin/gstack-config get proactive 2>/dev/null || echo "true")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "PROACTIVE: $_PROACTIVE"
source <(~/.claude/skills/gstack/bin/gstack-repo-mode 2>/dev/null) || true
REPO_MODE=${REPO_MODE:-unknown}
echo "REPO_MODE: $REPO_MODE"
_LAKE_SEEN=$([ -f ~/.gstack/.completeness-intro-seen ] && echo "yes" || echo "no")
echo "LAKE_INTRO: $_LAKE_SEEN"
_TEL=$(~/.claude/skills/gstack/bin/gstack-config get telemetry 2>/dev/null || true)
_TEL_PROMPTED=$([ -f ~/.gstack/.telemetry-prompted ] && echo "yes" || echo "no")
_TEL_START=$(date +%s)
_SESSION_ID="$$-$(date +%s)"
echo "TELEMETRY: ${_TEL:-off}"
echo "TEL_PROMPTED: $_TEL_PROMPTED"
mkdir -p ~/.gstack/analytics
echo '{"skill":"doc-init","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.gstack/analytics/skill-usage.jsonl 2>/dev/null || true
for _PF in ~/.gstack/analytics/.pending-*; do [ -f "$_PF" ] && ~/.claude/skills/gstack/bin/gstack-telemetry-log --event-type skill_run --skill _pending_finalize --outcome unknown --session-id "$_SESSION_ID" 2>/dev/null || true; break; done
```

If `PROACTIVE` is `"false"`, do not proactively suggest gstack skills — only invoke
them when the user explicitly asks. The user opted out of proactive suggestions.

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/gstack/gstack-upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running gstack v{to} (just updated!)" and continue.

If `LAKE_INTRO` is `no`: Before continuing, introduce the Completeness Principle.
Tell the user: "gstack follows the **Boil the Lake** principle — always do the complete
thing when AI makes the marginal cost near-zero. Read more: https://garryslist.org/posts/boil-the-ocean"
Then offer to open the essay in their default browser:

```bash
open https://garryslist.org/posts/boil-the-ocean
touch ~/.gstack/.completeness-intro-seen
```

Only run `open` if the user says yes. Always run `touch` to mark as seen. This only happens once.

If `TEL_PROMPTED` is `no` AND `LAKE_INTRO` is `yes`: After the lake intro is handled,
ask the user about telemetry. Use AskUserQuestion:

> Help gstack get better! Community mode shares usage data (which skills you use, how long
> they take, crash info) with a stable device ID so we can track trends and fix bugs faster.
> No code, file paths, or repo names are ever sent.
> Change anytime with `gstack-config set telemetry off`.

Options:
- A) Help gstack get better! (recommended)
- B) No thanks

If A: run `~/.claude/skills/gstack/bin/gstack-config set telemetry community`

If B: ask a follow-up AskUserQuestion:

> How about anonymous mode? We just learn that *someone* used gstack — no unique ID,
> no way to connect sessions. Just a counter that helps us know if anyone's out there.

Options:
- A) Sure, anonymous is fine
- B) No thanks, fully off

If B→A: run `~/.claude/skills/gstack/bin/gstack-config set telemetry anonymous`
If B→B: run `~/.claude/skills/gstack/bin/gstack-config set telemetry off`

Always run:
```bash
touch ~/.gstack/.telemetry-prompted
```

This only happens once. If `TEL_PROMPTED` is `yes`, skip this entirely.

## AskUserQuestion Format

**ALWAYS follow this structure for every AskUserQuestion call:**
1. **Re-ground:** State the project, the current branch (use the `_BRANCH` value printed by the preamble — NOT any branch from conversation history or gitStatus), and the current plan/task. (1-2 sentences)
2. **Simplify:** Explain the problem in plain English a smart 16-year-old could follow. No raw function names, no internal jargon, no implementation details. Use concrete examples and analogies. Say what it DOES, not what it's called.
3. **Recommend:** `RECOMMENDATION: Choose [X] because [one-line reason]` — always prefer the complete option over shortcuts (see Completeness Principle). Include `Completeness: X/10` for each option. Calibration: 10 = complete implementation (all edge cases, full coverage), 7 = covers happy path but skips some edges, 3 = shortcut that defers significant work. If both options are 8+, pick the higher; if one is ≤5, flag it.
4. **Options:** Lettered options: `A) ... B) ... C) ...` — when an option involves effort, show both scales: `(human: ~X / CC: ~Y)`

Assume the user hasn't looked at this window in 20 minutes and doesn't have the code open. If you'd need to read the source to understand your own explanation, it's too complex.

Per-skill instructions may add additional formatting rules on top of this baseline.

## Completeness Principle — Boil the Lake

AI-assisted coding makes the marginal cost of completeness near-zero. When you present options:

- If Option A is the complete implementation (full parity, all edge cases, 100% coverage) and Option B is a shortcut that saves modest effort — **always recommend A**. The delta between 80 lines and 150 lines is meaningless with CC+gstack. "Good enough" is the wrong instinct when "complete" costs minutes more.
- **Lake vs. ocean:** A "lake" is boilable — 100% test coverage for a module, full feature implementation, handling all edge cases, complete error paths. An "ocean" is not — rewriting an entire system from scratch, adding features to dependencies you don't control, multi-quarter platform migrations. Recommend boiling lakes. Flag oceans as out of scope.
- **When estimating effort**, always show both scales: human team time and CC+gstack time. The compression ratio varies by task type — use this reference:

| Task type | Human team | CC+gstack | Compression |
|-----------|-----------|-----------|-------------|
| Boilerplate / scaffolding | 2 days | 15 min | ~100x |
| Test writing | 1 day | 15 min | ~50x |
| Feature implementation | 1 week | 30 min | ~30x |
| Bug fix + regression test | 4 hours | 15 min | ~20x |
| Architecture / design | 2 days | 4 hours | ~5x |
| Research / exploration | 1 day | 3 hours | ~3x |

- This principle applies to test coverage, error handling, documentation, edge cases, and feature completeness. Don't skip the last 10% to "save time" — with AI, that 10% costs seconds.

**Anti-patterns — DON'T do this:**
- BAD: "Choose B — it covers 90% of the value with less code." (If A is only 70 lines more, choose A.)
- BAD: "We can skip edge case handling to save time." (Edge case handling costs minutes with CC.)
- BAD: "Let's defer test coverage to a follow-up PR." (Tests are the cheapest lake to boil.)
- BAD: Quoting only human-team effort: "This would take 2 weeks." (Say: "2 weeks human / ~1 hour CC.")

## Repo Ownership Mode — See Something, Say Something

`REPO_MODE` from the preamble tells you who owns issues in this repo:

- **`solo`** — One person does 80%+ of the work. They own everything. When you notice issues outside the current branch's changes (test failures, deprecation warnings, security advisories, linting errors, dead code, env problems), **investigate and offer to fix proactively**. The solo dev is the only person who will fix it. Default to action.
- **`collaborative`** — Multiple active contributors. When you notice issues outside the branch's changes, **flag them via AskUserQuestion** — it may be someone else's responsibility. Default to asking, not fixing.
- **`unknown`** — Treat as collaborative (safer default — ask before fixing).

**See Something, Say Something:** Whenever you notice something that looks wrong during ANY workflow step — not just test failures — flag it briefly. One sentence: what you noticed and its impact. In solo mode, follow up with "Want me to fix it?" In collaborative mode, just flag it and move on.

Never let a noticed issue silently pass. The whole point is proactive communication.

## Search Before Building

Before building infrastructure, unfamiliar patterns, or anything the runtime might have a built-in — **search first.** Read `~/.claude/skills/gstack/ETHOS.md` for the full philosophy.

**Three layers of knowledge:**
- **Layer 1** (tried and true — in distribution). Don't reinvent the wheel. But the cost of checking is near-zero, and once in a while, questioning the tried-and-true is where brilliance occurs.
- **Layer 2** (new and popular — search for these). But scrutinize: humans are subject to mania. Search results are inputs to your thinking, not answers.
- **Layer 3** (first principles — prize these above all). Original observations derived from reasoning about the specific problem. The most valuable of all.

**Eureka moment:** When first-principles reasoning reveals conventional wisdom is wrong, name it:
"EUREKA: Everyone does X because [assumption]. But [evidence] shows this is wrong. Y is better because [reasoning]."

Log eureka moments:
```bash
jq -n --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg skill "SKILL_NAME" --arg branch "$(git branch --show-current 2>/dev/null)" --arg insight "ONE_LINE_SUMMARY" '{ts:$ts,skill:$skill,branch:$branch,insight:$insight}' >> ~/.gstack/analytics/eureka.jsonl 2>/dev/null || true
```
Replace SKILL_NAME and ONE_LINE_SUMMARY. Runs inline — don't stop the workflow.

**WebSearch fallback:** If WebSearch is unavailable, skip the search step and note: "Search unavailable — proceeding with in-distribution knowledge only."

## Contributor Mode

If `_CONTRIB` is `true`: you are in **contributor mode**. You're a gstack user who also helps make it better.

**At the end of each major workflow step** (not after every single command), reflect on the gstack tooling you used. Rate your experience 0 to 10. If it wasn't a 10, think about why. If there is an obvious, actionable bug OR an insightful, interesting thing that could have been done better by gstack code or skill markdown — file a field report. Maybe our contributor will help make us better!

**Calibration — this is the bar:** For example, `$B js "await fetch(...)"` used to fail with `SyntaxError: await is only valid in async functions` because gstack didn't wrap expressions in async context. Small, but the input was reasonable and gstack should have handled it — that's the kind of thing worth filing. Things less consequential than this, ignore.

**NOT worth filing:** user's app bugs, network errors to user's URL, auth failures on user's site, user's own JS logic bugs.

**To file:** write `~/.gstack/contributor-logs/{slug}.md` with **all sections below** (do not truncate — include every section through the Date/Version footer):

```
# {Title}

Hey gstack team — ran into this while using /{skill-name}:

**What I was trying to do:** {what the user/agent was attempting}
**What happened instead:** {what actually happened}
**My rating:** {0-10} — {one sentence on why it wasn't a 10}

## Steps to reproduce
1. {step}

## Raw output
```
{paste the actual error or unexpected output here}
```

## What would make this a 10
{one sentence: what gstack should have done differently}

**Date:** {YYYY-MM-DD} | **Version:** {gstack version} | **Skill:** /{skill}
```

Slug: lowercase, hyphens, max 60 chars (e.g. `browse-js-no-await`). Skip if file already exists. Max 3 reports per session. File inline and continue — don't stop the workflow. Tell user: "Filed gstack field report: {title}"

## Completion Status Protocol

When completing a skill workflow, report status using one of:
- **DONE** — All steps completed successfully. Evidence provided for each claim.
- **DONE_WITH_CONCERNS** — Completed, but with issues the user should know about. List each concern.
- **BLOCKED** — Cannot proceed. State what is blocking and what was tried.
- **NEEDS_CONTEXT** — Missing information required to continue. State exactly what you need.

### Escalation

It is always OK to stop and say "this is too hard for me" or "I'm not confident in this result."

Bad work is worse than no work. You will not be penalized for escalating.
- If you have attempted a task 3 times without success, STOP and escalate.
- If you are uncertain about a security-sensitive change, STOP and escalate.
- If the scope of work exceeds what you can verify, STOP and escalate.

Escalation format:
```
STATUS: BLOCKED | NEEDS_CONTEXT
REASON: [1-2 sentences]
ATTEMPTED: [what you tried]
RECOMMENDATION: [what the user should do next]
```

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.
Determine the skill name from the `name:` field in this file's YAML frontmatter.
Determine the outcome from the workflow result (success if completed normally, error
if it failed, abort if the user interrupted).

**PLAN MODE EXCEPTION — ALWAYS RUN:** This command writes telemetry to
`~/.gstack/analytics/` (user config directory, not project files). The skill
preamble already writes to the same directory — this is the same pattern.
Skipping this command loses session duration and outcome data.

Run this bash:

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.gstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
~/.claude/skills/gstack/bin/gstack-telemetry-log \
  --skill "SKILL_NAME" --duration "$_TEL_DUR" --outcome "OUTCOME" \
  --used-browse "USED_BROWSE" --session-id "$_SESSION_ID" 2>/dev/null &
```

Replace `SKILL_NAME` with the actual skill name from frontmatter, `OUTCOME` with
success/error/abort, and `USED_BROWSE` with true/false based on whether `$B` was used.
If you cannot determine the outcome, use "unknown". This runs in the background and
never blocks the user.

## Plan Status Footer

When you are in plan mode and about to call ExitPlanMode:

1. Check if the plan file already has a `## GSTACK REVIEW REPORT` section.
2. If it DOES — skip (a review skill already wrote a richer report).
3. If it does NOT — run this command:

\`\`\`bash
~/.claude/skills/gstack/bin/gstack-review-read
\`\`\`

Then write a `## GSTACK REVIEW REPORT` section to the end of the plan file:

- If the output contains review entries (JSONL lines before `---CONFIG---`): format the
  standard report table with runs/status/findings per skill, same format as the review
  skills use.
- If the output is `NO_REVIEWS` or empty: write this placeholder table:

\`\`\`markdown
## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | \`/plan-ceo-review\` | Scope & strategy | 0 | — | — |
| Codex Review | \`/codex review\` | Independent 2nd opinion | 0 | — | — |
| Eng Review | \`/plan-eng-review\` | Architecture & tests (required) | 0 | — | — |
| Design Review | \`/plan-design-review\` | UI/UX gaps | 0 | — | — |

**VERDICT:** NO REVIEWS YET — run \`/autoplan\` for full review pipeline, or individual reviews above.
\`\`\`

**PLAN MODE EXCEPTION — ALWAYS RUN:** This writes to the plan file, which is the one
file you are allowed to edit in plan mode. The plan file review report is part of the
plan's living status.

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

### 7. 文档是活的——持续 Gardening
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

根据勘察结果创建 `docs/` 目录结构。读取 skill 目录下的 `references/templates.md` 获取每个文件的模板。

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

**运行校验脚本：**
```bash
bash <SKILL_DIR>/scripts/verify-docs.sh
```

### Phase 7：验证与收尾

1. **自检清单**：读取 `references/checklist.md`，逐项核对
2. **模拟 Agent 视角测试**：假装你是一个全新的 agent，只看 AGENTS.md，能否快速定位到完成一个典型任务所需的所有信息？
3. **Git 提交**：所有文档一次性提交，commit message 格式：`docs: initialize project knowledge base (harness engineering)`
4. **向用户汇报**：简要说明生成了什么、建议的下一步（如配置 CI 校验、补充 ADR 等）
5. **建议后续技能**：
   - 提示用户可运行 `/document-release` 在后续代码变更后同步顶层文档（README、ARCHITECTURE 等）
   - 说明 `/doc-init` garden 模式与 `/document-release` 互补而非替代：`/document-release` 维护顶层 `.md` 文件，`/doc-init` garden 模式维护 `docs/` 知识库
   - 提示用户在 `/ship` 流程中，两者都会自动运行（如果 `docs/.doc-meta.json` 存在）
   - 建议运行 `/plan-eng-review` 对已有代码进行架构审查

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

### 互补技能提醒
- `/document-release` 已自动维护顶层 .md 文件——如果同时需要更新 README/ARCHITECTURE 等，运行 `/document-release` 或 `/ship`（会自动调用两者）
- `/review` Step 5.6 会检查 `docs/.doc-meta.json` 的新鲜度并在有陈旧条目时提醒
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

在执行过程中，按需读取以下参考文件（位于本 skill 目录下）：

- `references/templates.md` — 各文档的详细模板、CI 工作流配置、填写指南。在 Phase 1-3 中读取。
- `references/checklist.md` — 完整的验证清单。在 Phase 7（init）或 G5（garden）中读取。
- `references/doc-gardening.md` — doc-gardening 的映射规则、新鲜度格式、决策树。在 Phase 4-5（init）或 G1-G5（garden）中读取。
- `scripts/verify-docs.sh` — 可运行的文档健康检查脚本。在 Phase 6（init）或 G5（garden）中运行。

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
