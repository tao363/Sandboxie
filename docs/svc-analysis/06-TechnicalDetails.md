# 技术细节与实现机制

## 1. LPC 通信机制详解

### 1.1 LPC 概述

**LPC（Local Procedure Call）：**
- Windows 内核提供的进程间通信机制
- 比命名管道更高效
- 内核级别的消息传递
- 支持同步和异步通信

### 1.2 端口类型

**服务器端口（Server Port）：**
- 使用 `NtCreatePort` 创建
- 监听客户端连接请求
- 每个服务一个

**客户端端口（Client Port）：**
- 连接到服务器端口
- 每个客户端线程一个
- 用于发送请求和接收响应

**通信端口（Communication Port）：**
- 连接建立后创建
- 用于实际数据传输
- 双向通信

### 1.3 消息结构

**PORT_MESSAGE 结构：**
```cpp
typedef struct _PORT_MESSAGE {
    union {
        struct {
            USHORT DataLength;    // 数据长度
            USHORT TotalLength;   // 总长度
        } s1;
        ULONG Length;
    } u1;
    union {
        struct {
            USHORT Type;          // 消息类型
            USHORT DataInfoOffset;
        } s2;
        ULONG ZeroInit;
    } u2;
    union {
        CLIENT_ID ClientId;       // 客户端 ID
        double DoNotUseThisField;
    };
    ULONG MessageId;
    union {
        SIZE_T ClientViewSize;
        ULONG CallbackId;
    };
    UCHAR Data[ANYSIZE_ARRAY];   // 消息数据
} PORT_MESSAGE;
```

**消息类型：**
- `LPC_CONNECTION_REQUEST` (1) - 连接请求
- `LPC_REQUEST` (2) - 普通请求
- `LPC_REPLY` (3) - 响应
- `LPC_DATAGRAM` (4) - 数据报
- `LPC_PORT_CLOSED` (6) - 端口关闭
- `LPC_CLIENT_DIED` (7) - 客户端终止

### 1.4 通信流程

**连接建立：**
```cpp
// 客户端
NtConnectPort(&hPort, &PortName, &QoS, NULL, NULL, NULL, NULL, NULL);

// 服务器
NtListenPort(hServerPort, &msg);
NtAcceptConnectPort(&hClientPort, PortContext, &msg, TRUE, NULL, NULL);
NtCompleteConnectPort(hClientPort);
```

**消息发送：**
```cpp
// 客户端
NtRequestWaitReplyPort(hPort, &RequestMsg, &ReplyMsg);

// 服务器
NtReplyWaitReceivePort(hServerPort, &PortContext, &ReplyMsg, &RequestMsg);
```

### 1.5 大消息处理

**问题：**
- LPC 消息大小限制：约 256 字节
- 需要传输大数据时不够用

**解决方案：**
1. **分片传输**
   - 将大消息分成多个小片段
   - 第一个片段包含总长度和消息 ID
   - 后续片段包含数据

2. **重组机制**
   - 服务器端缓存片段
   - 按序号重组
   - 完整后处理

3. **序列号**
   - 防止消息混淆
   - 支持并发请求
   - 错误检测

**实现代码：**
```cpp
// 发送端
ULONG total_len = msg->length;
ULONG sent = 0;
UCHAR sequence = GetNextSequence();

while (sent < total_len) {
    ULONG chunk_size = min(MSG_DATA_LEN, total_len - sent);
    PORT_MESSAGE port_msg;
    
    if (sent == 0) {
        // 第一个片段
        ((ULONG*)port_msg.Data)[0] = total_len;
        ((ULONG*)port_msg.Data)[1] = msg->msgid;
        ((UCHAR*)port_msg.Data)[3] = sequence;
        memcpy(port_msg.Data + 8, msg + sent, chunk_size - 8);
    } else {
        // 后续片段
        memcpy(port_msg.Data, msg + sent, chunk_size);
    }
    
    NtRequestPort(hPort, &port_msg);
    sent += chunk_size;
}

// 接收端
if (!client->buf_hdr) {
    // 第一个片段
    ULONG total_len = ((ULONG*)msg->Data)[0];
    client->buf_hdr = AllocMsg(total_len);
    client->sequence = ((UCHAR*)msg->Data)[3];
}

memcpy(client->buf_ptr, msg->Data, msg->u1.s1.DataLength);
client->buf_ptr += msg->u1.s1.DataLength;

if (client->buf_ptr - (UCHAR*)client->buf_hdr >= client->buf_hdr->length) {
    // 接收完整
    ProcessMessage(client->buf_hdr);
}
```

