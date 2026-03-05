# 文件级分析：SandMan.cpp

## 1. 文件概述

**职责定位**：Sandboxie Plus 的主窗口和应用程序控制器，负责 GUI 初始化、事件处理、多显示器支持、主题管理和用户交互协调。

**文件类型**：Qt 应用程序 / 主窗口控制器

**文件路径**：`SandboxiePlus/SandMan/SandMan.cpp`

**所属模块**：GUI 层 (SandMan.exe) - Sandboxie Plus

---

## 2. 公开接口（Public API）

| 名称 | 类型 | 签名/参数 | 返回值 | 简要说明 |
|------|------|----------|--------|----------|
| CSandMan | 类 | - | - | 主窗口类（推测） |
| CNativeEventFilter | 类 | - | - | Windows 原生事件过滤器 |
| nativeEventFilter | 方法 | (const QByteArray&, void*, qintptr*) | bool | 处理 Windows 原生消息 |
| UpdateDrives | 方法 | (void) | void | 更新驱动器列表 |
| UpdateTheme | 方法 | (void) | void | 更新应用主题 |
| UpdateTitleTheme | 方法 | (HWND) | void | 更新窗口标题栏主题 |
| CGetTargetMonitorSetting | 静态函数 | (void) | int | 获取目标显示器设置 |
| CGetNonMainTargetMonitorSetting | 静态函数 | (void) | int | 获取非主窗口目标显示器设置 |
| CGetMonitorFallbackSetting | 静态函数 | (void) | int | 获取显示器回退设置 |
| CGetRecoveryTargetMonitorSetting | 静态函数 | (void) | int | 获取恢复窗口目标显示器设置 |
| CGetNotificationTargetMonitorSetting | 静态函数 | (void) | int | 获取通知窗口目标显示器设置 |
| CGetSupportDialogTargetMonitorSetting | 静态函数 | (void) | int | 获取支持对话框目标显示器设置 |
| CGetWindowsMonitorNumber | 静态函数 | (const QString&) | int | 从屏幕名称获取 Windows 显示器编号 |
| CGetDisplayNumberForScreen | 静态函数 | (QScreen*) | int | 获取屏幕的显示器编号 |

---

## 3. 核心逻辑

### 3.1 应用程序架构

```
CSandMan (主窗口)
    ↓
├─ CSbiePlusAPI (API 层)
│  └─ 与 SbieSvc 通信
│
├─ CNativeEventFilter (事件过滤器)
│  ├─ WM_DEVICECHANGE (设备变化)
│  ├─ WM_SETTINGCHANGE (系统设置变化)
│  └─ WM_SHOWWINDOW (窗口显示)
│
├─ Views (视图层)
│  ├─ SbieView (沙箱视图)
│  ├─ TraceView (跟踪视图)
│  └─ FileView (文件视图)
│
├─ Windows (窗口层)
│  ├─ SettingsWindow (设置窗口)
│  ├─ OptionsWindow (选项窗口)
│  ├─ RecoveryWindow (恢复窗口)
│  ├─ SelectBoxWindow (选择沙箱窗口)
│  ├─ SupportDialog (支持对话框)
│  ├─ BoxImageWindow (沙箱镜像窗口)
│  └─ PopUpWindow (弹出窗口)
│
├─ Wizards (向导)
│  ├─ SetupWizard (设置向导)
│  ├─ BoxAssistant (沙箱助手)
│  └─ TemplateWizard (模板向导)
│
├─ Engine (引擎层)
│  ├─ BoxEngine (沙箱引擎)
│  └─ ScriptManager (脚本管理器)
│
└─ Helpers (辅助工具)
   ├─ WinAdmin (Windows 管理)
   ├─ FullScreen (全屏支持)
   ├─ StorageInfo (存储信息)
   └─ WinHelper (Windows 辅助)
```

### 3.2 原生事件处理流程

