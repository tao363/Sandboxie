# Sandboxie-Plus — 编码约定

本文档描述 Sandboxie-Plus 项目的编码规范和约定。这些约定从现有代码中提取，新代码应遵循这些约定以保持一致性。

---

## 命名规范

### 函数命名

| 类型 | 规则 | 示例 |
|------|------|------|
| **公共 API** | `SbieApi_*` | `SbieApi_QueryProcessInfo` |
| **DLL 内部函数** | `*_Init`, `*_Hook` | `Dll_Init`, `File_Hook` |
| **驱动函数** | 无前缀，使用下划线分隔 | `Process_Create`, `Box_Create` |
| **静态函数** | 无特殊前缀 | `static NTSTATUS SbieApi_Ioctl` |
| **回调函数** | `*_Callback` 或 `*_Proc` | `DriverEntry`, `Syscall_Callback` |

### 变量命名

| 类型 | 规则 | 示例 |
|------|------|------|
| **全局变量** | 驼峰命名 | `SbieApi_DeviceHandle` |
| **局部变量** | 驼峰命名或下划线 | `box`, `process`, `pid` |
| **结构体成员** | 下划线分隔 | `process->pid`, `box->file_path` |
| **宏常量** | 全大写下划线 | `PAGE_SIZE`, `BOXNAME_COUNT` |
| **类型定义** | 大驼峰或全大写 | `PROCESS`, `BOX`, `NTSTATUS` |

### 类型命名

```c
// 结构体使用全大写 typedef
typedef struct _PROCESS {
    LIST_ELEM list_elem;
    HANDLE pid;
    BOX *box;
} PROCESS;

// 指针类型使用 P_ 前缀
typedef struct _PROCESS *PPROCESS;

// 函数指针使用 P_ 前缀
typedef NTSTATUS (*P_NtDeviceIoControlFile)(...);
```

---

## 代码组织

### 文件头部

每个源文件必须包含标准版权声明：

```c
/*
 * Copyright 2004-2020 Sandboxie Holdings, LLC 
 * Copyright 2020-2024 David Xanatos, xanasoft.com
 *
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
```

### 文件结构

```c
// 1. 版权声明
// 2. 模块描述注释
// 3. 防止重复包含（头文件）
#ifndef _MY_MODULE_H
#define _MY_MODULE_H

// 4. 包含文件
#include "common_header.h"

// 5. 宏定义
#define MY_CONSTANT 123

// 6. 类型定义
typedef struct _MY_STRUCT { ... } MY_STRUCT;

// 7. 函数声明
void MyFunction(void);

// 8. 结束保护
#endif // _MY_MODULE_H
```

### 包含文件顺序

```c
// 1. 项目公共头文件
#include "common/defines.h"
#include "common/list.h"

// 2. 模块私有头文件
#include "dll.h"
#include "hook.h"

// 3. 系统头文件
#include <windows.h>
#include <stdio.h>

// 4. 外部库头文件
#include <ntstrsafe.h>
```

---

## 注释风格

### 文件级注释

```c
//---------------------------------------------------------------------------
// Sandboxie Driver Entry Point
//---------------------------------------------------------------------------
```

### 函数注释

```c
//---------------------------------------------------------------------------
// SbieApi_QueryProcessInfo
//
// Query information about a sandboxed process.
//
// Parameters:
//   out        - Output buffer for result
//   info_type  - Type of information to query
//
// Returns:
//   STATUS_SUCCESS on success, error code otherwise
//---------------------------------------------------------------------------

NTSTATUS SbieApi_QueryProcessInfo(ULONG *out, ULONG info_type)
{
    // ...
}
```

### 行内注释

```c
// Check if process is sandboxed
if (process->box) {
    // Process is in a sandbox
    ...
}
```

---

## 错误处理

### NTSTATUS 返回值

```c
// 正确：检查所有可能的错误
NTSTATUS status = SbieApi_Ioctl(parms);
if (!NT_SUCCESS(status)) {
    LogError("Ioctl failed: 0x%08X", status);
    return status;
}

// 错误：忽略返回值
SbieApi_Ioctl(parms);  // ❌ 未检查返回值
```

### 错误日志

```c
// 使用项目日志宏
LogError("Failed to create process: %d", GetLastError());
LogDebug("Process created: pid=%d", pid);
```

### 清理模式

