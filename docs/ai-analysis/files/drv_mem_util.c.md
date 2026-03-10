# drv/mem.c / util.c — 内核工具库

## 概述

`mem.c` 和 `util.c` 提供驱动内核态的**底层工具函数库**，封装内存分配、字符串操作、链表管理等基础功能，供所有其他驱动模块使用。

## mem.c — 内存管理

### Pool（内存池）

Sandboxie 使用自定义内存池而非直接调用 `ExAllocatePoolWithTag`，好处是：
- 进程退出时一次性释放整个池（`Pool_Delete`），无内存泄漏风险
- 调试时可追踪单个池的总用量

```c
POOL *Pool_Create(void);
void *Pool_Alloc(POOL *pool, ULONG size);
void  Pool_Free(void *ptr, ULONG size);  // 可选释放（池被整体删除时自动释放）
void  Pool_Delete(POOL *pool);           // 释放整个池
```

### 全局池 vs 进程池

- `Driver_Pool`：全局池，生命周期与驱动相同
- `proc->pool`：进程池，进程退出时 `Pool_Delete` 一次性释放所有分配

## util.c — 通用工具

### 字符串函数

```c
WCHAR *Util_Alloc_String(POOL *pool, const WCHAR *str);
int    Util_wcsicmp_len(const WCHAR *a, const WCHAR *b, int len); // 不区分大小写比较
BOOLEAN Util_MatchPattern(const WCHAR *pattern, const WCHAR *str); // 通配符匹配
```

### 链表操作（list.h）

```c
void List_Init(LIST *list);
void List_Insert_Before(LIST *list, LIST_ELEM *elem, LIST_ELEM *new_elem);
void List_Remove(LIST *list, LIST_ELEM *elem);
LIST_ELEM *List_Head(LIST *list);
LIST_ELEM *List_Next(LIST_ELEM *elem);
```

### 哈希表操作（hash.h）

```c
HASH_MAP *map_init(POOL *pool, ULONG n_buckets);
void      map_insert(HASH_MAP *map, ULONG64 key, void *value, ULONG size);
void     *map_get(HASH_MAP *map, ULONG64 key);
void      map_remove(HASH_MAP *map, ULONG64 key);
```

哈希表以 64 位整数为 key（PID 用 `(ULONG64)pid`），开链法解决冲突。
