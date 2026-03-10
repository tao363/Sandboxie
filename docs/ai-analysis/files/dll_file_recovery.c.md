# dll/file_recovery.c — 文件恢复

## 概述

`file_recovery.c` 实现**立即恢复**功能：检测沙箱进程新建的文件，提示用户将其恢复（复制）到沙箱外真实文件系统。

## 工作原理

1. 在 `File_NtCreateFile` Hook 中，检测新创建的文件（`FILE_CREATE` disposition）
2. 检查文件路径是否匹配 `RecoverFolder` 配置
3. 若匹配，通过 `SbieApi_LogMessage` 发送 `SBIE_MSG_FILE_RECOVERY` 消息
4. SandMan GUI 收到消息后弹出「立即恢复」通知
5. 用户选择恢复 → SbieSvc FileServer 将文件从 CopyPath 复制到 TruePath

## 配置项

```ini
[DefaultBox]
RecoverFolder=%Desktop%     # 桌面新建文件自动提示恢复
RecoverFolder=%Personal%    # 文档目录
AutoRecoverIgnore=*.tmp     # 忽略临时文件
```

## file_snapshots.c — 快照支持

`file_snapshots.c` 实现文件系统快照：
- 快照时：将当前 CopyPath 内容打包存储
- 回滚时：将 CopyPath 替换为快照内容
- 支持多级快照（树形结构）
- 通过 SandMan SnapshotWindow 管理
