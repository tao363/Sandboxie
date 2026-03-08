# Sandboxie 深度学习文档

本目录包含 Sandboxie 项目的详细源码级分析文档，帮助从零开始完全掌握这个开源沙箱项目。

## 📚 文档列表

### 入门指南

1. **[00-完整学习指南.md](00-完整学习指南.md)**
   - 学习路线图
   - 前置知识要求
   - 学习方法建议
   - 实践项目推荐

2. **[01-项目概述与技术栈.md](01-项目概述与技术栈.md)**
   - 项目历史与背景
   - 核心功能介绍
   - 技术栈详解
   - 开发环境搭建

### 架构设计

3. **[02-架构设计详解.md](02-架构设计详解.md)**
   - 三层架构设计
   - 模块划分与职责
   - 通信机制
   - 数据流分析

### 核心模块分析

4. **[03-内核驱动层分析.md](03-内核驱动层分析.md)**
   - SbieDrv.sys 驱动架构
   - 驱动初始化流程
   - 核心数据结构
   - 驱动通信机制

5. **[05-系统服务层分析.md](05-系统服务层分析.md)**
   - SbieSvc.exe 服务架构
   - 进程启动代理
   - 配置管理
   - 权限提升处理

### 核心流程详解

6. **[08-核心流程详解.md](08-核心流程详解.md)**
   - 沙箱创建流程
   - 进程启动流程
   - 文件访问流程
   - 注册表访问流程

7. **[09-文件系统虚拟化详解.md](09-文件系统虚拟化详解.md)**
   - 文件系统虚拟化原理
   - 路径重定向机制
   - 写时复制实现
   - 文件恢复机制

### 源码级深度分析

8. **[10-进程管理源码详解.md](10-进程管理源码详解.md)** ⭐
   - PROCESS 结构体详解
   - 进程创建通知回调
   - 令牌过滤机制
   - DLL 注入实现
   - 完整源码示例

9. **[11-文件系统虚拟化源码详解.md](11-文件系统虚拟化源码详解.md)** ⭐
   - 路径映射算法
   - File_NtCreateFile 完整实现
   - 写时复制源码分析
   - 文件系统过滤器回调
   - 性能优化技巧

10. **[12-注册表虚拟化源码详解.md](12-注册表虚拟化源码详解.md)** ⭐
    - 注册表路径映射
    - Hive 挂载机制
    - 注册表过滤器实现
    - 键值合并算法
    - 配置规则详解

11. **[13-Hook框架与系统调用拦截源码详解.md](13-Hook框架与系统调用拦截源码详解.md)** ⭐
    - 系统调用表构建
    - Trampoline 生成技术
    - 指令分析算法
    - Hook 安装流程
    - IAT Hook 实现

## 🎯 学习路径

### 初学者路径（0基础）

```
第1周：理解整体架构
├─ 阅读 01-项目概述与技术栈.md
├─ 阅读 02-架构设计详解.md
└─ 了解基本的 Windows 概念

第2周：学习驱动层
├─ 阅读 03-内核驱动层分析.md
├─ 学习 Windows 驱动开发基础
└─ 理解系统调用拦截机制

第3周：学习核心流程
├─ 阅读 08-核心流程详解.md
├─ 阅读 09-文件系统虚拟化详解.md
└─ 理解路径重定向机制

第4周：深入源码分析
├─ 阅读 10-进程管理源码详解.md
├─ 阅读 11-文件系统虚拟化源码详解.md
├─ 阅读 12-注册表虚拟化源码详解.md
└─ 阅读 13-Hook框架与系统调用拦截源码详解.md

第5-6周：实践与调试
├─ 编译 Sandboxie 源码
├─ 使用 WinDbg 调试驱动
├─ 修改代码并测试
└─ 尝试添加新功能
```

### 开发者路径（有基础）

```
快速上手：
1. 阅读 02-架构设计详解.md - 理解整体架构
2. 阅读 10-13 的源码详解文档 - 深入核心实现
3. 结合源码进行实践
4. 尝试功能扩展
```

## 📖 文档特色

### ✅ 详细的源码分析

每个核心模块都包含：
- 完整的数据结构定义
- 详细的函数实现分析
- 真实的源码示例
- 执行流程图

### ✅ 丰富的可视化图表

使用 Mermaid 生成：
- 时序图（Sequence Diagram）
- 流程图（Flowchart）
- 架构图（Architecture Diagram）
- 状态图（State Diagram）

### ✅ 实用的调试技巧

包含：
- WinDbg 调试命令
- 日志输出方法
- 性能分析工具
- 常见问题解决

### ✅ 渐进式学习

- 从概念到实现
- 从简单到复杂
- 从理论到实践
- 从阅读到编写

## 🔧 实践建议

### 1. 搭建开发环境

```
必需工具：
- Visual Studio 2019/2022
- Windows SDK 10.0.19041.0+
- WDK (Windows Driver Kit)
- WinDbg (调试工具)
- VMware/VirtualBox (虚拟机)
```

### 2. 编译项目

```cmd
# 编译驱动
cd Sandboxie\Sandboxie
msbuild SandboxDrv.sln /p:Configuration=Release /p:Platform=x64

# 编译服务和DLL
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=x64
```

### 3. 调试技巧

