# Sandboxie 授权和网络功能完全移除方案

## 目标

1. **删除认证授权功能** - 使所有 Plus 功能无需授权即可使用
2. **删除远程控制授权能力** - 移除通过网络远程控制授权的功能
3. **删除黑名单控制** - 移除黑名单检查机制
4. **删除网络更新功能** - 完全禁用在线更新系统

---

## 实施策略

采用三层修改方案：
- **内核驱动层**：强制启用所有功能，移除证书验证
- **服务和 DLL 层**：跳过授权检查
- **GUI 界面层**：移除更新检查、证书管理界面

---

## 第一部分：删除认证授权功能

### 1.1 修改内核驱动层证书验证

#### 文件：`Sandboxie/core/drv/verify.c`

**修改点 1：强制设置最高权限（约第 850 行）**

找到 `Verify_CertInfo.active = 1;` 这一行，替换为：

```c
// 强制设置为最高级别永久证书，无需验证
Verify_CertInfo.active = 1;
Verify_CertInfo.type = eCertEternal;
Verify_CertInfo.level = eCertMaxLevel;
Verify_CertInfo.expired = 0;
Verify_CertInfo.outdated = 0;
Verify_CertInfo.grace_period = 0;
Verify_CertInfo.opt_desk = 1;   // 隔离桌面
Verify_CertInfo.opt_net = 1;    // 高级网络
Verify_CertInfo.opt_enc = 1;    // 加密沙盒
Verify_CertInfo.opt_sec = 1;    // 安全增强
Verify_CertInfo.expirers_in_sec = 0x7FFFFFFF; // 永不过期
```

**修改点 2：在没有证书时也启用功能（约第 1050 行）**

在 `CleanupExit:` 标签处，在返回前添加：

```c
CleanupExit:
    if(CertDbg) DbgPrint("Sbie Cert status: %08x; active: %d\n", status, Verify_CertInfo.active);

    // 即使没有有效证书，也强制启用所有功能
    if (!Verify_CertInfo.active) {
        memset(&Verify_CertInfo, 0, sizeof(Verify_CertInfo));
        Verify_CertInfo.active = 1;
        Verify_CertInfo.type = eCertEternal;
        Verify_CertInfo.level = eCertMaxLevel;
        Verify_CertInfo.opt_desk = 1;
        Verify_CertInfo.opt_net = 1;
        Verify_CertInfo.opt_enc = 1;
        Verify_CertInfo.opt_sec = 1;
        Verify_CertInfo.expirers_in_sec = 0x7FFFFFFF;
    }

    if(path)        Mem_Free(path, path_len);
    // ... 其余代码保持不变
```

**修改点 3：禁用网络证书验证（可选）**

注释掉所有网络下载证书的代码，搜索 `HTTP` 或 `Download` 相关代码并注释。

---

### 1.2 修改驱动层头文件

#### 文件：`Sandboxie/core/drv/verify.h`

在文件开头添加：

```c
// ============================================
// 强制启用所有功能，无需证书验证
// ============================================
#define FORCE_FULL_FEATURES 1

// ... 原有的 SCertInfo 定义 ...
```

在文件末尾，`#ifdef KERNEL_MODE` 之前添加：

```c
// 强制所有证书检查返回真
#define CERT_IS_LEVEL(cert,l)       (1)
#define CERT_HAS_FEATURE(cert,f)    (1)
#define CERT_IS_ACTIVE(cert)        (1)
```

---

### 1.3 修改 API 层授权检查

#### 文件：`Sandboxie/core/drv/api.c`

搜索所有使用 `Verify_CertInfo` 进行检查的地方，注释掉或修改为始终返回成功。

示例：

```c
// 原始代码：
// if (!Verify_CertInfo.active || !Verify_CertInfo.opt_net) {
//     return STATUS_NOT_SUPPORTED;
// }

// 修改为：直接删除检查，或者
if (FALSE) {  // 永远不会执行
    return STATUS_NOT_SUPPORTED;
}
```

---

## 第二部分：删除远程控制授权和黑名单

### 2.1 禁用远程证书下载

#### 文件：`Sandboxie/core/drv/verify.c`

找到所有网络请求相关代码（搜索 `HTTP`、`URL`、`Download`），注释掉或返回失败：

```c
// 示例：禁用证书下载函数
NTSTATUS Verify_DownloadCertificate(...)
{
    // 直接返回失败，不进行网络请求
    return STATUS_NOT_SUPPORTED;
}
```

### 2.2 移除黑名单检查

搜索包含 `blacklist`、`Blacklist`、`BLACKLIST` 的代码：

```bash
# 在以下文件中查找并注释相关代码：
# - Sandboxie/core/drv/syscall_win32.c
# - Sandboxie/core/dll/com.c
```

将黑名单检查函数修改为始终返回"不在黑名单"：

