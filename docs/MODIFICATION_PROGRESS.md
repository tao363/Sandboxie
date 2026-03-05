# Sandboxie 授权和网络功能移除 - 修改进度

## 已完成的修改

### ✅ 1. 内核驱动层 (verify.c 和 verify.h)

#### 文件：`Sandboxie/core/drv/verify.c`

**修改点 1（约第 835 行）：强制设置最高权限**
```c
Verify_CertInfo.active = 1;

// ============================================
// 强制设置为最高级别永久证书，无需验证
// ============================================
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
if(CertDbg) DbgPrint("Sbie Cert: Forced to max level (certificate validation bypassed)\n");
```

**修改点 2（约第 1095 行）：在没有证书时也启用功能**
```c
CleanupExit:
    if(CertDbg)     DbgPrint("Sbie Cert status: %08x; active: %d\n", status, Verify_CertInfo.active);

    // ============================================
    // 强制启用所有功能，无需证书验证
    // ============================================
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
        if(CertDbg) DbgPrint("Sbie Cert: Forced to max level (no certificate required)\n");
    }
```

#### 文件：`Sandboxie/core/drv/verify.h`

**修改点 1：添加全局宏定义**
```c
#define SOFTWARE_NAME L"Sandboxie-Plus"

// ============================================
// 强制启用所有功能，无需证书验证
// ============================================
#define FORCE_FULL_FEATURES 1
```

**修改点 2：强制所有证书检查返回真**
```c
// ============================================
// 强制所有证书检查返回真
// ============================================
#if FORCE_FULL_FEATURES
    #define CERT_IS_LEVEL(cert,l)       (1)
    #define CERT_HAS_FEATURE(cert,f)    (1)
    #define CERT_IS_ACTIVE(cert)        (1)
#else
    #define CERT_IS_LEVEL(cert,l)       (cert.active && cert.level >= (unsigned long)(l))
    #define CERT_HAS_FEATURE(cert,f)    (cert.f)
    #define CERT_IS_ACTIVE(cert)        (cert.active)
#endif
```

### ✅ 2. GUI 层 - 在线更新模块 (OnlineUpdater.cpp)

#### 文件：`SandboxiePlus/SandMan/OnlineUpdater.cpp`

**修改点 1：禁用 GetUpdates 函数**
```cpp
SB_PROGRESS COnlineUpdater::GetUpdates(QObject* receiver, const char* member, const QVariantMap& Params)
{
	// ============================================
	// 禁用网络更新功能
	// ============================================
	// 直接返回空进度，不进行网络请求
	CSbieProgressPtr pProgress = CSbieProgressPtr(new CSbieProgress());
	pProgress->Finish(SB_OK);
	
	// 返回空的更新数据
	QVariantMap EmptyData;
	EmptyData["disabled"] = true;
	EmptyData["message"] = "Online update is disabled in this build";
	QMetaObject::invokeMethod(receiver, member, Qt::QueuedConnection, 
		Q_ARG(QVariantMap, EmptyData), Q_ARG(QVariantMap, Params));
	
	return pProgress;
	
	/* 原始代码已禁用 */
}
```

**修改点 2：禁用 GetSupportCert 函数**
```cpp
SB_PROGRESS COnlineUpdater::GetSupportCert(const QString& Serial, QObject* receiver, const char* member, const QVariantMap& Params)
{
	// ============================================
	// 禁用证书下载功能
	// ============================================
	CSbieProgressPtr pProgress = CSbieProgressPtr(new CSbieProgress());
	pProgress->Finish(SB_ERR(SB_OtherError));
	return pProgress;
	
	/* 原始代码已禁用 */
}
```

---

## 🔄 待完成的修改

### 3. GUI 层 - 更新检查函数

#### 文件：`SandboxiePlus/SandMan/OnlineUpdater.cpp`

**需要修改：CheckForUpdates 函数**

由于文件格式问题，需要手动修改。找到 `void COnlineUpdater::CheckForUpdates(bool bManual)` 函数，在函数开头添加：

