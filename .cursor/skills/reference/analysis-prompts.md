# Sandboxie 深度分析 Prompt 模板

> 当用户要求对 Sandboxie 项目（或某个模块）进行完整的深度分析时使用这些模板。
> 分析结果会生成 Markdown 文件，可作为后续 AI 交互的上下文。

---

## 使用策略

### 对于 Sandboxie 这样的大型 C/C++ 项目，推荐的分析策略：

**不要逐文件分析**（文件太多，效率极低），而是采用**按子系统分块**的策略：

```
Level 1: 子系统分析（按功能域分块，每块包含多个相关文件）
    ↓
Level 2: 模块整合（驱动层 / DLL层 / 服务层 / API层 / UI层）
    ↓
Level 3: 项目全景
```

### Sandboxie 推荐的子系统划分：

```
Core 层（每个作为一个分析单元）：
  1. 文件系统虚拟化：core/drv/file*.c + core/dll/file*.c
  2. 注册表虚拟化：core/drv/key*.c + core/dll/key*.c
  3. 进程隔离与令牌：core/drv/process*.c + core/drv/token*.c + core/dll/proc*.c
  4. IPC 隔离：core/drv/ipc*.c + core/dll/ipc*.c
  5. 网络隔离：core/drv/net*.c + core/dll/net*.c
  6. GUI 隔离：core/drv/gui*.c + core/dll/gui*.c
  7. Hook 框架：core/dll/hook*.c + core/low/
  8. 驱动框架：core/drv/driver.c + core/drv/api.c + core/drv/conf.c + core/drv/log.c
  9. 服务框架：core/svc/ 全部

UI/API 层（每个作为一个分析单元）：
  10. QSbieAPI 核心 API
  11. SandMan 主框架 + 视图
  12. SandMan 设置与向导窗口
  13. 经典 UI (SbieCtrl)
  14. Start.exe 进程启动器

辅助层：
  15. 安装系统：install/ + Installer/
  16. COM 包装器：apps/com/
  17. 配置与模板：Templates.ini + msgs/
```

---

## Level 1: 子系统分析 Prompt

```markdown
# Role
你是一位精通 Windows 内核编程和系统安全的代码审阅专家。

# Context
- 项目：Sandboxie-Plus（Windows 应用隔离沙箱）
- 子系统：{{SUBSYSTEM_NAME}}
- 子系统简介：{{SUBSYSTEM_BRIEF}}
- 包含的文件：{{FILE_LIST}}

# Task
请对这个子系统中的所有源码进行整体分析，输出一份 Markdown 文档。

## 输出结构

### 1. 子系统概述
- 该子系统在 Sandboxie 隔离机制中的角色（2—3 句话）。
- 它的运行层级（内核态 / 用户态 / 两者兼有）。

### 2. 文件职责清单
用表格列出每个文件的核心职责：

| 文件名 | 职责 | 代码行数（估算） | 复杂度 |
|--------|------|-----------------|--------|

### 3. 核心数据结构
列出该子系统定义或使用的关键结构体、枚举、全局变量。
对核心字段加注释。

### 4. 关键函数与调用链
挑选 3—5 个最重要的函数，说明：
- 函数签名与职责
- 被谁调用、调用了谁
- 核心处理逻辑（简明描述 + 伪代码）

如有必要，用 Mermaid 时序图展示关键流程。

### 5. 驱动层 ↔ DLL 层协作
（如果该子系统跨越驱动和 DLL 两层）
说明两层之间如何协作：
- 哪些拦截在驱动层完成，哪些在 DLL 层完成
- 数据如何在两层之间传递

### 6. 配置项
列出该子系统读取的 Sandboxie.ini 配置项，说明每个配置的作用。

### 7. 关注点
- 代码质量问题（如有）
- 安全相关注意事项
- 已知的 TODO/FIXME
- 可能的性能瓶颈

# Rules
1. 只基于提供的源码分析，不臆测。
2. 使用 Windows 内核编程的标准术语。
3. 代码引用使用 `code` 格式，标注文件名和函数名。
4. 中文输出。不要寒暄。

# Input
<source_files>
{{逐一粘贴该子系统的所有文件内容，每个文件用 === 文件名 === 分隔}}
</source_files>
```

---

## Level 2: 模块整合 Prompt

```markdown
# Role
你是一位 Windows 系统安全架构师。

# Context
- 项目：Sandboxie-Plus
- 模块：{{MODULE_NAME}}（如：内核驱动 SbieDrv / 注入 DLL SbieDll / 系统服务 SbieSvc / API 层 / UI 层）
- 该模块下包含的子系统分析文档见输入部分。

# Input
<subsystem_analyses>
{{粘贴该模块下所有子系统分析 MD 的内容}}
</subsystem_analyses>

# Task
请整合这些子系统分析，输出模块级分析文档。

## 输出结构

### 1. 模块概述
- 该模块在 Sandboxie 架构中的定位（驱动/服务/DLL/API/UI）
- 它的进程身份和权限级别
- 一句话总结核心职责

### 2. 内部架构图
用 Mermaid 图展示该模块内部各子系统之间的关系。

### 3. 子系统协作
描述模块内各子系统如何协作。例如驱动模块中，
进程管理子系统如何与文件虚拟化子系统协作。

### 4. 对外接口汇总
列出该模块对外暴露的所有接口（IOCTL 号 / 导出函数 / LPC 消息 / 信号槽等）。

### 5. 配置项汇总
整合所有子系统的配置项，按功能分类。

### 6. 安全边界分析
- 该模块处于哪个安全边界内？
- 信任模型是什么？（信任来源、不信任来源）
- 有哪些关键的安全检查？

### 7. 关注点总结
整合子系统级别的关注点，去重并按严重程度排序。

# Rules
同 Level 1。
```

