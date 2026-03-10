# dll/key_merge.c — 注册表枚举合并

## 概述

`key_merge.c` 实现注册表枚举操作的**双路合并**，类似 `file_dir.c` 对目录枚举的处理，将沙箱 CopyPath 和真实 TruePath 两处的注册表键/值合并返回。

## 关键函数

### `Key_NtEnumerateKey()`

合并枚举子键：
1. 枚举 CopyPath 下的所有子键
2. 枚举 TruePath 下的子键，跳过：
   - CopyPath 中已有的键名
   - CopyPath 中有删除标记的键名
3. 按枚举 index 顺序返回合并结果

### `Key_NtEnumerateValueKey()`

合并枚举键值，逻辑同上，针对值名称进行去重。

### `Key_NtQueryKey()`

查询键的元数据（子键数量、值数量、最大名称长度等）时，需要返回合并后的统计数据：
```c
// 合并计数
out_info->SubKeys = copy_sub_keys + true_sub_keys - overlap_count;
out_info->Values = copy_values + true_values - overlap_values;
```

## key_util.c — 注册表辅助函数

提供注册表操作的通用辅助函数：
- `Key_OpenIfBoxed(path)`：检查路径是否在沙箱键路径下
- `Key_GetParentPath(path, parent)`：获取父键路径
- `Key_EnsurePath(CopyPath)`：确保 CopyPath 的所有父键存在
- `Key_CopyKey(TrueKey, CopyKey)`：将 TruePath 键内容复制到 CopyPath（写时复制触发）

## key_del.c — 注册表删除标记

管理注册表删除标记：
- 删除键时：在 CopyPath 对应位置创建特殊的「删除标记键」（含特殊值 `SBIE_DELETE_V1`）
- 枚举时：过滤有删除标记的键/值
- 重新创建时：清除删除标记