---

## 2. 内存管理

### 2.1 内存池设计

**Pool 结构：**
- 预分配大块内存
- 分割成固定大小的块
- 快速分配和释放
- 减少内存碎片

**实现：**
```cpp
typedef struct _POOL {
    CRITICAL_SECTION lock;
    LIST_ELEM free_list;      // 空闲块链表
    ULONG block_size;         // 块大小
    ULONG total_blocks;       // 总块数
    ULONG used_blocks;        // 已用块数
    UCHAR *memory;            // 内存区域
} POOL;

POOL *Pool_Create() {
    POOL *pool = HeapAlloc(GetProcessHeap(), 0, sizeof(POOL));
    InitializeCriticalSection(&pool->lock);
    
    pool->block_size = 4096;
    pool->total_blocks = 1024;
    pool->memory = VirtualAlloc(NULL, 
        pool->block_size * pool->total_blocks,
        MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    
    // 初始化空闲链表
    for (ULONG i = 0; i < pool->total_blocks; i++) {
        UCHAR *block = pool->memory + i * pool->block_size;
        List_Insert_After(&pool->free_list, NULL, block);
    }
    
    return pool;
}

void *Pool_Alloc(POOL *pool, ULONG size) {
    EnterCriticalSection(&pool->lock);
    
    void *block = List_Head(&pool->free_list);
    if (block) {
        List_Remove(&pool->free_list, block);
        pool->used_blocks++;
    }
    
    LeaveCriticalSection(&pool->lock);
    return block;
}

void Pool_Free(void *ptr, ULONG size) {
    EnterCriticalSection(&pool->lock);
    
    List_Insert_After(&pool->free_list, NULL, ptr);
    pool->used_blocks--;
    
    LeaveCriticalSection(&pool->lock);
}
```

### 2.2 消息缓冲区管理

**分配策略：**
- 小消息（< 256 字节）：直接分配
- 中等消息（< 4KB）：从内存池分配
- 大消息（> 4KB）：使用 HeapAlloc

**保护机制：**
```cpp
MSG_HEADER *AllocMsg(ULONG length) {
    UCHAR *buf = Pool_Alloc(pool, length + sizeof(ULONG) * 2);
    
    // 添加保护标记
    ((MSG_HEADER*)buf)->length = length;
    *(ULONG*)(buf + length) = 0;              // 尾部标记
    *(ULONG*)(buf + length + sizeof(ULONG)) = tzuk;  // 签名
    
    return (MSG_HEADER*)buf;
}

void FreeMsg(MSG_HEADER *msg) {
    UCHAR *buf = (UCHAR*)msg;
    
    // 验证保护标记
    if (*(ULONG*)(buf + msg->length) != 0 ||
        *(ULONG*)(buf + msg->length + sizeof(ULONG)) != tzuk) {
        // 缓冲区溢出检测
        SbieApi_Log(2316, NULL);
        __debugbreak();
    }
    
    Pool_Free(msg, msg->length + sizeof(ULONG) * 2);
}
```

---

## 3. 线程同步

### 3.1 临界区优化

**自旋计数：**
```cpp
InitializeCriticalSectionAndSpinCount(&m_lock, 1000);
```
- 在进入内核模式前自旋等待
- 减少上下文切换
- 提高短锁性能

**锁粒度：**
- 细粒度锁：每个数据结构独立锁
- 减少锁竞争
- 提高并发性

### 3.2 无锁数据结构

**原子操作：**
```cpp
// 原子交换
HANDLE old = InterlockedExchangePointer(&m_hServerPort, new_port);

// 原子比较交换
InterlockedCompareExchangePointer(&ptr, new_val, old_val);

// 原子增减
InterlockedIncrement(&counter);
InterlockedDecrement(&counter);
```

