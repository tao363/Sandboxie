# Sandboxie 授权移除实施指南

## 概述

根据对比分析，要去除 Sandboxie 的授权限制，需要修改以下关键代码。本文档提供具体的代码修改方案。

---

## 核心修改策略

### 方案 1：强制启用所有功能（推荐）

这是最简单直接的方法，通过修改证书验证逻辑，让系统认为始终有一个最高级别的永久证书。

---

## 详细修改步骤

### 1. 修改驱动层证书验证 (verify.c)

**文件位置：** `Sandboxie/core/drv/verify.c`

#### 修改点 1：在证书验证成功后强制设置最高权限

找到第 850 行左右的 `Verify_CertInfo.active = 1;` 这一行，在其后添加强制设置代码：

```c
// 原始代码（约第 850 行）
Verify_CertInfo.active = 1;

// 在此之后添加以下代码：
#ifdef FORCE_FULL_FEATURES
    // 强制设置为最高级别永久证书
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
#endif
```

#### 修改点 2：在没有证书时也启用功能

找到文件末尾的 `CleanupExit:` 标签（约第 1050 行），在返回前添加：

```c
CleanupExit:
    if(CertDbg) DbgPrint("Sbie Cert status: %08x; active: %d\n", status, Verify_CertInfo.active);

#ifdef FORCE_FULL_FEATURES
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
#endif

    if(path)        Mem_Free(path, path_len);
    // ... 其余清理代码
```

---

### 2. 修改驱动层头文件 (verify.h)

**文件位置：** `Sandboxie/core/drv/verify.h`

在文件开头添加宏定义和条件编译：

```c
// 在 #define SOFTWARE_NAME 之前添加
#ifndef FORCE_FULL_FEATURES
#define FORCE_FULL_FEATURES 1  // 设置为 1 启用完整功能，0 使用原始验证
#endif

// ... 原有的 SCertInfo 定义 ...

// 在文件末尾，#ifdef KERNEL_MODE 之前添加：
#if FORCE_FULL_FEATURES
// 强制所有证书检查返回真
#define CERT_IS_LEVEL(cert,l)       (1)
#define CERT_HAS_FEATURE(cert,f)    (1)
#else
// 原始定义
#define CERT_IS_LEVEL(cert,l)       (cert.active && cert.level >= (unsigned long)(l))
#define CERT_HAS_FEATURE(cert,f)    (cert.f)
#endif
```

---

### 3. 修改 API 层授权检查 (api.c)

**文件位置：** `Sandboxie/core/drv/api.c`

找到所有使用 `Verify_CertInfo` 进行检查的地方，添加条件编译：

```c
// 示例：在功能检查处
#if !FORCE_FULL_FEATURES
if (!Verify_CertInfo.active || !Verify_CertInfo.opt_net) {
    return STATUS_NOT_SUPPORTED;
}
#endif
// 继续执行功能代码
```

---

### 4. 修改 GUI 层授权检查

#### 4.1 修改 SandMan.cpp

**文件位置：** `SandboxiePlus/SandMan/SandMan.cpp`

找到 `g_CertInfo` 的初始化和使用位置，添加强制设置：

```cpp
// 在 CSandMan 构造函数或初始化函数中添加
void CSandMan::OnCertificateLoaded()
{
#ifdef FORCE_FULL_FEATURES
    // 强制设置证书信息
    g_CertInfo.active = 1;
    g_CertInfo.type = 4;  // eCertEternal
    g_CertInfo.level = 7; // eCertMaxLevel
    g_CertInfo.opt_desk = 1;
    g_CertInfo.opt_net = 1;
    g_CertInfo.opt_enc = 1;
    g_CertInfo.opt_sec = 1;
    g_CertInfo.expired = 0;
    g_CertInfo.expirers_in_sec = 0x7FFFFFFF;
#else
    // 原始证书加载逻辑
#endif
}
```

#### 4.2 修改 SettingsWindow.cpp

**文件位置：** `SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`

修改证书检查函数：

```cpp
bool CSettingsWindow::HasCertificate()
{
#ifdef FORCE_FULL_FEATURES
    return true; // 始终返回有证书
#else
    return m_pCertificate && m_pCertificate->active;
#endif
}

int CSettingsWindow::GetCertificateLevel()
{
#ifdef FORCE_FULL_FEATURES
    return 7; // 返回最高级别 eCertMaxLevel
#else
    if (!m_pCertificate || !m_pCertificate->active)
        return 0;
    return m_pCertificate->level;
#endif
}

bool CSettingsWindow::HasFeature(const QString& feature)
{
#ifdef FORCE_FULL_FEATURES
    return true; // 所有功能都可用
#else
    // 原始功能检查逻辑
#endif
}
```

#### 4.3 修改 OptionsGeneral.cpp

**文件位置：** `SandboxiePlus/SandMan/Windows/OptionsGeneral.cpp`

