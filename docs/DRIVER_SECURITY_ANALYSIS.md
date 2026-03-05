# Sandboxie 驱动程序 - 安全模块详细分析

## 概述

安全模块负责令牌过滤、权限控制和证书验证，确保沙箱进程的安全隔离。

## 主要功能

1. **令牌过滤** - 降低进程权限
2. **权限移除** - 移除危险特权
3. **完整性级别** - 设置低完整性级别
4. **证书验证** - 验证高级功能许可

## 令牌过滤流程

```
原始令牌
  ↓
Token_FilterPrimary()
  ├─ 移除管理员组
  ├─ 移除特权（Backup, Restore, Debug, etc.）
  ├─ 添加受限 SID
  ├─ 设置低完整性级别（Vista+）
  └─ 创建新令牌
  ↓
受限令牌
```

## 移除的特权

- SE_RESTORE_PRIVILEGE - 恢复文件和目录
- SE_BACKUP_PRIVILEGE - 备份文件和目录
- SE_LOAD_DRIVER_PRIVILEGE - 加载驱动程序
- SE_SHUTDOWN_PRIVILEGE - 关闭系统
- SE_DEBUG_PRIVILEGE - 调试程序
- SE_SYSTEMTIME_PRIVILEGE - 修改系统时间
- SE_MANAGE_VOLUME_PRIVILEGE - 管理卷

## 移除的组

- Administrators（管理员）
- Power Users（高级用户）

## 添加的 SID

- Sandboxie All（S-1-5-100-0）
- Sandboxie Admin（S-1-5-100-544）- 如果原本是管理员

## 关键函数

- `Token_Init()` - 初始化令牌管理
- `Token_FilterPrimary()` - 过滤主令牌
- `Token_ReplacePrimary()` - 替换进程主令牌
- `Token_CreateToken()` - 创建新令牌

## 证书验证

```c
if (Verify_CertInfo.active && Verify_CertInfo.opt_sec) {
    // 允许使用安全模式
} else {
    // 限制高级功能
}
```

详细分析请参考完整文档。
