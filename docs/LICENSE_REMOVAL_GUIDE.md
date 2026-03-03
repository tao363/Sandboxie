# Sandboxie 授权机制分析与移除指南

> 详细分析 Sandboxie Plus 的授权系统，以及如何编译完整功能的免费版本

## 📋 目录

- [授权机制概述](#授权机制概述)
- [授权类型和级别](#授权类型和级别)
- [功能限制分析](#功能限制分析)
- [如何移除授权限制](#如何移除授权限制)
- [编译完整功能版本](#编译完整功能版本)
- [法律和道德考虑](#法律和道德考虑)

---

## 📊 授权机制概述

### 核心文件位置

```
授权验证代码：
├─ Sandboxie/core/drv/verify.c      # 内核驱动验证
├─ Sandboxie/core/drv/verify.h      # 证书结构定义
├─ Sandboxie/core/drv/api.c         # API 授权检查
├─ SandboxiePlus/SandMan/           # GUI 授权检查
└─ Sandboxie/core/svc/              # 服务层验证
```

### 授权验证流程

```
启动 Sandboxie Plus
    ↓
读取证书文件/注册表
    ↓
验证数字签名（ECDSA P256）
    ↓
检查证书类型和级别
    ↓
设置功能标志
    ↓
根据授权启用/禁用功能
```

---

## 🎫 授权类型和级别

### 证书结构（SCertInfo）

```c
typedef union _SCertInfo {
    unsigned long long State;
    struct {
        unsigned long
            active      : 1,    // 证书激活
            expired     : 1,    // 证书过期
            outdated    : 1,    // 证书过时
            grace_period: 1,    // 宽限期
            locked      : 1,    // 锁定
            lock_req    : 1,    // 需要锁定
            
            type        : 5,    // 证书类型
            level       : 3,    // 证书级别
            
            // 功能标志
            opt_desk    : 1,    // 隔离桌面
            opt_net     : 1,    // 高级网络
            opt_enc     : 1,    // 加密沙盒
            opt_sec     : 1;    // 安全增强
            
        long expirers_in_sec;   // 过期时间
    };
} SCertInfo;
```

### 证书类型（ECertType）

| 类型 | 值 | 说明 |
|------|-----|------|
| `eCertEternal` | 0b00100 | 永久证书 |
| `eCertContributor` | 0b00101 | 贡献者证书 |
| `eCertBusiness` | 0b01000 | 商业证书 |
| `eCertPersonal` | 0b01100 | 个人证书 |
| `eCertHome` | 0b10000 | 家庭证书 |
| `eCertFamily` | 0b10001 | 家庭版 |
| `eCertDeveloper` | 0b10100 | 开发者证书 |
| `eCertPatreon` | 0b11000 | Patreon 支持者 |
| `eCertGreatPatreon` | 0b11001 | 高级 Patreon |
| `eCertEntryPatreon` | 0b11010 | 入门 Patreon |
| `eCertEvaluation` | 0b11100 | 评估版 |

### 证书级别（ECertLevel）

| 级别 | 值 | 功能 |
|------|-----|------|
| `eCertNoLevel` | 0b000 | 无授权 |
| `eCertStandard` | 0b010 | 标准功能 |
| `eCertStandard2` | 0b011 | 标准+ |
| `eCertAdvanced1` | 0b100 | 高级1 |
| `eCertAdvanced` | 0b101 | 高级功能 |
| `eCertMaxLevel` | 0b111 | 最高级别 |

---

## 🔒 功能限制分析

### 需要授权的高级功能

#### 1. 隔离桌面（opt_desk = 1）

```ini
# 需要授权
UseSandboxDesktop=y
```

**功能：** 在独立的桌面环境中运行沙盒程序

#### 2. 高级网络功能（opt_net = 1）

```ini
# 需要授权
NetworkDnsFilter=y
NetworkUseProxy=y
```

**功能：**
- DNS 过滤和重定向
- 强制使用代理服务器
- 网络流量控制

#### 3. 加密沙盒（opt_enc = 1）

```ini
# 需要授权
ConfidentialBox=y
UseFileImage=y
EnableEFS=y
```

**功能：**
- 加密沙盒内容
- 使用文件镜像
- EFS 加密支持

#### 4. 安全增强（opt_sec = 1）

```ini
# 需要授权
UseSecurityMode=y
SysCallLockDown=y
RestrictDevices=y
UseRuleSpecificity=y
UsePrivacyMode=y
ProtectHostImages=y
NoSecurityIsolation=y
```

**功能：**
- 安全模式
- 系统调用锁定
- 设备限制
- 规则特异性
- 隐私模式
- 保护主机镜像

### 无需授权的功能

```ini
# 免费功能
UseRamDisk=y
ForceUsbDrives=y
# 自动更新
# 基础沙盒隔离
# 文件恢复
# 快照管理
```

---

## 🛠️ 如何移除授权限制

### ⚠️ 重要声明

**本指南仅用于教育和研究目的。Sandboxie Plus 是开源软件，但作者依靠捐赠和授权维持开发。**

**建议：**
- 如果你觉得软件有用，请购买授权支持开发者
- 或者通过 Patreon 支持项目
- 或者为项目贡献代码

### 方法 1：修改证书验证代码（推荐）

#### 步骤 1：修改 verify.h

**文件：** `Sandboxie/core/drv/verify.h`

```c
// 在文件末尾添加宏定义
#define FORCE_FULL_FEATURES 1

#if FORCE_FULL_FEATURES
// 强制启用所有功能
#define CERT_IS_LEVEL(cert,l) (1)
#define CERT_HAS_FEATURE(cert,f) (1)
#else
// 原始定义
#define CERT_IS_LEVEL(cert,l) (cert.active && cert.level >= (unsigned long)(l))
#define CERT_HAS_FEATURE(cert,f) (cert.f)
#endif
```

#### 步骤 2：修改 verify.c

**文件：** `Sandboxie/core/drv/verify.c`

找到证书验证函数，添加：

```c
NTSTATUS Verify_GetCertificate(SCertInfo* pCertInfo)
{
#if FORCE_FULL_FEATURES
    // 创建一个虚拟的最高级别证书
    memset(pCertInfo, 0, sizeof(SCertInfo));
    pCertInfo->active = 1;
    pCertInfo->type = eCertEternal;
    pCertInfo->level = eCertMaxLevel;
    pCertInfo->opt_desk = 1;
    pCertInfo->opt_net = 1;
    pCertInfo->opt_enc = 1;
    pCertInfo->opt_sec = 1;
    pCertInfo->expirers_in_sec = 0x7FFFFFFF; // 永不过期
    return STATUS_SUCCESS;
#else
    // 原始证书验证代码
    // ...
#endif
}
```

#### 步骤 3：修改 GUI 检查

**文件：** `SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`

找到授权检查代码：

```cpp
bool CSettingsWindow::HasCertificate()
{
#if FORCE_FULL_FEATURES
    return true; // 始终返回有证书
#else
    // 原始检查代码
    return m_pCertificate && m_pCertificate->active;
#endif
}

int CSettingsWindow::GetCertificateLevel()
{
#if FORCE_FULL_FEATURES
    return 7; // 返回最高级别
#else
    // 原始代码
    if (!m_pCertificate || !m_pCertificate->active)
        return 0;
    return m_pCertificate->level;
#endif
}
```

### 方法 2：修改功能检查点

#### 找到所有功能检查

```bash
# 搜索授权检查
grep -r "cert.opt_" Sandboxie/
grep -r "CERT_IS_LEVEL" Sandboxie/
grep -r "GetCertificateLevel" SandboxiePlus/
```

#### 直接移除检查

**示例：** 移除网络功能检查

**文件：** `Sandboxie/core/dll/dns_filter.c`

```c
// 原始代码
if (!g_certificate_level || !g_certificate.opt_net) {
    return STATUS_NOT_SUPPORTED;
}

// 修改为
#if !FORCE_FULL_FEATURES
if (!g_certificate_level || !g_certificate.opt_net) {
    return STATUS_NOT_SUPPORTED;
}
#endif
// 继续执行功能代码
```

### 方法 3：使用预处理器宏

创建一个全局配置文件：

**文件：** `Sandboxie/common/license_config.h`

```c
#ifndef _LICENSE_CONFIG_H
#define _LICENSE_CONFIG_H

// 设置为 1 启用所有功能
#define ENABLE_ALL_FEATURES 1

#if ENABLE_ALL_FEATURES
    #define CHECK_CERT_LEVEL(level) (1)
    #define CHECK_CERT_FEATURE(feature) (1)
    #define REQUIRE_CERTIFICATE() 
#else
    #define CHECK_CERT_LEVEL(level) (g_certificate.active && g_certificate.level >= level)
    #define CHECK_CERT_FEATURE(feature) (g_certificate.feature)
    #define REQUIRE_CERTIFICATE() if (!g_certificate.active) return STATUS_NOT_LICENSED;
#endif

#endif
```

然后在所有需要检查的地方包含这个头文件并使用宏。

---

## 🔨 编译完整功能版本

### 前置要求

```
工具：
├─ Visual Studio 2019/2022
├─ Windows SDK 10.0.19041.0+
├─ WDK (Windows Driver Kit)
├─ Qt 5.15+ 或 Qt 6.x
└─ Git
```

### 编译步骤

#### 1. 克隆仓库

```bash
git clone https://github.com/sandboxie-plus/Sandboxie.git
cd Sandboxie
```

#### 2. 应用修改

```bash
# 创建补丁分支
git checkout -b full-features

# 应用上述修改到相关文件
# - Sandboxie/core/drv/verify.h
# - Sandboxie/core/drv/verify.c
# - SandboxiePlus/SandMan/Windows/SettingsWindow.cpp
# 等等
```

#### 3. 编译驱动

```bash
cd Sandboxie
# 使用 Visual Studio 打开 Sandbox.sln
# 或使用命令行
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=x64
```

#### 4. 编译 GUI

```bash
cd SandboxiePlus
# 使用 Qt Creator 打开 SandboxiePlus.pro
# 或使用命令行
qmake SandboxiePlus.pro
nmake release
```

#### 5. 打包安装程序

```bash
cd Installer
# 修改 Sandboxie-Plus.iss
# 运行 Inno Setup 编译安装程序
iscc Sandboxie-Plus.iss
```

### 编译配置

**修改编译选项：**

在 `Sandboxie/common/my_version.h` 中：

```c
#define MY_VERSION_STRING "1.14.0-Full"
#define MY_VERSION_COMPAT "1.14.0"

// 添加自定义标识
#define FULL_FEATURES_BUILD 1
```

---

## 📝 修改清单

### 需要修改的文件列表

```
核心驱动：
├─ Sandboxie/core/drv/verify.h          # 证书结构定义
├─ Sandboxie/core/drv/verify.c          # 证书验证
├─ Sandboxie/core/drv/api.c             # API 授权检查
├─ Sandboxie/core/drv/process.c         # 进程授权
└─ Sandboxie/core/drv/util.c            # 工具函数

用户态 DLL：
├─ Sandboxie/core/dll/dns_filter.c      # DNS 过滤授权
├─ Sandboxie/core/dll/net.c             # 网络功能授权
└─ Sandboxie/core/dll/support.c         # 支持功能

GUI 界面：
├─ SandboxiePlus/SandMan/SandMan.cpp    # 主程序
├─ SandboxiePlus/SandMan/Windows/SettingsWindow.cpp
├─ SandboxiePlus/SandMan/Windows/OptionsGeneral.cpp
├─ SandboxiePlus/SandMan/Windows/OptionsNetwork.cpp
├─ SandboxiePlus/SandMan/Wizards/NewBoxWizard.cpp
└─ SandboxiePlus/SandMan/OnlineUpdater.cpp

服务：
├─ Sandboxie/core/svc/DriverAssistStart.cpp
├─ Sandboxie/core/svc/UserServer.cpp
└─ Sandboxie/core/svc/MountManager.cpp
```

### 搜索和替换模式

```bash
# 查找所有授权检查
grep -rn "g_certificate" Sandboxie/
grep -rn "cert.opt_" Sandboxie/
grep -rn "CERT_IS_LEVEL" Sandboxie/
grep -rn "GetCertificateLevel" SandboxiePlus/

# 查找功能限制
grep -rn "STATUS_NOT_LICENSED" Sandboxie/
grep -rn "STATUS_NOT_SUPPORTED" Sandboxie/
```

---

## ⚖️ 法律和道德考虑

### 开源许可

Sandboxie Plus 使用 **GPLv3 许可证**：

```
LICENSE.Plus:
- 允许修改和重新分发
- 必须保持开源
- 必须包含原始版权声明
- 修改后的版本必须标明修改
```

### 道德建议

1. **支持开发者**
   - 如果你使用 Sandboxie Plus，请考虑购买授权
   - 或通过 Patreon 支持：https://www.patreon.com/DavidXanatos
   - 或为项目贡献代码

2. **合法使用**
   - 仅用于个人学习和研究
   - 不要用于商业目的
   - 不要重新分发修改版本

3. **尊重作者**
   - David Xanatos 维护这个项目多年
   - 开源不等于免费劳动
   - 授权收入支持持续开发

### 替代方案

如果你不想付费，可以：

1. **使用免费功能**
   - 基础沙盒隔离完全免费
   - 大多数功能无需授权

2. **贡献代码**
   - 成为贡献者可获得免费授权
   - 帮助改进项目

3. **等待促销**
   - 定期有折扣活动
   - 关注官方公告

---

## 🎯 总结

### 可行性

**答案：完全可以移除授权限制并编译完整功能版本**

- ✅ 代码完全开源
- ✅ 授权检查在源码中可见
- ✅ 可以通过修改源码移除限制
- ✅ 可以自己编译安装

### 技术难度

- ⭐⭐ **简单** - 修改几个文件即可
- 需要基本的 C/C++ 知识
- 需要 Visual Studio 编译环境
- 大约 1-2 小时完成

### 推荐做法

**最佳方案：**

1. **先使用免费版本**
   - 评估是否真的需要高级功能
   - 大多数用户免费功能已足够

2. **如果需要高级功能**
   - 考虑购买授权（支持开发）
   - 或者修改源码自己编译

3. **如果修改源码**
   - 仅供个人使用
   - 不要重新分发
   - 考虑日后支持项目

### 功能对比

| 功能 | 免费版 | 付费版 | 自编译版 |
|------|--------|--------|---------|
| 基础隔离 | ✅ | ✅ | ✅ |
| 文件恢复 | ✅ | ✅ | ✅ |
| 快照管理 | ✅ | ✅ | ✅ |
| 隔离桌面 | ❌ | ✅ | ✅ |
| DNS 过滤 | ❌ | ✅ | ✅ |
| 加密沙盒 | ❌ | ✅ | ✅ |
| 安全增强 | ❌ | ✅ | ✅ |
| 官方支持 | ❌ | ✅ | ❌ |
| 自动更新 | ✅ | ✅ | ⚠️ |

---

## 📚 参考资源

- **官方网站**: https://sandboxie-plus.com/
- **GitHub**: https://github.com/sandboxie-plus/Sandboxie
- **文档**: https://sandboxie-plus.github.io/sandboxie-docs/
- **Patreon**: https://www.patreon.com/DavidXanatos
- **Discord**: https://discord.gg/S4tFu6Enne

---

**文档版本：** 1.0  
**创建日期：** 2025-01-02  
**作者：** Claude (Opus 4.6)  
**免责声明：** 本文档仅用于教育目的，请尊重开发者的劳动成果
