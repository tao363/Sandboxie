# Sandboxie-Plus — 组件详解

本文档详细描述各核心组件的职责、接口、数据结构和注意事项。

---

## 1. SbieDrv.sys — 内核驱动

**路径：** `Sandboxie/core/drv/`  
**职责：** 内核态系统调用拦截，强制执行隔离策略，管理沙箱进程对象

### 公共接口

驱动通过 IOCTL 设备 `\\Device\\SandboxieDriverApi` 与用户态通信：

| IOCTL 代码 | 功能 | 参数 |
|------------|------|------|
| `API_GET_VERSION` | 获取驱动版本 | 无 |
| `API_CREATE_PROCESS` | 注册新沙箱进程 | 进程 ID, 沙箱名 |
| `API_QUERY_PROCESS` | 查询进程信息 | 进程 ID |
| `API_KILL_PROCESS` | 终止沙箱进程 | 进程 ID |
| `API_QUERY_BOX_PATH` | 获取沙箱路径 | 沙箱名 |
| `API_SET_USER_NAME` | 设置用户信息 | 用户名, SID |

### 关键数据结构

```c
// 进程对象 (process.h)
typedef struct _PROCESS {
    LIST_ELEM list_elem;
    HANDLE pid;
    BOX *box;
    HANDLE pool;
    ULONG create_time;
    // ... 更多字段
} PROCESS;

// 沙箱对象 (box.h)
typedef struct _BOX {
    LIST_ELEM list_elem;
    WCHAR name[BOXNAME_COUNT];
    WCHAR file_path[MAX_PATH];
    WCHAR key_path[MAX_PATH];
    WCHAR ipc_path[MAX_PATH];
    // ... 更多字段
} BOX;
```

### 内部架构

```
driver.c (入口点)
    ├── api.c (IOCTL 处理)
    ├── process.c (进程管理)
    │   ├── process_force.c (强制沙箱化)
    │   ├── process_hook.c (注入管理)
    │   └── process_low.c (低级进程)
    ├── syscall.c (系统调用拦截)
    │   ├── syscall_32.c (x86)
    │   └── syscall_64.c (x64)
    ├── file.c (文件系统过滤)
    ├── key.c (注册表过滤)
    ├── ipc.c (IPC 过滤)
    └── gui.c (GUI 过滤)
```

### 与其他组件的交互

- **用户态通信**：通过 IOCTL 接收 SbieSvc 和 QSbieAPI 的请求
- **DLL 注入**：通过 APC 或线程劫持将 SbieDll.dll 注入到目标进程
- **系统调用拦截**：Hook SSDT 或使用 Filter Manager

### 已知约束和注意事项

- 必须在系统启动时加载驱动
- 驱动代码不能使用标准 C 运行时，需使用内核专用函数
- 修改驱动代码需要重新签名才能在生产环境使用
- 调试驱动需要使用 WinDbg 或 DebugView

---

## 2. SbieDll.dll — 注入 DLL

**路径：** `Sandboxie/core/dll/`  
**职责：** 用户态 API Hook，路径重定向，与驱动和服务通信

### 公共接口

```c
// 导出函数 (sbiedll.h)
SBIEDLL_EXPORT BOOL SbieDll_Hook(const char *Source, void *Target, void *Detour);
SBIEDLL_EXPORT LONG SbieApi_QueryProcessInfo(ULONG *out, ULONG info_type);
SBIEDLL_EXPORT WCHAR *SbieDll_GetBoxName(void);
SBIEDLL_EXPORT BOOL SbieDll_IsBoxedProcess(void);
```

### 关键数据结构

```c
// DLL 全局状态 (dll.h)
typedef struct _DLL_DATA {
    HANDLE heap;
    WCHAR box_name[BOXNAME_COUNT];
    WCHAR home_path[MAX_PATH];
    ULONG pid;
    BOOLEAN is_wow64;
    // ... 更多字段
} DLL_DATA;
```

### 内部架构

