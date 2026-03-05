# ImBox 代码分析文档

## 项目概述

ImBox 是一个加密虚拟磁盘工具，用于创建和管理加密的虚拟磁盘。它支持多种存储后端（虚拟内存、物理内存、镜像文件）和多种加密算法（AES、Twofish、Serpent及其组合）。该项目基于 DiskCryptor 的加密库，使用 XTS 加密模式，并通过 ImDisk 驱动程序提供虚拟磁盘功能。

## 核心架构

### 1. 抽象IO层 (AbstractIO.h)

**类：CAbstractIO**

这是所有IO操作的抽象基类，定义了虚拟磁盘操作的统一接口。

**主要方法：**
- `GetAllocSize()` - 获取实际分配的磁盘空间大小
- `GetDiskSize()` - 获取虚拟磁盘的逻辑大小
- `CanBeFormated()` - 检查磁盘是否可以被格式化
- `Init()` - 初始化IO后端
- `PrepViewOfFile(BYTE*)` - 准备共享内存视图
- `DiskWrite()` - 写入数据到磁盘
- `DiskRead()` - 从磁盘读取数据
- `TrimProcess()` - 处理TRIM命令（释放未使用的块）

---

## 2. IO实现类

### 2.1 虚拟内存IO (VirtualMemoryIO.cpp/h)

**类：CVirtualMemoryIO**

使用系统虚拟内存作为存储后端，适合临时使用的RAM磁盘。

**数据结构：**
```cpp
struct SVirtualMemory {
    ULONG64 uSize;                    // 磁盘总大小
    int mem_block_size;               // 内存块大小
    int mem_block_size_mask;          // 块大小掩码（用于快速计算）
    int mem_block_size_shift;         // 块大小位移量
    size_t table_size;                // 块表大小
    void **ptr_table;                 // 指向内存块的指针表
    volatile size_t n_block;          // 已分配的块数量
}
```

**主要函数：**

1. **CVirtualMemoryIO::CVirtualMemoryIO(ULONG64 uSize, int BlockSize)**
   - 构造函数，初始化虚拟内存IO
   - 参数：uSize - 磁盘大小，BlockSize - 块大小的位移量（默认20，即1MB）
   - 计算块大小：2^BlockSize（范围：4KB到1GB）

2. **CVirtualMemoryIO::Init()**
   - 初始化内存块表
   - 分配指针表用于跟踪内存块

3. **CVirtualMemoryIO::DiskWrite(void* buf, int size, __int64 offset)**
   - 写入数据到虚拟内存
   - 使用稀疏分配：只在写入非零数据时分配内存块
   - 使用 `data_search()` 检测全零块以节省内存
   - 如果可用内存低于 MINIMAL_MEM (100MB)，写入失败

4. **CVirtualMemoryIO::DiskRead(void* buf, int size, __int64 offset)**
   - 从虚拟内存读取数据
   - 未分配的块返回零

5. **CVirtualMemoryIO::TrimProcess(DEVICE_DATA_SET_RANGE* range, int n)**
   - 处理TRIM命令，释放不再使用的内存块
   - 检查块是否全零，如果是则释放内存

6. **CVirtualMemoryIO::Expand(ULONG64 uSize)**
   - 动态扩展磁盘大小
   - 重新分配指针表并复制现有数据

---

### 2.2 物理内存IO (PhysicalMemoryIO.cpp/h)

**类：CPhysicalMemoryIO**

使用 AWE (Address Windowing Extensions) API 直接分配物理内存，性能更高但需要特殊权限。

**数据结构：**
```cpp
struct SPhysicalMemory {
    ULONG64 uSize;                    // 磁盘大小
    int mem_block_size;               // 内存块大小
    int mem_block_size_mask;          // 块掩码
    int mem_block_size_shift;         // 块位移
    size_t table_size;                // 块表大小
    void *virtual_mem_ptr;            // 虚拟内存映射指针
    bool *allocated_block;            // 块分配状态表
    HANDLE current_process;           // 当前进程句柄
    ULONG_PTR n_pages;                // 每块的页数
    ULONG_PTR *pfn;                   // 物理页帧号数组
    volatile size_t n_block;          // 已分配块数
}
```

**主要函数：**

1. **CPhysicalMemoryIO::Init()**
   - 获取 SeLockMemoryPrivilege 权限
   - 初始化物理页表和虚拟内存映射区域
   - 使用 `AllocateUserPhysicalPages()` 分配物理内存

2. **CPhysicalMemoryIO::DiskWrite()**
   - 使用 `MapUserPhysicalPages()` 映射物理页到虚拟地址空间
   - 写入数据后解除映射
   - 支持稀疏分配

