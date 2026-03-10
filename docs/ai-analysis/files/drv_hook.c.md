# drv/hook.c — 内核 Hook 框架

## 概述

`hook.c` 提供了 Sandboxie 驱动层的**内核函数钩子框架**，用于在内核函数入口处安装跳转指令，将调用重定向到 Sandboxie 的处理函数，同时保留调用原始函数的能力（通过 trampoline）。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/drv/hook.c` |
| 所属模块 | SbieDrv.sys |
| 核心职责 | 内核函数 Inline Hook（跳板技术）|
| 关联文件 | `hook_32.c`（x86）, `hook_64.c`（x64）|

## Hook 技术原理

Sandboxie 使用 **Inline Hook + Trampoline** 技术：

```
原始函数入口（修改后）：
  [E9 xx xx xx xx]  JMP -> Hook处理函数

Trampoline（跳板）：
  [原始前5字节备份]
  [E9 xx xx xx xx]  JMP -> 原始函数+5
```

调用链：
```
调用方 → 原始函数(被Hook) → 跳板 → Hook处理函数
                                        ↓
                              调用原始函数（通过跳板）
```

## 关键函数

### `Hook_BuildTramp(old_func, new_func, ...)`
构建跳板代码：
1. 分配可执行内存
2. 复制原始函数前 N 字节到跳板
3. 在跳板末尾添加 JMP 回原始函数+N
4. 在原始函数入口写入 JMP 到新函数
5. 需要临时关闭写保护（`DisableWriteProtect` / `EnableWriteProtect`）

### `Hook_GetService()`
从 ntdll.dll 的 Nt 函数存根中提取系统调用号，进而找到内核中对应的服务函数地址（通过 SSDT/KeServiceDescriptorTable）。

### `Hook_Find_ZwRoutine()`
在内核导出表中查找 Zw 函数对应的内核地址。

## 写保护控制

```c
// 关闭 CR0 寄存器的写保护位
void DisableWriteProtect() {
    __asm { mov eax, cr0 }
    __asm { and eax, ~0x10000 }
    __asm { mov cr0, eax }
}

// 恢复写保护
void EnableWriteProtect() {
    __asm { mov eax, cr0 }
    __asm { or  eax, 0x10000 }
    __asm { mov cr0, eax }
}
```

## ARM64 特殊处理

ARM64 上不使用 Inline Hook，而是通过拦截 `KiServiceInternal` 实现系统调用拦截（见 `driver.c: Driver_FindKiServiceInternal`）。
