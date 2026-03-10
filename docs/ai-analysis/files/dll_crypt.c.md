# dll/crypt.c — 加密 API Hook

## 概述

`crypt.c` 拦截 Windows 加密 API（CryptoAPI / CNG），处理沙箱进程访问证书存储、密钥容器等加密资源的请求。

## 核心 Hook

```c
SBIEDLL_HOOK(Crypt, CertOpenStore);           // 证书存储访问控制
SBIEDLL_HOOK(Crypt, CertOpenSystemStoreW);    // 系统证书存储
SBIEDLL_HOOK(Crypt, CryptAcquireContextW);    // 密钥容器访问
```

## 处理逻辑

- `CertOpenStore(CERT_STORE_PROV_SYSTEM)`：重定向到沙箱内的证书存储（注册表虚拟化已覆盖大部分场景，此处补充特殊路径）
- `CryptAcquireContext`：密钥容器文件路径重定向到沙箱文件系统
- 保证沙箱进程的证书操作（安装/删除证书）不影响真实系统证书存储

## cred.c — 凭据 Hook

`cred.c` 拦截 Windows 凭据管理器 API：
```c
SBIEDLL_HOOK(Cred, CredWriteW);    // 阻止写入系统凭据
SBIEDLL_HOOK(Cred, CredReadW);     // 凭据读取控制
SBIEDLL_HOOK(Cred, CredDeleteW);   // 阻止删除系统凭据
```

配置 `OpenCredentials=y` 时允许沙箱进程访问真实凭据；默认情况下凭据读写被重定向到沙箱注册表虚拟区域。