3. **CPhysicalMemoryIO::PrepViewOfFile(BYTE* shm_view)**
   - 锁定共享内存视图到物理内存
   - 增加进程工作集大小以容纳缓冲区

---

### 2.3 镜像文件IO (ImageFileIO.cpp/h)

**类：CImageFileIO**

使用磁盘上的文件作为虚拟磁盘镜像，支持稀疏文件以节省空间。

**数据结构：**
```cpp
struct SImageFileIO {
    std::wstring FilePath;            // 文件路径
    ULONG64 uSize;                    // 文件大小
    HANDLE Handle;                    // 文件句柄
    LARGE_INTEGER fileCreationTime;   // 创建时间
    LARGE_INTEGER fileLastAccessTime; // 最后访问时间
    LARGE_INTEGER fileLastWriteTime;  // 最后写入时间
    LARGE_INTEGER fileLastChangeTime; // 最后修改时间
    BOOL bTimeStampValid;             // 时间戳是否有效
}
```

**主要函数：**

1. **CImageFileIO::Init()**
   - 打开或创建镜像文件
   - 使用 FILE_FLAG_NO_BUFFERING 和 FILE_FLAG_WRITE_THROUGH 标志
   - 将文件设置为稀疏文件（如果文件系统支持）
   - 保存原始时间戳并禁用自动时间戳更新

2. **CImageFileIO::DiskWrite(void* buf, int size, __int64 offset)**
   - 使用 SetFilePointerEx 定位
   - 使用 WriteFile 写入数据

3. **CImageFileIO::TrimProcess(DEVICE_DATA_SET_RANGE* range, int n)**
   - 使用 FSCTL_SET_ZERO_DATA 将文件区域标记为稀疏零区域
   - 释放磁盘空间而不实际写入零

4. **析构函数**
   - 恢复文件的原始时间戳
   - 关闭文件句柄

---

## 3. 加密层 (CryptoIO.cpp/h)

**类：CCryptoIO**

提供透明的磁盘加密功能，包装任何 CAbstractIO 实现。

**数据结构：**
```cpp
struct SCryptoIO {
    std::wstring Cipher;              // 加密算法名称
    bool AllowFormat;                 // 是否允许格式化
    SSecureBuffer<dc_pass> password;  // 密码（安全缓冲区）
    xts_key benc_k;                   // XTS加密密钥
    SSection* section;                // 共享内存区段
}
```

**加密头结构 (dc_header)：**
- 大小：2KB
- 包含：PKCS5盐值、签名、CRC校验、版本、标志、磁盘ID、加密算法、加密密钥、数据偏移等
- 支持在头部存储最多1KB的自定义数据

**主要函数：**

1. **CCryptoIO::InitCrypto()**
   - 解析加密算法（AES、Twofish、Serpent及其组合）
   - 如果允许格式化，创建新的加密头
   - 使用 `dc_decrypt_header()` 解密现有头部
   - 使用 `xts_set_key()` 设置加密密钥

2. **CCryptoIO::WriteHeader(struct _dc_header* header)**
   - 使用 PKCS5.2 (1000次迭代) 从密码派生头部加密密钥
   - 使用派生密钥加密头部
   - 写入盐值和加密的头部到磁盘

3. **CCryptoIO::DiskWrite(void* buf, int size, __int64 offset)**
   - 使用 XTS 模式加密数据
   - 调用底层IO的写入方法
   - 偏移量加上 DC_AREA_SIZE (2KB) 以跳过头部

4. **CCryptoIO::DiskRead(void* buf, int size, __int64 offset)**
   - 从底层IO读取加密数据
   - 使用 XTS 模式解密数据

5. **CCryptoIO::ChangePassword(const WCHAR* pNewKey)**
   - 解密现有头部
   - 使用新密码重新加密头部
   - 不改变数据加密密钥（无需重新加密整个磁盘）

6. **CCryptoIO::BackupHeader() / RestoreHeader()**
   - 备份和恢复加密头部
   - 用于灾难恢复

7. **CCryptoIO::SetData() / GetData()**
   - 在加密头部存储/读取自定义数据（最多1KB）
   - 可用于存储元数据

---

## 4. ImDisk集成 (ImDiskIO.cpp/h)

**类：CImDiskIO**

与 ImDisk 虚拟磁盘驱动程序通信，将IO后端挂载为Windows磁盘。

