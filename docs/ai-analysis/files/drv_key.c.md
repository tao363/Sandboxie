# drv/key.c — 注册表虚拟化

## 概述

`key.c` 实现了 Sandboxie 的**注册表虚拟化**。通过 `CmRegisterCallbackEx` 注册注册表回调过滤器（Vista+）或解析回调钩子（XP），将沙箱进程的注册表操作重定向到沙箱专属的注册表蜂巢文件，实现注册表的写时复制隔离。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/drv/key.c` |
| 所属模块 | SbieDrv.sys |
| 语言 | C（内核模式）|
| 核心职责 | 注册表写时复制虚拟化 |
| 关联文件 | `key_flt.c`（过滤器）, `key_merge.c`（键合并）|

## 双路径模型

与文件系统类似，注册表也使用 TruePath / CopyPath 模型：

- **TruePath**：真实注册表路径（如 `\REGISTRY\MACHINE\SOFTWARE\...`）
- **CopyPath**：沙箱蜂巢路径（如 `\REGISTRY\USER\Sandbox_User_DefaultBox\...`）

## KEY_MOUNT 结构体

```c
struct _KEY_MOUNT {
    LIST_ELEM list_elem;
    WCHAR *hive_path;      // 蜂巢文件路径（在沙箱文件目录下）
    WCHAR *root_key;       // 挂载点注册表路径
    volatile ULONG ref_count;
    volatile ULONG unmount_pending;
    volatile ULONG busy;
};
```

## 关键函数

### `Key_Init()`
注册注册表回调（Vista+：`CmRegisterCallbackEx`；XP：对象解析回调）。初始化 Key_Mounts 列表和锁。

### `Key_MountHive(PROCESS*)` — 挂载沙箱注册表蜂巢
为沙箱进程挂载专属注册表蜂巢：
1. 确定蜂巢文件路径（在 `box->file_path\RegHive` 下）
2. 若蜂巢文件不存在则创建空蜂巢
3. 调用 `ZwLoadKey2` 将蜂巢文件挂载到 `\REGISTRY\USER\Sandbox_SID_BoxName`
4. 更新 `proc->key_mount` 指针

### `Key_UnmountHive(PROCESS*)` — 卸载蜂巢
进程退出时：
1. 减少引用计数
2. 引用为 0 时调用 `ZwUnloadKey` 卸载蜂巢
3. 从 Key_Mounts 列表移除

### `Key_MyParseProc_2()` — 注册表路径解析（Vista+ 前回调）
拦截所有注册表操作，判断路径权限，决定是否重定向到 CopyPath。

### `Key_InitProcess(PROCESS*)` — 初始化进程注册表规则
读取 `OpenKeyPath`、`ClosedKeyPath`、`ReadKeyPath`、`WriteKeyPath` 配置，构建 PATTERN 规则列表。

## 注册表蜂巢挂载时序

```mermaid
sequenceDiagram
    participant P as Process_NotifyImage
    participant K as key.c
    participant FS as 文件系统
    participant REG as 注册表管理器

    P->>K: Key_MountHive(proc)
    K->>K: 计算蜂巢路径\nbox->file_path\\RegHive
    K->>FS: 检查蜂巢文件是否存在
    alt 不存在
        K->>REG: ZwCreateKey 创建空蜂巢根键
        K->>REG: ZwSaveKey 保存为蜂巢文件
    end
    K->>REG: ZwLoadKey2 挂载蜂巢到\n\\REGISTRY\\USER\\Sandbox_xxx
    