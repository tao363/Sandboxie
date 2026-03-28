# Doc-Gardening 参考文档

本文件包含 garden 模式所需的映射规则、新鲜度注册表格式、决策树和操作指南。

---

## 1. 新鲜度注册表格式（docs/.doc-meta.json）

```json
{
  "$schema": "doc-meta-v1",
  "last_gardened_commit": "abc1234def5678",
  "last_gardened_date": "2026-03-26T10:00:00Z",
  "documents": {
    "docs/architecture/overview.md": {
      "content_hash": "sha256:a1b2c3d4...",
      "last_verified": "2026-03-26T10:00:00Z",
      "verified_at_commit": "abc1234def5678",
      "status": "fresh",
      "mapped_code_paths": [
        "Sandboxie/core/drv/**",
        "Sandboxie/core/dll/**",
        "Sandboxie/core/svc/**"
      ]
    },
    "docs/architecture/components.md": {
      "content_hash": "sha256:e5f6g7h8...",
      "last_verified": "2026-03-26T10:00:00Z",
      "verified_at_commit": "abc1234def5678",
      "status": "fresh",
      "mapped_code_paths": [
        "Sandboxie/core/**",
        "SandboxiePlus/SandMan/**",
        "SandboxiePlus/QSbieAPI/**"
      ]
    }
  },
  "mappings": {
    "description": "代码路径到文档的映射。Garden 模式用此判断哪些文档可能受代码变更影响。",
    "rules": [
      {
        "code_pattern": "**/*.sln",
        "affects_docs": ["docs/architecture/build-system.md"],
        "reason": "构建系统配置"
      },
      {
        "code_pattern": "**/CMakeLists.txt",
        "affects_docs": ["docs/architecture/build-system.md"],
        "reason": "构建系统配置"
      },
      {
        "code_pattern": "**/test/**",
        "affects_docs": ["docs/guides/testing-guide.md"],
        "reason": "测试相关变更"
      },
      {
        "code_pattern": "AGENTS.md",
        "affects_docs": [],
        "reason": "导航文件自身变更，无需映射"
      }
    ]
  }
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `$schema` | string | 固定值 `"doc-meta-v1"`，用于版本管理 |
| `last_gardened_commit` | string | 上次 gardening 时的 HEAD commit hash |
| `last_gardened_date` | string | ISO 8601 时间戳 |
| `documents` | object | 每个文档的新鲜度记录，key 为相对路径 |
| `content_hash` | string | 文档内容的 SHA-256 哈希（前缀 `sha256:`） |
| `last_verified` | string | 上次验证该文档与代码一致的时间 |
| `verified_at_commit` | string | 验证时的 git commit hash |
| `status` | string | `fresh` / `stale_code` / `stale_doc` / `unverified` |
| `mapped_code_paths` | array | 该文档关联的代码路径 glob 模式 |
| `mappings.rules` | array | 全局的代码路径到文档的映射规则 |

### 生成 content_hash 的方法

```bash
# Unix/macOS
sha256sum docs/architecture/overview.md | cut -d' ' -f1

# Windows (PowerShell)
(Get-FileHash docs/architecture/overview.md -Algorithm SHA256).Hash.ToLower()