```c
BOOLEAN IsInBlacklist(...)
{
    return FALSE;  // 始终返回不在黑名单
}
```

### 2.3 禁用远程配置更新

#### 文件：`Sandboxie/core/svc/DriverAssistStart.cpp`

```cpp
// 禁用远程配置检查
NTSTATUS CheckRemoteConfig()
{
    return STATUS_SUCCESS;  // 跳过远程配置检查
}
```

---

## 第三部分：删除网络更新功能

### 3.1 禁用 OnlineUpdater 类

#### 文件：`SandboxiePlus/SandMan/OnlineUpdater.cpp`

**方案 A：修改关键函数返回空结果（推荐）**

```cpp
SB_PROGRESS COnlineUpdater::GetUpdates(QObject* receiver, const char* member, const QVariantMap& Params)
{
    // 直接返回空进度，不进行网络请求
    CSbieProgressPtr pProgress = CSbieProgressPtr(new CSbieProgress());
    pProgress->Finish(SB_OK);
    return pProgress;
}

void COnlineUpdater::CheckForUpdates(bool bManual)
{
    // 不执行任何操作
    if (bManual) {
        QMessageBox::information(nullptr, "更新检查", 
            "网络更新功能已禁用。\n此版本不支持在线更新。");
    }
    return;
}

bool COnlineUpdater::DownloadUpdate(const QVariantMap& Update, EUpdateScope Scope, bool bAndApply)
{
    return false;  // 始终返回失败
}

bool COnlineUpdater::DownloadInstaller(const QVariantMap& Release, bool bAndRun)
{
    return false;  // 始终返回失败
}

SB_PROGRESS COnlineUpdater::GetSupportCert(const QString& Serial, QObject* receiver, const char* member, const QVariantMap& Params)
{
    // 禁用证书下载
    CSbieProgressPtr pProgress = CSbieProgressPtr(new CSbieProgress());
    pProgress->Finish(SB_ERR(SB_OtherError));
    return pProgress;
}
```

**方案 B：完全删除文件（更彻底）**

如果选择完全删除，需要：
1. 删除 `OnlineUpdater.cpp` 和 `OnlineUpdater.h`
2. 从项目文件中移除引用
3. 注释掉所有调用 `COnlineUpdater` 的代码

---

### 3.2 修改主程序更新检查

#### 文件：`SandboxiePlus/SandMan/SandMan.cpp`

搜索 `CheckForUpdates`、`OnlineUpdater`、`m_pUpdater` 等关键字，注释掉相关代码：

```cpp
void CSandMan::OnStartup()
{
    // ... 其他启动代码 ...
    
    // 注释掉自动更新检查
    // if (m_pUpdater)
    //     m_pUpdater->CheckForUpdates(false);
}

void CSandMan::OnCheckUpdates()
{
    // 禁用手动更新检查
    QMessageBox::information(this, "更新检查", 
        "网络更新功能已禁用。\n此版本不支持在线更新。");
    return;
    
    // 原始代码注释掉
    // if (m_pUpdater)
    //     m_pUpdater->CheckForUpdates(true);
}
```

---

### 3.3 移除设置界面的更新选项

#### 文件：`SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`

找到更新相关的 UI 控件，隐藏或禁用：

```cpp
void CSettingsWindow::LoadSettings()
{
    // ... 其他设置加载 ...
    
    // 隐藏更新相关选项
    if (ui.tabUpdate) {
        ui.tabUpdate->setVisible(false);  // 隐藏整个更新标签页
    }
    
    // 或者禁用更新检查选项
    if (ui.chkAutoUpdate) {
        ui.chkAutoUpdate->setEnabled(false);
        ui.chkAutoUpdate->setChecked(false);
    }
    
    if (ui.btnCheckUpdates) {
        ui.btnCheckUpdates->setEnabled(false);
        ui.btnCheckUpdates->setVisible(false);
    }
}
```

---

### 3.4 移除证书管理界面

#### 文件：`SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`

```cpp
void CSettingsWindow::LoadCertificate()
{
    // 不加载证书信息
    if (ui.lblCertificate) {
        ui.lblCertificate->setText("证书验证已禁用");
    }
    
    // 隐藏证书相关按钮
    if (ui.btnGetCert) {
        ui.btnGetCert->setVisible(false);
    }
    if (ui.btnManageCert) {
        ui.btnManageCert->setVisible(false);
    }
}

void CSettingsWindow::OnGetCert()
{
    // 禁用获取证书功能
    QMessageBox::information(this, "证书管理", 
        "证书功能已禁用。\n所有 Plus 功能已默认启用。");
}
```

---

## 第四部分：GUI 层授权检查修改

### 4.1 强制启用所有功能

#### 文件：`SandboxiePlus/SandMan/SandMan.cpp`

