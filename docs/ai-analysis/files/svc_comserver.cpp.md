# svc/comserver.cpp 系列 — COM 代理服务

## 概述

`comserver.cpp` 及相关文件实现 SbieSvc 的 **COM 激活代理**，以 SYSTEM 权限代理激活沙箱进程无法直接访问的 COM 组件。

## 文件组成

| 文件 | 职责 |
|------|------|
| `comserver.cpp` | 主 COM 服务器框架 |
| `comserver2.cpp` | COM 接口代理实现 |
| `comserver9_ie.c` | Internet Explorer COM 兼容 |
| `comserver9_wmp.c` | Windows Media Player COM 兼容 |
| `comserver9.c` | 通用 COM 代理（版本9格式）|

## 工作原理

1. 沙箱进程的 `dll/com.c` 向 SbieSvc 发送 COM 激活请求（含 CLSID、IID）
2. ComServer 在 SbieSvc 进程（SYSTEM 权限）中调用 `CoCreateInstance`
3. 通过自定义 Marshal/Proxy 将接口指针传回沙箱进程
4. 沙箱进程获得接口代理对象，透明调用 COM 方法

## 安全白名单

ComServer 维护允许代理的 CLSID 白名单，未在白名单的 COM 对象拒绝代理：
```cpp
// 白名单示例
static const CLSID AllowedCLSIDs[] = {
    CLSID_WbemLocator,      // WMI
    CLSID_ShellLink,        // 快捷方式
    // ...
};
```