# 在 Git Bash 中（Windows 上最常用）
sha256sum docs/architecture/overview.md | cut -d' ' -f1
```

---

## 2. Domain-to-Doc 映射规则

### 通用映射模式

以下是常见代码变更类型到受影响文档的映射。在 init 模式中，根据项目实际情况定制 `mappings.rules`。

| 代码变更模式 | 受影响的文档 | 更新类型 |
|-------------|------------|---------|
| 新增源代码目录/模块 | architecture/overview.md, components.md, domain-map.md | 新增模块描述 |
| 删除源代码目录/模块 | architecture/overview.md, components.md, domain-map.md | 移除模块描述 |
| 修改 API 接口/函数签名 | architecture/components.md | 更新接口说明 |
| 修改构建配置 | architecture/build-system.md | 更新构建命令 |
| 新增/修改测试 | guides/testing-guide.md | 更新测试说明 |
| 修改安全相关代码 | architecture/security-model.md | 更新安全模型 |
| 新增依赖/库 | architecture/overview.md (技术栈) | 更新依赖列表 |
| 修改配置文件格式 | guides/getting-started.md | 更新配置说明 |
| 重命名文件/目录 | 所有引用该路径的文档 | 更新路径引用 |
| 新增/删除文档文件 | AGENTS.md (导航索引) | 更新索引 |

### 项目特定映射示例（Sandboxie）

```json
{
  "rules": [
    {
      "code_pattern": "Sandboxie/core/drv/**",
      "affects_docs": [
        "docs/architecture/overview.md",
        "docs/architecture/security-model.md",
        "docs/architecture/components.md"
      ],
      "reason": "内核驱动代码变更影响架构和安全模型文档"
    },
    {
      "code_pattern": "Sandboxie/core/dll/**",
      "affects_docs": [
        "docs/architecture/overview.md",
        "docs/architecture/components.md"
      ],
      "reason": "注入 DLL 代码变更影响组件架构文档"
    },
    {
      "code_pattern": "Sandboxie/core/svc/**",
      "affects_docs": [
        "docs/architecture/overview.md",
        "docs/architecture/components.md"
      ],
      "reason": "系统服务代码变更影响组件架构文档"
    },
    {
      "code_pattern": "SandboxiePlus/SandMan/**",
      "affects_docs": [
        "docs/architecture/components.md"
      ],
      "reason": "GUI 代码变更影响组件文档"
    },
    {
      "code_pattern": "SandboxiePlus/QSbieAPI/**",
      "affects_docs": [
        "docs/architecture/components.md",
        "docs/architecture/dependency-rules.md"
      ],
      "reason": "API 层代码变更影响组件和依赖文档"
    },
    {
      "code_pattern": "Sandboxie/install/**",
      "affects_docs": [
        "docs/guides/getting-started.md"
      ],
      "reason": "安装相关变更影响入门指南"
    },
    {
      "code_pattern": "**/*.sln",
      "affects_docs": [
        "docs/architecture/build-system.md"
      ],
      "reason": "解决方案文件变更影响构建文档"
    }
  ]
}
```

---

## 3. 陈旧度检测算法

### 检测流程

```
输入：
  - docs/.doc-meta.json（注册表）
  - git diff <last_gardened_commit>...HEAD --name-only（变更文件列表）

对每个注册文档 D：
  1. 文件存在性检查
     - D 文件不存在 → 标记为 ORPHAN

  2. 内容哈希检查
     - 计算 D 的当前 content_hash
     - 与注册表中的 content_hash 对比
     - 不一致 → 标记为 STALE_DOC（文档被外部修改但未重新验证）

  3. 关联代码变更检查
     - 获取 D 的 mapped_code_paths
     - 遍历变更文件列表，检查是否匹配任何 mapped_code_path
     - 有匹配 → 标记为 STALE_CODE

  4. 无异常 → 标记为 FRESH

对 docs/ 下的所有 .md 文件：
  - 如果文件存在但不在注册表中 → 标记为 NEW

输出：每个文档的状态标记
```

### Glob 匹配规则

映射中的 `code_pattern` 使用 glob 语法：
- `*` — 匹配单层目录内的任意文件
- `**` — 匹配任意深度的目录
- `*.ext` — 匹配指定扩展名
- `path/to/file.c` — 精确匹配

---

## 4. 自动更新 vs 用户确认 决策树

```
变更已识别 → 分类决策：

├─ 事实性变更（Auto-update）：
│   ├─ 路径/文件名变更 → 更新所有引用
│   ├─ 新增模块/组件 → 添加到列表/表格
│   ├─ 删除模块/组件 → 从列表/表格移除
│   ├─ 计数变更（"N 个模块" → "N+1 个模块"）
│   ├─ 交叉引用链接修复
│   ├─ 代码示例更新（API 签名变更）
│   └─ 版本号/日期更新
│
├─ 需要用户确认（Ask-user）：
│   ├─ 架构叙述变更（设计哲学、架构决策原因）
│   ├─ 安全模型描述修改
│   ├─ 删除文档中的整个章节
│   ├─ 大幅重写（> 10 行连续修改）
│   ├─ 新增质量评级或改变评级等级
│   ├─ 修改核心信念/黄金规则
│   ├─ 模糊关联（不确定代码变更是否真的影响该文档）
│   └─ 移除文档文件
│
└─ 跳过（No action needed）：
    ├─ 纯格式变更（空行、缩进）
    ├─ 注释修改（不影响公共 API）
    ├─ 测试内部逻辑（不影响测试策略文档）
    └─ 重构未改变外部行为
