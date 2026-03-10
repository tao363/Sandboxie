# drv/process_hook.c — 进程 Hook 安装

## 概述

`process_hook.c` 负责在沙箱进程中**安装 Hook 框架的核心基础设施**，包括为注入的 DLL 准备系统调用拦截数据，以及协调用户态 Hook 与内核态拦截的衔接。

## 关键函数

### `Process_Hook_BuildSyscallData(proc, SyscallData)`

将驱动中的系统调用拦截表（`syscall.c` 建立的 `Syscall_Table`）序列化为用户态可读的格式，写入共享内存，供 SbieDll 在初始化时读取：

```c
// 序列化格式
typedef struct _SYSCALL_ENTRY_USER {
    ULONG index;          // 系统调用号
    ULONG param_count;    // 参数数量
    ULONG handler_flags;  // 拦截标志
    CHAR  name[1];        // 系统调用名称
} SYSCALL_ENTRY_USER;
```

### `Process_Hook_FixSyscalls(proc, ntdll_base)`

在进程启动时（注入阶段）修正 ntdll 系统调用存根：
- 对于需要驱动代理执行的系统调用（通过 `Syscall_Api_Invoke`），将 ntdll 中对应的 Nt 函数存根替换为调用驱动 IOCTL 的代码
- 确保 WoW64 进程（32位）的系统调用号与 64 位内核的正确映射

## process_util.c — 进程辅助工具

`process_util.c` 提供进程管理的通用辅助函数：

### `Process_GetImageName(pid, buf, len)`
获取指定进程的可执行文件名（basename），用于强制规则匹配。

### `Process_MatchImageName(proc, pattern)`
带通配符的进程名匹配（支持 `*` 和 `?`），用于 `ForceProcess`、`AlertProcess` 规则检查。

### `Process_IsSameBox(proc1, proc2)`
检查两个 PROCESS 是否属于同一沙箱（相同 BoxName + SID + SessionId）。

### `Process_GetConfBool(proc, name, def)`
便捷函数，读取进程所属沙箱的布尔配置值（封装 `Conf_Get_Boolean`）。
