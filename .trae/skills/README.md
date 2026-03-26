# Sandboxie 项目 AI 辅助开发指南

## 这是什么

这是一个专为 **Sandboxie-Plus** 项目设计的 AI Skill（技能包），目的是让 AI（Claude 等）能够**快速理解**你的项目代码，并**准确地帮你修改**代码。

传统方式是把整个项目丢给 AI——但 Sandboxie 有几十万行代码，远超任何 AI 的上下文窗口。这个 Skill 的解决方案是：**给 AI 一张精确的地图，让它按需查看，而不是一次看完**。

---

## 快速开始

### 方式一：在 Claude.ai 中使用

1. 将整个 `sandboxie-skill/` 目录上传为自定义 Skill（或手动粘贴 `SKILL.md` 的内容作为对话开头的上下文）

2. 对话时直接说你要做什么，例如：
   ```
   我想让 Sandboxie 在拦截 NtCreateFile 时，对某种特定路径做特殊处理。
   请帮我定位需要修改的文件，并给出修改方案。
   ```

3. AI 会根据 Skill 中的模块速查表直接定位到 `core/drv/file.c` 和 `core/dll/file.c`，然后要求你提供这些文件的内容。

### 方式二：在 Claude Code（命令行）中使用

1. 将 `sandboxie-skill/` 放到你的项目中或 Claude Code 可访问的路径

2. 在 `.claude/settings.json` 或项目配置中引用此 Skill

3. Claude Code 可以直接读取项目源文件，实现真正的自主导航和修改

### 方式三：通过 API 自动化

1. 将 `SKILL.md` + `references/architecture.md` 作为 System Prompt 的一部分

2. 每次请求时只附加相关源文件的内容（根据模块速查表选择）

3. 可以用 `references/analysis-prompts.md` 中的模板进行自动化批量分析

---

## 工作流详解

### 场景一：我想修改某个功能

```
你 → "我想修改沙箱中浏览器的网络隔离行为"
AI → 读取 SKILL.md 的模块速查表
   → 定位到：core/drv/net*.c + core/dll/net*.c
   → 请你提供这些文件（或在 Claude Code 中自动读取）
   → 阅读代码后给出修改方案
   → 告诉你还需要修改哪些关联文件（配置、UI 等）
```

### 场景二：我想理解某个流程

```
你 → "沙箱进程是怎么启动的？完整流程是什么？"
AI → 读取 references/architecture.md 第 2.2 节
   → 给出整体流程说明
   → 如果你需要更多细节，再去读具体的 start.cpp / SbieSvc / SbieDrv 代码
```

### 场景三：我想对整个项目做深度分析

```
你 → "帮我对文件系统虚拟化子系统做完整分析"
AI → 读取 references/analysis-prompts.md 中的 Level 1 模板
   → 用子系统扫描脚本确定文件列表
   → 逐子系统生成分析文档
   → 然后可以做 Level 2（模块整合）→ Level 3（项目全景）
```

---

## Skill 文件结构

```
sandboxie-skill/
├── SKILL.md                              # 主入口，AI 首先读这个
│                                         # 包含：项目结构、模块速查表、
│                                         #       修改规范、命名约定
│
├── references/
│   ├── architecture.md                   # 详细架构文档（AI 的"地图"）
│   │                                     # 包含：5 层架构详解、核心流程、
│   │                                     #       每个模块的文件清单、
│   │                                     #       常见修改模式
│   │
│   └── analysis-prompts.md               # 深度分析 Prompt 模板
│                                         # 包含：3 层分析模板、
│                                         #       子系统划分方案、
│                                         #       自动扫描脚本
│
└── README.md                             # 本文件（使用指南）
```

---

## 为什么不用"逐文件生成 MD 再聚合"的方式？

之前的方案（每个文件生成一个 MD → 模块 MD → 项目 MD）理论上很完美，但对于 Sandboxie 这样的项目存在实际问题：

| 问题 | 说明 |
|------|------|
| **文件数量太多** | 仅 core/dll/ 就有 40+ 文件，全项目数百个文件。逐一分析耗时极长且成本高 |
| **大部分分析无用** | 你修改项目时通常只涉及一小部分文件，90% 的文件级 MD 永远不会被用到 |
| **上下文浪费** | 把所有 MD 喂给 AI 会超出上下文限制；分层聚合又丢失了关键细节 |
| **维护成本高** | 每次代码更新都要重新生成受影响文件的 MD |

**本 Skill 的方案更务实**：

1. **预置架构地图**（architecture.md）— 让 AI 对项目有全局认知，只需读一次
2. **按需深入**（模块速查表）— 用户提出具体需求时，AI 才去读相关源码
3. **修改模式库**（常见修改模式）— 直接告诉 AI "加 Hook 要改这几个文件"，省去分析过程
4. **保留深度分析能力**（analysis-prompts.md）— 如果确实需要全量分析，模板现成可用

---

## 定制与扩展

### 添加你自己的领域知识

如果你对 Sandboxie 某个模块特别熟悉，可以在 `references/` 下添加更多文档：

```
references/
├── architecture.md        # 已有
├── analysis-prompts.md    # 已有
├── my-file-hook-notes.md  # 你自己的笔记：文件 Hook 的坑
├── my-token-design.md     # 你自己的笔记：令牌机制的理解
└── ...
```

然后在 `SKILL.md` 中添加引用，告诉 AI 什么时候该读你的笔记。

### 适配其他项目

这套 Skill 的设计模式（地图 + 速查表 + 修改模式 + 按需深入）是通用的。
如果你想为其他大型项目创建类似的 Skill：

1. 把 `SKILL.md` 作为模板，替换项目结构和模块速查表
2. 把 `architecture.md` 作为模板，替换架构描述和文件清单
3. 核心思路：**不要让 AI 看所有代码，而是给它一张地图让它按需查看**

---

## 常见问题

**Q: AI 的上下文窗口放不下某个很大的文件怎么办？**

只提供文件中相关的部分。例如 `file.c` 可能有几千行，但如果你只关心 `NtCreateFile` 的处理，
就告诉 AI 只看 `File_NtCreateFile` 函数。SKILL.md 中的命名约定可以帮助 AI 猜测函数名。

**Q: 我是 Sandboxie 项目的新手，从哪里开始？**

让 AI 先读 `architecture.md`，然后问它："用最简单的方式解释 Sandboxie 是怎么工作的"。
建议从"进程启动流程"和"文件虚拟化流程"这两个核心场景开始理解。

**Q: 这个 Skill 需要随项目更新吗？**

架构层面的内容（SKILL.md 和 architecture.md）相对稳定，除非 Sandboxie 做了大的架构变更。
文件级别的变化不需要更新 Skill——AI 看的是实际源码，Skill 只是导航。
