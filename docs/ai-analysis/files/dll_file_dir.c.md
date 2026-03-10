# dll/file_dir.c — 目录枚举虚拟化

## 概述

`file_dir.c` 处理目录枚举操作（`NtQueryDirectoryFile`），合并沙箱 CopyPath 和真实 TruePath 两处的目录内容，同时过滤已删除标记的文件，向应用程序呈现一个统一的虚拟目录视图。

## 关键函数

### `File_NtQueryDirectoryFile()`

合并枚举算法：
1. 第一轮：枚举 CopyPath 下的所有条目（包括新建、修改的文件）
2. 第二轮：枚举 TruePath 下的条目，跳过：
   - 已在 CopyPath 中出现的文件名（CopyPath 版本优先）
   - 在 CopyPath 中有删除标记的文件名
3. 将两轮结果合并返回给调用者

### `File_NtQueryDirectoryFileEx()`（Windows 10+）
同上，处理 `NtQueryDirectoryFileEx` 的扩展版本。

### `File_MergeCache`

目录枚举使用缓存结构避免重复计算：
- 首次枚举时构建 CopyPath 文件名哈希表
- 后续调用直接查哈希表判断重复
- 文件句柄关闭时释放缓存

## 删除标记过滤

```c
// 检查 TruePath 中的文件是否在 CopyPath 有删除标记
if (File_CheckDeleteMark(CopyPath, FileName)) {
    // 跳过此文件，不出现在枚举结果中
    continue;
}
```

## file_copy.c — 文件复制

`file_copy.c` 实现写时复制触发时的文件复制操作：
- 第一次写入沙箱外文件时，先将 TruePath 文件复制到 CopyPath
- 使用分块复制（避免大文件占用过多内存）
- 保留文件时间戳、属性、安全描述符

## file_del.c — 删除标记管理

`file_del.c` 管理文件/目录的删除标记：
- `File_SetDeleteMark(CopyPath)`：创建 `.delete` 标记文件
- `File_CheckDeleteMark(CopyPath, Name)`：检查标记是否存在
- `File_DeleteMark_Clear(CopyPath)`：清除标记（文件被重新创建时）