```
内核调试：
1. 启用测试签名模式
   bcdedit /set testsigning on
   
2. 配置内核调试
   bcdedit /debug on
   bcdedit /dbgsettings serial debugport:1 baudrate:115200
   
3. 使用 WinDbg 连接
   设置符号路径
   设置断点
   查看日志
```

### 4. 修改代码

建议从简单的修改开始：
1. 修改日志输出
2. 添加新的配置项
3. 修改路径匹配规则
4. 添加新的Hook函数

## 📊 核心概念速查

### 三层架构

```
┌─────────────────────────────────────┐
│  应用程序层 (被沙箱化的程序)          │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│  SbieDll.dll (用户态 Hook 层)        │
│  • API Hooking                      │
│  • 路径转换                          │
│  • 与服务通信                        │
└────────────────┬────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
┌───▼──────┐         ┌───────▼──────┐
│ SbieSvc  │◄────────┤   SbieDrv    │
│ (服务)    │  IOCTL  │   (驱动)      │
└──────────┘         └──────────────┘
```

### 核心技术

| 技术 | 用途 | 实现位置 |
|-----|------|---------|
| 系统调用拦截 | 内核级API拦截 | drv/syscall.c |
| Trampoline Hook | 用户态API拦截 | dll/hook_tramp.c |
| 路径重定向 | 文件系统隔离 | drv/file.c, dll/file.c |
| 注册表Hive | 注册表隔离 | drv/key.c, dll/key.c |
| 令牌过滤 | 权限降级 | drv/token.c |
| DLL注入 | 进程初始化 | drv/dll.c |

### 关键数据结构

```c
// 进程对象
typedef struct _PROCESS {
    HANDLE pid;
    BOX *box;
    WCHAR *image_name;
    void *primary_token;
    // ...
} PROCESS;

// 沙箱对象
typedef struct _BOX {
    WCHAR *name;
    ULONG session_id;
    LIST file_paths;
    LIST key_paths;
    // ...
} BOX;

// 系统调用条目
typedef struct _SYSCALL_ENTRY {
    const UCHAR *name;
    ULONG syscall_index;
    void *ntos_func;
    P_Syscall_Handler1 handler1;
    // ...
} SYSCALL_ENTRY;
```

## 🔗 相关资源

### 官方资源

- [Sandboxie GitHub](https://github.com/sandboxie-plus/Sandboxie)
- [Sandboxie-Plus 官网](https://sandboxie-plus.com/)
- [官方文档](https://sandboxie-plus.com/sandboxie/)

### 学习资源

- [Windows Internals](https://docs.microsoft.com/en-us/sysinternals/resources/windows-internals)
- [WDK Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/)
- [Windows Driver Development Tutorial](https://www.osronline.com/)

### 社区资源

- [Sandboxie Forum](https://sandboxie-plus.com/forum/)
- [GitHub Issues](https://github.com/sandboxie-plus/Sandboxie/issues)
- [Reddit r/Sandboxie](https://www.reddit.com/r/Sandboxie/)

## 💡 常见问题

### Q1: 需要什么基础知识？

**A:** 
- C/C++ 编程
- Windows API 基础
- 基本的操作系统概念
- （可选）Windows 驱动开发经验

### Q2: 如何开始学习？

**A:** 
1. 先阅读 00-完整学习指南.md
2. 按照学习路径逐步深入
3. 结合源码阅读文档
4. 动手实践和调试

### Q3: 遇到问题怎么办？

**A:** 
1. 查看文档中的调试技巧章节
2. 使用 WinDbg 进行调试
3. 查看 GitHub Issues
4. 在社区论坛提问

### Q4: 如何贡献？

**A:** 
1. Fork 项目仓库
2. 创建功能分支
3. 提交 Pull Request
4. 参与代码审查

## 📝 文档更新日志

### 2026-03-06
- ✅ 创建完整学习指南
- ✅ 添加项目概述与技术栈
- ✅ 完成架构设计详解
- ✅ 完成内核驱动层分析
- ✅ 完成系统服务层分析
- ✅ 完成核心流程详解
- ✅ 完成文件系统虚拟化详解
- ✅ **新增：进程管理源码详解**
- ✅ **新增：文件系统虚拟化源码详解**
- ✅ **新增：注册表虚拟化源码详解**
- ✅ **新增：Hook框架与系统调用拦截源码详解**

### 待完成
- ⏳ IPC 隔离机制源码详解
- ⏳ 网络过滤源码详解
- ⏳ GUI 隔离源码详解
- ⏳ COM 隔离源码详解
- ⏳ 安全机制深度分析
- ⏳ 性能优化指南
- ⏳ 常见问题诊断

## 🎓 学习目标

通过学习这些文档，你应该能够：

✅ **理解架构** - 完全理解 Sandboxie 的三层架构设计  
✅ **读懂代码** - 能够阅读和理解任何模块的代码  
✅ **掌握原理** - 深入理解沙箱隔离的核心原理  
✅ **修改代码** - 能够自信地修改和扩展功能  
✅ **诊断问题** - 能够快速定位和解决问题  
✅ **学习技能** - 掌握 Windows 内核编程等相关技能  

## 📧 反馈与建议

如果你在学习过程中有任何问题或建议，欢迎：
- 提交 GitHub Issue
- 在论坛发帖讨论
- 贡献文档改进

---

**祝学习愉快！** 🚀