```cpp
void COptionsGeneral::LoadSettings()
{
    // ... 原有代码 ...
    
#ifdef FORCE_FULL_FEATURES
    // 启用所有高级选项
    ui.chkUseSecurityMode->setEnabled(true);
    ui.chkUsePrivacyMode->setEnabled(true);
    // ... 其他高级选项 ...
#else
    // 原始授权检查
    if (!theAPI->GetCertInfo().opt_sec) {
        ui.chkUseSecurityMode->setEnabled(false);
        // ...
    }
#endif
}
```

#### 4.4 修改 OptionsNetwork.cpp

**文件位置：** `SandboxiePlus/SandMan/Windows/OptionsNetwork.cpp`

```cpp
void COptionsNetwork::LoadSettings()
{
#ifdef FORCE_FULL_FEATURES
    // 启用所有网络功能
    ui.chkNetworkDnsFilter->setEnabled(true);
    ui.chkNetworkUseProxy->setEnabled(true);
#else
    // 原始授权检查
    if (!theAPI->GetCertInfo().opt_net) {
        ui.chkNetworkDnsFilter->setEnabled(false);
        // ...
    }
#endif
}
```

#### 4.5 修改 NewBoxWizard.cpp

**文件位置：** `SandboxiePlus/SandMan/Wizards/NewBoxWizard.cpp`

```cpp
void CNewBoxWizard::InitializePage(int id)
{
#ifdef FORCE_FULL_FEATURES
    // 显示所有沙盒类型选项
    m_pBoxTypePage->ShowAllOptions();
#else
    // 根据证书级别显示选项
    if (!theAPI->GetCertInfo().opt_enc) {
        m_pBoxTypePage->HideEncryptedBox();
    }
#endif
}
```

---

### 5. 修改服务层授权检查

#### 5.1 修改 DriverAssistStart.cpp

**文件位置：** `Sandboxie/core/svc/DriverAssistStart.cpp`

```cpp
NTSTATUS CheckCertificate()
{
#ifdef FORCE_FULL_FEATURES
    return STATUS_SUCCESS; // 跳过证书检查
#else
    // 原始证书检查逻辑
#endif
}
```

#### 5.2 修改 UserServer.cpp

**文件位置：** `Sandboxie/core/svc/UserServer.cpp`

```cpp
bool UserServer::HasFeature(const wchar_t* feature)
{
#ifdef FORCE_FULL_FEATURES
    return true; // 所有功能都可用
#else
    // 原始功能检查
#endif
}
```

---

### 6. 创建全局配置头文件

**新建文件：** `Sandboxie/common/license_config.h`

```c
#ifndef _LICENSE_CONFIG_H
#define _LICENSE_CONFIG_H

// ============================================
// 授权配置
// ============================================
// 设置为 1 启用所有功能（无需证书）
// 设置为 0 使用原始证书验证系统
#define FORCE_FULL_FEATURES 1

// ============================================
// 条件编译宏
// ============================================
#if FORCE_FULL_FEATURES

    // 证书级别检查 - 始终返回真
    #define CHECK_CERT_LEVEL(level) (1)
    
    // 证书功能检查 - 始终返回真
    #define CHECK_CERT_FEATURE(feature) (1)
    
    // 证书要求 - 空操作
    #define REQUIRE_CERTIFICATE() 
    
    // 功能启用检查 - 始终返回真
    #define IS_FEATURE_ENABLED(feature) (1)

#else

    // 原始证书检查宏
    #define CHECK_CERT_LEVEL(level) \
        (Verify_CertInfo.active && Verify_CertInfo.level >= (level))
    
    #define CHECK_CERT_FEATURE(feature) \
        (Verify_CertInfo.feature)
    
    #define REQUIRE_CERTIFICATE() \
        if (!Verify_CertInfo.active) return STATUS_NOT_LICENSED;
    
    #define IS_FEATURE_ENABLED(feature) \
        (Verify_CertInfo.feature)

#endif

#endif // _LICENSE_CONFIG_H
```

然后在所有需要检查授权的文件开头包含此头文件：

```c
#include "common/license_config.h"
```

---

## 编译配置

### 修改项目配置

#### Visual Studio 项目设置

1. 打开 `Sandboxie.sln`
2. 右键点击项目 → 属性
3. C/C++ → 预处理器 → 预处理器定义
4. 添加：`FORCE_FULL_FEATURES=1`

#### 或者修改 CMakeLists.txt（如果使用 CMake）

```cmake
# 添加全局定义
add_definitions(-DFORCE_FULL_FEATURES=1)
```

#### 或者修改 common.h

在 `Sandboxie/common/common.h` 开头添加：

```c
// 强制启用完整功能
#ifndef FORCE_FULL_FEATURES
#define FORCE_FULL_FEATURES 1
#endif
```

---

## 需要修改的文件清单

