# drv/dyn_data.c — 动态数据（版本适配）

## 概述

`dyn_data.c` 提供不同 Windows 版本之间的**内核结构体偏移量**和**未导出函数地址**，使驱动能在多个 Windows 版本上正确访问内核数据结构，无需硬编码偏移。

## 工作原理

Windows 内核的许多内部结构（如 `EPROCESS`、`KTHREAD`）在不同版本中字段偏移不同。`dyn_data.c` 维护一个按 OS Build 号索引的数据表：

```c
typedef struct _DYN_DATA {
    ULONG build;              // Windows Build 号
    ULONG eproc_token;        // EPROCESS.Token 字段偏移
    ULONG eproc_job;          // EPROCESS.Job 字段偏移
    ULONG kthread_trap_frame; // KTHREAD.TrapFrame 字段偏移
    ULONG obj_type_index;     // OBJECT_TYPE.Index 字段偏移
    // ... 更多字段
} DYN_DATA;

// 静态数据表（每个支持的 Windows 版本一条记录）
static DYN_DATA DynData_Table[] = {
    { 7601,  0xF8, 0x150, ... },  // Windows 7 SP1
    { 9200,  0xF8, 0x158, ... },  // Windows 8
    { 10240, 0x358, 0x3A0, ... }, // Windows 10 1507
    // ...
};
```

## 关键函数

### `DynData_Init()`
根据 `Driver_OsBuild` 在 `DynData_Table` 中查找匹配记录，设置全局 `Dyn_Data` 指针。若找不到匹配版本则驱动拒绝加载。

### 使用示例

```c
// token.c 中：通过动态偏移访问 EPROCESS.Token
ULONG_PTR token_ptr = *(ULONG_PTR*)((UCHAR*)eprocess + Dyn_Data->eproc_token);
```