**内存屏障：**
```cpp
// 确保内存操作顺序
MemoryBarrier();

// 读屏障
_ReadBarrier();

// 写屏障
_WriteBarrier();
```

### 3.3 TLS（线程本地存储）

**用途：**
- 存储调用者信息
- 避免全局锁
- 提高并发性能

**实现：**
```cpp
// 分配 TLS 索引
ULONG TlsIndex = TlsAlloc();

// 设置 TLS 数据
CLIENT_TLS_DATA data;
data.PortHandle = hPort;
data.PortMessage = msg;
TlsSetValue(TlsIndex, &data);

// 获取 TLS 数据
CLIENT_TLS_DATA *data = TlsGetValue(TlsIndex);
ULONG pid = data->PortMessage->ClientId.UniqueProcess;
```

---

## 4. 哈希映射实现

### 4.1 哈希表结构

**HASH_MAP 结构：**
```cpp
typedef struct _HASH_MAP {
    ULONG num_buckets;        // 桶数量
    ULONG nnodes;             // 节点数量
    LIST_ELEM *buckets;       // 桶数组
    POOL *mem_pool;           // 内存池
} HASH_MAP;

typedef struct _HASH_NODE {
    LIST_ELEM list_elem;
    ULONG_PTR key;            // 键
    void *value;              // 值
    ULONG hash;               // 哈希值
} HASH_NODE;
```

### 4.2 哈希函数

**简单哈希：**
```cpp
ULONG Hash(ULONG_PTR key) {
    // 对于指针和 PID，直接使用值
    return (ULONG)key;
}
```

**桶索引：**
```cpp
ULONG bucket_index = hash % map->num_buckets;
```

### 4.3 操作实现

**插入：**
```cpp
void map_insert(HASH_MAP *map, ULONG_PTR key, void *value, ULONG hash) {
    HASH_NODE *node = Pool_Alloc(map->mem_pool, sizeof(HASH_NODE));
    node->key = key;
    node->value = value;
    node->hash = hash ? hash : Hash(key);
    
    ULONG bucket = node->hash % map->num_buckets;
    List_Insert_After(&map->buckets[bucket], NULL, node);
    map->nnodes++;
}
```

**查找：**
```cpp
void *map_get(HASH_MAP *map, ULONG_PTR key) {
    ULONG hash = Hash(key);
    ULONG bucket = hash % map->num_buckets;
    
    HASH_NODE *node = List_Head(&map->buckets[bucket]);
    while (node) {
        if (node->key == key)
            return node->value;
        node = List_Next(node);
    }
    return NULL;
}
```

**删除：**
```cpp
void map_remove(HASH_MAP *map, ULONG_PTR key) {
    ULONG hash = Hash(key);
    ULONG bucket = hash % map->num_buckets;
    
    HASH_NODE *node = List_Head(&map->buckets[bucket]);
    while (node) {
        if (node->key == key) {
            List_Remove(&map->buckets[bucket], node);
            Pool_Free(node, sizeof(HASH_NODE));
            map->nnodes--;
            return;
        }
        node = List_Next(node);
    }
}
```

### 4.4 性能优化

**预分配桶：**
```cpp
map_resize(&m_client_map, 128);  // 预分配 128 个桶
```

**动态扩容：**
```cpp
if (map->nnodes > map->num_buckets * 2) {
    // 负载因子 > 2，扩容
    map_resize(map, map->num_buckets * 2);
}
```

---

## 5. 进程注入技术

### 5.1 注入方法

**CreateRemoteThread 注入：**
```cpp
// 1. 在目标进程中分配内存
LPVOID pRemoteBuf = VirtualAllocEx(hProcess, NULL, 
    path_len, MEM_COMMIT, PAGE_READWRITE);

// 2. 写入 DLL 路径
WriteProcessMemory(hProcess, pRemoteBuf, dll_path, path_len, NULL);

// 3. 获取 LoadLibrary 地址
LPVOID pLoadLibrary = GetProcAddress(
    GetModuleHandle(L"kernel32.dll"), "LoadLibraryW");

// 4. 创建远程线程
HANDLE hThread = CreateRemoteThread(hProcess, NULL, 0,
    (LPTHREAD_START_ROUTINE)pLoadLibrary, pRemoteBuf, 0, NULL);

// 5. 等待加载完成
WaitForSingleObject(hThread, INFINITE);
```

