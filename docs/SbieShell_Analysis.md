# SbieShell 代码分析文档

## 项目概述

SbieShell 是 Sandboxie-Plus 的 Windows Shell 扩展组件，为 Windows 资源管理器提供右键菜单集成，允许用户直接从文件资源管理器中在沙箱环境中打开文件或文件夹。

## 项目结构

```
SbieShell/
├── SbieShell/              # 主可执行程序
│   └── main.cpp
├── SbieShellExt/           # Shell 扩展 DLL
│   ├── dllmain.cpp
│   ├── framework.h
│   ├── pch.h
│   └── pch.cpp
└── SbieShellPkg/           # MSIX 打包配置
    └── AppxManifest.xml
```

## 核心组件分析

### 1. SbieShell/main.cpp

**文件作用**: 主可执行程序入口，负责注册和卸载 Shell 扩展包。

#### 主要函数

##### `wmain(int argc, wchar_t* argv[])`
- **功能**: 程序入口点
- **参数**: 
  - `-install`: 注册 Shell 扩展包
  - `-uninstall`: 卸载 Shell 扩展包
- **实现逻辑**:
  1. 加载 `SbieShellExt.dll`
  2. 根据命令行参数调用相应的导出函数
  3. `-install` 调用 `RegisterPackage()`
  4. `-uninstall` 调用 `RemovePackage()`

##### WinRT API 包装函数
文件中定义了一系列 WinRT API 的动态加载包装函数，用于在运行时从 `combase.dll` 加载 Windows Runtime 函数：

- `WINRT_GetRestrictedErrorInfo`: 获取受限错误信息
- `WINRT_RoGetActivationFactory`: 获取 WinRT 类的激活工厂
- `WINRT_RoOriginateLanguageException`: 创建语言异常
- `WINRT_SetRestrictedErrorInfo`: 设置受限错误信息
- `WINRT_WindowsCreateString`: 创建 HSTRING
- `WINRT_WindowsCreateStringReference`: 创建 HSTRING 引用
- `WINRT_WindowsDeleteString`: 删除 HSTRING
- `WINRT_WindowsPreallocateStringBuffer`: 预分配字符串缓冲区
- `WINRT_WindowsDeleteStringBuffer`: 删除字符串缓冲区
- `WINRT_WindowsPromoteStringBuffer`: 提升字符串缓冲区
- `WINRT_WindowsGetStringRawBuffer`: 获取字符串原始缓冲区

**设计目的**: 这些包装函数允许程序动态加载 WinRT API，避免静态链接依赖。

---

### 2. SbieShellExt/dllmain.cpp

**文件作用**: Shell 扩展 DLL 的核心实现，提供右键菜单功能。

#### 全局变量

- `g_path`: 存储 DLL 所在目录路径
- `g_ExploreSandboxed`: "Explore Sandboxed" 菜单项文本（可本地化）
- `g_OpenSandboxed`: "Open Sandboxed" 菜单项文本（可本地化）

#### 主要函数

##### `DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)`
- **功能**: DLL 入口点
- **DLL_PROCESS_ATTACH 处理**:
  1. 获取 DLL 所在目录路径并存储到 `g_path`
  2. 从注册表读取本地化字符串：
     - 注册表路径: `HKEY_CURRENT_USER\SOFTWARE\Xanasoft\Sandboxie-Plus\SbieShellExt\Lang`
     - 读取 "Explore Sandboxed" 和 "Open Sandboxed" 的翻译文本
  3. 如果注册表中没有找到，使用默认英文文本

##### `GetDWORDRegKey(HKEY hKey, const std::wstring& strValueName, DWORD& nValue)`
- **功能**: 从注册表读取 DWORD 值
- **返回**: 错误代码

##### `GetStringRegKey(HKEY hKey, const std::wstring& strValueName, std::wstring& strValue)`
- **功能**: 从注册表读取字符串值
- **返回**: 错误代码

#### COM 类实现

