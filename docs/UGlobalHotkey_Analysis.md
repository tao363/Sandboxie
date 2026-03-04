# UGlobalHotkey 代码分析文档

## 概述

UGlobalHotkey 是一个基于 Qt 框架的跨平台全局热键库，支持 Windows、Linux 和 MacOSX 平台。该库允许应用程序注册系统级的全局热键，即使应用程序不在前台也能响应热键事件。

**作者**: [bakwc](https://github.com/bakwc)  
**来源**: 从 [Pastexen](https://github.com/bakwc/Pastexen) 项目中提取  
**许可证**: Public Domain（公共领域）

---

## 目录结构

```
UGlobalHotkey/
├── uglobal.h              # 导出宏定义
├── uexception.h/cpp       # 异常处理类
├── ukeysequence.h/cpp     # 按键序列处理类
├── uglobalhotkeys.h/cpp   # 全局热键管理器主类
├── hotkeymap.h            # 平台相关的按键映射
└── README.md              # 项目说明文档
```

---

## 文件详细分析

### 1. uglobal.h

**作用**: 定义库的导出宏，用于跨平台的动态库符号导出/导入。

#### 宏定义

- `UGLOBALHOTKEY_EXPORT`: 根据编译配置自动选择导出或导入符号
  - 当定义 `UGLOBALHOTKEY_LIBRARY` 时：使用 `Q_DECL_EXPORT` 导出符号
  - 当定义 `UGLOBALHOTKEY_NOEXPORT` 时：不导出符号
  - 默认情况：使用 `Q_DECL_IMPORT` 导入符号

**设计目的**: 确保库在编译为动态库时能正确导出符号，在使用库时能正确导入符号。

---

### 2. uexception.h/cpp

**作用**: 提供自定义异常类，用于库内部的错误处理。

#### 类: UException

继承自 `std::exception`，提供 Qt 风格的异常处理。

##### 成员变量

- `QByteArray Message`: 存储异常消息的字节数组

##### 成员函数

**构造函数**
```cpp
UException(const QString& message) throw()
```
- **功能**: 创建异常对象并存储错误消息
- **参数**: `message` - QString 格式的错误消息
- **实现**: 将 QString 转换为本地 8 位编码的 QByteArray 存储

**析构函数**
```cpp
~UException() throw()
```
- **功能**: 清理异常对象
- **特点**: 使用 `throw()` 声明不抛出异常

**what() 方法**
```cpp
const char* what() const throw()
```
- **功能**: 返回异常消息的 C 字符串
- **返回值**: 指向错误消息的 const char* 指针
- **用途**: 符合标准 C++ 异常接口

---

### 3. ukeysequence.h/cpp

**作用**: 处理按键序列的解析、存储和转换，是热键功能的核心数据结构。

#### 类: UKeySequence

继承自 `QObject`，管理按键组合（如 Ctrl+Shift+F12）。

##### 成员变量

- `QVector<int> Keys`: 存储按键代码的向量，包括修饰键和普通键

##### 构造函数

**默认构造函数**
```cpp
UKeySequence(QObject *parent = 0)
```
- **功能**: 创建空的按键序列对象

**字符串构造函数**
```cpp
UKeySequence(const QString& str, QObject *parent = 0)
```
- **功能**: 从字符串解析并创建按键序列
- **参数**: `str` - 按键组合字符串（如 "Ctrl+Shift+F12"）
- **实现**: 调用 `FromString()` 方法解析字符串

##### 核心方法

**FromString()**
```cpp
void FromString(const QString& str)
```
- **功能**: 解析按键组合字符串
- **实现**: 
  1. 使用 '+' 分割字符串
  2. 逐个添加按键到序列中
- **示例**: "Ctrl+Shift+F12" → [Qt::Key_Control, Qt::Key_Shift, Qt::Key_F12]

**ToString()**
```cpp
QString ToString()
```
- **功能**: 将按键序列转换为字符串表示
- **实现**:
  1. 分别获取修饰键和普通键
  2. 使用 '+' 连接所有按键名称
- **返回值**: 格式化的按键组合字符串

**AddKey(int key)**
```cpp
void AddKey(int key)
```
- **功能**: 添加按键代码到序列
- **特点**:
  - 忽略无效按键（key <= 0）
  - 自动去重，避免重复添加相同按键
  - 输出调试信息

**AddKey(const QString& key)**
```cpp
void AddKey(const QString& key)
```
- **功能**: 从字符串添加按键
- **支持的修饰键**:
  - "alt" → Qt::Key_Alt
  - "shift" / "shft" → Qt::Key_Shift
  - "control" / "ctrl" → Qt::Key_Control
  - "win" / "meta" → Qt::Key_Meta
- **错误处理**: 
  - 检测非法字符（'+' 或 ','）
  - 验证按键序列有效性
  - 抛出 UException 异常

**AddModifiers()**
```cpp
void AddModifiers(Qt::KeyboardModifiers mod)
```
- **功能**: 添加 Qt 键盘修饰符
- **支持的修饰符**:
  - Qt::ShiftModifier
  - Qt::ControlModifier
  - Qt::AltModifier
  - Qt::MetaModifier

**AddKey(const QKeyEvent* event)**
```cpp
void AddKey(const QKeyEvent* event)
```
- **功能**: 从键盘事件添加按键
- **实现**: 提取事件的按键代码和修饰符

**GetSimpleKeys()**
```cpp
QVector<int> GetSimpleKeys() const
```
- **功能**: 获取所有非修饰键
- **返回值**: 普通按键的向量（如 F12, A, B 等）

**GetModifiers()**
```cpp
QVector<int> GetModifiers() const
```
- **功能**: 获取所有修饰键
- **返回值**: 修饰键的向量（Shift, Ctrl, Alt, Meta）

**Size()**
```cpp
inline size_t Size() const
```
- **功能**: 返回按键序列中的按键数量

**operator[]**
```cpp
inline int operator[](size_t n) const
```
- **功能**: 通过索引访问按键
- **错误处理**: 越界时抛出 UException

##### 辅助函数

**IsModifier()**
```cpp
bool IsModifier(int key)
```
- **功能**: 判断按键是否为修饰键
- **检查的按键**: Shift, Control, Alt, Meta

**KeyToStr()**
```cpp
static QString KeyToStr(int key)
```
- **功能**: 将按键代码转换为字符串
- **特殊处理**: 修饰键使用自定义名称，其他键使用 QKeySequence 转换

---

### 4. hotkeymap.h

**作用**: 提供平台相关的按键映射转换函数，将 Qt 按键代码转换为操作系统原生按键代码。

#### Windows 平台

**QtKeyToWin()**
```cpp
inline size_t QtKeyToWin(size_t key)
```
- **功能**: 将 Qt 按键代码转换为 Windows 虚拟键码
- **实现**:
  - F1-F24 功能键：计算偏移量转换为 VK_F1 到 VK_F24
  - 其他键：直接返回（Qt 键码与 Windows 键码兼容）
- **注意**: 注释表明需要完善其他按键的映射

#### Linux 平台

**结构体: UKeyData**
```cpp
struct UKeyData {
    int key;   // 按键代码
    int mods;  // 修饰符掩码
}
```

**QtKeyToLinux()**
```cpp
inline UKeyData QtKeyToLinux(const UKeySequence &keySeq)
```
- **功能**: 将 Qt 按键序列转换为 X11/XCB 按键数据
- **按键转换**:
  - F1-F35: 计算偏移量转换为 XK_F1 到 XK_F35
  - Space 到 QuoteLeft 范围：无需转换
  - 其他键：抛出异常（未定义转换）
- **修饰符转换**:
  - Qt::Key_Shift → XCB_MOD_MASK_SHIFT
  - Qt::Key_Control → XCB_MOD_MASK_CONTROL
  - Qt::Key_Alt → XCB_MOD_MASK_1
  - Qt::Key_Meta → XCB_MOD_MASK_4
- **错误处理**: 
  - 无普通键时抛出 "Invalid hotkey"
  - 未定义转换时抛出异常

#### MacOSX 平台

**结构体: UKeyData**
```cpp
struct UKeyData {
    uint32_t key;   // 按键代码
    uint32_t mods;  // 修饰符掩码
}
```

**KEY_MAP**
- **类型**: `std::unordered_map<uint32_t, uint32_t>`
- **功能**: Qt 按键到 macOS 虚拟键码的映射表
- **包含**: 
  - A-Z 字母键 (kVK_ANSI_A 到 kVK_ANSI_Z)
  - 0-9 数字键 (kVK_ANSI_0 到 kVK_ANSI_9)
  - F1-F14 功能键 (kVK_F1 到 kVK_F14)

**MOD_MAP**
- **类型**: `std::unordered_map<uint32_t, uint32_t>`
- **功能**: Qt 修饰键到 macOS 修饰符的映射
- **映射关系**:
  - Qt::Key_Shift → shiftKey
  - Qt::Key_Alt → optionKey
  - Qt::Key_Control → controlKey
  - Qt::Key_Option → optionKey
  - Qt::Key_Meta → cmdKey

**QtKeyToMac()**
```cpp
inline UKeyData QtKeyToMac(const UKeySequence &keySeq)
```
- **功能**: 将 Qt 按键序列转换为 macOS 按键数据
- **实现**:
  1. 提取普通键和修饰键
  2. 验证普通键在映射表中
  3. 累加所有修饰符
- **错误处理**: 无效按键或修饰符时抛出 UException

---

### 5. uglobalhotkeys.h/cpp

**作用**: 全局热键管理器的核心实现，负责注册、注销热键并处理系统热键事件。

#### 类: UGlobalHotkeys

继承自 `QWidget`，在 Linux 平台还继承 `QAbstractNativeEventFilter`。

##### 平台相关数据结构

**Linux 平台 - UHotkeyData**
```cpp
struct UHotkeyData {
    xcb_keycode_t keyCode;  // XCB 按键代码
    int mods;               // 修饰符掩码
    bool operator ==(const UHotkeyData& data) const;
}
```
- **功能**: 存储 Linux 平台的热键数据
- **用途**: 用于热键的注册和查找

##### 成员变量

**Windows 平台**
- `QSet<size_t> Registered`: 已注册热键 ID 的集合

**Linux 平台**
- `QHash<size_t, UHotkeyData> Registered`: 热键 ID 到热键数据的映射
- `xcb_connection_t* X11Connection`: X11 连接对象
- `xcb_window_t X11Wid`: X11 窗口 ID（根窗口）
- `xcb_key_symbols_t* X11KeySymbs`: X11 按键符号表

**MacOSX 平台**
- `QHash<size_t, EventHotKeyRef> HotkeyRefs`: 热键 ID 到热键引用的映射

##### 构造函数

```cpp
UGlobalHotkeys(QWidget *parent = 0)
```
- **功能**: 初始化全局热键管理器
- **Windows**: 创建隐藏窗口用于接收热键消息
- **Linux**: 
  1. 安装原生事件过滤器
  2. 获取 X11 连接
  3. 获取根窗口 ID
  4. 分配按键符号表
- **MacOSX**: 创建隐藏窗口
- **共同特点**: 设置窗口不可见（`setVisible(false)`）

##### 析构函数

```cpp
~UGlobalHotkeys()
```
- **功能**: 清理资源
- **Windows**: 注销所有已注册的热键
- **Linux**: 释放 X11 按键符号表
- **MacOSX**: 自动清理（通过 QHash）

##### 公共方法

**registerHotkey(const QString& keySeq, size_t id)**
```cpp
void registerHotkey(const QString& keySeq, size_t id = 1)
```
- **功能**: 注册字符串格式的热键
- **参数**:
  - `keySeq`: 热键字符串（如 "Ctrl+Shift+F12"）
  - `id`: 热键唯一标识符（默认为 1）
- **实现**: 转换为 UKeySequence 后调用重载版本

**registerHotkey(const UKeySequence& keySeq, size_t id)**
```cpp
void registerHotkey(const UKeySequence& keySeq, size_t id = 1)
```
- **功能**: 注册热键序列
- **验证**: 检查按键序列是否为空，空则抛出异常
- **重复处理**: 如果 ID 已存在，先注销旧热键

**Windows 实现**:
1. 解析按键序列，提取修饰符和主键
2. 转换修饰符:
   - Qt::Key_Control → MOD_CONTROL
   - Qt::Key_Alt → MOD_ALT
   - Qt::Key_Shift → MOD_SHIFT
   - Qt::Key_Meta → MOD_WIN
3. 转换主键（使用 QtKeyToWin）
4. 特殊处理: Pause 键和 Cancel 键
5. 调用 Windows API `RegisterHotKey()`
6. 成功后将 ID 添加到 Registered 集合

**Linux 实现**:
- 调用 `regLinuxHotkey()` 方法

**MacOSX 实现**:
1. 先注销已存在的热键
2. 创建事件热键引用和 ID
3. 设置事件类型为键盘热键按下
4. 安装应用程序事件处理器（`macHotkeyHandler`）
5. 转换按键序列（使用 QtKeyToMac）
6. 调用 `RegisterEventHotKey()`
7. 保存热键引用到 HotkeyRefs

**unregisterHotkey(size_t id)**
```cpp
void unregisterHotkey(size_t id = 1)
```
- **功能**: 注销指定 ID 的热键
- **验证**: 断言热键已注册
- **Windows**: 调用 `UnregisterHotKey()`
- **Linux**: 调用 `unregLinuxHotkey()`
- **MacOSX**: 调用 `UnregisterEventHotKey()`
- **清理**: 从 Registered 中移除 ID

**unregisterAllHotkeys()**
```cpp
void unregisterAllHotkeys()
```
- **功能**: 注销所有已注册的热键
- **实现**: 遍历 Registered 集合，逐个调用 `unregisterHotkey()`
- **注意**: Windows 和 Linux 平台创建临时副本以避免迭代时修改

##### 信号

**activated(size_t id)**
```cpp
signals:
    void activated(size_t id);
```
- **功能**: 热键被触发时发出信号
- **参数**: `id` - 被触发的热键 ID
- **用途**: 连接到应用程序的槽函数处理热键事件

##### Windows 平台方法

**winEvent(MSG* message)**
```cpp
bool winEvent(MSG* message)
```
- **功能**: 处理 Windows 消息
- **实现**:
  1. 检查消息类型是否为 WM_HOTKEY
  2. 提取热键 ID（wParam）
  3. 验证 ID 已注册
  4. 发出 activated 信号
- **返回值**: false（允许其他处理器继续处理）

**nativeEvent()**
```cpp
bool nativeEvent(const QByteArray &eventType, void *message, long/qintptr *result)
```
- **功能**: Qt 原生事件过滤器接口
- **实现**: 调用 `winEvent()` 处理消息
- **兼容性**: Qt 6.0+ 使用 qintptr，之前版本使用 long

##### Linux 平台方法

**nativeEventFilter()**
```cpp
bool nativeEventFilter(const QByteArray &eventType, void *message, long *result)
```
- **功能**: Qt 原生事件过滤器接口
- **实现**: 调用 `linuxEvent()` 处理 XCB 事件

**linuxEvent(xcb_generic_event_t* message)**
```cpp
bool linuxEvent(xcb_generic_event_t *message)
```
- **功能**: 处理 XCB 事件
- **实现**:
  1. 检查事件类型是否为 XCB_KEY_PRESS
  2. 提取按键详情和状态
  3. 忽略 NumLock 状态（& ~XCB_MOD_MASK_2）
  4. 在 Registered 中查找匹配的热键
  5. 找到则发出 activated 信号
- **返回值**: 
  - true: 事件已处理（是注册的热键）
  - false: 不是热键事件

**regLinuxHotkey(const UKeySequence& keySeq, size_t id)**
```cpp
void regLinuxHotkey(const UKeySequence &keySeq, size_t id)
```
- **功能**: 在 Linux 平台注册热键
- **实现**:
  1. 转换按键序列为 Linux 格式（QtKeyToLinux）
  2. 获取按键代码（xcb_key_symbols_get_keycode）
  3. 创建 UHotkeyData 结构
  4. 调用 xcb_grab_key 两次:
     - 第一次: 不带 NumLock
     - 第二次: 带 NumLock（XCB_MOD_MASK_2）
  5. 将热键数据插入 Registered

**unregLinuxHotkey(size_t id)**
```cpp
void unregLinuxHotkey(size_t id)
```
- **功能**: 在 Linux 平台注销热键
- **实现**:
  1. 从 Registered 中取出并移除热键数据
  2. 调用 xcb_ungrab_key 两次（对应注册时的两次 grab）

##### MacOSX 平台方法

**onHotkeyPressed(size_t id)**
```cpp
void onHotkeyPressed(size_t id)
```
- **功能**: MacOSX 热键回调函数
- **实现**: 发出 activated 信号
- **调用者**: `macHotkeyHandler` 全局函数

**macHotkeyHandler() 全局函数**
```cpp
OSStatus macHotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData)
```
- **功能**: MacOSX 系统热键事件处理器
- **实现**:
  1. 从事件中提取热键 ID
  2. 将 userData 转换为 UGlobalHotkeys 指针
  3. 调用 `onHotkeyPressed()` 方法
- **返回值**: noErr（无错误）

---

## 工作流程

### 热键注册流程

1. **用户调用**: `registerHotkey("Ctrl+Shift+F12", 1)`
2. **字符串解析**: UKeySequence 解析按键组合
3. **平台转换**: 
   - Windows: 转换为 MOD_* 和 VK_* 代码
   - Linux: 转换为 XCB 按键代码和修饰符
   - MacOSX: 转换为 Carbon 按键代码和修饰符
4. **系统注册**: 调用操作系统 API 注册全局热键
5. **记录状态**: 保存热键 ID 和相关数据

### 热键触发流程

1. **系统事件**: 用户按下注册的热键组合
2. **事件捕获**:
   - Windows: WM_HOTKEY 消息到达窗口
   - Linux: XCB_KEY_PRESS 事件被过滤器捕获
   - MacOSX: Carbon 事件处理器被调用
3. **ID 识别**: 从事件中提取或查找热键 ID
4. **信号发射**: 发出 `activated(id)` 信号
5. **应用响应**: 连接的槽函数执行相应操作

---

## 平台差异总结

### Windows
- **优点**: 实现简单，API 直接
- **机制**: 基于窗口消息（WM_HOTKEY）
- **限制**: 需要窗口句柄

### Linux
- **优点**: 灵活，支持 X11/XCB
- **机制**: 基于 X11 键盘抓取（xcb_grab_key）
- **特点**: 需要处理 NumLock 状态
- **限制**: 按键转换范围有限

### MacOSX
- **优点**: 系统级事件处理
- **机制**: 基于 Carbon Event Manager
- **特点**: 使用事件处理器回调
- **限制**: 需要维护热键引用

---

## 使用示例

```cpp
// 创建热键管理器
UGlobalHotkeys *hotkeyManager = new UGlobalHotkeys();

// 注册热键
hotkeyManager->registerHotkey("Ctrl+Shift+F12", 1);
hotkeyManager->registerHotkey("Alt+Q", 2);

// 连接信号
connect(hotkeyManager, &UGlobalHotkeys::activated, [=](size_t id) {
    switch(id) {
        case 1:
            qDebug() << "Ctrl+Shift+F12 pressed";
            // 执行操作 1
            break;
        case 2:
            qDebug() << "Alt+Q pressed";
            // 执行操作 2
            break;
    }
});

// 注销热键
hotkeyManager->unregisterHotkey(1);

// 注销所有热键
hotkeyManager->unregisterAllHotkeys();
```

---

## 设计特点

### 1. 跨平台抽象
- 统一的 API 接口隐藏平台差异
- 平台相关代码通过条件编译分离
- 使用 Qt 的跨平台特性

### 2. 异常安全
- 使用自定义异常类处理错误
- 关键操作有验证和错误检查
- 资源管理遵循 RAII 原则

### 3. 信号槽机制
- 利用 Qt 信号槽实现事件通知
- 解耦热键检测和业务逻辑
- 支持多个槽函数连接

### 4. ID 管理
- 使用数字 ID 标识热键
- 支持动态注册和注销
- 防止重复注册

### 5. 隐藏窗口技巧
- Windows 需要窗口接收消息
- 设置窗口不可见避免干扰用户
- 利用 Qt 的窗口管理

---

## 潜在改进方向

1. **按键映射完善**: Windows 和 Linux 的按键转换不完整
2. **错误处理增强**: 可以提供更详细的错误信息
3. **热键冲突检测**: 检测与系统或其他应用的热键冲突
4. **热键序列支持**: 支持连续按键序列（如 Ctrl+K, Ctrl+D）
5. **配置持久化**: 支持保存和加载热键配置
6. **热键禁用/启用**: 支持临时禁用热键而不注销

---

## 依赖项

### Qt 模块
- QtCore: 核心功能
- QtWidgets: 窗口和事件处理

### 平台 API
- **Windows**: Windows.h (RegisterHotKey, UnregisterHotKey)
- **Linux**: XCB (xcb_grab_key, xcb_ungrab_key)
- **MacOSX**: Carbon (RegisterEventHotKey, UnregisterEventHotKey)

---

## 总结

UGlobalHotkey 是一个设计良好的跨平台全局热键库，通过抽象平台差异提供统一的 API。它充分利用了 Qt 框架的特性，实现了简洁易用的接口。该库适用于需要全局热键功能的桌面应用程序，如截图工具、剪贴板管理器、快速启动器等。

**核心价值**:
- 跨平台支持（Windows/Linux/MacOSX）
- 简单易用的 API
- 基于 Qt 信号槽的事件机制
- Public Domain 许可证，使用自由

