# svc/iphlpserver.cpp — IP Helper 代理

## 概述

`iphlpserver.cpp` 代理沙箱进程的 IP Helper API 调用（`GetAdaptersInfo`、`GetIpForwardTable` 等），可过滤或修改返回的网络配置信息。

## 消息处理

| 消息 ID | 功能 |
|--------|------|
| `MSGID_IPHLP_GET_ADAPTERS_INFO` | 获取网络适配器信息 |
| `MSGID_IPHLP_GET_ADAPTERS_ADDRESSES` | 获取适配器地址 |
| `MSGID_IPHLP_GET_ROUTE_TABLE` | 获取路由表 |

## 网络信息过滤

当配置 `HideNetworkAdapters=y` 时，返回虚假的网络接口信息，防止沙箱程序枚举真实网络拓扑。

## netapiserver.cpp

`netapiserver.cpp` 类似地代理 NetAPI 函数（`NetShareEnum`、`NetUserEnum` 等），防止沙箱进程枚举网络资源。
