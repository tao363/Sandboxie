# Sandboxie 驱动程序 - 文件系统模块详细分析

## 概述

文件系统模块实现了文件系统虚拟化，通过拦截文件操作并重定向到沙箱目录，实现写时复制（Copy-on-Write）机制。

## 架构

### Windows XP/2003
- 使用解析过程钩子（Parse Procedure Hook）
- 钩子 `\FileSystem` 对象类型的解析过程

### Windows Vista+
- 使用文件系统微过滤器（Minifilter）
- 注册为文件系统过滤驱动

## 主要功能

1. **文件系统虚拟化** - 提供独立的文件系统视图
2. **写时复制** - 首次写入时复制文件到沙箱
3. **路径重定向** - 将访问重定向到沙箱目录
4. **访问控制** - 根据规则允许或拒绝访问
5. **特殊文件处理** - 命名管道、邮槽、网络文件

## 关键文件

- `file.c/h` - 文件系统核心
- `file_flt.c` - 微过滤器实现（Vista+）
- `file_xp.c` - 解析过程钩子（XP）
- `file_xlat.c` - 路径转换
- `file_ctrl.c` - 文件控制操作

## 路径转换示例

```
真实路径: C:\Windows\System32\notepad.exe
沙箱路径: <BoxPath>\drive\C\Windows\System32\notepad.exe

真实路径: \\Server\Share\file.txt
沙箱路径: <BoxPath>\share\Server\Share\file.txt
```

## 配置选项

```ini
OpenFilePath=%USERPROFILE%\Downloads    # 直接访问
ClosedFilePath=C:\Windows\System32      # 拒绝访问
ReadFilePath=C:\Program Files           # 只读访问
WriteFilePath=C:\ProgramData            # 写入重定向
```

详细分析请参考完整文档。
