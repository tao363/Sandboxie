# dll/net.c — 网络 Hook

拦截网络相关 API，实现沙箱进程的网络访问控制。

## 核心 Hook

```c
SBIEDLL_HOOK(Net, WSAStartup);      // 初始化拦截
SBIEDLL_HOOK(Net, connect);         // TCP 连接控制
SBIEDLL_HOOK(Net, WSAConnect);
SBIEDLL_HOOK(Net, getaddrinfo);     // DNS 解析控制
SBIEDLL_HOOK(Net, GetAdaptersInfo); // 网络接口信息
```

## dns_filter.c

`dns_filter.c` 实现 DNS 过滤功能（`DnsBlock` 配置项）：
- Hook `DnsQuery_W` 等 DNS API
- 根据 `DnsBlock=domain.com` 规则阻止特定域名解析
- 返回 `WSAHOST_NOT_FOUND` 模拟域名不存在

## 网络访问控制层次

1. **驱动层（WFP）**：内核级，不可绕过，控制 TCP/IP 连接
2. **用户态（net.c）**：Winsock API 层，提供更细粒度的 DNS/接口控制

## iphlp.c

`iphlp.c` 拦截 IP Helper API（`GetAdaptersAddresses` 等），过滤或修改网络接口信息，防止泄露真实网络配置。
