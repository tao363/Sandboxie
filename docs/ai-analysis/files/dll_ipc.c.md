# dll/ipc.c + ipc_start.c — IPC Hook（用户态）

## 概述

`dll/ipc.c` 拦截命名对象创建/打开 API，将沙箱进程的命名对象操作重定向到沙箱专属命名空间。`ipc_start.c` 处理进程/会话启动阶段的 IPC 初始化。

## 命名空间重定向

沙箱进程访问 `\BaseNamedObjects\MyEvent` 时，被重定向到：
```
\Sandbox\{SID}\Session_{N}\{BoxName}\BaseNamedObjects\MyEvent
```

## 关键 Hook

| API | Hook 函数 | 处理 |
|-----|---------|------|
| `NtOpenDirectoryObject` | `Ipc_NtOpenDirectoryObject` | 对象目录访问控制 |
| `NtCreateSymbolicLinkObject` | `Ipc_NtCreateSymbolicLinkObject` | 符号链接创建重定向 |
| `NtOpenSymbolicLinkObject` | `Ipc_NtOpenSymbolicLinkObject` | 符号链接打开重定向 |
| `NtCreateMutant` | `Ipc_NtCreateMutant` | 互斥体创建重定向 |
| `NtOpenMutant` | `Ipc_NtOpenMutant` | 互斥体打开重定向 |
| `NtCreateEvent` | `Ipc_NtCreateEvent` | 事件创建重定向 |
| `NtCreateSemaphore` | `Ipc_NtCreateSemaphore` | 信号量创建重定向 |
| `NtCreateSection` | `Ipc_NtCreateSection` | 内存节创建控制 |

## ipc_start.c 功能

### `Ipc_Launch_Csr()`
启动沙箱专属的 CSRSS（Client/Server Runtime）连接：
- 沙箱进程不直接连接系统 CSRSS
- 通过 SbieSvc 代理初始化 Win32 子系统连接

### `Ipc_LsaLogon()`
代理 LSA 登录操作（通过 SbieSvc 的 LsaServer）。