---

## Level 3: 项目全景 Prompt

```markdown
# Role
你是一位首席安全架构师。

# Context
- 项目：Sandboxie-Plus
- 简介：Windows 平台开源应用隔离沙箱，通过内核驱动 + DLL 注入实现文件/注册表/IPC/网络/GUI 的虚拟化隔离。
- 技术栈：C (驱动/DLL/服务), C++ (API/UI), Qt6 (Plus UI), MFC (Classic UI), WDK, InnoSetup

# Input
<module_analyses>
{{粘贴所有模块级分析文档}}
</module_analyses>

# Task
输出项目全景文档。

## 输出结构

### 1. 项目总览
### 2. 系统架构图（Mermaid，含所有模块和外部系统）
### 3. 隔离机制全景
  - 按隔离维度（文件/注册表/IPC/网络/GUI/进程）说明双层拦截策略
### 4. 核心业务流程（3—5 个，用时序图）
  - 进程启动与注入
  - 文件写操作（Copy-on-Write）
  - 沙箱创建与配置
  - 快照与恢复
  - 进程间通信隔离
### 5. 安全模型
  - 信任边界
  - 攻击面分析
  - 令牌与权限模型
### 6. 数据架构
  - 配置系统（INI → 服务 → 驱动 → DLL 的传播路径）
  - 沙箱文件存储结构
### 7. 跨模块依赖矩阵
### 8. 整体评估与建议

# Rules
同 Level 1。
```

---

## 快速启动命令

如果你使用 Claude Code 或类似工具来自动化分析，可以用以下脚本列出每个子系统应该包含的文件：

```bash
#!/bin/bash
# scan-subsystems.sh — 列出 Sandboxie 各子系统的文件
# 用法：在 Sandboxie 项目根目录运行

PROJECT_ROOT="$(pwd)"

echo "=== 1. 文件系统虚拟化 ==="
find "$PROJECT_ROOT/Sandboxie/core/drv" -name "file*" -type f
find "$PROJECT_ROOT/Sandboxie/core/dll" -name "file*" -type f

echo "=== 2. 注册表虚拟化 ==="
find "$PROJECT_ROOT/Sandboxie/core/drv" -name "key*" -type f
find "$PROJECT_ROOT/Sandboxie/core/dll" -name "key*" -type f

echo "=== 3. 进程隔离与令牌 ==="
find "$PROJECT_ROOT/Sandboxie/core/drv" \( -name "process*" -o -name "token*" -o -name "thread*" \) -type f
find "$PROJECT_ROOT/Sandboxie/core/dll" -name "proc*" -type f

echo "=== 4. IPC 隔离 ==="
find "$PROJECT_ROOT/Sandboxie/core/drv" -name "ipc*" -type f
find "$PROJECT_ROOT/Sandboxie/core/dll" -name "ipc*" -type f

echo "=== 5. 网络隔离 ==="
find "$PROJECT_ROOT/Sandboxie/core/drv" -name "net*" -type f
find "$PROJECT_ROOT/Sandboxie/core/dll" -name "net*" -type f

echo "=== 6. GUI 隔离 ==="
find "$PROJECT_ROOT/Sandboxie/core/drv" -name "gui*" -type f
find "$PROJECT_ROOT/Sandboxie/core/dll" \( -name "gui*" -o -name "gdi*" \) -type f

echo "=== 7. Hook 框架 ==="
find "$PROJECT_ROOT/Sandboxie/core/dll" -name "hook*" -type f
find "$PROJECT_ROOT/Sandboxie/core/low" -type f

echo "=== 8. 驱动框架 ==="
echo "$PROJECT_ROOT/Sandboxie/core/drv/driver.c"
echo "$PROJECT_ROOT/Sandboxie/core/drv/api.c"
echo "$PROJECT_ROOT/Sandboxie/core/drv/conf.c"
echo "$PROJECT_ROOT/Sandboxie/core/drv/log.c"
echo "$PROJECT_ROOT/Sandboxie/core/drv/verify.c"

echo "=== 9. 服务框架 ==="
find "$PROJECT_ROOT/Sandboxie/core/svc" -type f -name "*.c" -o -name "*.cpp" -o -name "*.h"

echo "=== 10. QSbieAPI ==="
find "$PROJECT_ROOT/SandboxiePlus/QSbieAPI" -type f \( -name "*.cpp" -o -name "*.h" \)

echo "=== 11—12. SandMan UI ==="
find "$PROJECT_ROOT/SandboxiePlus/SandMan" -maxdepth 2 -type f \( -name "*.cpp" -o -name "*.h" \)

echo "=== 13. 经典 UI ==="
find "$PROJECT_ROOT/Sandboxie/apps/control" -type f \( -name "*.cpp" -o -name "*.h" \)

echo "=== 14. Start.exe ==="
find "$PROJECT_ROOT/Sandboxie/apps/start" -type f \( -name "*.cpp" -o -name "*.h" \)

echo "=== 15. 安装系统 ==="
find "$PROJECT_ROOT/Sandboxie/install" -type f
find "$PROJECT_ROOT/Installer" -type f -name "*.iss"

echo "=== 16. COM 包装器 ==="
find "$PROJECT_ROOT/Sandboxie/apps/com" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" \)

echo "=== 17. 配置与模板 ==="
echo "$PROJECT_ROOT/Sandboxie/install/Templates.ini"
find "$PROJECT_ROOT/Sandboxie/msgs" -type f
```