**NtCreateThreadEx 注入：**
```cpp
HANDLE hThread;
NtCreateThreadEx(&hThread, THREAD_ALL_ACCESS, NULL,
    hProcess, pLoadLibrary, pRemoteBuf, 
    FALSE, 0, 0, 0, NULL);
```

### 5.2 WoW64 处理

**检测 WoW64：**
```cpp
BOOL IsWow64 = FALSE;
IsWow64Process(hProcess, &IsWow64);
```

**32 位注入到 64 位：**
- 使用 64 位注入器
- 注入 64 位 DLL

**64 位注入到 32 位：**
- 使用 32 位注入器
- 注入 32 位 DLL

### 5.3 注入时机

**进程创建时：**
- 以 `CREATE_SUSPENDED` 标志创建
- 注入 DLL
- 恢复主线程

**运行时注入：**
- 挂起所有线程
- 注入 DLL
- 恢复线程

---

## 6. 作业对象详解

### 6.1 作业对象限制

**进程限制：**
```cpp
JOBOBJECT_BASIC_LIMIT_INFORMATION basic;
basic.LimitFlags = 
    JOB_OBJECT_LIMIT_ACTIVE_PROCESS |      // 限制活动进程数
    JOB_OBJECT_LIMIT_PRIORITY_CLASS |      // 限制优先级
    JOB_OBJECT_LIMIT_AFFINITY |            // 限制 CPU 亲和性
    JOB_OBJECT_LIMIT_WORKINGSET |          // 限制工作集
    JOB_OBJECT_LIMIT_PROCESS_TIME |        // 限制 CPU 时间
    JOB_OBJECT_LIMIT_JOB_TIME;             // 限制作业时间

basic.ActiveProcessLimit = 100;
basic.MinimumWorkingSetSize = 1024 * 1024;
basic.MaximumWorkingSetSize = 100 * 1024 * 1024;
```

**扩展限制：**
```cpp
JOBOBJECT_EXTENDED_LIMIT_INFORMATION extended;
extended.BasicLimitInformation = basic;
extended.ProcessMemoryLimit = 500 * 1024 * 1024;  // 500MB
extended.JobMemoryLimit = 1024 * 1024 * 1024;     // 1GB
```

### 6.2 UI 限制详解

**桌面限制：**
- `JOB_OBJECT_UILIMIT_DESKTOP` - 禁止切换桌面
- 防止访问其他用户的桌面
- 限制在当前桌面

**系统参数限制：**
- `JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS` - 禁止修改系统参数
- 防止修改墙纸、屏保等
- 保护系统设置

**句柄限制：**
- `JOB_OBJECT_UILIMIT_HANDLES` - 限制用户对象句柄访问
- 防止访问其他进程的窗口
- 增强隔离性

### 6.3 通知机制

**完成端口：**
```cpp
HANDLE hCompletionPort = CreateIoCompletionPort(
    INVALID_HANDLE_VALUE, NULL, 0, 1);

JOBOBJECT_ASSOCIATE_COMPLETION_PORT port;
port.CompletionKey = job_key;
port.CompletionPort = hCompletionPort;

SetInformationJobObject(hJob, 
    JobObjectAssociateCompletionPortInformation,
    &port, sizeof(port));

// 接收通知
DWORD bytes;
ULONG_PTR key;
LPOVERLAPPED overlapped;
GetQueuedCompletionStatus(hCompletionPort, 
    &bytes, &key, &overlapped, INFINITE);

// bytes 包含通知类型
switch (bytes) {
    case JOB_OBJECT_MSG_NEW_PROCESS:
        // 新进程加入
        break;
    case JOB_OBJECT_MSG_EXIT_PROCESS:
        // 进程退出
        break;
    case JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO:
        // 所有进程已退出
        break;
}
```

---

## 7. 安全机制

