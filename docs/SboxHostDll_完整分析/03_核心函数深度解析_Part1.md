# 03 - 核心函数深度解析

## 目录
- [dllmain.cpp 函数分析](#dllmaincpp-函数分析)
- [SboxHostDll.cpp 函数分析](#sboxhostdllcpp-函数分析)
- [函数调用关系](#函数调用关系)
- [数据流分析](#数据流分析)
- [算法复杂度分析](#算法复杂度分析)

---

## dllmain.cpp 函数分析

### 全局变量

```cpp
HANDLE g_hInjectedGlobalNameObj = NULL;
```

**类型**: `HANDLE` - Windows 句柄类型

**用途**: 存储全局互斥体句柄

**生命周期**:
- **创建**: `DLL_PROCESS_ATTACH` 时
- **销毁**: `DLL_PROCESS_DETACH` 时

**线程安全**: 
- ⚠️ 不是线程安全的
- 但由于只在 DllMain 中访问，而 DllMain 是串行化的，所以没有问题

---

### 函数 1: InjectDllMain

#### 函数签名

```cpp
extern "C" __declspec(dllexport) void InjectDllMain(
    HINSTANCE hSbieDll,
    ULONG_PTR UnusedParameter
)
```

#### 参数详解

| 参数 | 类型 | 说明 |
|------|------|------|
| `hSbieDll` | `HINSTANCE` | SbieDll.dll 的模块句柄 |
| `UnusedParameter` | `ULONG_PTR` | 未使用的参数（保留） |

**HINSTANCE vs HMODULE**:
```cpp
// 在 Windows 中，这两个类型实际上是相同的
typedef HINSTANCE HMODULE;

// 历史原因：
// HINSTANCE - 16位Windows时代的实例句柄
// HMODULE   - 32位Windows时代的模块句柄
// 现在它们是同义词
```

#### 函数属性

**extern "C"**:
```cpp
extern "C" {
    // 使用C链接规范，不进行C++名称修饰
    void InjectDllMain(...);
}
```

**作用**:
- 防止 C++ 名称修饰（Name Mangling）
- 使函数名在导出表中保持为 `InjectDllMain`
- 便于 Sandboxie 通过名称查找函数

**C++ 名称修饰示例**:
```cpp
// 不使用 extern "C"
void InjectDllMain(HINSTANCE, ULONG_PTR);
// 导出名称可能是: ?InjectDllMain@@YAXPAUHINSTANCE__@@K@Z

// 使用 extern "C"
extern "C" void InjectDllMain(HINSTANCE, ULONG_PTR);
// 导出名称: InjectDllMain
```

**__declspec(dllexport)**:
```cpp
__declspec(dllexport) void InjectDllMain(...);
```

**作用**:
- 将函数导出到 DLL 的导出表
- 使外部程序可以调用此函数
- 等同于在 .def 文件中声明导出

#### 函数实现

```cpp
extern "C" __declspec(dllexport) void InjectDllMain(HINSTANCE hSbieDll, ULONG_PTR UnusedParameter)
{
    InitHook(hSbieDll);
}
```

**流程**:
1. 接收 SbieDll.dll 的模块句柄
2. 调用 `InitHook` 函数初始化 API Hook
3. 无返回值（void）

#### 调用时机

```
Sandboxie 注入流程:
1. SbieDll.dll 被注入到目标进程
2. SbieDll 读取配置，发现需要注入 SboxHostDll.dll
3. SbieDll 加载 SboxHostDll.dll
4. SbieDll 通过 GetProcAddress 获取 InjectDllMain 地址
5. SbieDll 调用 InjectDllMain(hSbieDll, 0)
6. SboxHostDll 初始化完成
```

#### 为什么需要这个函数？

**问题**: DllMain 有很多限制
- 不能调用某些 API
- 不能加载其他 DLL
- 容易导致死锁

**解决方案**: 使用单独的初始化函数
- `DllMain` 只做最基本的验证
- `InjectDllMain` 做实际的初始化工作
- 由注入器在安全的时机调用

#### 调试技巧

```cpp
extern "C" __declspec(dllexport) void InjectDllMain(HINSTANCE hSbieDll, ULONG_PTR UnusedParameter)
{
    // 添加调试日志
    OutputDebugString(L"[SboxHostDll] InjectDllMain called");
    
    // 验证参数
    if (!hSbieDll) {
        OutputDebugString(L"[SboxHostDll] ERROR: hSbieDll is NULL");
        return;
    }
    
    // 初始化 Hook
    if (InitHook(hSbieDll)) {
        OutputDebugString(L"[SboxHostDll] Hook initialized successfully");
    } else {
        OutputDebugString(L"[SboxHostDll] ERROR: Hook initialization failed");
    }
}
```

---

### 函数 2: DllMain

#### 函数签名

```cpp
BOOL APIENTRY DllMain(
    HMODULE hModule,
    DWORD ul_reason_for_call,
    LPVOID lpReserved
)
```

#### 参数详解

| 参数 | 类型 | 说明 |
|------|------|------|
| `hModule` | `HMODULE` | DLL 模块句柄 |
| `ul_reason_for_call` | `DWORD` | 调用原因 |
| `lpReserved` | `LPVOID` | 保留参数 |

**ul_reason_for_call 的可能值**:

| 常量 | 值 | 说明 | 调用时机 |
|------|-----|------|----------|
| `DLL_PROCESS_ATTACH` | 1 | 进程加载DLL | LoadLibrary 或进程启动 |
| `DLL_THREAD_ATTACH` | 2 | 线程创建 | CreateThread |
| `DLL_THREAD_DETACH` | 3 | 线程退出 | ExitThread |
| `DLL_PROCESS_DETACH` | 4 | 进程卸载DLL | FreeLibrary 或进程退出 |

**lpReserved 的含义**:

```cpp
// 在 DLL_PROCESS_ATTACH 时:
if (lpReserved != NULL) {
    // DLL 是静态加载的（进程启动时）
} else {
    // DLL 是动态加载的（LoadLibrary）
}

// 在 DLL_PROCESS_DETACH 时:
if (lpReserved != NULL) {
    // 进程正在终止
    // 不要做清理工作，系统会自动清理
} else {
    // DLL 被 FreeLibrary 卸载
    // 应该做清理工作
}
```

#### 返回值

```cpp
BOOL bRet = TRUE;
return bRet;
```

**返回值含义**:
- `TRUE`: DLL 初始化成功，允许加载
- `FALSE`: DLL 初始化失败，拒绝加载

**返回 FALSE 的后果**:
```cpp
// 如果 DllMain 返回 FALSE:
HMODULE hDll = LoadLibrary(L"SboxHostDll.dll");
if (!hDll) {
    // LoadLibrary 失败
    DWORD error = GetLastError();
    // error 可能是 ERROR_DLL_INIT_FAILED (1114)
}
```

#### 完整实现分析

```cpp
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    BOOL bRet = TRUE;

    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        // 进程加载 DLL 时的处理
        {
            WCHAR wszDLLPath[MAX_PATH + 1];
            if (GetModuleFileName(GetModuleHandle(NULL), wszDLLPath, MAX_PATH))
            {
                if (wcsstr(wszDLLPath, L"OfficeClickToRun.exe"))
                {
                    // 目标进程，允许加载
                    g_hInjectedGlobalNameObj = CreateMutex(NULL, FALSE, SBOX_HOST_DLL_LOADED);
                    bRet = TRUE;
                }
                else
                {
                    // 非目标进程，拒绝加载
                    bRet = FALSE;
                }
            }
        }
        break;

    case DLL_THREAD_ATTACH:
        // 新线程创建时（当前未处理）
        break;
        
    case DLL_THREAD_DETACH:
        // 线程退出时（当前未处理）
        break;

    case DLL_PROCESS_DETACH:
        // 进程卸载 DLL 时的清理
        if (g_hInjectedGlobalNameObj)
        {
            CloseHandle(g_hInjectedGlobalNameObj);
        }
        break;
    }
    
    return bRet;
}
```

#### DLL_PROCESS_ATTACH 详细分析

##### 步骤 1: 声明局部变量

```cpp
WCHAR wszDLLPath[MAX_PATH + 1];
```

**类型**: `WCHAR` 数组（宽字符）

**大小**: `MAX_PATH + 1` = 261 字符
- `MAX_PATH` = 260
- +1 用于 null 终止符

**为什么使用 WCHAR**:
- Windows 内部使用 Unicode (UTF-16)
- 支持国际化路径
- 避免字符编码问题

##### 步骤 2: 获取当前进程路径

```cpp
if (GetModuleFileName(GetModuleHandle(NULL), wszDLLPath, MAX_PATH))
```

**GetModuleHandle(NULL)**:
```cpp
HMODULE hExe = GetModuleHandle(NULL);
// NULL 表示获取当前进程的可执行文件句柄
// 返回值: 进程的 .exe 文件的模块句柄
```

**GetModuleFileName**:
```cpp
DWORD GetModuleFileName(
    HMODULE hModule,        // 模块句柄
    LPWSTR lpFilename,      // 输出缓冲区
    DWORD nSize             // 缓冲区大小（字符数）
);

// 返回值:
// 成功: 复制的字符数（不包括 null 终止符）
// 失败: 0
```

**示例输出**:
```
C:\Program Files\Microsoft Office\root\Integration\OfficeClickToRun.exe
```

##### 步骤 3: 检查进程名称

```cpp
if (wcsstr(wszDLLPath, L"OfficeClickToRun.exe"))
```

**wcsstr 函数**:
```cpp
wchar_t* wcsstr(
    const wchar_t* str,      // 源字符串
    const wchar_t* substr    // 要查找的子字符串
);

// 返回值:
// 找到: 指向第一次出现位置的指针
// 未找到: NULL
```

**为什么使用子字符串匹配**:
- 不需要完整路径匹配
- 只关心可执行文件名
- 更灵活，适应不同的安装路径

**潜在问题**:
```cpp
// ⚠️ 可能的误判
// 如果路径中包含 "OfficeClickToRun.exe" 字符串:
C:\Backup\OfficeClickToRun.exe.old\SomeOtherProgram.exe
// 也会匹配成功！

// 更严格的检查:
WCHAR* fileName = wcsrchr(wszDLLPath, L'\\');
if (fileName && wcscmp(fileName + 1, L"OfficeClickToRun.exe") == 0) {
    // 精确匹配文件名
}
```

##### 步骤 4: 创建全局标识

```cpp
g_hInjectedGlobalNameObj = CreateMutex(NULL, FALSE, SBOX_HOST_DLL_LOADED);
```

**CreateMutex 函数**:
```cpp
HANDLE CreateMutex(
    LPSECURITY_ATTRIBUTES lpMutexAttributes,  // 安全属性
    BOOL bInitialOwner,                       // 是否初始拥有
    LPCWSTR lpName                            // 互斥体名称
);
```

**参数分析**:
- `NULL`: 默认安全属性
- `FALSE`: 不初始拥有互斥体
- `SBOX_HOST_DLL_LOADED`: 全局命名互斥体

**为什么不检查返回值**:
```cpp
// 当前代码:
g_hInjectedGlobalNameObj = CreateMutex(NULL, FALSE, SBOX_HOST_DLL_LOADED);

// 更健壮的代码:
g_hInjectedGlobalNameObj = CreateMutex(NULL, FALSE, SBOX_HOST_DLL_LOADED);
if (!g_hInjectedGlobalNameObj) {
    DWORD error = GetLastError();
    // 记录错误
}
```

**可能的错误**:
- `ERROR_ACCESS_DENIED`: 权限不足
- `ERROR_ALREADY_EXISTS`: 互斥体已存在（不是错误）

##### 步骤 5: 设置返回值

```cpp
bRet = TRUE;   // 允许加载
// 或
bRet = FALSE;  // 拒绝加载
```

#### DLL_PROCESS_DETACH 详细分析

```cpp
case DLL_PROCESS_DETACH:
    if (g_hInjectedGlobalNameObj)
    {
        CloseHandle(g_hInjectedGlobalNameObj);
    }
    break;
```

**清理流程**:
1. 检查句柄是否有效
2. 关闭互斥体句柄
3. 系统自动删除互斥体对象（如果没有其他引用）

**为什么要检查句柄**:
```cpp
// 可能的情况:
// 1. DLL_PROCESS_ATTACH 失败，句柄为 NULL
// 2. CreateMutex 失败，句柄为 NULL
// 3. 正常情况，句柄有效

if (g_hInjectedGlobalNameObj) {
    // 只在句柄有效时关闭
    CloseHandle(g_hInjectedGlobalNameObj);
}
```

**CloseHandle 的重要性**:
```cpp
// ❌ 不关闭句柄 - 资源泄漏
// 每次加载/卸载 DLL 都会泄漏一个句柄
// 最终可能耗尽句柄资源

// ✅ 正确关闭句柄
CloseHandle(g_hInjectedGlobalNameObj);
g_hInjectedGlobalNameObj = NULL;  // 可选：防止重复关闭
```

#### DllMain 的限制和注意事项

**禁止的操作**:
```cpp
// ❌ 不要在 DllMain 中做这些:
LoadLibrary(...);           // 加载其他 DLL - 可能死锁
CreateThread(...);          // 创建线程 - 可能死锁
CoInitialize(...);          // COM 初始化 - 不安全
MessageBox(...);            // 显示对话框 - 可能挂起
```

**允许的操作**:
```cpp
// ✅ 可以在 DllMain 中做这些:
GetModuleFileName(...);     // 获取模块信息
CreateMutex(...);           // 创建同步对象
InitializeCriticalSection(...);  // 初始化临界区
分配内存（malloc, new）
```

**死锁风险**:
```
线程 A: 持有 Loader Lock，调用 DllMain
        ↓
        尝试加载 DLL B (LoadLibrary)
        ↓
        等待 Loader Lock（被线程 A 持有）
        ↓
        死锁！
```

---

## SboxHostDll.cpp 函数分析

### 全局变量

```cpp
typedef BOOL (*P_OpenProcessToken)(HANDLE ProcessHandle, DWORD DesiredAccess, PHANDLE phTokenOut);
static P_OpenProcessToken __sys_OpenProcessToken = NULL;
```

**类型定义**:
- `P_OpenProcessToken`: 函数指针类型
- `__sys_OpenProcessToken`: 保存原始 API 地址

**命名约定**:
- `__sys_` 前缀表示系统原始函数
- Sandboxie 的标准命名规范

---

### 函数 3: InitHook

#### 函数签名

```cpp
BOOLEAN InitHook(HINSTANCE hSbieDll)
```

#### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `hSbieDll` | `HINSTANCE` | SbieDll.dll 的模块句柄 |

#### 返回值

```cpp
return TRUE;  // 总是返回 TRUE
```

**注意**: 当前实现总是返回成功，即使 Hook 失败也不报错。

#### 完整实现

```cpp
BOOLEAN InitHook(HINSTANCE hSbieDll)
{
    if (hSbieDll && !__sys_OpenProcessToken)
    {
        HMODULE module = GetModuleHandle(L"Advapi32.dll");
        
        void *OpenProcessToken = (P_OpenProcessToken)GetProcAddress(module, "OpenProcessToken");
        
        if (OpenProcessToken)
            SBIEDLL_HOOK(SboxHostDll_, OpenProcessToken);
    }
    return TRUE;
}
```

#### 详细分析

##### 步骤 1: 参数和状态检查

```cpp
if (hSbieDll && !__sys_OpenProcessToken)
```

**检查条件**:

**条件 1**: `hSbieDll` 不为 NULL
```cpp
if (hSbieDll) {
    // SbieDll.dll 已加载
    // 可以使用 Sandboxie 的 Hook 功能
}
```

**条件 2**: `!__sys_OpenProcessToken`
```cpp
if (!__sys_OpenProcessToken) {
    // 尚未设置 Hook
    // 防止重复 Hook
}
```

**为什么需要防止重复 Hook**:
```cpp
// 场景: 配置文件中重复指定了注入
[DefaultBox]
InjectDll=SboxHostDll.dll
InjectDll=SboxHostDll.dll  // 重复！

// 如果不检查:
第一次: OpenProcessToken → SboxHostDll_OpenProcessToken ✅
第二次: SboxHostDll_OpenProcessToken → SboxHostDll_OpenProcessToken ❌
// 导致无限递归！
```

##### 步骤 2: 获取目标模块

```cpp
HMODULE module = GetModuleHandle(L"Advapi32.dll");
```

**GetModuleHandle**:
```cpp
HMODULE GetModuleHandle(LPCWSTR lpModuleName);
// 返回值:
// 成功: 模块句柄
// 失败: NULL
```

**为什么不检查返回值**:
```cpp
// Advapi32.dll 是 Windows 核心 DLL
// 几乎总是已经加载
// 但更健壮的代码应该检查:

HMODULE module = GetModuleHandle(L"Advapi32.dll");
if (!module) {
    // 极少见的情况
    return FALSE;
}
```

**Advapi32.dll 的作用**:
- 高级 Windows API
- 安全和注册表功能
- 包含 `OpenProcessToken` 等安全 API

##### 步骤 3: 获取函数地址

```cpp
void *OpenProcessToken = (P_OpenProcessToken)GetProcAddress(module, "OpenProcessToken");
```

**GetProcAddress**:
```cpp
FARPROC GetProcAddress(
    HMODULE hModule,     // 模块句柄
    LPCSTR lpProcName    // 函数名（ANSI字符串）
);
```

**注意**: 函数名必须是 ANSI 字符串，不是 Unicode！

```cpp
// ✅ 正确
GetProcAddress(module, "OpenProcessToken");

// ❌ 错误
GetProcAddress(module, L"OpenProcessToken");
```

**类型转换**:
```cpp
void *OpenProcessToken = (P_OpenProcessToken)GetProcAddress(...);
//                       ^^^^^^^^^^^^^^^^^^^
//                       转换为函数指针类型
```

##### 步骤 4: 设置 Hook

```cpp
if (OpenProcessToken)
    SBIEDLL_HOOK(SboxHostDll_, OpenProcessToken);
```

**SBIEDLL_HOOK 宏展开**:
```cpp
// 宏定义（简化版）
#define SBIEDLL_HOOK(prefix, func) \
    __sys_##func = (P_##func)func; \
    func = prefix##func;

// 展开后:
__sys_OpenProcessToken = (P_OpenProcessToken)OpenProcessToken;
OpenProcessToken = SboxHostDll_OpenProcessToken;
```

**实际效果**:
```
Hook 前:
应用程序 → OpenProcessToken (Advapi32.dll)

Hook 后:
应用程序 → SboxHostDll_OpenProcessToken (SboxHostDll.dll)
              ↓
              __sys_OpenProcessToken (Advapi32.dll)
```

**Hook 机制**:
```cpp
// Sandboxie 的 Hook 实现可能使用:
// 1. IAT (Import Address Table) Hook
// 2. Inline Hook (修改函数开头的指令)
// 3. Detours 库

// IAT Hook 示例:
struct ImportEntry {
    char* name;
    void** address;
};

// 找到 IAT 中的 OpenProcessToken 条目
ImportEntry* entry = FindImportEntry("OpenProcessToken");
// 修改地址
*entry->address = SboxHostDll_OpenProcessToken;
```

#### 改进建议

```cpp
BOOLEAN InitHook(HINSTANCE hSbieDll)
{
    // 添加错误处理和日志
    if (!hSbieDll) {
        OutputDebugString(L"[SboxHostDll] ERROR: hSbieDll is NULL");
        return FALSE;
    }
    
    if (__sys_OpenProcessToken) {
        OutputDebugString(L"[SboxHostDll] Hook already initialized");
        return TRUE;  // 已经初始化，不是错误
    }
    
    HMODULE module = GetModuleHandle(L"Advapi32.dll");
    if (!module) {
        OutputDebugString(L"[SboxHostDll] ERROR: Cannot get Advapi32.dll");
        return FALSE;
    }
    
    void *OpenProcessToken = GetProcAddress(module, "OpenProcessToken");
    if (!OpenProcessToken) {
        OutputDebugString(L"[SboxHostDll] ERROR: Cannot find OpenProcessToken");
        return FALSE;
    }
    
    SBIEDLL_HOOK(SboxHostDll_, OpenProcessToken);
    
    if (__sys_OpenProcessToken) {
        OutputDebugString(L"[SboxHostDll] Hook initialized successfully");
        return TRUE;
    } else {
        OutputDebugString(L"[SboxHostDll] ERROR: Hook failed");
        return FALSE;
    }
}
```

---

**继续**: 下一部分将详细分析最复杂的函数 `SboxHostDll_OpenProcessToken`

---

**下一章**: [04_API_Hook技术详解.md](./04_API_Hook技术详解.md) →
