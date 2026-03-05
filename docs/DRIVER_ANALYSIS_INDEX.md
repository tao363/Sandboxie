# Sandboxie 驱动程序代码分析 - 文档索引

## 概述

本系列文档详细分析了 Sandboxie 驱动程序（`Sandboxie\core\drv`）的代码结构、功能和实现细节。

## 已创建的分析文档

### 1. 主文档
📄 **[DRIVER_CODE_ANALYSIS.md](./DRIVER_CODE_ANALYSIS.md)**
- 驱动程序整体架构概述
- 模块分类和组织结构
- 工作原理和流程图
- 关键技术说明
- 安全特性介绍

### 2. 核心模块分析
📄 **[DRIVER_CORE_ANALYSIS.md](./DRIVER_CORE_ANALYSIS.md)**
- `driver.c/h` - 驱动程序入口和全局管理
- `api.c/h` - 用户态通信 API 接口
- `conf.c/h` - 配置管理
- `util.c/h` - 通用工具函数
- `mem.c/h` - 内存管理
- `log.c/h` - 日志系统
- `log_buff.c/h` - 日志缓冲区

### 3. 进程管理模块分析
📄 **[DRIVER_PROCESS_ANALYSIS.md](./DRIVER_PROCESS_ANALYSIS.md)**
- `process.c/h` - 进程管理核心
- `process_api.c` - 进程 API 函数
- `process_force.c` - 强制沙箱化
- `process_low.c` - 底层进程操作
- `process_util.c` - 进程工具函数
- `process_hook.c` - 进程钩子
- `thread.c/h` - 线程管理
- `thread_token.c` - 线程令牌管理

### 4. 文件系统模块分析
📄 **[DRIVER_FILE_ANALYSIS.md](./DRIVER_FILE_ANALYSIS.md)**
- `file.c/h` - 文件系统核心
- `file_flt.c` - 微过滤器实现（Vista+）
- `file_xp.c` - 解析过程钩子（XP）
- `file_xlat.c` - 路径转换
- `file_ctrl.c` - 文件控制操作

### 5. 注册表模块分析
📄 **[DRIVER_KEY_ANALYSIS.md](./DRIVER_KEY_ANALYSIS.md)**
- `key.c/h` - 注册表核心
- `key_flt.c` - 注册表回调（Vista+）
- `key_xp.c` - 解析过程钩子（XP）

### 6. IPC 模块分析
📄 **[DRIVER_IPC_ANALYSIS.md](./DRIVER_IPC_ANALYSIS.md)**
- `ipc.c/h` - IPC 拦截核心
- `ipc_lsa.c` - LSA 端点处理
- `ipc_sam.c` - SAM 端点处理
- `ipc_port.c` - LPC/ALPC 端口处理
- `ipc_spl.c` - 打印后台处理程序

### 7. 安全模块分析
📄 **[DRIVER_SECURITY_ANALYSIS.md](./DRIVER_SECURITY_ANALYSIS.md)**
- `token.c/h` - 令牌管理
- `verify.c/h` - 证书验证

### 8. 系统调用模块分析
📄 **[DRIVER_SYSCALL_ANALYSIS.md](./DRIVER_SYSCALL_ANALYSIS.md)**
- `syscall.c/h` - 系统调用拦截框架
- `syscall_32.c` - 32位系统调用
- `syscall_64.c` - 64位系统调用
- `syscall_open.c` - 系统调用开放接口
- `syscall_util.c` - 系统调用工具
- `syscall_win32.c` - Win32k 系统调用

## 文档结构

每个模块分析文档包含以下内容：

1. **概述** - 模块的主要功能和作用
2. **架构** - 模块的设计架构
3. **数据结构** - 关键数据结构定义
4. **关键函数** - 重要函数的详细说明
5. **工作流程** - 处理流程和逻辑
6. **配置选项** - 相关配置说明
7. **示例** - 代码示例和使用场景

## 核心概念

### 1. 沙箱化流程

```
进程启动
  ↓
Process_NotifyProcessEx (进程通知)
  ↓
Process_NotifyProcess_Create (创建进程对象)
  ↓
Process_Low_Inject (注入 SbieDll.dll)
  ↓
Process_NotifyImage (镜像加载通知)
  ↓
初始化各个子系统
  ├─ File_InitProcess (文件系统)
  ├─ Key_InitProcess (注册表)
  ├─ Ipc_InitProcess (IPC)
  ├─ Gui_InitProcess (GUI)
  └─ Token_ReplacePrimary (令牌)
  ↓
进程完全沙箱化
```

### 2. 文件系统虚拟化

```
应用程序访问文件
  ↓
File_PreOperation (微过滤器拦截)
  ↓
File_Generic_MyParseProc (解析路径)
  ↓
Process_MatchPathEx (匹配规则)
  ↓
决策：
  ├─ 在沙箱内 → 直接访问
  ├─ OpenFilePath → 直接访问真实文件
  ├─ ClosedFilePath → 拒绝访问
  ├─ ReadFilePath → 只读访问真实文件
  └─ 写访问 → 重定向到沙箱（写时复制）
```

### 3. 注册表虚拟化