```cpp
void CSandMan::InitCertificate()
{
    // 强制设置证书信息为最高级别
    g_CertInfo.active = 1;
    g_CertInfo.type = 4;  // eCertEternal
    g_CertInfo.level = 7; // eCertMaxLevel
    g_CertInfo.opt_desk = 1;
    g_CertInfo.opt_net = 1;
    g_CertInfo.opt_enc = 1;
    g_CertInfo.opt_sec = 1;
    g_CertInfo.expired = 0;
    g_CertInfo.expirers_in_sec = 0x7FFFFFFF;
    
    // 不从驱动或文件加载证书
    // 原始代码注释掉
}
```

### 4.2 修改功能检查函数

#### 文件：`SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`

```cpp
bool CSettingsWindow::HasCertificate()
{
    return true;  // 始终返回有证书
}

int CSettingsWindow::GetCertificateLevel()
{
    return 7;  // 返回最高级别 eCertMaxLevel
}

bool CSettingsWindow::HasFeature(const QString& feature)
{
    return true;  // 所有功能都可用
}

bool CSettingsWindow::IsCertificateExpired()
{
    return false;  // 永不过期
}
```

### 4.3 启用所有高级选项

#### 文件：`SandboxiePlus/SandMan/Windows/OptionsGeneral.cpp`

```cpp
void COptionsGeneral::LoadSettings()
{
    // ... 原有代码 ...
    
    // 启用所有高级选项，不检查证书
    ui.chkUseSecurityMode->setEnabled(true);
    ui.chkUsePrivacyMode->setEnabled(true);
    ui.chkUseEncryption->setEnabled(true);
    // ... 其他高级选项 ...
}
```

#### 文件：`SandboxiePlus/SandMan/Windows/OptionsNetwork.cpp`

```cpp
void COptionsNetwork::LoadSettings()
{
    // 启用所有网络功能，不检查证书
    ui.chkNetworkDnsFilter->setEnabled(true);
    ui.chkNetworkUseProxy->setEnabled(true);
    ui.chkNetworkAdvanced->setEnabled(true);
    // ... 其他网络选项 ...
}
```

#### 文件：`SandboxiePlus/SandMan/Wizards/NewBoxWizard.cpp`

```cpp
void CNewBoxWizard::InitializePage(int id)
{
    // 显示所有沙盒类型选项，不检查证书
    m_pBoxTypePage->ShowAllOptions();
    // 不隐藏任何高级选项
}
```

---

## 第五部分：移除网络相关依赖

### 5.1 禁用 SSL 网络请求

#### 文件：`SandboxiePlus/SandMan/OnlineUpdater.cpp`

注释掉 SSL 检查：

```cpp
// #ifdef QT_NO_SSL
// #error Qt requires Open SSL support for the updater to work
// #endif
```

### 5.2 移除网络管理器

如果完全不需要网络功能，可以注释掉网络管理器的初始化：

```cpp
void COnlineUpdater::StartJob(CUpdatesJob* pJob, const QUrl& Url)
{
    // 不创建网络请求
    return;
    
    // 原始代码注释掉
    // if (m_RequestManager == NULL) 
    //     m_RequestManager = new CNetworkAccessManager(30 * 1000, this);
    // ...
}
```

---

## 第六部分：项目配置修改

### 6.1 添加全局宏定义

创建新文件：`Sandboxie/common/license_config.h`

```c
#ifndef _LICENSE_CONFIG_H
#define _LICENSE_CONFIG_H

// ============================================
// 授权和网络功能配置
// ============================================

// 强制启用所有功能（无需证书）
#define FORCE_FULL_FEATURES 1

// 禁用网络更新功能
#define DISABLE_ONLINE_UPDATER 1

// 禁用远程授权控制
#define DISABLE_REMOTE_LICENSE 1

// 禁用黑名单检查
#define DISABLE_BLACKLIST 1

// ============================================
// 条件编译宏
// ============================================

#if FORCE_FULL_FEATURES
    #define CHECK_CERT_LEVEL(level) (1)
    #define CHECK_CERT_FEATURE(feature) (1)
    #define REQUIRE_CERTIFICATE() 
    #define IS_FEATURE_ENABLED(feature) (1)
#else
    #define CHECK_CERT_LEVEL(level) \
        (Verify_CertInfo.active && Verify_CertInfo.level >= (level))
    #define CHECK_CERT_FEATURE(feature) \
        (Verify_CertInfo.feature)
    #define REQUIRE_CERTIFICATE() \
        if (!Verify_CertInfo.active) return STATUS_NOT_LICENSED;
    #define IS_FEATURE_ENABLED(feature) \
        (Verify_CertInfo.feature)
#endif

#if DISABLE_BLACKLIST
    #define CHECK_BLACKLIST(item) (FALSE)
#else
    #define CHECK_BLACKLIST(item) IsInBlacklist(item)
#endif

#endif // _LICENSE_CONFIG_H
```

