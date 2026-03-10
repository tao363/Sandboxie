# drv/file_ctrl.c / file_xlat.c — 文件路径翻译

## 概述

`file_ctrl.c` 实现文件系统控制操作（`DeviceIoControl` 类文件操作）的重定向；`file_xlat.c` 实现路径翻译（DOS 路径 ↔ NT 路径转换）。

## file_xlat.c — 路径翻译

### 功能

将 DOS 风格路径（`C:\Windows\...`）翻译为 NT 内核路径（`\Device\HarddiskVolume3\Windows\...`），以及反向翻译。

### 关键函数

#### `File_GetDosPath(NtPath, DosPath)`
将 NT 路径翻译为 DOS 路径：
- 维护 `\Device\HarddiskVolumeX` → 盘符 的映射表
- 处理网络路径（`\Device\Mup\...` → `\\server\share\...`）
- 处理符号链接路径

#### `File_GetNtPath(DosPath, NtPath)`
将 DOS 路径翻译为 NT 路径，调用 `RtlDosPathNameToNtPathName_U`。

#### `File_TranslateDosToNt(buffer)`
就地翻译缓冲区中的路径（节省内存分配）。

## file_ctrl.c — 控制操作

### 功能

处理通过 `NtDeviceIoControlFile` / `NtFsControlFile` 发出的文件系统控制码：

| 控制码 | 处理 |
|--------|------|
| `FSCTL_GET_REPARSE_POINT` | 重解析点读取（重定向到 CopyPath）|
| `FSCTL_SET_REPARSE_POINT` | 重解析点写入（拦截，防止创建指向沙箱外的链接）|
| `FSCTL_DELETE_REPARSE_POINT` | 重解析点删除 |
| `FSCTL_MOVE_FILE` | 文件移动（确保目标在 CopyPath）|

### 符号链接安全

阻止沙箱进程创建指向沙箱外路径的符号链接（防止通过符号链接逃逸沙箱）。

## file_xp.c / key_xp.c — XP 兼容层

`file_xp.c` 和 `key_xp.c` 包含 Windows XP 上文件/注册表虚拟化的备用实现，使用对象解析回调（`ObSetObjectSecurityCallback`）替代 Vista+ 的 FltMgr/CmRegisterCallback。
