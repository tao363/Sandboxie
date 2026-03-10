# dll/proc.c — 进程 Hook（用户态）

## 概述

`dll/proc.c` 在用户态拦截进程/线程创建相关 API（`CreateProcessInternalW`、`NtCreateUserProcess` 等），确保在沙箱内启动的子进程也正确进入沙箱，并处理各种特殊情况（PCA Job、强制进程重启、WoW64 等）。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/dll/proc.c` |
| 所属模块 | SbieDll.dll |
| 语言 | C（用户态）|
| 核心职责 | 进程创建拦截、沙箱继承保证 |

## 关键函数

### `Proc_CreateProcessInternalW()`

拦截 `kernel32!CreateProcessInternalW`（所有进程创建最终都经过此函数）：
1. 解析应用程序路径和命令行
2. 若启动的是批处理文件（.bat/.cmd），修正命令行
3. 向 SbieSvc 发送 `MSGID_PROCESS_RUN_SANDBOXED` 消息（若需要特殊处理）
4. 继续调用原始 `CreateProcessInternalW`
5. 驱动层的 `Process_NotifyProcessEx` 接管后续处理

### `Proc_NtCreateUserProcess()`

拦截底层 `NtCreateUserProcess` 系统调用：
- 处理进程创建标志
- 确保子进程正确加入沙箱
- 处理 `PROC_THREAD_ATTRIBUTE_PARENT_PROCESS` 属性

### `Proc_RestartProcessOutOfPcaJob()`

若当前进程在 PCA（程序兼容性助手）Job 中，且驱动无法将其加入沙箱 Job，则重新以正确的方式启动自身，脱离 PCA Job 环境。

### `Proc_AlternateCreateProcess()`

用于特殊情况的备用进程启动路径（如 App Container 进程）。

### `Proc_ExitProcess()`

拦截 `ExitProcess`，在进程退出前执行清理操作（如自动恢复文件）。

## 进程类型识别（Dll_SelectImageType）

`proc.c` 中也包含进程类型识别逻辑：
- 检测进程名称匹配 Firefox/Chrome/IE/Office 等
- 设置 `Dll_ImageType` 供其他模块使用专属兼容补丁

## Hook 注册

```c
SBIEDLL_HOOK(Proc, CreateProcessInternalW);
SBIEDLL_HOOK(Nt, CreateUserProcess);
SBIEDLL_HOOK(Proc, ExitProcess);
SBIEDLL_HOOK(Proc, SetProcessMitigationPolicy); // 阻止某些缓解策略
```