### 驱动层（必须修改）
- ✅ `Sandboxie/core/drv/verify.h` - 添加宏定义
- ✅ `Sandboxie/core/drv/verify.c` - 强制设置证书信息
- ✅ `Sandboxie/core/drv/api.c` - 移除 API 授权检查
- ⚠️ `Sandboxie/core/drv/process.c` - 移除进程相关授权检查

### 用户态 DLL（必须修改）
- ⚠️ `Sandboxie/core/dll/dns_filter.c` - DNS 过滤授权
- ⚠️ `Sandboxie/core/dll/net.c` - 网络功能授权

### GUI 界面（必须修改）
- ✅ `SandboxiePlus/SandMan/SandMan.cpp` - 主程序证书初始化
- ✅ `SandboxiePlus/SandMan/Windows/SettingsWindow.cpp` - 设置窗口
- ✅ `SandboxiePlus/SandMan/Windows/OptionsGeneral.cpp` - 常规选项
- ✅ `SandboxiePlus/SandMan/Windows/OptionsNetwork.cpp` - 网络选项
- ✅ `SandboxiePlus/SandMan/Wizards/NewBoxWizard.cpp` - 新建沙盒向导
- ⚠️ `SandboxiePlus/SandMan/OnlineUpdater.cpp` - 在线更新

### 服务层（可选修改）
- ⚠️ `Sandboxie/core/svc/DriverAssistStart.cpp` - 驱动辅助启动
- ⚠️ `Sandboxie/core/svc/UserServer.cpp` - 用户服务

### 新建文件
- ✅ `Sandboxie/common/license_config.h` - 全局授权配置

**图例：**
- ✅ 必须修改
- ⚠️ 建议修改（取决于需要的功能）

---

## 快速实施方案

### 最小修改方案（仅 3 个文件）

如果只想快速启用所有功能，只需修改以下 3 个文件：

1. **`Sandboxie/core/drv/verify.c`** - 在第 850 行和 1050 行添加强制设置代码
2. **`Sandboxie/core/drv/verify.h`** - 添加 `FORCE_FULL_FEATURES` 宏定义
3. **`SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`** - 修改 3 个函数返回值

这样就能启用大部分高级功能。

---

## 验证修改

### 编译后验证

1. **检查驱动加载**
```cmd
sc query SbieDrv
```

2. **检查证书状态**
打开 Sandboxie Manager → 帮助 → 关于，查看证书信息应显示为最高级别。

3. **测试高级功能**
- 创建加密沙盒
- 启用隔离桌面
- 配置 DNS 过滤
- 使用安全模式

### 调试输出

在 `verify.c` 中启用调试输出：

```c
#define CertDbg 1  // 在文件开头设置
```

然后使用 DebugView 查看证书加载信息。

---

## 注意事项

### 1. 法律和道德

- ⚠️ 本指南仅用于教育和研究目的
- ⚠️ 建议购买正版授权支持开发者
- ⚠️ 不要重新分发修改后的版本

### 2. 更新问题

- 修改后的版本可能无法使用官方自动更新
- 需要手动合并新版本的代码

### 3. 数字签名

- 修改后的驱动需要重新签名
- 测试模式下可以加载未签名驱动：
```cmd
bcdedit /set testsigning on
```

### 4. 兼容性

- 确保所有模块使用相同的 `FORCE_FULL_FEATURES` 设置
- 驱动和 GUI 必须匹配

---

## 编译命令

### 使用 Visual Studio

```cmd
cd Sandboxie
msbuild Sandboxie.sln /p:Configuration=Release /p:Platform=x64 /p:DefineConstants="FORCE_FULL_FEATURES"
```

### 使用 Qt 编译 GUI

```cmd
cd SandboxiePlus
qmake SandboxiePlus.pro "DEFINES+=FORCE_FULL_FEATURES"
nmake release
```

---

## 对比 SandboxieCrack

根据分析，`SandboxieCrack` 项目并没有直接修改源代码，而是：

1. Fork 原始仓库
2. 通过 GitHub Actions 自动构建
3. 提供替换的二进制文件（可能已经打过补丁）
4. 用户需要自己构建 Plus 部分，然后用提供的文件替换

这种方式避免了直接分发修改后的源代码，但实际效果与本文档描述的修改方案相同。

---

## 总结

要完全去除 Sandboxie 的授权限制，核心修改点是：

1. **驱动层**：在 `verify.c` 中强制设置 `Verify_CertInfo` 为最高级别
2. **头文件**：在 `verify.h` 中定义 `FORCE_FULL_FEATURES` 宏
3. **GUI 层**：在各个设置窗口中跳过授权检查

最简单的方法是使用全局宏 `FORCE_FULL_FEATURES=1`，然后在关键位置添加条件编译代码。

**预计修改时间：** 1-2 小时  
**技术难度：** ⭐⭐ (中等)  
**需要技能：** C/C++ 基础、Visual Studio 使用、Windows 驱动开发基础

---

**文档版本：** 2.0  
**创建日期：** 2025-03-04  
**最后更新：** 2025-03-04  
