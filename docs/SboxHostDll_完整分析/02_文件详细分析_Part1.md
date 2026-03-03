# 02 - 文件详细分析

## 目录
- [文件概览](#文件概览)
- [stdafx.h - 预编译头文件](#stdafxh---预编译头文件)
- [stdafx.cpp - 预编译头实现](#stdafxcpp---预编译头实现)
- [targetver.h - 平台版本定义](#targetverh---平台版本定义)
- [resource.h - 资源定义](#resourceh---资源定义)
- [SboxHostDll.h - 模块头文件](#sboxhostdllh---模块头文件)
- [dllmain.cpp - DLL入口点](#dllmaincpp---dll入口点)
- [SboxHostDll.cpp - 核心实现](#sboxhostdllcpp---核心实现)

---

## 文件概览

### 文件列表

| 文件名 | 类型 | 行数 | 主要功能 | 复杂度 |
|--------|------|------|----------|--------|
| stdafx.h | 头文件 | 35 | 预编译头声明 | ⭐ |
| stdafx.cpp | 源文件 | 25 | 预编译头实现 | ⭐ |
| targetver.h | 头文件 | 25 | 平台版本定义 | ⭐ |
| resource.h | 头文件 | 30 | 资源ID定义 | ⭐ |
| SboxHostDll.h | 头文件 | 20 | 模块常量定义 | ⭐ |
| dllmain.cpp | 源文件 | 80 | DLL入口和验证 | ⭐⭐⭐ |
| SboxHostDll.cpp | 源文件 | 180 | 核心Hook逻辑 | ⭐⭐⭐⭐⭐ |

### 依赖关系图

```
编译依赖关系:

stdafx.h
  ├─ targetver.h
  ├─ windows.h
  ├─ string (C++ STL)
  ├─ atlsecurity.h (ATL)
  └─ Psapi.h

stdafx.cpp
  └─ stdafx.h

dllmain.cpp
  ├─ stdafx.h
  └─ SboxHostDll.h

SboxHostDll.cpp
  ├─ stdafx.h
  └─ core/dll/sbiedll.h (Sandboxie)
```

---

## stdafx.h - 预编译头文件

### 文件信息

| 属性 | 值 |
|------|-----|
| **文件路径** | `Sandboxie\SboxHostDll\stdafx.h` |
| **文件类型** | C++ 头文件 |
| **代码行数** | 35 行 |
| **主要功能** | 包含常用头文件，加速编译 |
| **修改频率** | 极低 |

### 完整源码分析

```cpp
/*
 * Copyright 2004-2020 Sandboxie Holdings, LLC 
 *
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

//#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files:
#include <windows.h>

#include <string>
#include <atlsecurity.h>
#include <Psapi.h>

// TODO: reference additional headers your program requires here
```

### 逐行解析

#### 1. 版权声明（第 1-16 行）

```cpp
/*
 * Copyright 2004-2020 Sandboxie Holdings, LLC 
 * ...
 * GNU General Public License v3.0 or later
 */
```

**说明**:
- 采用 GPL v3 开源许可证
- 版权归 Sandboxie Holdings, LLC 所有
- 允许自由修改和分发

#### 2. 文件说明注释（第 18-21 行）

```cpp
// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
```

**说明**:
- 这是 Visual Studio 的标准预编译头文件
- 用于包含不常修改的头文件
- 加速编译过程

#### 3. #pragma once（第 23 行）

```cpp
#pragma once
```

**作用**:
- 防止头文件被重复包含
- 现代 C++ 的标准做法
- 比传统的 `#ifndef` 保护更简洁

**等价的传统写法**:
```cpp
#ifndef STDAFX_H
#define STDAFX_H
// ... 头文件内容 ...
#endif
```

#### 4. 包含平台版本定义（第 25 行）

```cpp
#include "targetver.h"
```

**作用**:
- 定义目标 Windows 平台版本
- 必须在包含 Windows 头文件之前
- 影响可用的 API 和功能

#### 5. WIN32_LEAN_AND_MEAN（第 27 行，已注释）

```cpp
//#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
```

**说明**:
- 这个宏被注释掉了，说明需要完整的 Windows API
- 如果定义，会排除一些不常用的 Windows 头文件
- 可以加速编译，但可能缺少某些 API

**影响的头文件**:
- 排除: `winsock.h`, `ole2.h`, `commdlg.h` 等
- 保留: 核心 Windows API

#### 6. 包含 Windows 核心头文件（第 29 行）

```cpp
#include <windows.h>
```

**提供的功能**:
- 基础 Windows API
- 数据类型定义（DWORD, HANDLE, BOOL 等）
- 常量定义（MAX_PATH, TRUE, FALSE 等）
- 函数声明（CreateMutex, OpenProcess 等）

**关键类型**:
```cpp
typedef void* HANDLE;              // 句柄类型
typedef unsigned long DWORD;       // 32位无符号整数
typedef int BOOL;                  // 布尔类型
typedef wchar_t WCHAR;             // 宽字符
typedef const WCHAR* LPCWSTR;      // 常量宽字符串指针
```

#### 7. 包含 C++ 标准字符串库（第 31 行）

```cpp
#include <string>
```

**使用场景**:
```cpp
std::wstring wsLogonSid;           // 存储 SID 字符串
std::wstring wsAltLogonSid;        // 存储备用 SID 字符串
```

**为什么使用 std::wstring**:
- Windows 使用 Unicode（UTF-16）字符串
- `std::wstring` 是宽字符版本的 `std::string`
- 自动内存管理，避免内存泄漏

#### 8. 包含 ATL 安全类（第 32 行）

```cpp
#include <atlsecurity.h>
```

**提供的关键类**:

##### CAccessToken 类
```cpp
class CAccessToken {
public:
    // 附加令牌句柄
    void Attach(HANDLE hToken);
    
    // 分离令牌句柄（不关闭）
    HANDLE Detach();
    
    // 获取用户 SID
    bool GetUser(CSid* pSid) const;
    
    // 获取登录会话 SID
    bool GetLogonSid(CSid* pSid) const;
    
    // 检查是否为受限令牌
    bool IsTokenRestricted() const;
};
```

##### CSid 类
```cpp
class CSid {
public:
    // 获取 SID 字符串表示
    LPCTSTR Sid() const;
    
    // 比较 SID
    bool operator==(const CSid& rhs) const;
};
```

**使用示例**:
```cpp
ATL::CAccessToken token;
ATL::CSid userSid;

token.Attach(hToken);
if (token.GetUser(&userSid)) {
    LPCTSTR sidString = userSid.Sid();  // 例如: "S-1-5-21-..."
}
token.Detach();
```

#### 9. 包含进程状态 API（第 33 行）

```cpp
#include <Psapi.h>
```

**提供的关键函数**:

##### EnumProcesses
```cpp
BOOL EnumProcesses(
    DWORD* lpidProcess,      // [out] 进程ID数组
    DWORD cb,                // [in]  数组大小（字节）
    LPDWORD lpcbNeeded       // [out] 实际需要的大小
);
```

**使用示例**:
```cpp
DWORD aPid[1024];
DWORD cbReturned;

if (EnumProcesses(aPid, sizeof(aPid), &cbReturned)) {
    DWORD nPidCount = cbReturned / sizeof(DWORD);
    for (UINT i = 0; i < nPidCount; i++) {
        // 处理每个进程 ID: aPid[i]
    }
}
```

### 预编译头的工作原理

#### 编译过程

```
第一次编译:
1. 编译器读取 stdafx.cpp
2. 处理 #include "stdafx.h"
3. 展开所有包含的头文件
4. 生成预编译头文件 stdafx.pch
5. 保存编译状态

后续编译:
1. 编译器检测到 #include "stdafx.h"
2. 直接加载 stdafx.pch
3. 跳过头文件解析
4. 大幅加速编译速度
```

#### 性能提升

| 场景 | 不使用预编译头 | 使用预编译头 | 提升 |
|------|----------------|--------------|------|
| 首次编译 | 10秒 | 12秒 | -20% |
| 增量编译 | 10秒 | 2秒 | +400% |
| 大型项目 | 数分钟 | 数十秒 | +10倍 |

### 依赖的库文件

编译时需要链接的库：

```
Advapi32.lib    - OpenProcessToken, 安全API
Psapi.lib       - EnumProcesses
Kernel32.lib    - CreateMutex, OpenProcess
User32.lib      - 基础Windows API
```

---

## stdafx.cpp - 预编译头实现

### 文件信息

| 属性 | 值 |
|------|-----|
| **文件路径** | `Sandboxie\SboxHostDll\stdafx.cpp` |
| **文件类型** | C++ 源文件 |
| **代码行数** | 25 行 |
| **主要功能** | 生成预编译头 |
| **编译产物** | stdafx.pch |

### 完整源码

```cpp
/*
 * Copyright 2004-2020 Sandboxie Holdings, LLC 
 *
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// stdafx.cpp : source file that includes just the standard includes
// SboxHostDll.pch will be the pre-compiled header
// stdafx.obj will contain the pre-compiled type information

#include "stdafx.h"

// TODO: reference any additional headers you need in STDAFX.H
// and not in this file
```

### 文件作用

这个文件看起来很简单，但它有特殊的编译设置：

#### Visual Studio 项目设置

```xml
<ClCompile Include="stdafx.cpp">
  <PrecompiledHeader>Create</PrecompiledHeader>
</ClCompile>

<ClCompile Include="dllmain.cpp">
  <PrecompiledHeader>Use</PrecompiledHeader>
</ClCompile>

<ClCompile Include="SboxHostDll.cpp">
  <PrecompiledHeader>Use</PrecompiledHeader>
</ClCompile>
```

**说明**:
- `stdafx.cpp`: 设置为 **Create**（创建预编译头）
- 其他 `.cpp`: 设置为 **Use**（使用预编译头）

#### 编译器行为

```
编译 stdafx.cpp:
  /Yc"stdafx.h"     创建预编译头
  → 生成 stdafx.pch

编译 dllmain.cpp:
  /Yu"stdafx.h"     使用预编译头
  → 加载 stdafx.pch

编译 SboxHostDll.cpp:
  /Yu"stdafx.h"     使用预编译头
  → 加载 stdafx.pch
```

### 注意事项

**规则 1**: 每个 `.cpp` 文件必须首先包含 `stdafx.h`

```cpp
// ✅ 正确
#include "stdafx.h"
#include "SboxHostDll.h"
// ... 其他代码

// ❌ 错误 - 会导致编译错误
#include "SboxHostDll.h"
#include "stdafx.h"
```

**规则 2**: 不要在 `stdafx.h` 中包含经常修改的头文件

```cpp
// ❌ 不好 - 每次修改都要重新编译所有文件
#include "MyFrequentlyChangedHeader.h"

// ✅ 好 - 在需要的 .cpp 文件中单独包含
// 在 SboxHostDll.cpp 中:
#include "stdafx.h"
#include "MyFrequentlyChangedHeader.h"
```

---

## targetver.h - 平台版本定义

### 文件信息

| 属性 | 值 |
|------|-----|
| **文件路径** | `Sandboxie\SboxHostDll\targetver.h` |
| **文件类型** | C++ 头文件 |
| **代码行数** | 25 行 |
| **主要功能** | 定义目标Windows平台 |

### 完整源码

```cpp
/*
 * Copyright 2004-2020 Sandboxie Holdings, LLC 
 *
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

// Including SDKDDKVer.h defines the highest available Windows platform.

// If you wish to build your application for a previous Windows platform, include WinSDKVer.h and
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.

#include <SDKDDKVer.h>
```

### 平台版本控制

#### SDKDDKVer.h 的作用

```cpp
// SDKDDKVer.h 会自动定义最高可用的平台版本
// 例如，如果安装了 Windows 10 SDK:

#define _WIN32_WINNT 0x0A00    // Windows 10
#define NTDDI_VERSION 0x0A000000
```

#### 自定义目标平台

如果需要支持较旧的 Windows 版本：

```cpp
#pragma once

// 支持 Windows 7 及以上
#include <WinSDKVer.h>
#define _WIN32_WINNT 0x0601    // Windows 7
#include <SDKDDKVer.h>
```

#### Windows 版本常量

| 常量 | 值 | Windows 版本 |
|------|-----|--------------|
| `_WIN32_WINNT_WIN7` | 0x0601 | Windows 7 |
| `_WIN32_WINNT_WIN8` | 0x0602 | Windows 8 |
| `_WIN32_WINNT_WIN81` | 0x0603 | Windows 8.1 |
| `_WIN32_WINNT_WIN10` | 0x0A00 | Windows 10 |

#### 影响的API

```cpp
// 如果 _WIN32_WINNT < 0x0602，以下API不可用:
#if _WIN32_WINNT >= 0x0602
    // Windows 8+ 专有API
    GetPackageFamilyName(...);
#endif

// 条件编译示例
#if _WIN32_WINNT >= _WIN32_WINNT_WIN7
    // Windows 7+ 可用的代码
#else
    // Windows Vista 及更早版本的替代代码
#endif
```

### SboxHostDll 的平台要求

根据使用的 API 分析：

| API | 最低要求 | 说明 |
|-----|----------|------|
| `OpenProcessToken` | Windows 2000 | 基础安全API |
| `EnumProcesses` | Windows 2000 | 进程枚举 |
| `CreateMutex` | Windows 2000 | 同步对象 |
| ATL 安全类 | Windows XP | ATL 7.0+ |

**结论**: SboxHostDll 理论上可以支持 Windows XP 及以上版本。

---

## resource.h - 资源定义

### 文件信息

| 属性 | 值 |
|------|-----|
| **文件路径** | `Sandboxie\SboxHostDll\resource.h` |
| **文件类型** | C++ 头文件 |
| **代码行数** | 30 行 |
| **主要功能** | 定义资源ID |
| **生成方式** | Visual Studio 自动生成 |

### 完整源码

```cpp
/*
 * Copyright 2004-2020 Sandboxie Holdings, LLC 
 *
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

//{{NO_DEPENDENCIES}}
// Microsoft Visual C++ generated include file.
// Used by SboxHostDll.rc

// Next default values for new objects
// 
#ifdef APSTUDIO_INVOKED
#ifndef APSTUDIO_READONLY_SYMBOLS
#define _APS_NEXT_RESOURCE_VALUE        101
#define _APS_NEXT_COMMAND_VALUE         40001
#define _APS_NEXT_CONTROL_VALUE         1001
#define _APS_NEXT_SYMED_VALUE           101
#endif
#endif
```

### 资源系统说明

#### 资源文件 (.rc)

资源文件 `SboxHostDll.rc` 可能包含：
- 版本信息
- 图标
- 字符串表
- 对话框模板

#### 资源ID定义

```cpp
#define _APS_NEXT_RESOURCE_VALUE        101
```

**说明**:
- 下一个资源的ID将从 101 开始
- Visual Studio 资源编辑器自动管理
- 避免ID冲突

#### 当前状态

从代码来看，SboxHostDll 当前**没有使用任何资源**：
- 没有定义具体的资源ID
- 只有默认的起始值
- 这是一个纯代码DLL，不需要UI资源

---

## SboxHostDll.h - 模块头文件

### 文件信息

| 属性 | 值 |
|------|-----|
| **文件路径** | `Sandboxie\SboxHostDll\SboxHostDll.h` |
| **文件类型** | C++ 头文件 |
| **代码行数** | 20 行 |
| **主要功能** | 定义模块常量 |
| **重要程度** | ⭐⭐⭐ |

### 完整源码

```cpp
/*
 * Copyright 2004-2020 Sandboxie Holdings, LLC 
 *
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#define SBOX_HOST_DLL_LOADED L"Global\\SboxHostDllLoaded"
```

### 常量详解

#### SBOX_HOST_DLL_LOADED

```cpp
#define SBOX_HOST_DLL_LOADED L"Global\\SboxHostDllLoaded"
```

**类型**: 宽字符串常量（Unicode）

**用途**: 全局命名互斥体的名称

**命名空间**: `Global\` - 跨会话可见

#### 互斥体命名规则

Windows 命名对象的命名空间：

| 前缀 | 作用域 | 说明 |
|------|--------|------|
| `Global\` | 所有会话 | 跨用户会话可见 |
| `Local\` | 当前会话 | 仅当前用户会话可见 |
| 无前缀 | 当前会话 | 默认为 Local |

**示例**:
```cpp
// 全局互斥体 - 所有用户都能看到
CreateMutex(NULL, FALSE, L"Global\\MyMutex");

// 本地互斥体 - 只有当前用户能看到
CreateMutex(NULL, FALSE, L"Local\\MyMutex");

// 默认本地
CreateMutex(NULL, FALSE, L"MyMutex");  // 等同于 Local\\MyMutex
```

#### 使用场景

**创建互斥体**（在 dllmain.cpp 中）:
```cpp
g_hInjectedGlobalNameObj = CreateMutex(NULL, FALSE, SBOX_HOST_DLL_LOADED);
```

**检测DLL是否已加载**（外部程序）:
```cpp
HANDLE hMutex = OpenMutex(SYNCHRONIZE, FALSE, L"Global\\SboxHostDllLoaded");
if (hMutex) {
    // DLL 已加载
    CloseHandle(hMutex);
} else {
    // DLL 未加载
}
```

**用途**:
1. **状态标识**: 标识 SboxHostDll 是否已成功加载
2. **调试辅助**: 开发者可以检查DLL加载状态
3. **防重复注入**: 理论上可以用于检测重复注入（虽然代码中未实现）

#### 安全考虑

**潜在风险**:
- 全局命名对象可能被恶意程序抢先创建
- 可能导致 DLL 加载失败或行为异常

**改进建议**:
```cpp
// 使用更复杂的名称，包含随机成分或进程ID
#define SBOX_HOST_DLL_LOADED L"Global\\SboxHostDll_Loaded_{GUID}"

// 或者使用进程ID
WCHAR mutexName[MAX_PATH];
swprintf(mutexName, MAX_PATH, L"Global\\SboxHostDll_%d", GetCurrentProcessId());
g_hInjectedGlobalNameObj = CreateMutex(NULL, FALSE, mutexName);
```

---

**继续阅读**: 下一部分将详细分析 `dllmain.cpp` 和 `SboxHostDll.cpp` 的实现细节。

由于篇幅限制，这两个最重要的文件将在后续章节中详细展开。

---

**下一章**: [03_核心函数深度解析.md](./03_核心函数深度解析.md) →
