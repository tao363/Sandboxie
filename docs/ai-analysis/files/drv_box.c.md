# drv/box.c / box.h — 沙箱描述符

## 概述

`box.h` 定义了 `BOX` 结构体，是 Sandboxie 中每个沙箱实例的**核心描述符**，包含沙箱名称、用户 SID、会话 ID 以及四个路径（文件、注册表、IPC、管道）。`box.c` 实现了 BOX 的创建、克隆和释放。

## BOX 结构体

```c
struct _BOX {
    WCHAR name[BOXNAME_COUNT];  // 沙箱名称（如 "DefaultBox"）
    ULONG name_len;

    WCHAR *sid;                 // 用户 SID 字符串（如 "S-1-5-21-..."）
    ULONG sid_len;
    BOOLEAN fake_admin;         // 模拟管理员（AdminAccountProtection）

    ULONG session_id;           // Terminal Services 会话 ID

    CONF_EXPAND_ARGS *expand_args; // 路径变量展开参数

    // 文件系统路径（如 C:\Sandbox\User\DefaultBox）
    WCHAR *file_path;           // NT 路径
    WCHAR *file_raw_path;       // 重解析点原始路径
    ULONG  file_path_len;

    // 注册表路径（如 \REGISTRY\USER\Sandbox_User_DefaultBox）
    WCHAR *key_path;
    ULONG  key_path_len;

    // 命名对象目录（如 \Sandbox\SID\Session_1\DefaultBox）
    WCHAR *ipc_path;
    ULONG  ipc_path_len;

    // 管道路径（ipc_path 中 \\ 替换为 _）
    WCHAR *pipe_path;
    ULONG  pipe_path_len;

    // 其他特殊路径
    WCHAR *spooler_directory;
    WCHAR *system_temp_path;
    WCHAR *user_temp_path;
};
```

## 关键函数

### `Box_Create(pool, boxname, init_paths)`
创建 BOX 实例：
1. 从当前进程令牌获取用户 SID
2. 获取当前 Terminal Services 会话 ID
3. 若 `init_paths=TRUE`，读取配置并构建四个路径

### `Box_Clone(pool, model)`
深拷贝 BOX（用于子进程继承沙箱）：将所有字段分配到新内存池并复制。

### `Box_Free(box)`
释放 BOX（仅释放指针，不释放整个 pool，pool 由 PROCESS 管理）。

### `Box_IsBoxedPath(box, m, uni)`
宏，检查 UNICODE_STRING 路径是否在沙箱的某个路径下（file/key/ipc）。

## 路径变量展开

配置中可使用以下变量（`conf_expand.c` 展开）：

| 变量 | 展开为 |
|------|-------|
| `%SandboxiePath%` | Sandboxie 安装目录 |
| `%SID%` | 用户 SID 字符串 |
| `%SessionId%` | 会话 ID 数字 |
| `%BoxName%` | 沙箱名称 |
| `%UserName%` | 用户名 |
| `%UserProfile%` | 用户 Profile 目录 |