##### `TestExplorerCommandBase` (抽象基类)
实现 `IExplorerCommand` 和 `IObjectWithSite` 接口，提供 Shell 扩展命令的基础功能。

**主要方法**:

- `GetTitle()`: 返回菜单项标题（纯虚函数）
- `GetIcon()`: 返回菜单项图标
  - 图标路径: `{DLL目录}\SandMan.exe,-0`
  - 使用 SandMan.exe 的第一个图标资源
  
- `GetState()`: 返回命令状态（启用/禁用）
  - 默认返回 `ECS_ENABLED`

- `Invoke()`: 执行命令的核心逻辑
  1. 遍历用户选择的所有文件/文件夹
  2. 获取每个项目的文件系统路径
  3. 构建命令行参数：
     - 基础参数: `/box:__ask__` (提示用户选择沙箱)
     - 对于 Explore 命令: 添加 `C:\WINDOWS\explorer.exe`
     - 添加选中项目的路径
  4. 使用 `ShellExecuteEx` 启动 `SandMan.exe`
  5. 设置工作目录为选中项目的父目录

- `GetFlags()`: 返回命令标志
  - 默认: `ECF_DEFAULT`

- `EnumSubCommands()`: 枚举子命令
  - 默认返回 `E_NOTIMPL`（无子命令）

- `SetSite()` / `GetSite()`: IObjectWithSite 接口实现
  - 用于获取 Shell 窗口句柄等上下文信息

##### `ExploreCommandHandler` (CLSID: EA3E972D-62C7-4309-8F15-883263041E99)
- **功能**: "Explore Sandboxed" 命令处理器
- **菜单文本**: `g_ExploreSandboxed`（默认 "Explore Sandboxed"）
- **命令类型**: `eExplore`
- **行为**: 在沙箱中打开 Windows 资源管理器，浏览选中的文件夹

##### `OpenCommandHandler` (CLSID: 3FD2D9EE-DAF9-404A-9B7E-13B2DCD63950)
- **功能**: "Open Sandboxed" 命令处理器
- **菜单文本**: `g_OpenSandboxed`（默认 "Open Sandboxed"）
- **命令类型**: `eOpen`
- **行为**: 在沙箱中直接打开选中的文件

#### 包注册函数

##### `RegisterSparsePackage(const std::wstring& sparseExtPath, const std::wstring& sparsePackagePath)`
- **功能**: 注册稀疏包（Sparse Package）
- **参数**:
  - `sparseExtPath`: 外部位置 URI（DLL 所在目录）
  - `sparsePackagePath`: 包清单路径（.msix 文件）
- **实现**:
  1. 创建 `PackageManager` 实例
  2. 配置 `AddPackageOptions`，设置外部位置
  3. 调用 `AddPackageByUriAsync` 异步添加包
  4. 等待操作完成并检查结果
  5. 失败时返回 -1

##### `UnregisterSparsePackage(const std::wstring& sparsePackageName)`
- **功能**: 卸载稀疏包
- **参数**: `sparsePackageName` - 包名称（"SandboxieShell"）
- **实现**:
  1. 创建 `PackageManager` 实例
  2. 调用 `FindPackagesForUser` 查找所有用户包
  3. 遍历包列表，查找匹配的包名
  4. 调用 `RemovePackageAsync` 异步移除包
  5. 等待操作完成并检查结果

##### `RegisterPackage()` (导出函数)
- **功能**: 注册包的导出函数
- **实现**: 调用 `RegisterSparsePackage`，使用 `g_path` 构建路径

##### `RemovePackage()` (导出函数)
- **功能**: 移除包的导出函数
- **实现**: 调用 `UnregisterSparsePackage`，包名为 "SandboxieShell"

#### COM 导出函数

##### `DllGetActivationFactory(_In_ HSTRING activatableClassId, _COM_Outptr_ IActivationFactory** factory)`
- **功能**: 获取 WinRT 激活工厂
- **实现**: 委托给 WRL Module