```
dllmain.c (入口点)
    ├── ldr_init.c (加载器初始化)
    ├── hook_inst.c (Hook 安装)
    ├── file.c (文件 API Hook)
    ├── key.c (注册表 API Hook)
    ├── ipc.c (IPC API Hook)
    ├── gui.c (GUI API Hook)
    ├── proc.c (进程 API Hook)
    ├── scm.c (服务控制管理器 Hook)
    ├── net.c (网络 API Hook)
    └── sbieapi.c (与驱动通信)
```

### 与其他组件的交互

- **与驱动通信**：通过 `SbieApi_*` 函数发送 IOCTL
- **与服务通信**：通过命名管道 `\\.\pipe\SbieSvcPort`
- **注入时机**：在进程启动早期通过 LowLevel.dll 注入

### 已知约束和注意事项

- DLL 注入后不能卸载
- Hook 必须在进程早期安装，否则可能遗漏调用
- 需要处理 32/64 位兼容性问题
- 某些反调试/反注入软件可能检测到 SbieDll 的存在

---

## 3. SbieSvc.exe — 系统服务

**路径：** `Sandboxie/core/svc/`  
**职责：** 进程管理，配置代理，权限代理，GUI 服务器

### 公共接口

服务通过 LPC 端口 `\\RPC Control\\SbieSvcPort` 和命名管道与客户端通信：

| 端口/管道 | 功能 |
|-----------|------|
| `SbieSvcPort` | 主 LPC 端口 |
| `\\.\pipe\SbieSvcPort` | 命名管道通信 |
| `\\.\pipe\SbieSvcPort_*` | 专用管道 |

### 关键数据结构

```cpp
// 管道服务器 (PipeServer.h)
class PipeServer {
public:
    virtual void Run() = 0;
    virtual BOOL SendMsg(void* msg, ULONG msg_len) = 0;
};
```

### 内部架构

```
main.cpp (入口点)
    ├── PipeServer.cpp (管道服务器框架)
    ├── DriverAssist.cpp (驱动辅助)
    │   ├── DriverAssistInject.cpp (注入管理)
    │   ├── DriverAssistLog.cpp (日志)
    │   └── DriverAssistSid.cpp (SID 管理)
    ├── ProcessServer.cpp (进程服务)
    ├── FileServer.cpp (文件服务)
    ├── comserver.cpp (COM 服务)
    ├── sbieiniserver.cpp (INI 配置服务)
    ├── GuiServer.cpp (GUI 服务)
    └── MountManager.cpp (挂载管理)
```

### 与其他组件的交互

- **与驱动通信**：通过 IOCTL 控制驱动行为
- **与 DLL 通信**：通过命名管道接收沙箱进程请求
- **与 GUI 通信**：通过 LPC/管道接收 GUI 请求

### 已知约束和注意事项

- 服务必须以 SYSTEM 权限运行
- 服务崩溃会导致所有沙箱进程无法正常通信
- 配置文件修改需要通过服务代理以确保一致性

---

## 4. SandMan.exe — Qt GUI (Plus 版)

**路径：** `SandboxiePlus/SandMan/`  
**职责：** 现代化管理界面，提供完整的沙箱管理功能

### 公共接口

通过 QSbieAPI.dll 与核心组件通信，不直接暴露接口。

### 关键类

```cpp
// 主窗口 (SandMan.h)
class CSandMan : public QMainWindow {
    // 沙箱管理
    void OnBoxMenu(const QPoint&);
    void OnBoxCommand(int cmd);
    // 进程管理
    void OnProcMenu(const QPoint&);
    void OnProcCommand(int cmd);
};

// 沙箱模型 (SbieModel.h)
class CSbieModel : public QAbstractItemModel {
    // 数据模型
};
```

### 内部架构

