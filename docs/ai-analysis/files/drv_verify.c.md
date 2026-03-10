# drv/verify.c — 证书验证

## 概述

`verify.c` 实现 Sandboxie 的**授权证书验证机制**，检查用户是否持有有效的 Sandboxie 证书（`Sandboxie.ini` 中的 `SbieKey`），并据此启用或限制高级功能（安全模式、加密沙箱、网络代理等）。

## 基本信息

| 属性 | 值 |
|------|----|
| 文件路径 | `Sandboxie/core/drv/verify.c` |
| 所属模块 | SbieDrv.sys |
| 核心职责 | 证书解析与功能授权控制 |

## SCertInfo 结构体

```c
typedef union _SCertInfo {
    struct {
        unsigned long
            active      : 1,  // 证书已激活
            type        : 5,  // 证书类型（见 eCertType）
            level       : 3,  // 证书级别（0-7，eCertMaxLevel=7）
            opt_desk    : 1,  // 隔离桌面特性
            opt_net     : 1,  // 高级网络代理
            opt_enc     : 1,  // 加密沙箱
            opt_sec     : 1;  // 安全增强模式
        long expirers_in_sec; // 剩余有效期（秒）
    };
    ULONGLONG State;          // 完整状态（64位）
} SCertInfo;
```

## 证书类型（eCertType）

| 类型 | 值 | 含义 |
|------|---|------|
| `eCertFree` | 0 | 免费版 |
| `eCertPersonal` | 1 | 个人版 |
| `eCertBusiness` | 2 | 商业版 |
| `eCertDeveloper` | 3 | 开发者版（无需签名）|
| `eCertEternal` | 4 | 永久版 |

## 关键函数

### `MyValidateCertificate()`
驱动加载时调用：
1. 从 `Sandboxie.ini` 读取 `SbieKey`
2. 调用 `KphVerifyBuffer` 验证 ECDSA-P256 签名
3. 解析证书内容，填充 `Verify_CertInfo`
4. 检查有效期

### `Api_QueryDriverInfo(info_class=-1)`
返回 `Verify_CertInfo.State`（完整证书状态），供用户态读取。

## 功能门控

驱动中多处通过 `Verify_CertInfo` 控制功能开关：

```c
// 示例：UseSecurityMode 需要 opt_sec
if (!(Verify_CertInfo.active && Verify_CertInfo.opt_sec)) {
    // 无证书：限时运行（5分钟后终止进程）
    Process_ScheduleKill(proc, 5*60*1000);
}
```