##### `DllCanUnloadNow()`
- **功能**: 检查 DLL 是否可以卸载
- **返回**: 如果对象计数为 0 返回 S_OK，否则返回 S_FALSE

##### `DllGetClassObject(_In_ REFCLSID rclsid, _In_ REFIID riid, _COM_Outptr_ void** instance)`
- **功能**: 获取 COM 类对象
- **实现**: 委托给 WRL Module

---

### 3. SbieShellExt/framework.h

**文件作用**: 预编译头文件框架，定义基础 Windows 头文件。

**内容**:
```cpp
#define WIN32_LEAN_AND_MEAN  // 排除不常用的 Windows 头文件
#include <windows.h>
```

---

### 4. SbieShellExt/pch.h 和 pch.cpp

**文件作用**: 预编译头文件配置。

- `pch.h`: 包含 `framework.h`
- `pch.cpp`: 预编译头源文件（必需但为空）

---

### 5. SbieShellExt/Source.def

**文件作用**: DLL 导出定义文件。

**导出函数**:
- `DllCanUnloadNow` (PRIVATE)
- `DllGetClassObject` (PRIVATE)
- `DllGetActivationFactory` (PRIVATE)

---

### 6. SbieShellPkg/AppxManifest.xml

**文件作用**: MSIX 包清单文件，定义 Shell 扩展的注册信息。

#### 包标识

- **包名**: SandboxieShell
- **发布者**: Tonalio GmbH
- **版本**: 1.0.0.0
- **架构**: neutral（平台无关）

#### 应用程序配置

- **可执行文件**: SbieShell.exe
- **信任级别**: mediumIL（中等完整性级别）
- **运行时行为**: win32App

#### Shell 扩展注册

##### 文件资源管理器上下文菜单 (desktop4:FileExplorerContextMenus)

**目录类型** (`Directory`):
- **Verb ID**: BowPad
- **CLSID**: EA3E972D-62C7-4309-8F15-883263041E99
- **功能**: 在文件夹上右键显示 "Explore Sandboxed"

**目录背景** (`Directory\Background`):
- **Verb ID**: BowPad
- **CLSID**: EA3E972D-62C7-4309-8F15-883263041E99
- **功能**: 在文件夹空白处右键显示 "Explore Sandboxed"

**所有文件** (`*`):
- **Verb ID**: BowPad
- **CLSID**: 3FD2D9EE-DAF9-404A-9B7E-13B2DCD63950
- **功能**: 在文件上右键显示 "Open Sandboxed"

##### COM 服务器注册 (com:ComServer)

**ExploreCommandHandler**:
- **CLSID**: EA3E972D-62C7-4309-8F15-883263041E99
- **DLL 路径**: SbieShellExt.dll
- **线程模型**: STA (Single-Threaded Apartment)
- **显示名称**: BowPad Context Menu Handler

**OpenCommandHandler**:
- **CLSID**: 3FD2D9EE-DAF9-404A-9B7E-13B2DCD63950
- **DLL 路径**: SbieShellExt.dll
- **线程模型**: STA
- **显示名称**: BowPad Context Menu Handler

#### 功能权限

- `runFullTrust`: 完全信任运行权限
- `unvirtualizedResources`: 访问非虚拟化资源权限

---

## 工作流程

### 安装流程

1. 用户运行 `SbieShell.exe -install`
2. `main.cpp` 加载 `SbieShellExt.dll`
3. 调用 `RegisterPackage()` 导出函数
4. `RegisterSparsePackage()` 使用 Windows Package Manager API 注册稀疏包
5. 系统根据 `AppxManifest.xml` 注册 COM 类和 Shell 扩展
6. Shell 扩展在文件资源管理器中生效

### 卸载流程

1. 用户运行 `SbieShell.exe -uninstall`
2. `main.cpp` 加载 `SbieShellExt.dll`
3. 调用 `RemovePackage()` 导出函数
4. `UnregisterSparsePackage()` 查找并移除 "SandboxieShell" 包
5. Shell 扩展从系统中移除

