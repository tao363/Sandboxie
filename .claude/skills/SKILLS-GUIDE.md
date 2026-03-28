# Sandboxie Skills 使用指南

## 📚 Skills 概览

为 Sandboxie 项目创建了两个互补的 skills：

### 1. sandboxie-codebase (代码导航)
**位置**：`.cursor/skills/SKILL.md`  
**用途**：代码导航、架构理解、模块分析

**适用场景**：
- ✅ 理解项目架构和模块关系
- ✅ 查找特定功能的代码位置
- ✅ 分析代码结构和设计模式
- ✅ 浏览项目文件和目录结构
- ✅ 学习 Sandboxie 的实现原理

**关键词**：架构、代码在哪、模块分析、项目结构、函数定位、沙箱原理

---

### 2. sandboxie-modifier (代码修改)
**位置**：`.cursor/skills/sandboxie-modifier/SKILL.md`  
**用途**：修改、优化、测试核心模块

**适用场景**：
- ✅ 修改内核驱动（SbieDrv）
- ✅ 修改系统服务（SbieSvc）
- ✅ 修改注入 DLL（SbieDll）
- ✅ 性能优化和代码重构
- ✅ Bug 修复和安全增强
- ✅ 编译、测试、调试、部署

**关键词**：修改驱动、优化性能、修复 bug、增强安全、测试沙箱、编译 Sandboxie

---

## 🎯 使用决策树

```
用户请求
    ↓
是否需要修改代码？
    ↓ NO
使用 sandboxie-codebase
    - 查看架构文档
    - 定位代码位置
    - 理解实现原理
    ↓ YES
使用 sandboxie-modifier
    - 分析修改范围
    - 实施代码修改
    - 编译和测试
    - 部署验证
```

---

## 📖 完整分析文档

已生成的详细分析文档位于 `docs/ai-analysis/`：

### 文档结构

```
docs/ai-analysis/
├── README.md                          ⭐ 索引和导航
├── ANALYSIS-SUMMARY.md                📝 分析完成总结
├── 00-PROJECT-OVERVIEW.md             🌐 项目全景（539行）
├── modules/                           📂 模块级分析
│   ├── 01-kernel-driver-layer.md      🔧 内核驱动层（385行）
│   ├── 02-service-layer.md            🏢 服务层（376行）
│   └── 03-gui-layer.md                🎨 GUI层（58行）
└── files/                             📂 文件级分析
    ├── drv_driver.c.md                📄 驱动入口（290行）
    ├── drv_file.c.md                  📄 文件虚拟化（383行）
    ├── drv_process.c.md               📄 进程管理（487行）
    ├── svc_main.cpp.md                📄 服务入口（514行）
    └── gui_SandMan.cpp.md             📄 GUI主窗口（463行）
```

### 推荐阅读顺序

**快速入门**：
1. `README.md` - 了解文档结构
2. `00-PROJECT-OVERVIEW.md` - 了解整体架构
3. 根据需求选择模块级或文件级文档

**深入研究**：
1. 按模块顺序阅读所有文档
2. 结合源代码进行实践
3. 使用 skills 辅助开发

---

## 💡 使用示例

### 示例 1：查找文件虚拟化代码

**用户问题**：文件虚拟化的代码在哪里？

**使用 skill**：`sandboxie-codebase`

**操作步骤**：
1. 查看 `docs/ai-analysis/files/drv_file.c.md`
2. 了解文件虚拟化的实现原理
3. 定位到 `Sandboxie/core/drv/file.c`
4. 查看相关函数实现

---

### 示例 2：优化文件系统性能

**用户问题**：如何优化文件操作的性能？

**使用 skill**：`sandboxie-modifier`

**操作步骤**：
1. 阅读性能分析章节
2. 定位性能瓶颈（file.c）
3. 实施优化（添加缓存）
4. 编译测试
5. 性能对比验证

---

### 示例 3：添加新的配置项

