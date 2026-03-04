# Sandboxie Common 目录代码分析

## 目录概述

`Sandboxie\common` 目录包含了 Sandboxie 项目中共享的通用代码库，这些代码被驱动程序、服务和用户态组件共同使用。该目录提供了基础数据结构、加密算法、内存管理、Hook工具等核心功能。

---

## 文件分类

### 1. 基础数据结构
- **list.c / list.h** - 双向链表实现
- **pool.c / pool.h** - 内存池管理器
- **map.c / map.h** - 哈希映射表
- **rbtree.c / rbtree.h** - 红黑树实现
- **stream.c / stream.h** - 流处理

### 2. 加密与安全
- **bignum.c / bignum.h** - 大数运算库
- **rc4.c** - RC4 加密算法
- **verify.c** - 数字签名验证
- **base64.c** - Base64 编解码

### 3. Hook 与注入
- **hook_util.c** - Hook 工具函数
- **dllimport.c / dllimport.h** - DLL 导入表解析
- **Detours/** - Microsoft Detours 库（用于函数拦截）

### 4. 配置与工具
- **ini.cpp / ini.h** - INI 配置文件解析
- **pattern.c / pattern.h** - 模式匹配
- **str_util.c / str_util.h** - 字符串工具
- **crc.c** - CRC 校验和计算
- **bom.c** - BOM（字节序标记）检测

### 5. 系统定义
- **defines.h** - 通用宏定义
- **my_version.h** - 版本信息
- **ntproto.h** - Windows NT 内核原型
- **win32_ntddk.h** - Win32/NT DDK 兼容层

### 6. 其他
- **lock.c / lock.h** - 锁机制
- **netfw.c / netfw.h** - 网络防火墙相关
- **JSON/** - JSON 解析库

---

## 详细文件分析

### 一、基础数据结构模块

#### 1. list.c / list.h - 双向链表

**功能概述：**
实现了一个基于双向链表的通用数据结构，用于管理动态元素集合。

**数据结构：**
```c
typedef struct LIST_ELEM {
   struct LIST_ELEM *next;  // 指向下一个元素
   struct LIST_ELEM *prev;  // 指向前一个元素
} LIST_ELEM;

typedef struct {
    LIST_ELEM *head;    // 链表头
    LIST_ELEM *tail;    // 链表尾
    int count;          // 元素计数
} LIST;
```

**核心函数：**
- `List_Init(LIST *list)` - 初始化链表
- `List_Insert_Before(LIST *list, void *oldelem, void *newelem)` - 在指定元素前插入
- `List_Insert_After(LIST *list, void *elem, void *newelem)` - 在指定元素后插入
- `List_Remove(LIST *list, void *elem)` - 删除指定元素

**使用场景：**
- 管理内存池中的页面
- 跟踪沙箱中的进程和线程
- 维护各种动态资源列表

---

#### 2. pool.c / pool.h - 内存池管理器

**功能概述：**
高效的内存分配器，减少频繁的系统内存分配调用，提高性能。采用页面和单元格（cell）的两级管理机制。

**核心概念：**
- **页面（PAGE）**：固定大小的内存块（内核模式 4KB，用户模式 64KB）
- **单元格（CELL）**：页面内的小块内存单元（内核模式 16 字节，用户模式 128 字节）
- **大块（LARGE_CHUNK）**：超过阈值的大内存分配

**数据结构：**
```c
struct POOL {
    ULONG eyecatcher;           // 魔数标记
    LOCK/CRITICAL_SECTION lock; // 线程同步锁
    LIST pages;                 // 可用页面列表
    LIST full_pages;            // 已满页面列表
    LIST large_chunks;          // 大块内存列表
    UCHAR initial_bitmap[...];  // 初始位图
};

struct PAGE {
    LIST_ELEM list_elem;
    PAGE *next;
    POOL *pool;
    ULONG eyecatcher;
    USHORT num_free;  // 空闲单元格数量（估计值）
};
```

**核心函数：**
- `Pool_Create()` / `Pool_CreateTagged(ULONG tag)` - 创建内存池
- `Pool_Delete(POOL *pool)` - 删除内存池
- `Pool_Alloc(POOL *pool, ULONG size)` - 分配内存
- `Pool_Free(void *ptr, ULONG size)` - 释放内存

**内部机制：**
1. **小内存分配**（< 3KB）：
   - 使用位图标记单元格的占用状态
   - 在页面中查找连续的空闲单元格
   - 采用阈值机制避免搜索几乎满的页面

2. **大内存分配**（≥ 3KB）：
   - 直接分配页面对齐的内存块
   - 在块尾部存储 LARGE_CHUNK 结构用于管理

**优化特性：**
- 位图快速查找空闲单元格
- 分离满页面和可用页面，减少搜索时间
- 支持多线程安全访问
- 内存对齐优化

---

#### 3. map.c / map.h - 哈希映射表

**功能概述：**
实现了一个通用的哈希表数据结构，支持键值对存储和快速查找。

**数据结构：**
```c
typedef struct map_base_t {
  map_node_t **buckets;     // 哈希桶数组
  int nbuckets, nnodes;     // 桶数量和节点数量
  
  void* mem_pool;           // 内存池
  void*(*func_malloc)(void* pool, size_t size);
  void(*func_free)(void* pool, void* ptr);
  
  int(*func_key_size)(const void* key);
  unsigned int (*func_hash_key)(const void* key, size_t size);
  BOOLEAN (*func_match_key)(const void* key1, const void* key2);
} map_base_t;
```

**核心函数：**
- `map_init(map_base_t *m, void* pool)` - 初始化映射表
- `map_insert(map_base_t* m, const void* key, void* vdata, size_t vsize)` - 插入键值对
- `map_append(map_base_t *m, const void* key, void* vdata, size_t vsize)` - 追加值（支持一键多值）
- `map_get(map_base_t *m, const void* key)` - 获取值
- `map_remove(map_base_t* m, const void* key)` - 删除键值对
- `map_resize(map_base_t* m, int nbuckets)` - 调整哈希表大小

**迭代器支持：**
```c
map_iter_t map_iter();
BOOLEAN map_next(map_base_t *m, map_iter_t *iter);
BOOLEAN map_erase(map_base_t *m, map_iter_t *iter);
```

**使用场景：**
- 配置项快速查找
- 进程/线程 ID 到对象的映射
- 文件路径到句柄的映射

---

### 二、加密与安全模块

#### 4. bignum.c / bignum.h - 任意精度大数运算

**功能概述：**
实现了任意精度的无符号整数运算库，用于加密算法（如 RSA）中的大数计算。

**数据结构：**
```c
typedef ULONG *BIGNUM;  // 大数表示为 ULONG 数组
// 第一个元素存储数组长度，后续元素存储数值
```

**核心函数：**

**创建与转换：**
- `BigNum_CreateFromInteger(POOL *pool, ULONG Value)` - 从整数创建
- `BigNum_CreateFromBigNum(POOL *pool, BIGNUM Value)` - 复制大数
- `BigNum_CreateFromString(POOL *pool, const WCHAR *Value, int Base)` - 从字符串创建
- `BigNum_ConvertToString(POOL *pool, BIGNUM BigNum, int Base)` - 转换为字符串
- `BigNum_CreateRandom(POOL *pool, int Digits, int Base)` - 创建随机大数

**基本运算：**
- `BigNum_Compare(BIGNUM BigNumA, BIGNUM BigNumB)` - 比较大小
- `BigNum_Add(POOL *pool, BIGNUM BigNumA, BIGNUM BigNumB)` - 加法
- `BigNum_Subtract(POOL *pool, BIGNUM BigNumA, BIGNUM BigNumB)` - 减法
- `BigNum_Multiply(POOL *pool, BIGNUM BigNumA, BIGNUM BigNumB)` - 乘法
- `BigNum_Divide(POOL *pool, BIGNUM Dividend, BIGNUM Divisor, BIGNUM *pReminder)` - 除法

**位运算：**
- `BigNum_ShiftLeft(POOL *pool, BIGNUM BigNumA, ULONG Bits, ULONG OrValue)` - 左移
- `BigNum_ShiftRight(POOL *pool, BIGNUM BigNumA, ULONG Bits)` - 右移

**高级运算：**
- `BigNum_ModPow(POOL *pool, BIGNUM Base, BIGNUM Exponent, BIGNUM Modulus)` - 模幂运算
  - 用于 RSA 加密/解密：C = M^E mod N
  - 采用平方求幂法优化性能

**实现特点：**
- 使用 32 位字（ULONG）作为基本单元
- 自动处理进位和借位
- 去除前导零优化存储
- 基于 Knuth 算法的长除法

**使用场景：**
- 许可证验证中的 RSA 签名验证
- 数字证书处理

---

#### 5. rc4.c - RC4 流加密算法

**功能概述：**
实现 RC4（Rivest Cipher 4）对称加密算法，用于快速数据加密。

**核心函数：**
- `RC4_Init(RC4_CONTEXT *ctx, const UCHAR *key, ULONG keylen)` - 初始化密钥
- `RC4_Crypt(RC4_CONTEXT *ctx, UCHAR *data, ULONG datalen)` - 加密/解密数据

**算法特点：**
- 流加密算法，加密和解密使用相同操作
- 密钥长度可变（通常 40-256 位）
- 速度快，适合大量数据加密
- 使用 256 字节的状态表（S-box）

**使用场景：**
- 配置文件加密
- 进程间通信数据加密
- 临时数据保护

---

#### 6. verify.c - 数字签名验证

**功能概述：**
实现数字签名验证功能，用于验证 Sandboxie 组件的完整性和真实性。

**核心功能：**
- 验证 PE 文件的数字签名
- 检查证书链的有效性
- 防止恶意代码注入和篡改

**关键技术：**
- 使用 Windows Authenticode 签名
- 验证证书颁发机构（CA）
- 检查证书吊销列表（CRL）
- 时间戳验证

**使用场景：**
- 驱动程序加载前验证
- DLL 注入前验证
- 更新包完整性检查

---

#### 7. base64.c - Base64 编解码

**功能概述：**
实现 Base64 编码和解码，用于二进制数据的文本表示。

**核心函数：**
- `b64_encoded_size(size_t inlen)` - 计算编码后大小
- `b64_encode(const unsigned char *in, size_t inlen, wchar_t *out, size_t outlen)` - 编码
- `b64_decoded_size(const wchar_t *in)` - 计算解码后大小
- `b64_decode(const wchar_t *in, unsigned char *out, size_t outlen)` - 解码

**实现特点：**
- 使用宽字符（wchar_t）输出
- 标准 Base64 字符集：A-Z, a-z, 0-9, +, /
- 支持填充字符 '='
- 输入验证防止无效数据

**使用场景：**
- 配置文件中存储二进制数据
- 许可证密钥编码
- 网络传输数据编码

---

### 三、Hook 与注入模块

#### 8. hook_util.c - Hook 工具函数

**功能概述：**
提供函数 Hook 的底层工具函数，用于拦截和重定向 Windows API 调用。这是 Sandboxie 实现沙箱隔离的核心技术。

**核心函数：**

**1. DLL 导出查找：**
```c
UCHAR *FindDllExport(void *DllBase, const UCHAR *ProcName, ULONG* pErr)
UCHAR *FindDllExportEx(void *DllBase, const UCHAR *ProcName, ULONG* pErr, ULONG* pMaxLen)
```
- 在 DLL 的导出表中查找指定函数
- 支持 32 位和 64 位 PE 格式
- 返回函数地址和最大长度（用于确定 Hook 空间）

**2. Chrome/Firefox Hook 检测：**
```c
void* Hook_CheckChromeHook(void *SourceFunc, void* ProcBase)
```
- 检测 Chrome 和 Firefox 浏览器的内部 Hook
- 识别浏览器的函数拦截机制
- 返回真实的目标函数地址

**Chrome Hook 特征识别：**
```
// Chrome 64位 Hook 模式
mov rax, <target>
jmp rax

// 或旧版本
push rax
mov rax, <target>
```

**Firefox Hook 特征识别：**
- 查找对 `g_originals` 导出变量的引用
- 解析 Firefox 的拦截器表

**3. ARM64 支持：**
```c
void* Hook_GetXipTarget(void* ptr, int mode)
```
- 解析 ARM64 指令序列
- 识别 ADRP + LDR/ADD + BR 模式
- 获取跳转目标地址

**4. 系统调用索引获取：**
```c
USHORT Hook_GetSysCallIndex(UCHAR* SourceFunc)
```
- 从 ntdll 函数中提取系统调用号
- 支持标准 syscall 和 int 2E 方式

**5. FFS（Fast Forward Sequence）目标获取：**
```c
void* Hook_GetFFSTarget(UCHAR* SourceFunc)
```
- 识别 Windows 11 的快速转发序列
- 跟踪多层跳转找到真实函数

**实现技巧：**
- 位置无关代码（PIC）设计，可在 shellcode 中使用
- 支持多种 CPU 架构（x86, x64, ARM64, ARM64EC）
- 处理各种编译器和优化级别的代码模式

**使用场景：**
- 在沙箱进程中 Hook Windows API
- 绕过浏览器的安全机制
- 兼容第三方安全软件的 Hook

---

#### 9. dllimport.c / dllimport.h - DLL 导入表解析

**功能概述：**
提供跨进程的 DLL 导出函数查找功能，支持从远程进程或磁盘文件中解析 PE 格式。

**核心函数：**

**1. 查找 DLL 基址：**
```c
DWORD64 FindDllBase64(HANDLE hProcess, const WCHAR* dll)
```
- 遍历目标进程的虚拟内存
- 通过文件名匹配找到 DLL 加载地址
- 支持 64 位地址空间

**2. 映射远程 DLL：**
```c
BYTE* MapRemoteDll(HANDLE hProcess, DWORD64 DllBase)
```
- 读取远程进程中的 DLL 内存
- 按页（4KB）读取完整模块
- 返回本地内存副本

**3. 查找导出函数：**
```c
DWORD64 FindDllExportInMem(DWORD64 DllBase, const char* ProcName)
DWORD64 FindRemoteDllExport(HANDLE hProcess, DWORD64 DllBase, const char* ProcName)
DWORD64 FindDllExportFromFile(const WCHAR* dll, const char* ProcName)
```
- 从内存、远程进程或文件中查找导出函数
- 解析 PE 导出表（IMAGE_EXPORT_DIRECTORY）
- 支持按名称查找

**4. ARM64EC 重定向解析：**
```c
DWORD64 ResolveWoWRedirection64(...)
```
- 处理 ARM64EC（模拟兼容）模式
- 解析 CHPE（Compiled Hybrid PE）元数据
- 查找 x64 到 ARM64 的重定向表

**PE 格式支持：**
- IMAGE_NT_HEADERS32（32 位）
- IMAGE_NT_HEADERS64（64 位）
- IMAGE_ARM64EC_METADATA（ARM64EC）
- 动态值重定位表（Dynamic Value Reloc Table）

**使用场景：**
- 注入代码到目标进程前查找函数地址
- 分析其他进程的 API 使用情况
- 实现跨进程的函数调用

---

### 四、配置与工具模块

#### 10. ini.cpp / ini.h - INI 配置文件解析

**功能概述：**
解析和管理 Sandboxie.ini 配置文件，这是 Sandboxie 的核心配置系统。

**核心功能：**
- 读取和写入 INI 格式配置
- 支持节（Section）和键值对（Key-Value）
- 模板（Template）继承机制
- 配置热更新

**配置结构：**
```ini
[GlobalSettings]
; 全局设置

[DefaultBox]
; 默认沙箱配置
Template=Firefox
Enabled=y
```

**使用场景：**
- 沙箱行为配置
- 文件/注册表访问规则
- 网络访问策略
- 应用程序兼容性设置

---

#### 11. pattern.c / pattern.h - 模式匹配

**功能概述：**
实现通配符和正则表达式风格的字符串匹配，用于路径和规则匹配。

**支持的模式：**
- `*` - 匹配任意字符序列
- `?` - 匹配单个字符
- 大小写不敏感匹配
- 路径分隔符处理

**核心函数：**
- `Pattern_Match(const WCHAR *pat, const WCHAR *str)` - 模式匹配
- `Pattern_MatchX(...)` - 扩展匹配选项

**使用场景：**
- 文件路径规则匹配（如 `C:\Windows\*\*.dll`）
- 进程名称过滤
- 注册表键路径匹配
- 网络地址过滤

---

#### 12. str_util.c / str_util.h - 字符串工具

**功能概述：**
提供各种字符串操作的辅助函数。

**核心函数：**
- 字符串复制和连接
- 大小写转换
- Unicode 和 ANSI 转换
- 路径规范化
- 字符串比较（支持通配符）

**使用场景：**
- 路径处理
- 配置解析
- 日志格式化
- 进程间通信

---

#### 13. crc.c - CRC 校验和计算

**功能概述：**
实现多种哈希和校验和算法，用于数据完整性验证和快速比较。

**实现的算法：**

**1. CRC_Adler32：**
- Adler-32 校验和算法
- 比 CRC32 更快，但碰撞率稍高
- 用于快速数据验证

**2. CRC_Tzuk32：**
- 自定义哈希算法
- 使用位旋转和累加
- 针对 Sandboxie 优化

**3. CRC32：**
- 标准 CRC-32 算法
- 使用查找表优化
- 多项式：0xEDB88320

**核心函数：**
```c
ULONG CRC_Adler32(const UCHAR *data, int len)
ULONG CRC_Tzuk32(const UCHAR *data, int len)
ULONG CRC32(const char *buf, size_t len)
```

**使用场景：**
- 文件内容快速比较
- 内存块完整性检查
- 哈希表键生成
- 配置文件变更检测

---

#### 14. bom.c - BOM（字节序标记）检测

**功能概述：**
检测和处理文本文件的字节序标记（Byte Order Mark），支持多种编码格式。

**支持的编码：**
- UTF-8（BOM: EF BB BF）
- UTF-16 LE（BOM: FF FE）
- UTF-16 BE（BOM: FE FF）
- 自动检测（无 BOM 时）

**核心函数：**
```c
ULONG Read_BOM(UCHAR** data, ULONG* len)
```
- 返回值：0=UTF-16 LE, 1=UTF-8, 2=UTF-16 BE
- 自动跳过 BOM 字节
- 启发式检测编码

**检测逻辑：**
1. 检查已知 BOM 签名
2. 如无 BOM，检查 null 字节分布
3. UTF-16 LE：奇数位置多为 0
4. UTF-16 BE：偶数位置多为 0
5. UTF-8：无 null 字节

**使用场景：**
- 读取 Sandboxie.ini 配置文件
- 解析日志文件
- 处理用户提供的文本数据

---

### 五、系统定义与兼容层

#### 15. defines.h - 通用宏定义

**功能概述：**
定义了整个项目使用的通用宏、常量和内联函数。

**关键定义：**

**1. 编译器属性：**
```c
#define ALIGNED       // 内存对齐
#define NOINLINE      // 禁止内联
#define _FX           // 函数修饰符
```

**2. 内存和页面：**
```c
#define PAGE_SIZE 4096
#define BOXNAME_COUNT (38 + 2)
#define CONF_LINE_LEN 2000
```

**3. 时间转换：**
```c
#define SECONDS(n64) (((LONGLONG)n64) * 10000000L)
#define MINUTES(n64) (SECONDS(n64) * 60)
#define HOURS(n64)   (MINUTES(n64) * 60)
#define DAYS(n64)    (HOURS(n64) * 24)
```

**4. 内存操作：**
```c
#define memzero(mem,len)  memset((mem),0,(len))
#define wmemzero(mem,len) memzero((mem),(len)*sizeof(WCHAR))
```

**5. 配置操作类型：**
```c
#define CONF_UPDATE_VALUE    1
#define CONF_APPEND_VALUE    2
#define CONF_REMOVE_VALUE    4
#define CONF_REMOVE_SECTION  5
```

**使用场景：**
- 统一代码风格
- 跨平台兼容
- 性能优化提示

---

#### 16. my_version.h - 版本信息

**功能概述：**
定义 Sandboxie 的版本号、产品信息和各组件的文件名。

**版本定义：**
```c
#define VERSION_MJR  5
#define VERSION_MIN  72
#define VERSION_REV  3
#define VERSION_UPD  0

#define MY_VERSION_STRING "5.72.3"
#define MY_ABI_VERSION 0x57170
```

**产品信息：**
```c
#define MY_PRODUCT_NAME_STRING  "Sandboxie"
#define MY_COMPANY_NAME_STRING  "Sandboxie-Plus.com"
#define MY_COPYRIGHT_STRING     "Copyright © 2020-2026 by David Xanatos"
```

**组件文件名：**
```c
#define SBIEDRV_SYS    L"SbieDrv.sys"    // 驱动程序
#define SBIESVC_EXE    L"SbieSvc.exe"    // 服务程序
#define SBIEDLL        L"SbieDll"        // 注入 DLL
#define START_EXE      L"Start.exe"      // 启动器
```

**特殊标识：**
```c
#define SBIE_BOXED_    L"SBIE_BOXED_"    // 沙箱进程环境变量前缀
#define TITLE_SUFFIX_W L" [#]"           // 窗口标题后缀
```

**使用场景：**
- 版本兼容性检查
- 组件间通信验证
- 安装和更新管理
- 调试信息输出

---

#### 17. win32_ntddk.h - Win32/NT DDK 兼容层

**功能概述：**
提供 Windows NT 内核数据结构和函数的定义，使用户态代码能够使用内核级别的 API。

**关键内容：**
- NT 内核数据结构定义
- 未公开的系统调用原型
- 内核对象类型定义
- 驱动程序接口

**典型定义：**
```c
typedef struct _UNICODE_STRING {
    USHORT Length;
    USHORT MaximumLength;
    PWSTR  Buffer;
} UNICODE_STRING;

typedef struct _OBJECT_ATTRIBUTES {
    ULONG Length;
    HANDLE RootDirectory;
    PUNICODE_STRING ObjectName;
    ULONG Attributes;
    PVOID SecurityDescriptor;
    PVOID SecurityQualityOfService;
} OBJECT_ATTRIBUTES;
```

**使用场景：**
- 用户态调用 NT 原生 API
- 与驱动程序通信
- 底层系统操作

---

### 六、Detours 库

#### 18. Detours/ - Microsoft Detours 函数拦截库

**功能概述：**
Microsoft Detours 是一个用于拦截 Win32 API 调用的库。Sandboxie 使用它来实现函数 Hook。

**主要文件：**
- **detours.cpp / detours.h** - 核心 Hook 引擎
- **disasm.cpp** - 指令反汇编器
- **disolx86.cpp** - x86 指令解码
- **disolx64.cpp** - x64 指令解码
- **disolarm.cpp** - ARM 指令解码
- **disolarm64.cpp** - ARM64 指令解码
- **image.cpp** - PE 映像处理
- **modules.cpp** - 模块枚举

**核心功能：**

**1. 函数拦截：**
```c
DetourAttach(&(PVOID&)原函数指针, 新函数指针)
DetourDetach(&(PVOID&)原函数指针, 新函数指针)
```

**2. 事务机制：**
```c
DetourTransactionBegin()
DetourUpdateThread(hThread)
DetourAttach(...)
DetourTransactionCommit()
```

**3. 指令分析：**
- 计算函数前导指令长度
- 确保 Hook 不破坏指令边界
- 处理相对跳转和调用

**Hook 原理：**
1. 在目标函数开头写入跳转指令（JMP）
2. 跳转到 Detours 的 trampoline 函数
3. Trampoline 保存原始指令并调用 Hook 函数
4. Hook 函数可以调用原始函数或修改行为

**使用场景：**
- 拦截文件系统 API（CreateFile, ReadFile 等）
- 拦截注册表 API（RegOpenKey, RegSetValue 等）
- 拦截进程/线程 API（CreateProcess, CreateThread 等）
- 拦截网络 API（socket, connect 等）

---

### 七、JSON 解析库

#### 19. JSON/ - JSON 数据解析

**功能概述：**
提供 JSON 格式数据的解析和生成功能。

**主要文件：**
- **JSON.cpp / JSON.h** - JSON 解析器
- **JSONValue.cpp / JSONValue.h** - JSON 值对象

**支持的数据类型：**
- Object（对象）
- Array（数组）
- String（字符串）
- Number（数字）
- Boolean（布尔值）
- Null（空值）

**使用场景：**
- 解析配置文件
- 与现代应用程序通信
- 导出沙箱状态信息
- API 数据交换

---

### 八、其他工具模块

#### 20. lock.c / lock.h - 锁机制

**功能概述：**
提供跨内核态和用户态的统一锁接口。

**锁类型：**
- 互斥锁（Mutex）
- 临界区（Critical Section）
- 自旋锁（Spinlock）
- 读写锁（Reader-Writer Lock）

**核心函数：**
```c
Lock_Exclusive(LOCK *lock, const WCHAR *name)
Lock_Shared(LOCK *lock, const WCHAR *name)
Lock_Unlock(LOCK *lock, const WCHAR *name)
```

**使用场景：**
- 保护共享数据结构
- 内存池线程安全
- 配置文件并发访问

---

#### 21. netfw.c / netfw.h - 网络防火墙

**功能概述：**
与 Windows 防火墙集成，管理沙箱进程的网络访问权限。

**核心功能：**
- 添加/删除防火墙规则
- 控制入站/出站连接
- 端口和协议过滤
- 应用程序级别控制

**使用场景：**
- 限制沙箱进程的网络访问
- 防止恶意软件联网
- 实现网络隔离策略

---

#### 22. rbtree.c / rbtree.h - 红黑树

**功能概述：**
实现自平衡二叉搜索树（红黑树），提供 O(log n) 的查找、插入和删除性能。

**特性：**
- 自动平衡
- 有序存储
- 高效的范围查询
- 迭代器支持

**使用场景：**
- 有序数据集合
- 需要频繁插入/删除的场景
- 范围查询需求

---

#### 23. stream.c / stream.h - 流处理

**功能概述：**
提供字节流的读写接口，支持内存流和文件流。

**核心功能：**
- 顺序读写
- 随机访问
- 缓冲管理
- 格式化输入输出

**使用场景：**
- 配置文件读写
- 日志记录
- 数据序列化

---

## 总体架构分析

### 模块依赖关系

```
                    ┌─────────────────┐
                    │   应用层组件    │
                    │ (SbieSvc, Ctrl) │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Common 库     │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐        ┌─────▼─────┐       ┌─────▼─────┐
   │数据结构 │        │ 加密安全  │       │ Hook工具  │
   │ Pool    │        │ BigNum    │       │ Detours   │
   │ List    │        │ RC4       │       │ DllImport │
   │ Map     │        │ Verify    │       │ HookUtil  │
   └─────────┘        └───────────┘       └───────────┘
```

### 设计模式

**1. 内存池模式（Pool）：**
- 减少系统调用开销
- 提高内存分配效率
- 统一内存管理

**2. 策略模式（Map）：**
- 可插拔的哈希函数
- 自定义键比较逻辑
- 灵活的内存分配策略

**3. 迭代器模式（List, Map）：**
- 统一的遍历接口
- 支持安全删除
- 隐藏内部实现

**4. 工厂模式（Pool_Create）：**
- 统一的对象创建接口
- 资源初始化封装

---

## 性能优化技术

### 1. 内存管理优化
- **位图索引**：快速查找空闲内存块
- **页面分级**：分离满页面和可用页面
- **大块直接分配**：避免小块管理开销
- **内存对齐**：提高 CPU 缓存命中率

### 2. 算法优化
- **查找表**：CRC32 使用预计算表
- **平方求幂**：BigNum_ModPow 优化
- **位运算**：替代乘除法操作
- **短路求值**：模式匹配提前退出

### 3. 并发优化
- **细粒度锁**：减少锁竞争
- **读写锁**：提高并发读性能
- **无锁算法**：某些场景使用原子操作

---

## 安全考虑

### 1. 内存安全
- **边界检查**：防止缓冲区溢出
- **魔数验证**：检测内存损坏
- **安全释放**：防止 double-free

### 2. 加密安全
- **数字签名验证**：防止代码篡改
- **证书链验证**：确保信任来源
- **时间戳检查**：防止重放攻击

### 3. Hook 安全
- **指令边界检查**：避免破坏代码
- **原子操作**：防止竞态条件
- **权限验证**：防止未授权 Hook

---

## 跨平台支持

### 支持的架构
- **x86**：32 位 Intel/AMD
- **x64**：64 位 Intel/AMD
- **ARM**：32 位 ARM
- **ARM64**：64 位 ARM
- **ARM64EC**：ARM64 模拟兼容模式

### 内核/用户态兼容
- 统一的接口设计
- 条件编译分离实现
- 抽象层隔离差异

---

## 使用示例

### 示例 1：使用内存池

```c
// 创建内存池
POOL *pool = Pool_Create();

// 分配内存
void *ptr1 = Pool_Alloc(pool, 100);
void *ptr2 = Pool_Alloc(pool, 200);

// 使用内存
memcpy(ptr1, data, 100);

// 释放内存
Pool_Free(ptr1, 100);
Pool_Free(ptr2, 200);

// 删除内存池（自动释放所有未释放的内存）
Pool_Delete(pool);
```

### 示例 2：使用哈希表

```c
// 初始化哈希表
HASH_MAP map;
map_init(&map, pool);

// 插入键值对
WCHAR *key = L"test_key";
int value = 12345;
map_insert(&map, key, &value, sizeof(int));

// 查找值
int *result = (int*)map_get(&map, key);
if (result) {
    printf("Value: %d\n", *result);
}

// 删除键
map_remove(&map, key);

// 清空哈希表
map_clear(&map);
```

### 示例 3：Hook API 函数

```c
// 原始函数指针
typedef HANDLE (WINAPI *P_CreateFileW)(
    LPCWSTR lpFileName,
    DWORD dwDesiredAccess,
    DWORD dwShareMode,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes,
    DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes,
    HANDLE hTemplateFile
);

P_CreateFileW Real_CreateFileW = CreateFileW;

// Hook 函数
HANDLE WINAPI Hook_CreateFileW(
    LPCWSTR lpFileName,
    DWORD dwDesiredAccess,
    DWORD dwShareMode,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes,
    DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes,
    HANDLE hTemplateFile)
{
    // 记录调用
    wprintf(L"CreateFileW called: %s\n", lpFileName);
    
    // 调用原始函数
    return Real_CreateFileW(
        lpFileName, dwDesiredAccess, dwShareMode,
        lpSecurityAttributes, dwCreationDisposition,
        dwFlagsAndAttributes, hTemplateFile);
}

// 安装 Hook
DetourTransactionBegin();
DetourUpdateThread(GetCurrentThread());
DetourAttach(&(PVOID&)Real_CreateFileW, Hook_CreateFileW);
DetourTransactionCommit();
```

---

## 总结

Sandboxie 的 `common` 目录是整个项目的基础设施层，提供了：

1. **高效的数据结构**：内存池、链表、哈希表、红黑树
2. **强大的加密支持**：大数运算、RC4、数字签名验证
3. **灵活的 Hook 机制**：支持多架构、多浏览器、多场景
4. **完善的工具函数**：字符串处理、模式匹配、配置解析
5. **跨平台兼容性**：支持多种 CPU 架构和操作系统版本

这些模块共同构成了 Sandboxie 实现沙箱隔离的技术基础，使其能够：
- 高效地拦截和重定向系统调用
- 安全地管理沙箱进程的资源
- 灵活地配置沙箱行为
- 可靠地验证代码完整性

代码质量特点：
- **高性能**：优化的算法和数据结构
- **高可靠**：完善的错误处理和边界检查
- **高可维护**：清晰的模块划分和接口设计
- **高兼容性**：支持多种平台和场景

---

**文档版本**：1.0  
**分析日期**：2025年  
**Sandboxie 版本**：5.72.3  
**分析者**：AI Assistant
