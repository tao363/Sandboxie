# drv/conf_expand.c / conf_user.c — 配置扩展

## 概述

`conf_expand.c` 实现配置值中的**变量展开**，将 `%UserName%`、`%SID%` 等变量替换为实际值。`conf_user.c` 处理用户级别的配置（每用户独立配置，不同于全局配置）。

## conf_expand.c — 变量展开

### 支持的变量

| 变量 | 展开为 |
|------|-------|
| `%SandboxiePath%` | Sandboxie 安装目录 |
| `%SID%` | 当前用户 SID 字符串 |
| `%SessionId%` | Terminal Services 会话 ID |
| `%BoxName%` | 沙箱名称 |
| `%UserName%` | 当前用户名 |
| `%UserProfile%` | 用户 Profile 目录 |
| `%HomeDrive%` | 主驱动器（如 `C:`）|
| `%Temp%` / `%Tmp%` | 临时目录 |
| `%Desktop%` | 桌面目录 |
| `%Personal%` | 文档目录 |
| `%AppData%` | AppData\Roaming |
| `%LocalAppData%` | AppData\Local |

### 关键函数

`Conf_Expand(pool, src, expand_args)`：将 `src` 中的 `%变量%` 替换为实际值，分配新字符串返回。

## conf_user.c — 用户级配置

处理 `[UserSettings_{SID}]` 节（每个用户的私有配置）：
- 查询时优先返回用户级配置，若无则回退到全局配置
- 用于多用户环境下每个用户的独立沙箱设置
- `Conf_GetUser(section, setting, index)` 封装此优先级逻辑
