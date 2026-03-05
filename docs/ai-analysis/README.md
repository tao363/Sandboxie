# Sandboxie 项目分析文档索引

## 📚 文档概览

本分析采用**自底向上的分层分析方法**，从单个文件的详细分析开始，逐步整合到模块级分析，最终形成项目级全景视图。

---

## 📂 文档结构

```
docs/ai-analysis/
├── README.md                          # 本文件（索引）
├── 00-PROJECT-OVERVIEW.md             # 项目级全景分析 ⭐
├── modules/                           # 模块级分析
│   ├── 01-kernel-driver-layer.md      # 内核驱动层分析
│   ├── 02-service-layer.md            # 服务层分析
│   └── 03-gui-layer.md                # GUI 层分析
└── files/                             # 文件级分析
    ├── drv_driver.c.md                # 驱动入口文件
    ├── drv_file.c.md                  # 文件系统虚拟化
    ├── drv_process.c.md               # 进程管理
    ├── svc_main.cpp.md                # 服务入口
    └── gui_SandMan.cpp.md             # GUI 主窗口
```

---

## 🎯 阅读指南

### 快速了解项目
👉 **推荐阅读**：[00-PROJECT-OVERVIEW.md](00-PROJECT-OVERVIEW.md)

这份文档提供了 Sandboxie 项目的完整全景视图，包括：
- 项目概览和历史
- 整体架构和三层设计
- 核心技术原理
- 典型执行流程
- 安全机制
- 技术栈和统计数据
- 优势、挑战和改进建议

### 深入理解某个模块
👉 **推荐阅读**：`modules/` 目录下的对应文档

#### 1. 内核驱动层 (SbieDrv.sys)
📄 [modules/01-kernel-driver-layer.md](modules/01-kernel-driver-layer.md)

**内容**：
- 模块架构和数据流
- 核心文件清单（50+ 个文件）
- 系统调用拦截机制
- 文件系统虚拟化
- 进程隔离实现
- 内部协作模式
- 安全性和性能分析

**适合**：想了解内核级沙箱实现的开发者

#### 2. 服务层 (SbieSvc.exe)
📄 [modules/02-service-layer.md](modules/02-service-layer.md)

**内容**：
- 多服务器架构（15+ 个子服务器）
- 代理进程模式
- LPC 通信机制
- 驱动管理和通信
- 配置管理
- 权限提升代理

**适合**：想了解用户态服务实现的开发者

#### 3. GUI 层 (SandMan.exe)
📄 [modules/03-gui-layer.md](modules/03-gui-layer.md)

**内容**：
- Qt 框架应用
- MVC 架构
- Plus 独有功能
- 用户交互设计
- 多显示器支持

**适合**：想了解 GUI 实现和 Plus 功能的开发者

### 研究具体实现细节
👉 **推荐阅读**：`files/` 目录下的对应文档

#### 文件级分析列表

| 文件 | 文档 | 核心内容 |
|-----|------|---------|
| driver.c | [files/drv_driver.c.md](files/drv_driver.c.md) | 驱动入口、初始化流程、子系统管理 |
| file.c | [files/drv_file.c.md](files/drv_file.c.md) | 文件系统虚拟化、写时复制、路径重定向 |
| process.c | [files/drv_process.c.md](files/drv_process.c.md) | 进程隔离、沙箱化决策、DLL 注入 |
| main.cpp (svc) | [files/svc_main.cpp.md](files/svc_main.cpp.md) | 服务入口、代理进程、子服务器管理 |
| SandMan.cpp | [files/gui_SandMan.cpp.md](files/gui_SandMan.cpp.md) | GUI 主窗口、事件处理、多显示器支持 |

---

## 🔍 按主题查找

### 安全机制
- **系统调用拦截**：[01-kernel-driver-layer.md](modules/01-kernel-driver-layer.md) § 5.2
- **进程隔离**：[drv_process.c.md](files/drv_process.c.md) § 3.3
- **权限控制**：[01-kernel-driver-layer.md](modules/01-kernel-driver-layer.md) § 6.3
- **多层防护**：[00-PROJECT-OVERVIEW.md](00-PROJECT-OVERVIEW.md) § 7

### 虚拟化技术
- **文件系统虚拟化**：[drv_file.c.md](files/drv_file.c.md) § 3.4
- **注册表虚拟化**：[00-PROJECT-OVERVIEW.md](00-PROJECT-OVERVIEW.md) § 4.2
- **写时复制**：[drv_file.c.md](files/drv_file.c.md) § 3.4

### 进程管理
- **进程创建监控**：[drv_process.c.md](files/drv_process.c.md) § 3.2
- **沙箱化决策**：[drv_process.c.md](files/drv_process.c.md) § 3.3
- **DLL 注入**：[drv_process.c.md](files/drv_process.c.md) § 6.4