```

---

## 5. 导航文件重新生成规则

### 何时需要更新导航

| 触发条件 | 更新动作 |
|---------|---------|
| docs/ 下新增 .md 文件 | 添加到导航索引表 |
| docs/ 下删除 .md 文件 | 从导航索引表移除 |
| docs/ 下重命名 .md 文件 | 更新导航索引表中的路径 |
| 文档内容的"一句话描述"变更 | 更新导航索引表中的描述 |
| 新增代码域/模块 | 更新 domain-map.md |
| 删除代码域/模块 | 更新 domain-map.md |
| 高风险区域变更 | 检查导航文件中的高风险区域表 |

### 导航文件更新流程

```
1. 扫描 docs/ 下所有 .md 文件（排除 .doc-meta.json）
2. 读取当前导航文件（AGENTS.md / CLAUDE.md）
3. 提取导航文件中的文档索引表
4. 对比：
   a. 实际文件列表 vs 索引中的文件列表
   b. 生成差异报告
5. 对差异执行更新：
   a. 新增文档 → 读取文档第一行（标题）和第一段（描述），添加到索引
   b. 删除文档 → 从索引中移除
   c. 重命名文档 → 更新路径
6. 验证所有索引链接可达
```

### 大型项目的多级导航

对于大型项目（> 50K 行），使用层级化导航：

```
AGENTS.md（L0 全局导航）
  └─ docs/domain-map.md（域级概览）
       ├─ docs/architecture/overview.md（架构域入口）
       │    ├─ docs/architecture/components.md
       │    ├─ docs/architecture/dependency-rules.md
       │    └─ docs/architecture/security-model.md
       ├─ docs/guides/（指南域入口）
       │    ├─ coding-conventions.md
       │    ├─ getting-started.md
       │    └─ testing-guide.md
       └─ docs/plans/（规划域入口）
            ├─ tech-debt.md
            └─ active/
```

每一级只展示直接子项，不展开所有层级。Agent 从 L0 开始，逐级深入。

---

## 6. 质量评级更新规则

当 garden 模式检测到代码变更时，可能需要更新 `docs/quality.md` 中的评级。

### 评级变更触发条件

| 变更 | 可能的评级影响 | 需要用户确认？ |
|------|-------------|--------------|
| 新增单元测试 | 测试覆盖 ↑ | 是（等级变更需确认） |
| 新增文档文件 | 文档 ↑ | 是 |
| 删除死代码 | 代码质量 ↑ | 是 |
| 新增大量未测试代码 | 测试覆盖 ↓ | 是 |
| 安全修复 | 代码质量 ↑ | 是 |
| 重大架构重构 | 各项可能变化 | 是 |

### 评级变更流程

```
1. 识别可能影响质量评级的代码变更
2. 列出具体变更和预期影响
3. 使用 AskUserQuestion 向用户展示：
   - 当前评级
   - 代码变更摘要
   - 建议的评级调整
4. 用户确认后更新 quality.md
5. 更新 quality.md 中的"最后更新"日期
```

---

## 7. Garden 模式的 .gitignore 建议

`docs/.doc-meta.json` **应该** 被提交到 git 仓库。它是 garden 模式的状态文件，需要在团队成员和 agent 之间共享。

**不应提交的：**
- 临时的扫描报告文件
- 中间计算结果

---

## 8. 首次 Garden（从 init 过渡）

如果项目通过 init 模式创建了文档体系，首次 garden 时：

1. `docs/.doc-meta.json` 应该已经存在（init Phase 4 创建）
2. `last_gardened_commit` 是 init 时的 commit
3. 所有文档的初始状态为 `fresh`
4. Garden 会从 init commit 开始分析后续变更

如果项目文档是手动创建的（没有 `.doc-meta.json`）：

1. Garden 模式在 Phase G0 检测到缺少注册表
2. 先执行 Phase 4（新鲜度注册表初始化）
3. 将当前 HEAD 作为 `last_gardened_commit`
4. 然后正常执行 G1-G5
