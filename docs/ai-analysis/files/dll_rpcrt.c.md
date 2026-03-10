# dll/rpcrt.c — RPC 运行时 Hook

## 概述

`rpcrt.c` 拦截 RPC 运行时（`rpcrt4.dll`）的相关 API，控制沙箱进程的 RPC 端点注册和连接行为，防止通过 RPC 绕过 IPC 隔离。

## 核心 Hook

```c
SBIEDLL_HOOK(Rpc, RpcServerRegisterIf2);     // 阻止注册 RPC 服务端
SBIEDLL_HOOK(Rpc, RpcServerRegisterIf3);
SBIEDLL_HOOK(Rpc, RpcBindingFromStringBindingW); // 控制 RPC 连接目标
SBIEDLL_HOOK(Rpc, NdrClientCall2);           // 拦截 RPC 客户端调用
SBIEDLL_HOOK(Rpc, NdrClientCall3);
```

## 处理逻辑

- `RpcServerRegisterIf`：在沙箱命名空间内注册 RPC 端点，不影响全局 RPC 命名空间
- `RpcBindingFromStringBinding`：检查目标端点是否在允许列表，不允许则返回 `RPC_S_ACCESS_DENIED`
- ALPC 端口 RPC：由 `ipc_port.c` 的 ALPC 回调在内核层控制

## EpMapperServer 关联

`svc/EpMapperServer.cpp` 提供沙箱专属的 RPC 端点映射器（EPMapper）：
- 替代系统的 `\RPC Control\epmapper` 端口
- 维护沙箱内 RPC 服务器的端点注册表
- 允许沙箱内的 RPC 客户端发现沙箱内的 RPC 服务器