```
应用程序访问注册表
  ↓
Key_Callback (注册表回调)
  ↓
Key_MyParseProc_2 (解析路径)
  ↓
Process_MatchPathEx (匹配规则)
  ↓
决策：
  ├─ 在沙箱配置单元内 → 直接访问
  ├─ OpenKeyPath → 直接访问真实注册表
  ├─ ClosedKeyPath → 拒绝访问
  └─ 写访问 → 重定向到沙箱配置单元
```

### 4. 系统调用拦截

```
用户态调用 ZwXxx
  ↓
系统调用 (syscall/sysenter)
  ↓
内核 NtXxx
  ↓
Sandboxie 拦截
  ├─ Type 1: 完全替换
  ├─ Type 2: 对象打开检查
  └─ Type 3: Procmon 支持
  ↓
原始系统调用或自定义处理
```

## 关键技术

### 1. 写时复制（Copy-on-Write）
- 首次写入时从真实位置复制到沙箱
- 后续访问使用沙箱副本
- 节省磁盘空间和提高性能

### 2. 路径重定向
- 文件系统：`C:\Windows\...` → `<BoxPath>\drive\C\Windows\...`
- 注册表：`HKCU\Software\...` → `<Hive>\Software\...`
- IPC：`\BaseNamedObjects\...` → `\Sandbox\...\BaseNamedObjects\...`

### 3. 令牌过滤
- 移除管理员权限
- 移除危险特权
- 设置低完整性级别
- 添加受限 SID

### 4. 对象隔离
- 进程和线程隔离
- 命名对象隔离
- LPC/ALPC 端口隔离

## 目录结构

```
Sandboxie\core\drv\
├── 核心模块
│   ├── driver.c/h          - 驱动程序入口
│   ├── api.c/h             - API 接口
│   ├── conf.c/h            - 配置管理
│   ├── util.c/h            - 工具函数
│   ├── mem.c/h             - 内存管理
│   ├── log.c/h             - 日志系统
│   └── log_buff.c/h        - 日志缓冲区
│
├── 进程管理
│   ├── process.c/h         - 进程核心
│   ├── process_*.c         - 进程子模块
│   ├── thread.c/h          - 线程管理
│   └── thread_token.c      - 线程令牌
│
├── 文件系统
│   ├── file.c/h            - 文件核心
│   ├── file_flt.c          - 微过滤器
│   ├── file_xp.c           - XP 钩子
│   ├── file_xlat.c         - 路径转换
│   └── file_ctrl.c         - 文件控制
│
├── 注册表
│   ├── key.c/h             - 注册表核心
│   ├── key_flt.c           - 注册表回调
│   └── key_xp.c            - XP 钩子
│
├── IPC
│   ├── ipc.c/h             - IPC 核心
│   ├── ipc_lsa.c           - LSA 端点
│   ├── ipc_sam.c           - SAM 端点
│   ├── ipc_port.c          - LPC/ALPC
│   └── ipc_spl.c           - 打印后台
│
├── 安全
│   ├── token.c/h           - 令牌管理
│   └── verify.c/h          - 证书验证
│
├── 系统调用
│   ├── syscall.c/h         - 系统调用框架
│   ├── syscall_32.c        - 32位
│   ├── syscall_64.c        - 64位
│   ├── syscall_open.c      - 开放接口
│   ├── syscall_util.c      - 工具
│   └── syscall_win32.c     - Win32k
│
├── GUI
│   ├── gui.c/h             - GUI 核心
│   └── gui_xp.c            - XP 钩子
│
├── 其他
│   ├── hook.c/h            - 钩子管理
│   ├── dll.c/h             - DLL 管理
│   ├── obj.c/h             - 对象管理
│   ├── session.c/h         - 会话管理
│   ├── box.c/h             - 沙箱配置
│   ├── wfp.c/h             - 网络过滤
│   └── dyn_data.c/h        - 动态数据
```

## 统计信息

- **总文件数**：约 80 个源文件
- **代码行数**：约 100,000+ 行
- **支持的系统调用**：约 400+ 个
- **支持的操作系统**：Windows XP 到 Windows 11
- **支持的架构**：x86, x64, ARM64

## 使用建议

1. **从主文档开始**：先阅读 `DRIVER_CODE_ANALYSIS.md` 了解整体架构
2. **按模块深入**：根据兴趣选择特定模块的详细分析
3. **结合源码**：文档配合源代码阅读效果更佳
4. **关注流程图**：理解各模块之间的交互关系
5. **参考配置**：了解如何通过配置控制行为

## 相关资源

- [Sandboxie 官方网站](https://sandboxie-plus.com/)
- [GitHub 仓库](https://github.com/sandboxie-plus/Sandboxie)
- [用户文档](https://sandboxie-plus.com/sandboxie/docs/)
- [开发者论坛](https://github.com/sandboxie-plus/Sandboxie/discussions)

## 贡献

如果您发现文档中的错误或有改进建议，欢迎：
1. 提交 Issue
2. 创建 Pull Request
3. 在论坛讨论

## 许可证

本文档遵循与 Sandboxie 相同的 GPLv3 许可证。

---

**最后更新**：2024年
**文档版本**：1.0
**适用于**：Sandboxie 5.55+
