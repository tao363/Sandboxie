# dll/sbieapi.c — 驱动 API 封装

## 概述

`sbieapi.c` 封装了 SbieDll 与 SbieDrv 之间的所有 IOCTL 通信，提供用户友好的 C 函数接口，对应驱动 `api.c` 中注册的所有功能代码。

## 主要导出函数

| 函数 | 对应驱动 API | 说明 |
|------|------------|------|
| `SbieApi_GetVersion` | `API_GET_VERSION` | 获取驱动版本 |
| `SbieApi_LogMessage` | `API_LOG_MESSAGE` | 写日志 |
| `SbieApi_GetMessage` | `API_GET_MESSAGE` | 读日志 |
| `SbieApi_GetHomePath` | `API_GET_HOME_PATH` | 获取安装路径 |
| `SbieApi_QueryProcessInfo` | `API_QUERY_PROCESS_INFO` | 查询进程沙箱信息 |
| `SbieApi_EnumProcessEx` | `API_ENUM_PROCESSES` | 枚举沙箱进程 |
| `SbieApi_QueryConfBool` | `API_QUERY_CONF` | 查询布尔配置 |
| `SbieApi_QueryConf` | `API_QUERY_CONF` | 查询配置值 |
| `SbieApi_SetConf` | `API_SET_CONF` | 设置配置值 |
| `SbieApi_ReloadConf` | `API_RELOAD_CONF` | 重新加载配置 |
| `SbieApi_IsBoxedProcess` | `API_QUERY_PROCESS` | 检查进程是否沙箱化 |

## 通信机制

```c
// 所有调用最终通过 DeviceIoControl
DeviceIoControl(
    SbieApi_DeviceHandle,   // \Device\SandboxieDriverApi
    API_SBIEDRV_CTLCODE,    // IOCTL 控制码
    args,                   // 输入：ULONG64[API_NUM_ARGS]
    sizeof(args),
    args,                   // 输出：写回 args 数组
    sizeof(args),
    &BytesReturned,
    NULL
);
```

## SbieApi_DeviceHandle

`sbieapi.c` 维护全局设备句柄，在 `SbieApi_Init()` 中打开 `\\.\SandboxieDriverApi`。