### 7.1 令牌操作

**打开令牌：**
```cpp
HANDLE hToken;
OpenProcessToken(hProcess, TOKEN_ALL_ACCESS, &hToken);
```

**复制令牌：**
```cpp
HANDLE hNewToken;
DuplicateTokenEx(hToken, TOKEN_ALL_ACCESS, NULL,
    SecurityImpersonation, TokenPrimary, &hNewToken);
```

**调整权限：**
```cpp
TOKEN_PRIVILEGES tp;
tp.PrivilegeCount = 1;
LookupPrivilegeValue(NULL, SE_DEBUG_NAME, &tp.Privileges[0].Luid);
tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(tp), NULL, NULL);
```

### 7.2 完整性级别

**查询完整性级别：**
```cpp
DWORD integrity_level;
TOKEN_MANDATORY_LABEL *label;
GetTokenInformation(hToken, TokenIntegrityLevel, 
    label, size, &size);

integrity_level = *GetSidSubAuthority(label->Label.Sid,
    *GetSidSubAuthorityCount(label->Label.Sid) - 1);
```

**设置完整性级别：**
```cpp
// 低完整性
WCHAR *integrity_sid = L"S-1-16-4096";
ConvertStringSidToSid(integrity_sid, &sid);

TOKEN_MANDATORY_LABEL label;
label.Label.Attributes = SE_GROUP_INTEGRITY;
label.Label.Sid = sid;

SetTokenInformation(hToken, TokenIntegrityLevel,
    &label, sizeof(label));
```

### 7.3 数字签名验证

**验证文件签名：**
```cpp
NTSTATUS VerifyFileSignature(const wchar_t *FilePath) {
    WINTRUST_FILE_INFO file_info;
    memset(&file_info, 0, sizeof(file_info));
    file_info.cbStruct = sizeof(file_info);
    file_info.pcwszFilePath = FilePath;
    
    WINTRUST_DATA trust_data;
    memset(&trust_data, 0, sizeof(trust_data));
    trust_data.cbStruct = sizeof(trust_data);
    trust_data.dwUIChoice = WTD_UI_NONE;
    trust_data.fdwRevocationChecks = WTD_REVOKE_NONE;
    trust_data.dwUnionChoice = WTD_CHOICE_FILE;
    trust_data.pFile = &file_info;
    
    GUID policy = WINTRUST_ACTION_GENERIC_VERIFY_V2;
    LONG status = WinVerifyTrust(NULL, &policy, &trust_data);
    
    return (status == ERROR_SUCCESS) ? STATUS_SUCCESS : STATUS_UNSUCCESSFUL;
}
```

---

## 8. 性能监控

### 8.1 性能计数器

**CPU 使用率：**
```cpp
FILETIME create_time, exit_time, kernel_time, user_time;
GetProcessTimes(hProcess, &create_time, &exit_time, 
    &kernel_time, &user_time);

ULONGLONG total_time = 
    ((ULONGLONG)kernel_time.dwHighDateTime << 32 | kernel_time.dwLowDateTime) +
    ((ULONGLONG)user_time.dwHighDateTime << 32 | user_time.dwLowDateTime);
```

**内存使用：**
```cpp
PROCESS_MEMORY_COUNTERS pmc;
GetProcessMemoryInfo(hProcess, &pmc, sizeof(pmc));

ULONG working_set = pmc.WorkingSetSize;
ULONG peak_working_set = pmc.PeakWorkingSetSize;
ULONG page_faults = pmc.PageFaultCount;
```

**句柄数量：**
```cpp
DWORD handle_count;
GetProcessHandleCount(hProcess, &handle_count);
```

### 8.2 日志记录

**事件日志：**
```cpp
HANDLE hEventLog = RegisterEventSource(NULL, L"Sandboxie");

const WCHAR *strings[] = { message };
ReportEvent(hEventLog, EVENTLOG_INFORMATION_TYPE,
    0, msgid, NULL, 1, 0, strings, NULL);

DeregisterEventSource(hEventLog);
```

**调试输出：**
```cpp
#ifdef DEBUG
OutputDebugString(L"Debug message");
#endif
```