### 6.2 修改 Visual Studio 项目配置

在项目属性中添加预处理器定义：

```
FORCE_FULL_FEATURES=1
DISABLE_ONLINE_UPDATER=1
DISABLE_REMOTE_LICENSE=1
DISABLE_BLACKLIST=1
```

或者在 `common.h` 中添加：

```c
// 在 Sandboxie/common/common.h 开头添加
#include "license_config.h"
```

---

## 需要修改的文件清单

### 必须修改的文件（核心功能）

#### 驱动层
- ✅ `Sandboxie/core/drv/verify.h` - 添加宏定义
- ✅ `Sandboxie/core/drv/verify.c` - 强制设置证书信息
- ✅ `Sandboxie/core/drv/api.c` - 移除 API 授权检查

#### GUI 层
- ✅ `SandboxiePlus/SandMan/SandMan.cpp` - 主程序证书初始化
- ✅ `SandboxiePlus/SandMan/OnlineUpdater.cpp` - 禁用在线更新
- ✅ `SandboxiePlus/SandMan/Windows/SettingsWindow.cpp` - 设置窗口

#### 配置文件
- ✅ `Sandboxie/common/license_config.h` - 新建全局配置

### 可选修改的文件（增强体验）

- ⚠️ `SandboxiePlus/SandMan/Windows/OptionsGeneral.cpp` - 常规选项
- ⚠️ `SandboxiePlus/SandMan/Windows/OptionsNetwork.cpp` - 网络选项
- ⚠️ `SandboxiePlus/SandMan/Wizards/NewBoxWizard.cpp` - 新建沙盒向导
- ⚠️ `Sandboxie/core/drv/syscall_win32.c` - 移除黑名单检查
- ⚠️ `Sandboxie/core/dll/com.c` - 移除黑名单检查

---

## 编译和测试

### 编译步骤

1. **清理项目**
```cmd
cd Sandboxie
msbuild Sandboxie.sln /t:Clean
```

2. **编译驱动**
```cmd
msbuild Sandboxie.sln /p:Configuration=Release /p:Platform=x64
```

3. **编译 GUI**
```cmd
cd SandboxiePlus
qmake SandboxiePlus.pro
nmake release
```

### 测试验证

1. **检查驱动加载**
```cmd
sc query SbieDrv
```

2. **测试高级功能**
- 创建加密沙盒
- 启用隔离桌面
- 配置 DNS 过滤
- 使用安全模式

3. **验证更新功能已禁用**
- 打开设置 → 更新，确认更新选项已隐藏或禁用
- 点击"检查更新"应显示功能已禁用的提示

4. **验证证书状态**
- 打开"关于"对话框，应显示最高级别证书或不显示证书信息

---

## 注意事项

### 1. 法律和道德
- ⚠️ 本指南仅用于教育和研究目的
- ⚠️ 建议购买正版授权支持开发者
- ⚠️ 不要重新分发修改后的版本

### 2. 驱动签名
修改后的驱动需要重新签名，测试模式下可以加载未签名驱动：

```cmd
# 启用测试模式
bcdedit /set testsigning on

# 重启后生效
shutdown /r /t 0
```

### 3. 更新问题
- 修改后的版本无法使用官方自动更新
- 需要手动合并新版本的代码
- 建议保留原始代码备份

### 4. 兼容性
- 确保所有模块使用相同的宏定义
- 驱动和 GUI 必须匹配
- 建议同时编译所有组件

---

## 快速实施方案（最小修改）

如果只想快速启用所有功能，只需修改以下 **5 个文件**：

1. **`Sandboxie/core/drv/verify.c`** - 2 处修改（第 850 行和 1050 行）
2. **`Sandboxie/core/drv/verify.h`** - 添加宏定义
3. **`SandboxiePlus/SandMan/SandMan.cpp`** - 强制设置证书
4. **`SandboxiePlus/SandMan/OnlineUpdater.cpp`** - 禁用更新检查
5. **`SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`** - 修改 3 个函数

这样就能：
- ✅ 启用所有 Plus 功能
- ✅ 禁用在线更新
- ✅ 移除证书检查

---

## 总结

本方案通过三层修改实现了完整的功能解锁：

1. **内核层**：强制设置最高级别证书，跳过所有验证
2. **网络层**：禁用在线更新、远程授权、黑名单检查
3. **界面层**：移除更新界面，启用所有高级选项

**预计修改时间：** 2-4 小时  
**技术难度：** ⭐⭐⭐ (中等)  
**需要技能：** C/C++、Qt、Windows 驱动开发基础

---

**文档版本：** 1.0  
**创建日期：** 2025-01-XX  
**适用版本：** Sandboxie Plus 1.x
