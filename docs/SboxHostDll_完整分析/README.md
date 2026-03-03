# SboxHostDll 完整深度分析文档

## 文档结构

本分析文档分为多个部分，每个部分深入剖析 SboxHostDll 模块的不同方面：

### 📚 文档索引

**⚡ 快速入门**
- **[快速参考.md](./快速参考.md)** - 5分钟快速了解模块核心

**📖 完整分析**
1. **[00_总结文档.md](./00_总结文档.md)** - 完整技术分析总结
2. **[01_模块概述与架构.md](./01_模块概述与架构.md)** - 模块整体架构、设计目标和技术栈
3. **[02_文件详细分析_Part1.md](./02_文件详细分析_Part1.md)** - 每个源文件的逐行分析
4. **[03_核心函数深度解析.md](./03_核心函数深度解析.md)** - 关键函数的算法和实现细节
5. **[04_令牌处理机制详解.md](./04_令牌处理机制详解.md)** - Windows 令牌和 SID 的深入分析

---

## 快速导航

### 核心概念
- [什么是 SboxHostDll？](./01_模块概述与架构.md#模块定义)
- [为什么需要这个模块？](./01_模块概述与架构.md#问题背景)
- [技术架构图](./01_模块概述与架构.md#架构设计)

### 关键技术
- [OpenProcessToken Hook 实现](./03_核心函数深度解析.md#sboxhostdll_openprocesstoken)
- [令牌替换算法](./05_令牌处理机制.md#令牌替换算法)
- [进程验证机制](./06_DLL注入流程.md#进程验证)

### 实用信息
- [如何调试](./08_调试与故障排查.md)
- [性能优化建议](./09_性能分析与优化.md)
- [常见问题解答](./08_调试与故障排查.md#常见问题)

---

## 模块概述

**SboxHostDll** 是 Sandboxie 沙箱系统中的一个专用兼容性模块，专门用于解决 Microsoft Office ClickToRun 服务在沙箱环境中的访问令牌问题。

### 核心功能

```
┌─────────────────────────────────────────────────────────────┐
│                    SboxHostDll 工作流程                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Sandboxie 检测到 OfficeClickToRun.exe 启动             │
│                        ↓                                    │
│  2. 注入 SboxHostDll.dll 到目标进程                         │
│                        ↓                                    │
│  3. DllMain 验证进程名称                                    │
│                        ↓                                    │
│  4. InjectDllMain 初始化 Hook                               │
│                        ↓                                    │
│  5. Hook OpenProcessToken API                               │
│                        ↓                                    │
│  6. 拦截令牌请求，检查是否需要替换                          │
│                        ↓                                    │
│  7. 查找主机进程中的有效令牌                                │
│                        ↓                                    │
│  8. 返回替换后的令牌给调用者                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 技术特点

- ✅ **精准目标定位**：只在 OfficeClickToRun.exe 中激活
- ✅ **智能令牌替换**：自动识别需要替换的特殊账户令牌
- ✅ **会话一致性**：通过 Logon SID 匹配确保会话一致
- ✅ **安全防护**：严格的进程验证和错误处理
- ✅ **透明集成**：对应用程序完全透明

### 解决的问题

Microsoft Office ClickToRun 使用虚拟账户（Virtual Account）或匿名登录账户运行服务，这些特殊账户的访问令牌在 Sandboxie 沙箱环境中受到限制，导致：

- ❌ Office 应用无法正常启动
- ❌ ClickToRun 服务无法访问必要的系统资源
- ❌ 文档打开失败或功能受限

SboxHostDll 通过提供有效的主机令牌解决了这些问题。

---

## 技术栈

### 开发语言和框架
- **C++** (C++11 标准)
- **ATL (Active Template Library)** - 用于安全对象处理
- **Windows API** - 系统级编程接口

### 关键依赖
- `Advapi32.dll` - 高级 Windows API（令牌、安全等）
- `Psapi.dll` - 进程状态 API
- `SbieDll.dll` - Sandboxie 核心 DLL

### 编译环境
- Visual Studio 2017 或更高版本
- Windows SDK 10.0 或更高版本
- 支持 x86 和 x64 架构

---

## 代码统计

| 文件 | 行数 | 主要内容 |
|------|------|----------|
| dllmain.cpp | ~80 | DLL 入口点和进程验证 |
| SboxHostDll.cpp | ~180 | 核心 Hook 和令牌处理逻辑 |
| SboxHostDll.h | ~20 | 常量定义 |
| stdafx.h | ~35 | 预编译头文件 |
| stdafx.cpp | ~25 | 预编译头实现 |
| targetver.h | ~25 | 平台版本定义 |
| resource.h | ~30 | 资源定义 |
| **总计** | **~395** | **纯代码约 260 行** |

---

## 版权和许可

```
Copyright 2004-2020 Sandboxie Holdings, LLC
Copyright 2022 David Xanatos, xanasoft.com

Licensed under GNU General Public License v3.0 or later
```

---

## 阅读建议

### 快速入门
**⚡ 5分钟快速了解**: [快速参考指南](./快速参考.md)

### 初学者路径
1. 先阅读 [快速参考指南](./快速参考.md) 快速了解
2. 然后阅读 [模块概述与架构](./01_模块概述与架构.md) 了解整体设计
3. 最后阅读 [核心函数深度解析](./03_核心函数深度解析.md) 掌握实现细节

### 开发者路径
1. 直接阅读 [文件详细分析](./02_文件详细分析.md) 了解代码结构
2. 深入 [API Hook技术详解](./04_API_Hook技术详解.md) 理解 Hook 机制
3. 参考 [调试与故障排查](./08_调试与故障排查.md) 进行开发调试

### 安全研究者路径
1. 阅读 [令牌处理机制](./05_令牌处理机制.md) 了解安全模型
2. 深入 [安全性分析](./07_安全性分析.md) 评估风险
3. 参考 [性能分析与优化](./09_性能分析与优化.md) 了解实现细节

---

## 相关资源

### Sandboxie 项目
- [Sandboxie GitHub](https://github.com/sandboxie-plus/Sandboxie)
- [Sandboxie 官方文档](https://sandboxie-plus.com/sandboxie/)

### Windows 安全编程
- [Access Tokens (Microsoft Docs)](https://docs.microsoft.com/en-us/windows/win32/secauthz/access-tokens)
- [Security Identifiers (SIDs)](https://docs.microsoft.com/en-us/windows/win32/secauthz/security-identifiers)
- [DLL Injection Techniques](https://www.microsoft.com/security/blog/)

### ATL 编程
- [ATL Security Classes](https://docs.microsoft.com/en-us/cpp/atl/atl-security-classes)
- [CAccessToken Class](https://docs.microsoft.com/en-us/cpp/atl/reference/caccesstoken-class)

---

## 更新日志

- **2024-01**: 初始版本，完整分析 SboxHostDll 模块
- 基于 Sandboxie Plus 最新代码库

---

**开始阅读**: [01_模块概述与架构.md](./01_模块概述与架构.md) →