```c
// 使用 goto 进行清理
NTSTATUS DoSomething(void)
{
    HANDLE handle1 = NULL;
    PVOID buffer = NULL;
    NTSTATUS status;
    
    handle1 = OpenHandle();
    if (!handle1) {
        status = STATUS_UNSUCCESSFUL;
        goto cleanup;
    }
    
    buffer = AllocateBuffer();
    if (!buffer) {
        status = STATUS_NO_MEMORY;
        goto cleanup;
    }
    
    // ... 处理逻辑 ...
    status = STATUS_SUCCESS;
    
cleanup:
    if (buffer) FreeBuffer(buffer);
    if (handle1) CloseHandle(handle1);
    return status;
}
```

---

## 内存管理

### 内核驱动内存

```c
// 使用项目内存池
PVOID buffer = Mem_Alloc(pool, size);
if (!buffer) {
    return STATUS_NO_MEMORY;
}
// ... 使用 buffer ...
Mem_Free(buffer);
```

### 用户态内存

```c
// DLL 使用进程堆
PVOID buffer = HeapAlloc(GetProcessHeap(), 0, size);
if (!buffer) {
    return FALSE;
}
// ... 使用 buffer ...
HeapFree(GetProcessHeap(), 0, buffer);
```

### 内存清零

```c
// 使用项目宏
memzero(buffer, size);
wmemzero(wbuffer, count);  // 宽字符版本
```

---

## 字符串处理

### 安全字符串函数

```c
// 正确：使用安全版本
Sbie_snwprintf(buffer, count, L"Format: %s", str);
wcscpy_s(dest, dest_size, src);

// 错误：使用不安全版本
swprintf(buffer, L"Format: %s", str);  // ❌ 可能溢出
wcscpy(dest, src);                      // ❌ 无边界检查
```

### 宽字符约定

```c
// 项目使用宽字符 (WCHAR/wchar_t)
WCHAR path[MAX_PATH];
const WCHAR* name = L"Sandboxie";

// 字符串字面量使用 L 前缀
#define MY_STRING L"MyString"
```

---

## 线程安全

### 锁使用

```c
// 驱动使用 KEY_VALUE 机制
KIRQL irql;
KeAcquireSpinLock(&lock, &irql);
// ... 临界区代码 ...
KeReleaseSpinLock(&lock, irql);

// 用户态使用 CRITICAL_SECTION
EnterCriticalSection(&lock);
// ... 临界区代码 ...
LeaveCriticalSection(&lock);
```

### 原子操作

```c
// 使用 Interlocked 函数
InterlockedIncrement(&counter);
InterlockedCompareExchange(&value, new_value, old_value);
```

---

## 代码示例

### 正确示例

```c
//---------------------------------------------------------------------------
// MyModule_Init
//
// Initialize the module.
//---------------------------------------------------------------------------

NTSTATUS MyModule_Init(void)
{
    NTSTATUS status;
    
    // Allocate resources
    g_Handle = CreateHandle();
    if (!g_Handle) {
        LogError("Failed to create handle");
        return STATUS_UNSUCCESSFUL;
    }
    
    // Initialize subsystem
    status = Subsystem_Init();
    if (!NT_SUCCESS(status)) {
        LogError("Subsystem init failed: 0x%08X", status);
        CloseHandle(g_Handle);
        g_Handle = NULL;
        return status;
    }
    
    LogDebug("Module initialized successfully");
    return STATUS_SUCCESS;
}
```

### 错误示例

```c
// ❌ 缺少错误检查
void MyModule_Init(void)
{
    g_Handle = CreateHandle();  // 未检查返回值
    Subsystem_Init();           // 未检查返回值
}

// ❌ 内存泄漏
void ProcessData(void)
{
    PVOID buffer = malloc(size);
    if (error) {
        return;  // 未释放 buffer
    }
    free(buffer);
}

// ❌ 不安全的字符串操作
void CopyName(WCHAR* dest, const WCHAR* src)
{
    wcscpy(dest, src);  // 无边界检查
}
```

---

## 特殊约定

### 函数修饰符

```c
#define ALIGNED   // 内存对齐
#define NOINLINE  // 禁止内联
#define _FX       // 函数修饰符（空定义）
```

### 时间宏

```c
// 时间转换宏
SECONDS(60)   // 60 秒
MINUTES(5)    // 5 分钟
HOURS(2)      // 2 小时
DAYS(7)       // 7 天
```

### 版本宏

```c
#define VERSION_MJR  5
#define VERSION_MIN  72
#define VERSION_REV  3
#define VERSION_UPD  0
```

---

## 相关文档

- [入门指南](getting-started.md) — 新贡献者入门
- [构建系统](../architecture/build-system.md) — 构建说明
- [安全模型](../architecture/security-model.md) — 安全开发规则
