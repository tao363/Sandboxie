# Sandboxie Analyzer Skill - 使用指南

## 快速开始

这个 skill 已经创建完成！它可以帮助你深度分析 Sandboxie 项目。

## 主要功能

### 1. 架构分析
询问项目的整体架构、模块关系、通信机制等。

**示例问题**：
- "帮我分析 Sandboxie 的整体架构"
- "三层架构是如何协作的"
- "生成架构图"

### 2. 功能分析
分析特定功能的实现原理和执行流程。

**示例问题**：
- "文件系统虚拟化是如何实现的"
- "进程隔离的原理是什么"
- "生成文件操作的时序图"

### 3. 函数分析
深入分析特定函数的实现细节。

**示例问题**：
- "分析 File_NtCreateFile 函数"
- "Process_CreateProcessInternalW 做了什么"
- "这个函数的调用链是什么"

### 4. 结构体分析
分析数据结构的设计和使用。

**示例问题**：
- "PROCESS 结构体有哪些字段"
- "BOX 结构体是如何使用的"
- "分析 SYSCALL_ENTRY 的设计"

### 5. 流程分析
生成各种流程的可视化图表。

**示例问题**：
- "生成进程启动的时序图"
- "画出文件操作的流程图"
- "展示模块间的依赖关系"

### 6. 问题诊断
帮助定位和解决问题。

**示例问题**：
- "为什么某个程序在沙箱中无法运行"
- "这个崩溃是什么原因"
- "如何调试这个问题"

### 7. 学习指导
提供学习路径和技术指导。

**示例问题**：
- "我想学习 Sandboxie，从哪里开始"
- "如何学习 Windows 内核编程"
- "API Hook 的原理是什么"

## 参考文档

skill 包含以下参考文档：

- `references/architecture-overview.md` - 架构总览
- `references/module-mapping.md` - 模块映射表
- `templates/function-analysis.md` - 函数分析模板
- `templates/struct-analysis.md` - 结构体分析模板
- `templates/flow-analysis.md` - 流程分析模板

## 工具脚本

- `scripts/search-code.py` - 代码搜索工具

使用方法：
```bash
# 搜索函数
python scripts/search-code.py --function "File_NtCreateFile"

# 搜索结构体
python scripts/search-code.py --struct "PROCESS"

# 搜索配置项
python scripts/search-code.py --config "OpenFilePath"

# 搜索所有
python scripts/search-code.py --all "NtCreateFile"
```

## 学习路径

### 初学者（0 基础）
1. 阅读架构总览，理解三层架构
2. 学习 Windows 基础概念
3. 分析简单的函数和流程
4. 逐步深入各个模块

### 开发者（有基础）
1. 快速浏览架构文档
2. 根据需求定位相关模块
3. 深入分析具体实现
4. 尝试修改和扩展

### 安全研究者
1. 重点分析隔离机制
2. 研究可能的绕过方法
3. 评估安全边界
4. 提出改进建议

## 下一步

现在你可以开始使用这个 skill 了！只需要向 AI 提问，它会自动使用这个 skill 来帮助你分析 Sandboxie 项目。

祝学习愉快！🚀