```
Windows 消息
    ↓
CNativeEventFilter::nativeEventFilter()
    ↓
判断消息类型：
    ↓
├─ WM_DEVICECHANGE (设备变化)
│  ├─ DBT_DEVICEARRIVAL (设备到达)
│  └─ DBT_DEVICEREMOVECOMPLETE (设备移除)
│      ↓
│  theGUI->UpdateDrives()
│  - 更新驱动器列表
│  - 刷新文件视图
│
├─ WM_SETTINGCHANGE (系统设置变化)
│  ↓
│  if (UseDarkTheme == 2) {  // 自动主题
│      theGUI->UpdateTheme()
│      - 检测系统主题
│      - 应用深色/浅色主题
│  }
│
└─ WM_SHOWWINDOW (窗口显示)
   ↓
   if (CoverWindows) {  // 窗口保护
       ProtectWindow(hwnd, 0x0)  // 清除保护
       ProtectWindow(hwnd)       // 应用保护
   }
   ↓
   if (Dialog) {
       theGUI->UpdateTitleTheme(hwnd)
       - 更新标题栏主题
   }
```

### 3.3 多显示器支持

```
显示器配置系统：
    ↓
1. 主窗口显示器
   CGetTargetMonitorSetting()
   - Options/WindowTargetMonitor
    ↓
2. 非主窗口显示器
   CGetNonMainTargetMonitorSetting()
   - Options/NonMainWindowTargetMonitor
    ↓
3. 特定窗口显示器
   ├─ RecoveryWindow
   │  CGetRecoveryTargetMonitorSetting()
   ├─ NotificationWindow
   │  CGetNotificationTargetMonitorSetting()
   └─ SupportDialog
      CGetSupportDialogTargetMonitorSetting()
    ↓
4. 回退策略
   CGetMonitorFallbackSetting()
   - -4: 无回退
   - -3: 主显示器（默认）
   - -2: 当前鼠标位置
   - 0: 第一个显示器
    ↓
5. 显示器识别
   CGetWindowsMonitorNumber(screenName)
   - 从 "DISPLAY1", "DISPLAY2" 等提取编号
    ↓
6. 屏幕到显示器映射
   CGetDisplayNumberForScreen(pScreen)
   - 使用 MonitorFromPoint()
   - 获取 MONITORINFOEX
   - 提取设备名称
```

### 3.4 主题管理

```
主题系统：
    ↓
1. 主题检测
   UseDarkTheme 配置：
   - 0: 强制浅色主题
   - 1: 强制深色主题
   - 2: 自动跟随系统（默认）
    ↓
2. 系统主题监听
   WM_SETTINGCHANGE 消息
   ↓
3. 主题应用
   UpdateTheme()
   - 更新 Qt 样式表
   - 更新窗口标题栏
   - 更新图标
    ↓
4. 窗口标题栏主题
   UpdateTitleTheme(hwnd)
   - 使用 DwmSetWindowAttribute
   - 设置深色/浅色标题栏
```

---

## 4. 依赖关系

### 内部依赖（项目内）