**数据结构：**
```cpp
struct SImDiskIO {
    std::wstring Mount;               // 挂载点（驱动器号或路径）
    UINT Number;                      // 设备编号
    std::wstring Format;              // 文件系统格式（如 "ntfs:Label"）
    std::wstring Params;              // 额外的ImDisk参数
    HANDLE hImDisk;                   // ImDisk进程句柄
    std::wstring Proxy;               // 代理名称
    HANDLE hEvent;                    // 挂载完成事件
    HANDLE hMapping;                  // 共享内存映射
    SSection* pSection;               // 共享内存区段
}
```

**主要函数：**

1. **CImDiskIO::DoComm()**
   - 创建共享内存映射（用于与ImDisk通信）
   - 创建请求/响应事件
   - 启动 imdisk.exe 进程
   - 进入IO请求处理循环：
     - IMDPROXY_REQ_INFO：返回磁盘信息
     - IMDPROXY_REQ_READ：处理读取请求
     - IMDPROXY_REQ_WRITE：处理写入请求
     - IMDPROXY_REQ_UNMAP：处理TRIM请求
     - IMDPROXY_REQ_CLOSE：关闭连接

2. **CImDiskIO_Thread()**
   - 后台线程，等待磁盘挂载完成
   - 如果指定了格式化选项，格式化新磁盘
   - 使用 fmifs.dll 的 Format 函数
   - 验证挂载点是否正确

3. **辅助函数：**
   - `MyImDiskFindFreeDriveLetter()` - 查找空闲驱动器号
   - `MyImDiskOpenDeviceByMountPoint()` - 通过挂载点打开设备
   - `IsVolumeUnRecognized()` - 检查卷是否未格式化
   - `FormatVolume()` - 格式化卷

---

## 5. 加密库 (dc目录)

### 5.1 XTS加密模式 (xts_fast.c)

XTS (XEX-based tweaked-codebook mode with ciphertext stealing) 是专为磁盘加密设计的加密模式。

**主要函数：**

1. **xts_init(int hw_crypt)**
   - 初始化加密库
   - 检测CPU功能（AES-NI、AVX、SSE2）
   - 选择最优的加密实现
   - 返回值：1=AES-NI, 2=VIA PadLock, 0=软件实现

2. **xts_set_key(const unsigned char *key, int alg, xts_key *skey)**
   - 设置加密密钥
   - 支持的算法：
     - CF_AES：AES-256
     - CF_TWOFISH：Twofish-256
     - CF_SERPENT：Serpent-256
     - CF_AES_TWOFISH：AES+Twofish级联
     - CF_TWOFISH_SERPENT：Twofish+Serpent级联
     - CF_SERPENT_AES：Serpent+AES级联
     - CF_AES_TWOFISH_SERPENT：三重级联

3. **XTS加密/解密函数**
   - 每个扇区（512字节）使用唯一的tweak值
   - Tweak基于扇区偏移量计算
   - 支持硬件加速（AES-NI、VIA PadLock）

### 5.2 AES实现 (aes_key.c)

- 实现AES-256加密算法
- 包含预计算的S盒和T表
- 支持x86和x64架构
- 提供汇编优化版本（aes_amd64.asm, aes_i386.asm）

### 5.3 SHA-512实现 (sha512.c)

**主要函数：**

1. **sha512_init(sha512_ctx *ctx)**
   - 初始化SHA-512上下文

2. **sha512_hash(sha512_ctx *ctx, const unsigned char *in, size_t inlen)**
   - 处理数据块

3. **sha512_done(sha512_ctx *ctx, unsigned char *out)**
   - 完成哈希计算，输出64字节摘要

### 5.4 PKCS#5密钥派生 (sha512_pkcs5_2.c)

- 实现PBKDF2密钥派生函数
- 使用SHA-512作为伪随机函数
- 用于从密码生成加密密钥

---

## 6. 主程序 (ImBox.cpp)

**主要函数：wWinMain()**

命令行参数解析和处理：

**参数：**
- `type=` - 存储类型（virtual/ram, physical/awe, image/img）
- `image=` - 镜像文件路径
- `mount=` - 挂载点（驱动器号或目录）
- `number=` - 设备编号
- `size=` - 磁盘大小
- `key=` - 加密密码
- `cipher=` - 加密算法
- `format=` - 文件系统格式
- `params=` - ImDisk参数
- `new_key=` - 新密码（用于更改密码）
- `backup=` - 备份头部到文件
- `restore=` - 从文件恢复头部
- `set_data=` - 设置自定义数据
- `get_data=` - 获取自定义数据
- `proxy=` - 代理名称
- `event=` - 事件名称
- `section=` - 共享内存区段名称
- `mem=` - 内存地址

**执行流程：**

