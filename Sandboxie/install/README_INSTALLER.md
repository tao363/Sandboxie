# Sandboxie 简化安装包构建说明

## 概述

这是一个简化的 NSIS 安装脚本，用于打包已编译的 Sandboxie x64 版本。

## 前置要求

1. **NSIS 安装器**
   - 下载地址: https://nsis.sourceforge.io/Download
   - 推荐版本: NSIS 3.x
   - 安装后确保 `makensis.exe` 在 PATH 环境变量中

2. **已编译的文件**
   - 路径: `F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\x64\SbieRelease`
   - 必须包含所有核心文件（SbieDrv.sys, SbieDll.dll, SbieSvc.exe 等）

## 使用方法

### 方法 1: 使用批处理脚本（推荐）

```cmd
cd F:\Project\AI\sanbox\Sandboxie\Sandboxie\install
build_installer.bat
```

### 方法 2: 手动编译

```cmd
cd F:\Project\AI\sanbox\Sandboxie\Sandboxie\install
makensis SandboxieSimple.nsi
```

## 输出文件

- **安装包位置**: `F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\x64\SandboxieInstall-5.72.3-x64.exe`
- **文件大小**: 约 2-3 MB（取决于编译配置）

## 安装包功能

### 安装时会执行：

1. ✅ 复制所有核心文件到安装目录
2. ✅ 安装内核驱动 (SbieDrv.sys)
3. ✅ 安装系统服务 (SbieSvc.exe)
4. ✅ 创建开始菜单快捷方式
5. ✅ 写入卸载信息到注册表
6. ✅ 自动启动 Sandboxie 服务

### 卸载时会执行：

1. ✅ 停止并删除服务和驱动
2. ✅ 删除所有安装文件
3. ✅ 删除开始菜单快捷方式
4. ✅ 清理注册表项

## 安装包特点

- **简化版本**: 移除了复杂的多语言支持和升级检测
- **仅支持 x64**: 专为 64 位 Windows 系统设计
- **管理员权限**: 自动请求管理员权限
- **自动检测**: 检测并提示卸载旧版本
- **驱动管理**: 使用 KmdUtil.exe 管理驱动和服务

## 文件清单

安装包会包含以下文件：

### 核心组件
- SbieDrv.sys - 内核驱动
- SbieDll.dll - 注入 DLL
- SbieSvc.exe - 系统服务
- SbieMsg.dll - 消息资源
- SbieCtrl.exe - 控制面板
- Start.exe - 启动器
- SbieIni.exe - 配置工具
- KmdUtil.exe - 驱动管理工具

### COM 服务
- SandboxieRpcSs.exe
- SandboxieDcomLaunch.exe
- SandboxieBITS.exe
- SandboxieCrypto.exe
- SandboxieWUAU.exe

### 配置文件
- Templates.ini - 默认配置模板
- LICENSE.TXT - 许可证
- whatsnew.html - 更新日志
- Manifest0/1/2.txt - 清单文件

## 常见问题

### 1. 找不到 makensis.exe

**解决方案**:
- 安装 NSIS: https://nsis.sourceforge.io/Download
- 或添加 NSIS 到 PATH: `C:\Program Files (x86)\NSIS`

### 2. 找不到编译输出文件

**解决方案**:
```cmd
# 确保已编译 x64 Release 版本
cd F:\Project\AI\sanbox\Sandboxie\Sandboxie
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=x64
```

### 3. 驱动安装失败

**解决方案**:
- 启用测试签名模式:
  ```cmd
  bcdedit /set testsigning on
  bcdedit /set nointegritychecks on
  ```
- 重启计算机

### 4. 服务启动失败

**解决方案**:
- 检查是否有杀毒软件拦截
- 确保以管理员权限运行安装程序
- 查看 Windows 事件查看器中的错误日志

## 测试建议

1. **虚拟机测试**: 建议先在虚拟机中测试安装包
2. **清洁环境**: 在没有安装过 Sandboxie 的系统上测试
3. **升级测试**: 在已安装旧版本的系统上测试升级
4. **卸载测试**: 测试完整的卸载流程

## 与原版脚本的区别

| 特性 | 原版 (SandboxieVS.nsi) | 简化版 (SandboxieSimple.nsi) |
|------|------------------------|------------------------------|
| 多语言支持 | ✅ 30+ 种语言 | ❌ 仅英文和简体中文 |
| 32/64 位 | ✅ 支持双架构 | ❌ 仅 x64 |
| 升级检测 | ✅ 自动检测更新 | ❌ 无 |
| VC 运行库 | ✅ 自动下载安装 | ❌ 需手动安装 |
| 复杂度 | 高 (2000+ 行) | 低 (300+ 行) |
| 适用场景 | 正式发布 | 快速测试/个人使用 |

## 修改版本号

如需修改版本号，编辑 `SandboxieSimple.nsi` 第 14 行：

```nsis
!define VERSION "5.72.3"  ; 修改为你的版本号
```

## 自定义安装目录

默认安装到 `C:\Program Files\Sandboxie`，用户可在安装时选择其他目录。

## 许可证

本脚本基于 Sandboxie 项目，遵循 GPL-3.0 许可证。

## 技术支持

- GitHub: https://github.com/sandboxie-plus/Sandboxie
- 文档: https://sandboxie-plus.com/sandboxie/

---

**注意**: 此简化脚本仅用于快速打包测试，正式发布建议使用原版 `SandboxieVS.nsi` 脚本。
