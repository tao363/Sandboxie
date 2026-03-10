# dll/scm.c 系列 — SCM Hook

拦截 Windows 服务控制管理器 API，防止沙箱进程随意安装/启动系统服务。

## 访问控制策略

| API | 策略 |
|-----|------|
| `OpenSCManager` | 降权句柄（只读）|
| `CreateService` | 默认拒绝 |
| `StartService` | SbieSvc ServiceServer 代理 |
| `QueryServiceStatus` | 允许 |

## MSI 安装

服务二进制写入虚拟文件系统，注册表写入沙箱蜂巢，不影响真实系统服务。
