# Sandboxie 驱动程序 - 注册表模块详细分析

## 概述

注册表模块实现了注册表虚拟化，为每个沙箱提供独立的注册表视图。

## 架构

### Windows XP/2003
- 使用解析过程钩子（Parse Procedure Hook）
- 钩子 `\Registry` 对象类型的解析过程

### Windows Vista+
- 使用注册表回调（Registry Callback）
- 通过 `CmRegisterCallbackEx` 注册

## 主要功能

1. **注册表虚拟化** - 独立的注册表视图
2. **配置单元挂载** - 挂载 Registry.dat 文件
3. **路径重定向** - 重定向到沙箱配置单元
4. **访问控制** - 根据规则控制访问

## 配置单元结构

```
<BoxPath>\Registry.dat
  ├─ HKEY_CURRENT_USER\Sandbox\<BoxName>
  │  ├─ Software
  │  ├─ Environment
  │  └─ ...
  └─ HKEY_LOCAL_MACHINE\Sandbox\<BoxName>
     ├─ Software
     └─ ...
```

## 配置选项

```ini
OpenKeyPath=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer
ClosedKeyPath=HKLM\Software
ReadKeyPath=HKLM\System
WriteKeyPath=HKCU\Software
```

## 关键函数

- `Key_Init()` - 初始化注册表拦截
- `Key_MountHive()` - 挂载配置单元
- `Key_Callback()` - 注册表操作回调
- `Key_InitProcess()` - 初始化进程路径列表

详细分析请参考完整文档。