### 通信机制
- **LPC 通信**：[02-service-layer.md](modules/02-service-layer.md) § 5.2
- **IOCTL 接口**：[01-kernel-driver-layer.md](modules/01-kernel-driver-layer.md) § 4.1
- **驱动通信**：[02-service-layer.md](modules/02-service-layer.md) § 4.2

### 架构设计
- **三层架构**：[00-PROJECT-OVERVIEW.md](00-PROJECT-OVERVIEW.md) § 2
- **模块化设计**：[01-kernel-driver-layer.md](modules/01-kernel-driver-layer.md) § 2
- **MVC 架构**：[03-gui-layer.md](modules/03-gui-layer.md) § 2.2

---

## 📊 分析统计

### 分析范围

| 层级 | 文档数 | 分析文件数 | 代码行数 |
|-----|-------|-----------|---------|
| 项目级 | 1 | 全项目 | ~170,000 |
| 模块级 | 3 | ~180 | ~130,000 |
| 文件级 | 5 | 5 | ~10,000 |
| **总计** | **9** | **185+** | **~170,000** |

### 分析深度

- ✅ **架构分析**：三层架构、模块间通信
- ✅ **代码分析**：关键文件的详细分析
- ✅ **流程分析**：典型执行流程和数据流
- ✅ **安全分析**：安全机制和潜在风险
- ✅ **性能分析**：性能瓶颈和优化建议
- ✅ **质量分析**：代码质量和改进空间

---

## 🎓 学习路径

### 初学者路径
1. 阅读 [00-PROJECT-OVERVIEW.md](00-PROJECT-OVERVIEW.md) 了解整体架构
2. 阅读 [01-kernel-driver-layer.md](modules/01-kernel-driver-layer.md) 了解核心隔离机制
3. 阅读 [drv_file.c.md](files/drv_file.c.md) 了解文件虚拟化实现

### 开发者路径
1. 阅读所有模块级分析文档
2. 根据兴趣深入阅读文件级分析
3. 结合源代码进行实践

### 安全研究者路径
1. 重点阅读安全相关章节
2. 研究系统调用拦截和进程隔离
3. 分析潜在的安全风险和绕过方法

---

## 🔧 分析方法

本分析采用的方法论：

### 1. 自底向上分层分析
```
文件级分析 (单个 .c/.cpp 文件)
    ↓ 整合
模块级分析 (子系统/模块)
    ↓ 整合
项目级分析 (整体架构)
```

### 2. 多维度分析框架

每个文件/模块的分析包含：
- **职责定位**：模块的核心职责
- **公开接口**：对外暴露的 API
- **核心逻辑**：关键算法和流程
- **依赖关系**：内部和外部依赖
- **数据模型**：核心数据结构
- **潜在关注点**：安全、性能、可维护性问题
- **架构亮点**：设计优势
- **改进建议**：优化方向

### 3. 可视化辅助

使用多种图表：
- 架构图（Mermaid）
- 流程图
- 时序图
- 调用链路图

---

## 📝 文档规范

### 文档格式
- **Markdown** 格式
- 清晰的章节结构
- 代码块使用语法高亮
- 表格整理关键信息

### 命名规范
- 项目级：`00-PROJECT-OVERVIEW.md`
- 模块级：`01-xxx-layer.md`
- 文件级：`<layer>_<filename>.md`

### 内容规范
- 客观、准确、详细
- 包含代码示例
- 标注关注点（⚠️）和优势（✅）
- 提供改进建议

---

## 🤝 贡献指南

如果您想补充或改进这些分析文档：

1. **补充文件分析**：选择未分析的关键文件进行详细分析
2. **更新现有分析**：随着代码更新，同步更新分析文档
3. **添加示例**：提供更多代码示例和使用场景
4. **改进可视化**：添加更多图表和流程图
5. **翻译文档**：将文档翻译成其他语言

---

## 📞 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- Sandboxie 官方论坛
- Discord 社区

---

## 📜 许可证

本分析文档遵循与 Sandboxie 项目相同的许可证：
- Sandboxie Plus: 自定义许可证
- Sandboxie Classic: GPLv3

---

## 🙏 致谢

感谢 Sandboxie 开源项目的所有贡献者，特别是：
- David Xanatos (项目维护者)
- 原作者 Ronen Tzur
- Sophos 团队（开源发布）
- 所有社区贡献者

---

**文档创建时间**：2026-03-05  
**分析版本**：基于最新源代码  
**分析方法**：自底向上分层分析  
**文档总数**：9 个主要文档
