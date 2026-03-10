# dll/lsa.c / kernel.c — LSA 与内核辅助

## 概述

`dll/lsa.c` 处理用户态 LSA（本地安全机构）API 的 Hook；`kernel.c` 封装内核级别操作的用户态接口。

## lsa.c — LSA Hook

```c
SBIEDLL_HOOK(Lsa, LsaOpenPolicy);              // 策略打开控制
SBIEDLL_HOOK(Lsa, LsaQueryInformationPolicy);  // 策略查询控制
SBIEDLL_HOOK(Lsa, LsaEnumeratePrivileges);     // 特权枚举
```

### 处理逻辑
- `LsaOpenPolicy(POLICY_WRITE)` → 拒绝写权限
- `LsaQueryInformationPolicy` → 允许只读（程序需要查询审计策略等）
- 防止沙箱程序修改本机安全策略

## kernel.c — 内核操作接口

`kernel.c` 提供一些需要直接调用内核 API 的用户态操作封装：

```c
// 直接调用 ntdll 的 NT 函数（不经过 Hook）
// 使用 __sys_NtXxx 指针（Trampoline）
void *Kernel_GetNtdllOriginalFunc(const char *name);
```

### 用途

某些内部操作（如 Dll 初始化时访问自身 DLL 文件）需要**绕过沙箱 Hook** 直接调用原始系统函数，通过调用 `__sys_Xxx` 跳板指针实现：

```c
// 例：在沙箱 Hook 生效之前读取配置文件
// 使用 __sys_NtCreateFile 而非 NtCreateFile（避免自递归）
status = __sys_NtCreateFile(&handle, FILE_READ_DATA, ...);
```