```
main.cpp (入口点)
    ├── SandMan.cpp (主窗口)
    ├── Models/
    │   ├── SbieModel.cpp (沙箱数据模型)
    │   ├── MonitorModel.cpp (监控模型)
    │   └── TraceModel.cpp (追踪模型)
    ├── Forms/ (Qt UI 文件)
    ├── Helpers/ (辅助工具)
    └── Engine/ (脚本引擎)
```

### 与其他组件的交互

- **QSbieAPI**：通过 API 层与驱动和服务通信
- **Qt6**：UI 框架依赖
- **脚本引擎**：支持 JavaScript 扩展

### 已知约束和注意事项

- 需要 Qt 6.8.3 或更高版本
- Windows 7 需要特殊处理（见 `fix_qt6_win7.cmd`）
- 多语言支持通过 `.ts` 文件实现

---

## 5. QSbieAPI.dll — API 封装层

**路径：** `SandboxiePlus/QSbieAPI/`  
**职责：** 提供 Qt/C++ 封装的 API，简化 GUI 开发

### 公共接口

```cpp
// 主 API 类 (SbieAPI.h)
class CSbieAPI : public QThread {
public:
    SB_STATUS Connect(bool takeOver, bool withQueue);
    SB_STATUS Disconnect();
    bool IsConnected() const;
    
    QString GetSbiePath() const;
    QString GetIniPath() const;
    
    SB_STATUS CreateBox(const QString& BoxName, bool bReLoad = true);
    SB_STATUS ReloadBoxes(bool bForceUpdate = false);
    SB_STATUS UpdateProcesses(int iKeep, bool bAllSessions);
    
    QMap<QString, CSandBoxPtr> GetAllBoxes();
    QMap<quint32, CBoxedProcessPtr> GetAllProcesses();
    
    SB_STATUS TerminateAll(bool bNoExceptions = false);
    // ... 更多方法
};
```

### 关键类

```cpp
// 沙箱对象 (SandBox.h)
class CSandBox : public CSbieIni {
    QString GetName() const;
    QString GetFileRoot() const;
    SB_STATUS TerminateAll();
    SB_STATUS CleanBox();
};

// 进程对象 (BoxedProcess.h)
class CBoxedProcess : public QJsonObject {
    quint32 GetProcessId() const;
    QString GetProcessName() const;
    CSandBoxPtr GetBox() const;
};
```

### 与其他组件的交互

- **SbieDll**：通过 `SbieApi_*` 函数通信
- **SbieSvc**：通过 LPC/管道通信
- **Qt**：使用 Qt 的信号槽机制

---

## 6. LowLevel.dll — 低级注入代码

**路径：** `Sandboxie/core/low/`  
**职责：** 在进程启动极早期注入，确保进程从一开始就被隔离

### 公共接口

无导出接口，由驱动直接调用。

### 内部架构

```
init.c (初始化)
    ├── inject.c (注入逻辑)
    ├── entry_asm.asm (x86 入口)
    └── entry_arm.asm (ARM 入口)
```

### 已知约束和注意事项

- 代码必须非常精简，不能依赖任何外部库
- 必须在进程创建的最早阶段执行
- 需要处理不同架构（x86/x64/ARM）的差异

---

## 7. ImBox.exe — 加密沙箱工具

**路径：** `SandboxieTools/ImBox/`  
**职责：** 管理加密沙箱镜像，提供 AES-XTS 加密存储

### 公共接口

```cpp
// ImBox.h
class ImBox {
public:
    bool CreateImage(const wchar_t* path, uint64_t size);
    bool MountImage(const wchar_t* path, const wchar_t* password);
    bool DismountImage();
};
```

### 加密算法

- **AES-XTS**：主要加密算法
- **Serpent**：备选加密算法
- **Twofish**：备选加密算法

### 已知约束和注意事项

- 需要 ImDisk 驱动支持
- 密码丢失无法恢复数据
- 加密操作性能开销较大

---

## 相关文档

- [架构总览](overview.md) — 系统整体架构
- [依赖规则](dependency-rules.md) — 分层依赖规则
- [构建系统](build-system.md) — 构建说明
