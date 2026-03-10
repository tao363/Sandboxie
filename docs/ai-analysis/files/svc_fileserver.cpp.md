# svc/fileserver.cpp — 文件代理服务

## 概述

`fileserver.cpp` 为沙箱进程提供需要特权的**文件操作代理**，例如将文件从沙箱恢复到真实文件系统、删除沙箱内容等。

## 消息处理

| 消息 ID | 功能 |
|--------|------|
| `MSGID_FILE_RECOVER_FILE` | 从 CopyPath 恢复文件到 TruePath |
| `MSGID_FILE_GET_ALL_FILES` | 枚举沙箱内所有文件（用于清理）|
| `MSGID_FILE_DELETE_BOX_FILES` | 删除沙箱所有文件内容 |
| `MSGID_FILE_RENAME_FILE` | 沙箱文件重命名（需特权）|
| `MSGID_FILE_SET_ATTRIBUTES` | 设置文件属性 |

## 关键函数

### `RecoverFileHandler(msg)`
将文件从沙箱 CopyPath 复制到真实路径：
1. 验证源路径确实在沙箱内（防止路径逃逸）
2. 验证目标路径在允许的恢复目录内
3. 以 SbieSvc（SYSTEM 权限）执行文件复制
4. 保留文件时间戳和属性

### `DeleteBoxFilesHandler(msg)`
清理沙箱内容：
1. 枚举 `box->file_path` 下所有文件
2. 递归删除（跳过正在使用的文件）
3. 清理注册表蜂巢文件
4. 返回清理结果（成功/失败/部分失败）

## 安全考虑

所有路径参数都经过严格验证：
- 源路径必须以 `box->file_path` 为前缀
- 目标路径不能指向系统关键目录
- 使用 `PathCanonicalize` 防止 `..` 路径逃逸