**用户问题**：如何添加一个新的沙箱配置选项？

**使用 skill**：`sandboxie-modifier`

**操作步骤**：
1. 查看"添加新的配置项"模板
2. 修改相关文件：
   - `core/drv/conf.c` - 驱动侧读取
   - `install/Templates.ini` - 默认值
   - `msgs/Sbie-English-1033.txt` - 说明文本
3. 编译和测试
4. 验证功能

---

### 示例 4：理解进程隔离机制

**用户问题**：Sandboxie 是如何实现进程隔离的？

**使用 skill**：`sandboxie-codebase`

**操作步骤**：
1. 阅读 `docs/ai-analysis/00-PROJECT-OVERVIEW.md` § 4.2
2. 阅读 `docs/ai-analysis/files/drv_process.c.md` § 3.3
3. 查看源代码 `core/drv/process.c`
4. 理解沙箱化决策流程

---

## 🔧 Skills 特性对比

| 特性 | sandboxie-codebase | sandboxie-modifier |
|-----|-------------------|-------------------|
| 架构总览 | ✅ 详细 | ✅ 简要 |
| 代码定位 | ✅ 完整 | ✅ 针对性 |
| 修改指南 | ❌ | ✅ 详细 |
| 编译构建 | ❌ | ✅ 完整 |
| 测试验证 | ❌ | ✅ 完整 |
| 调试技巧 | ❌ | ✅ 详细 |
| 性能分析 | ❌ | ✅ 工具 |
| 代码审查 | ❌ | ✅ 清单 |

---

## 📊 分析成果统计

### 文档数量
- **总文档数**：11 个
- **项目级**：1 个（全景分析）
- **模块级**：3 个（驱动、服务、GUI）
- **文件级**：5 个（核心文件）
- **辅助文档**：2 个（索引、总结）

### 代码覆盖
- **分析代码量**：~170,000 行
- **核心文件数**：185+ 个
- **文档总行数**：3,500+ 行
- **文档总大小**：90,000+ 字节

---

## 🎓 学习路径

### 初学者路径
1. 阅读 `00-PROJECT-OVERVIEW.md` 了解整体架构
2. 使用 `sandboxie-codebase` skill 浏览代码
3. 阅读模块级分析文档
4. 尝试简单的代码修改

### 开发者路径
1. 深入阅读所有分析文档
2. 使用 `sandboxie-codebase` skill 定位代码
3. 使用 `sandboxie-modifier` skill 进行修改
4. 参与项目开发和优化

### 安全研究者路径
1. 重点阅读安全相关章节
2. 研究系统调用拦截机制
3. 分析潜在的安全风险
4. 提出改进建议

---

## 🚀 快速开始

### 第一次使用

1. **阅读索引**：
   ```
   打开 docs/ai-analysis/README.md
   ```

2. **了解架构**：
   ```
   打开 docs/ai-analysis/00-PROJECT-OVERVIEW.md
   ```

3. **选择 skill**：
   - 只是查看代码 → `sandboxie-codebase`
   - 需要修改代码 → `sandboxie-modifier`

4. **开始工作**：
   - 使用 skill 提供的模板和指南
   - 参考分析文档理解代码
   - 遵循最佳实践

---

## 📞 获取帮助

如有问题：
1. 查看 `docs/ai-analysis/README.md` 的详细索引
2. 搜索分析文档中的相关章节
3. 使用对应的 skill 获取指导
4. 参考 Sandboxie 官方文档和社区

---

## 📝 更新日志

### 2026-03-05
- ✅ 创建 `sandboxie-codebase` skill（代码导航）
- ✅ 创建 `sandboxie-modifier` skill（代码修改）
- ✅ 生成完整的项目分析文档（11 个文档）
- ✅ 建立文件级 → 模块级 → 项目级的分析体系

---

**文档版本**：1.0  
**最后更新**：2026-03-05  
**维护者**：AI 分析系统
