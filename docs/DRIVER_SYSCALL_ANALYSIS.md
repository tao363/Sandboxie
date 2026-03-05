# Sandboxie 驱动程序 - 系统调用模块详细分析

## 概述

系统调用模块负责拦截和重定向 Windows 系统调用，这是 Sandboxie 实现沙箱化的核心机制。

## 架构

```
用户态应用
  ↓
ntdll.dll (ZwXxx)
  ↓
系统调用 (syscall/sysenter)
  ↓
内核 (NtXxx)
  ↓
Sandboxie 拦截
  ├─ handler1_func - 替换系统调用
  ├─ handler2_func - 对象打开处理
  └─ handler3_func - Procmon 支持
  ↓
原始系统调用
```

## 主要功能

1. **系统调用扫描** - 扫描 ntdll.dll 导出
2. **系统调用表构建** - 构建索引表
3. **处理程序注册** - 注册拦截处理程序
4. **调用重定向** - 重定向到自定义处理程序

## 系统调用类型

### Type 1 - 完全替换
```c
Syscall_Set1("DuplicateObject", Syscall_DuplicateHandle)
```
完全替换系统调用实现

### Type 2 - 对象打开拦截
```c
Syscall_Set2("OpenProcess", Thread_CheckProcessObject)
```
在对象打开时检查权限

### Type 3 - Procmon 支持
```c
Syscall_Set3("QuerySystemInformation", Syscall_QuerySystemInfo_SupportProcmonStack)
```
支持 Process Monitor 等工具

## 拦截的系统调用

### 进程和线程
- NtOpenProcess
- NtOpenThread
- NtCreateUserProcess
- NtGetNextProcess
- NtGetNextThread

### 文件系统
- NtCreateFile
- NtOpenFile
- NtSetInformationFile
- NtQueryInformationFile

### 注册表
- NtCreateKey
- NtOpenKey
- NtSetValueKey
- NtQueryValueKey

### IPC
- NtCreateEvent
- NtCreateMutant
- NtCreateSection
- NtConnectPort
- NtAlpcConnectPort

### 令牌
- NtOpenProcessToken
- NtOpenThreadToken
- NtSetInformationToken

## 关键函数

- `Syscall_Init()` - 初始化系统调用拦截
- `Syscall_Init_List()` - 扫描 ntdll.dll
- `Syscall_GetByName()` - 根据名称查找系统调用
- `Syscall_Invoke()` - 调用原始系统调用

## 系统调用结构

```c
typedef struct _SYSCALL_ENTRY {
    USHORT syscall_index;           // 系统调用号
    USHORT param_count;             // 参数数量
    ULONG ntdll_offset;             // ntdll 中的偏移
    void *ntos_func;                // 内核函数地址
    P_Syscall_Handler1 handler1_func;
    P_Syscall_Handler2 handler2_func;
    P_Syscall_Handler3 handler3_func;
    BOOLEAN disabled;               // 是否禁用
    BOOLEAN approved;               // 是否批准
    USHORT name_len;
    UCHAR name[64];                 // 函数名
} SYSCALL_ENTRY;
```

详细分析请参考完整文档。