1. 解析命令行参数
2. 根据type创建相应的IO对象
3. 如果指定了backup/restore，执行头部备份/恢复操作
4. 如果指定了key，创建CCryptoIO包装器
5. 如果指定了new_key，执行密码更改操作
6. 如果指定了set_data/get_data，执行数据存储/读取操作
7. 初始化IO后端
8. 创建CImDiskIO对象并启动通信循环

---

## 7. 辅助功能

### 7.1 数据搜索优化 (ImDiskIO.cpp)

**函数：data_search()**

用于快速检测内存块是否全为零，以实现稀疏存储。

**实现：**
- `data_search_std()` - 标准实现（使用long扫描）
- `data_search_sse2()` - SSE2优化（使用128位向量）
- `data_search_avx()` - AVX优化（使用256位向量）
- 运行时自动选择最优实现

### 7.2 安全内存管理

**SSecureBuffer模板类：**
- 在可执行内存中分配（x86需要）
- 使用VirtualLock锁定内存防止交换
- 析构时使用RtlSecureZeroMemory清零
- 用于存储密码和密钥

---

## 8. 错误代码

```cpp
#define ERR_OK              0   // 成功
#define ERR_UNKNOWN_TYPE    1   // 未知类型
#define ERR_FILE_NOT_OPENED 2   // 文件打开失败
#define ERR_UNKNOWN_CIPHER  3   // 未知加密算法
#define ERR_WRONG_PASSWORD  4   // 密码错误
#define ERR_KEY_REQUIRED    5   // 需要密钥
#define ERR_PRIVILEGE       6   // 权限不足
#define ERR_INTERNAL        7   // 内部错误
#define ERR_FILE_MAPPING    8   // 文件映射失败
#define ERR_CREATE_EVENT    9   // 创建事件失败
#define ERR_IMDISK_FAILED   10  // ImDisk失败
#define ERR_IMDISK_TIMEOUT  11  // ImDisk超时
#define ERR_UNKNOWN_COMMAND 12  // 未知命令
#define ERR_MALLOC_ERROR    13  // 内存分配失败
#define ERR_INVALID_PARAM   14  // 无效参数
#define ERR_DATA_TO_LONG    15  // 数据过长
#define ERR_DATA_NOT_FOUND  16  // 数据未找到
```

---

## 9. 使用示例

### 创建加密RAM磁盘：
```
ImBox.exe type=virtual size=2147483648 mount=R: key=mypassword cipher=AES format=ntfs:MyDisk
```

### 创建加密镜像文件：
```
ImBox.exe type=image image="C:\disk.img" size=1073741824 mount=S: key=mypassword cipher=AES-TWOFISH format=ntfs
```

### 挂载现有加密镜像：
```
ImBox.exe type=image image="C:\disk.img" mount=S: key=mypassword
```

### 更改密码：
```
ImBox.exe type=image image="C:\disk.img" key=oldpassword new_key=newpassword
```

### 备份加密头：
```
ImBox.exe type=image image="C:\disk.img" backup="C:\header.backup"
```

---

## 10. 安全特性

1. **强加密**：支持AES-256、Twofish-256、Serpent-256及其级联
2. **XTS模式**：专为磁盘加密设计，防止模式攻击
3. **密钥派生**：使用PBKDF2-SHA512（1000次迭代）
4. **安全内存**：密钥和密码存储在锁定的内存中，使用后安全清零
5. **头部保护**：加密头部使用独立的密钥派生
6. **时间戳保护**：镜像文件的时间戳在操作后恢复
7. **硬件加速**：支持AES-NI和VIA PadLock硬件加速

---

## 11. 性能优化

1. **稀疏存储**：只分配实际使用的内存/磁盘空间
2. **块级管理**：使用可配置的块大小（默认1MB）
3. **硬件加速**：自动检测并使用CPU加密指令
4. **SIMD优化**：使用SSE2/AVX加速零块检测
5. **直接IO**：使用FILE_FLAG_NO_BUFFERING绕过系统缓存
6. **物理内存**：AWE API直接访问物理内存，减少页面错误

---

## 总结

ImBox是一个功能完整的加密虚拟磁盘解决方案，具有以下特点：

- **灵活的存储后端**：支持RAM、物理内存和文件镜像
- **强大的加密**：多种算法和级联模式
- **高性能**：硬件加速和优化的数据结构
- **易于集成**：通过ImDisk与Windows无缝集成
- **安全设计**：多层安全措施保护数据和密钥

该项目适用于需要临时或永久加密存储的场景，如保护敏感数据、创建安全工作环境等。