| 依赖模块 | 用途 |
|---------|------|
| MiscHelpers | 通用辅助工具库 |
| QSbieAPI | Sandboxie API 封装 |
| Views/* | 各种视图组件 |
| Windows/* | 各种窗口组件 |
| Wizards/* | 向导组件 |
| Engine/* | 引擎层（脚本、沙箱） |
| Helpers/* | 辅助工具 |
| UGlobalHotkey | 全局热键支持 |

### 外部依赖（Qt/Windows）

| 依赖库 | 用途 |
|-------|------|
| Qt Core | 核心功能 |
| Qt Widgets | GUI 组件 |
| Qt Concurrent | 并发处理 |
| Windows API | 原生 Windows 功能 |
| dbt.h | 设备广播消息 |
| MonitorFromPoint | 显示器检测 |
| GetMonitorInfoW | 显示器信息 |

---

## 5. 数据模型 / 类型定义

### 全局变量

```cpp
// API 实例
CSbiePlusAPI* theAPI = NULL;

// GUI 实例
CSandMan* theGUI = NULL;

// 主窗口句柄
HWND MainWndHandle = NULL;

// 待处理消息
extern QString g_PendingMessage;
```

### CNativeEventFilter 类

```cpp
class CNativeEventFilter : public QAbstractNativeEventFilter
{
public:
    virtual bool nativeEventFilter(
        const QByteArray &eventType, 
        void *message, 
        qintptr *result);
};
```

### 显示器设置常量

```cpp
// 显示器设置值
-4: 无回退
-3: 主显示器（默认）
-2: 当前鼠标位置
-1: 未设置
0+: 特定显示器编号
```

---

## 6. 潜在关注点

### 6.1 原生事件过滤器的性能

⚠️ **性能考虑**：`nativeEventFilter` 处理所有 Windows 消息。

**风险**：
- 处理逻辑过重会影响 UI 响应
- 频繁的消息（如 WM_NOTIFY）需要快速返回

**优化**：
- 只处理必要的消息
- 避免在过滤器中执行耗时操作

### 6.2 窗口保护机制

⚠️ **安全功能**：`ProtectWindow()` 保护窗口免受截图。

**实现**：
```cpp
if (CoverWindows) {
    ProtectWindow(hwnd, 0x0);  // 清除
    ProtectWindow(hwnd);       // 应用
}
```

**用途**：
- 防止屏幕截图
- 防止屏幕录制
- 隐私保护

### 6.3 多显示器配置的复杂性

⚠️ **配置项众多**：
- 主窗口显示器
- 非主窗口显示器
- 恢复窗口显示器
- 通知窗口显示器
- 支持对话框显示器
- 回退策略

**风险**：配置错误可能导致窗口显示在错误的显示器上。

### 6.4 主题自动切换

⚠️ **系统集成**：监听 `WM_SETTINGCHANGE` 自动切换主题。

**优点**：
- 跟随系统主题
- 用户体验一致

**风险**：
- 主题切换可能导致 UI 闪烁
- 需要正确处理所有窗口

### 6.5 设备变化处理

⚠️ **动态更新**：监听 `WM_DEVICECHANGE` 更新驱动器列表。

**场景**：
- USB 驱动器插入/移除
- 网络驱动器连接/断开
- 虚拟驱动器挂载/卸载

**用途**：
- 实时更新文件视图
- 更新沙箱路径

### 6.6 全局变量的线程安全

⚠️ **全局实例**：
```cpp
CSandMan* theGUI = NULL;
CSbiePlusAPI* theAPI = NULL;
```

**风险**：多线程访问可能导致竞态条件。

**保护**：需要确保访问时的线程安全。

### 6.7 Qt 版本兼容性

⚠️ **条件编译**：
```cpp
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    virtual bool nativeEventFilter(..., qintptr *result)
#else
    virtual bool nativeEventFilter(..., long *result)
#endif
```

**原因**：Qt 5 和 Qt 6 的 API 差异。

---

## 7. 架构设计亮点

### 7.1 MVC 架构

```
Model (数据层)
- CSbiePlusAPI
- BoxEngine
    ↓
View (视图层)
- SbieView
- TraceView
- FileView
    ↓
Controller (控制层)
- CSandMan
- ScriptManager
```

### 7.2 事件驱动架构

使用 Qt 信号槽机制和 Windows 消息处理：
- Qt 信号槽：跨组件通信
- Windows 消息：系统事件处理
- 原生事件过滤器：底层消息拦截

### 7.3 模块化设计

功能分散到独立模块：
- Views：显示逻辑
- Windows：窗口管理
- Wizards：向导流程
- Engine：业务逻辑
- Helpers：工具函数

### 7.4 多显示器支持

完善的多显示器管理：
- 灵活的配置选项
- 智能回退策略
- 跨平台兼容

---

## 8. 代码质量评估

**优点**：
- ✅ 清晰的模块化设计
- ✅ 完善的多显示器支持
- ✅ 良好的主题管理
- ✅ Qt 版本兼容性处理

**改进空间**：
- ⚠️ 全局变量可以封装
- ⚠️ 需要更多内联注释
- ⚠️ 事件过滤器可以优化
- ⚠️ 错误处理可以更完善

---

## 9. 用户体验特性

### 9.1 自动主题切换

跟随系统主题自动切换深色/浅色模式。

### 9.2 多显示器智能布局

窗口自动显示在合适的显示器上。

### 9.3 设备热插拔支持

自动检测 USB 驱动器等设备的插入和移除。

### 9.4 窗口保护

防止敏感窗口被截图或录制。

### 9.5 全局热键

支持全局热键快速操作。

---

## 10. 技术栈

### 10.1 UI 框架

- **Qt 5/6**：跨平台 GUI 框架
- **Qt Widgets**：传统桌面 UI
- **Qt Concurrent**：多线程支持

### 10.2 Windows 集成

- **Windows API**：原生功能
- **DWM API**：桌面窗口管理器
- **Monitor API**：多显示器支持

### 10.3 第三方库

- **UGlobalHotkey**：全局热键
- **MiscHelpers**：通用工具库
- **Archive**：压缩文件支持

---

**分析完成时间**：2026-03-05  
**分析版本**：基于最新源代码  
**UI 框架**：Qt 5/6