```cpp
void COnlineUpdater::CheckForUpdates(bool bManual)
{
	// ============================================
	// 禁用更新检查功能
	// ============================================
	if (bManual) {
		QMessageBox::information(theGUI, tr("Update Check"), 
			tr("Online update functionality is disabled in this build.\n"
			   "This version does not support automatic updates."));
	}
	return;
	
	/* 原始代码保持不变，但不会执行 */
}
```

### 4. GUI 层 - 证书初始化

#### 文件：`SandboxiePlus/SandMan/SandMan.cpp`

需要找到证书加载/初始化的函数（可能是 `ReloadCert()` 或 `LoadCert()`），添加强制设置：

```cpp
void CSandMan::LoadCertificate()  // 或 ReloadCert()
{
	// ============================================
	// 强制设置证书信息为最高级别
	// ============================================
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
	// 原始代码可以注释掉
}
```

### 5. GUI 层 - 设置窗口

#### 文件：`SandboxiePlus/SandMan/Windows/SettingsWindow.cpp`

需要找到并修改以下函数（如果存在）：

```cpp
// 隐藏或禁用更新相关的 UI 控件
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

// 禁用证书管理功能
void CSettingsWindow::OnGetCert()
{
	QMessageBox::information(this, "Certificate Management", 
		"Certificate functionality is disabled.\n"
		"All Plus features are enabled by default.");
}
```

### 6. 可选：其他 GUI 文件

#### 文件：`SandboxiePlus/SandMan/Windows/OptionsGeneral.cpp`

```cpp
void COptionsGeneral::LoadSettings()
{
	// ... 原有代码 ...
	
	// 启用所有高级选项，不检查证书
	ui.chkUseSecurityMode->setEnabled(true);
	ui.chkUsePrivacyMode->setEnabled(true);
	ui.chkUseEncryption->setEnabled(true);
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
}
```

---

## 📝 手动修改步骤

由于某些文件的格式问题，建议手动完成以下步骤：

1. **打开 `OnlineUpdater.cpp`**，搜索 `void COnlineUpdater::CheckForUpdates`
   - 在函数开头添加禁用代码（见上文）

2. **打开 `SandMan.cpp`**，搜索 `ReloadCert` 或 `LoadCert` 或 `g_CertInfo`
   - 找到证书初始化的位置
   - 添加强制设置代码（见上文）

3. **打开 `SettingsWindow.cpp`**，搜索更新相关的 UI 代码
   - 隐藏或禁用更新检查按钮
   - 修改证书管理函数

4. **（可选）修改其他选项窗口**
   - `OptionsGeneral.cpp` - 启用所有高级选项
   - `OptionsNetwork.cpp` - 启用所有网络选项

---

## 🔨 编译和测试

### 编译步骤

1. **清理项目**
```cmd
cd f:\Project\AI\sanbox\Sandboxie\Sandboxie
msbuild Sandboxie.sln /t:Clean
```

2. **编译驱动**
```cmd
msbuild Sandboxie.sln /p:Configuration=Release /p:Platform=x64
```

3. **编译 GUI**
```cmd
cd f:\Project\AI\sanbox\Sandboxie\SandboxiePlus
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

---

## 📊 修改进度总结

- ✅ **内核驱动层** - 100% 完成
  - ✅ verify.c - 2 处修改完成
  - ✅ verify.h - 2 处修改完成

- ✅ **GUI 在线更新模块** - 60% 完成
  - ✅ GetUpdates() - 已禁用
  - ✅ GetSupportCert() - 已禁用
  - ⏳ CheckForUpdates() - 需手动修改

- ⏳ **GUI 证书管理** - 0% 完成
  - ⏳ SandMan.cpp - 需手动修改
  - ⏳ SettingsWindow.cpp - 需手动修改

- ⏳ **GUI 选项窗口** - 0% 完成（可选）
  - ⏳ OptionsGeneral.cpp
  - ⏳ OptionsNetwork.cpp

**总体进度：约 50% 完成**

核心功能（驱动层授权移除）已完成，剩余的主要是 GUI 层的界面调整。

---

**文档版本：** 1.0  
**创建日期：** 2025-01-XX  
**最后更新：** 2025-01-XX