### 运行时流程

1. 用户在文件资源管理器中右键点击文件或文件夹
2. Windows Shell 加载 `SbieShellExt.dll`
3. 根据选中项类型，实例化相应的命令处理器：
   - 文件夹 → `ExploreCommandHandler`
   - 文件 → `OpenCommandHandler`
4. 调用 `GetTitle()` 获取菜单文本（支持本地化）
5. 调用 `GetIcon()` 获取菜单图标
6. 用户点击菜单项时，调用 `Invoke()`
7. `Invoke()` 构建命令行并启动 `SandMan.exe`
8. `SandMan.exe` 提示用户选择沙箱（`/box:__ask__`）
9. 在选定的沙箱中执行文件或打开资源管理器

---

## 技术特点

### 1. 稀疏包 (Sparse Package)
- 使用 Windows 10 稀疏包技术部署 Shell 扩展
- 无需完整的 MSIX 打包，文件保持在原位置
- 通过 `ExternalLocationUri` 指向实际文件位置

### 2. COM 互操作
- 使用 Windows Runtime Library (WRL) 实现 COM 接口
- 实现 `IExplorerCommand` 接口提供现代 Shell 扩展
- 支持 COM 激活和对象生命周期管理

### 3. 本地化支持
- 从注册表读取本地化字符串
- 注册表路径: `HKCU\SOFTWARE\Xanasoft\Sandboxie-Plus\SbieShellExt\Lang`
- 支持动态切换语言

### 4. 动态 API 加载
- `main.cpp` 中动态加载 WinRT API
- 避免静态链接依赖
- 提高兼容性和灵活性

### 5. 多文件支持
- `Invoke()` 方法支持处理多个选中项
- 遍历 `IShellItemArray` 中的所有项目
- 为每个项目启动独立的沙箱实例

---

## 依赖项

### Windows API
- Windows Shell API (`shobjidl_core.h`)
- Windows Runtime API (`winrt/Windows.Management.Deployment.h`)
- Windows Imaging Library (`wil/resource.h`)

### COM 接口
- `IExplorerCommand`: Shell 命令接口
- `IObjectWithSite`: 站点对象接口
- `IShellItemArray`: Shell 项目数组接口
- `IActivationFactory`: WinRT 激活工厂接口

### 外部组件
- `SandMan.exe`: Sandboxie-Plus 主程序
- `combase.dll`: Windows Runtime 基础库

---

## 安全考虑

1. **完整性级别**: 应用程序运行在 mediumIL（中等完整性级别）
2. **权限要求**: 需要 `runFullTrust` 和 `unvirtualizedResources` 权限
3. **路径验证**: 使用 `GetModuleFileName` 获取可信路径
4. **错误处理**: 所有 COM 操作都有错误检查和异常处理

---

## 注意事项

1. **命名遗留**: 代码中多处使用 "BowPad" 作为显示名称，这可能是从示例代码继承而来
2. **注释代码**: `dllmain.cpp` 中包含大量注释掉的示例代码，用于参考
3. **Windows 版本要求**: 需要 Windows 10 版本 10.0.18950.0 或更高
4. **架构支持**: 包清单指定为 neutral，支持所有处理器架构

---

## 总结

SbieShell 是一个精心设计的 Windows Shell 扩展，它利用现代 Windows 技术（稀疏包、WinRT、IExplorerCommand）为 Sandboxie-Plus 提供无缝的文件资源管理器集成。通过右键菜单，用户可以轻松地在沙箱环境中打开文件和文件夹，而无需手动启动 Sandboxie-Plus 主程序。

代码结构清晰，职责分明：
- `SbieShell.exe` 负责包的注册和卸载
- `SbieShellExt.dll` 实现 Shell 扩展的核心功能
- `AppxManifest.xml` 定义包的元数据和注册信息

该组件充分展示了如何使用现代 Windows API 创建高质量的 Shell 扩展，同时保持良好的可维护性和扩展性。
