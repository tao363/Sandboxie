# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sandboxie Plus/Classic is a sandbox-based isolation software for Windows that creates secure operating environments. The project consists of two editions sharing the same core:
- **Sandboxie Classic**: MFC-based UI (legacy, no longer actively developed)
- **Sandboxie Plus**: Modern Qt-based UI with additional features

## Core Architecture

The core of Sandboxie consists of three critical components that work together:

1. **SbieDrv** (Sandboxie/core/drv) - Kernel-mode driver that intercepts system calls
2. **SbieSvc** (Sandboxie/core/svc) - Windows service that manages sandboxes and communicates with the driver
3. **SbieDll** (Sandboxie/core/dll) - Injection DLL that hooks into every process running in a sandbox

Additional key components:
- **LowLevel** (Sandboxie/core/low) - Low-level DLL used for code injection, embedded as a resource in SbieSvc.exe
- **SbieCtrl** (Sandboxie/apps/control) - Classic UI control application
- **SandMan** (SandboxiePlus/SandMan) - Plus UI main application
- **QSbieAPI** (SandboxiePlus/QSbieAPI) - Qt-based API wrapper for communicating with Sandboxie service
- **SbieShell** (SandboxiePlus/SbieShell) - Shell extension for Windows Explorer integration
- **SboxHostDll** (Sandboxie/SboxHostDll) - Host injection DLL for redirecting host processes (e.g., MS Office ClickToRun)

## Build System Requirements

- **Visual Studio 2019** (for Windows 7-11 compatibility)
- **Windows 10 SDK 10.0.19041**
- **WDK (Windows Driver Kit) for Windows 10, version 2004 (10.0.19041)**
- **Qt Framework**: 5.15.15 (Windows 7+ support) or 6.x (Windows 10+, required for ARM64)
- **Qt Visual Studio Tools** extension
- **Jom** (parallel make tool for Qt)

## Build Commands

### Building Sandboxie Classic

Build order matters - for x64 builds, compile Win32 components first:

```cmd
# 1. Build x86 DLLs and service (required even for x64 builds)
msbuild /t:build Sandboxie\SandboxDll.sln /p:Configuration="SbieRelease" /p:Platform=Win32 -maxcpucount:8

# 2. Build x64 components
msbuild /t:build Sandboxie\Sandbox.sln /p:Configuration="SbieRelease" /p:Platform=x64 -maxcpucount:8

# 3. Build x64 driver
msbuild /t:build Sandboxie\SandboxDrv.sln /p:Configuration="SbieRelease" /p:Platform=x64 -maxcpucount:8
```

Note: For x64 builds, you must first compile `Sandboxie/core/low` (LowLevel) for Win32.

### Building Sandboxie Plus

```cmd
# Build Qt-based UI (automatically builds all dependencies)
SandboxiePlus\qmake_plus.cmd x64 build_qt6

# Build shell extension
msbuild /t:restore,build -p:RestorePackagesConfig=true SandboxiePlus\SbieShell\SbieShell.sln /p:Configuration="Release" /p:Platform=x64
```

The qmake_plus.cmd script builds in order:
1. UGlobalHotkey (global hotkey support)
2. QtSingleApp (single instance application)
3. MiscHelpers (utility library)
4. QSbieAPI (Sandboxie API wrapper)
5. SandMan (main UI application)

### Building SandboxieTools

```cmd
msbuild /t:build SandboxieTools\SandboxieTools.sln /p:Configuration="Release" /p:Platform=x64 -maxcpucount:8
```

### Creating Installers

After building both Classic and Plus:

```cmd
# Merge builds and prepare installer assets
Installer\copy_build.cmd x64 build_qt6
Installer\get_openssl.cmd
Installer\get_7zip.cmd
Installer\get_assets.cmd
```

## Development Setup

To run unsigned builds during development:

1. Enable Windows test signing mode:
   ```cmd
   bcdedit /set testsigning on
   ```
2. Reboot the system
3. Run SandMan.exe and use Maintenance menu to install/start components
4. When the driver detects test mode, it disables signature verification (no .sig files needed)

## Project Structure

```
Sandboxie/              # Classic edition (C/C++, MFC)
├── core/
│   ├── drv/           # Kernel driver (SbieDrv.sys)
│   ├── svc/           # Service (SbieSvc.exe)
│   ├── dll/           # Injection DLL (SbieDll.dll)
│   └── low/           # Low-level injection (LowLevel.dll)
├── apps/
│   ├── control/       # Classic UI (SbieCtrl.exe)
│   ├── start/         # Start utility (Start.exe)
│   ├── ini/           # INI utility (SbieIni.exe)
│   └── com/           # COM wrappers (BITS, Crypto, RpcSs, WUAU, DcomLaunch)
├── install/           # Installation utilities and templates
└── msgs/              # Message files and localization

SandboxiePlus/         # Plus edition (Qt-based)
├── SandMan/           # Main UI application
├── QSbieAPI/          # Qt API wrapper
├── MiscHelpers/       # Utility library
├── QtSingleApp/       # Single instance support
├── UGlobalHotkey/     # Global hotkey support
└── SbieShell/         # Shell extension

SandboxieTools/        # Additional tools
├── ImBox/             # ImDisk-based encrypted sandbox
├── ImDisk/            # ImDisk driver
└── UpdUtil/           # Update utility

Installer/             # Build scripts and installer creation
```

## Configuration Files

- **Sandboxie.ini** - Main configuration file for sandboxes (user-editable)
- **Templates.ini** - Sandbox templates for application compatibility
- **buildVariables.cmd** - Build configuration (Qt version, OpenSSL version, etc.)

## Multi-Architecture Support

Sandboxie supports multiple architectures:
- **x86** (Win32) - 32-bit Windows
- **x64** - 64-bit Windows (requires x86 components for WOW64 processes)
- **ARM64** - ARM64 Windows (requires Qt 6.x, also needs ARM64EC build of SbieDll)

## Language Files

Translation files are located in:
- `SandboxiePlus/SandMan/sandman_*.ts` - Qt translation files for Plus UI
- `Sandboxie/msgs/` - Message files for Classic and core components

To update translation files:
```cmd
lupdate SandboxiePlus/SandMan/SandMan.pro
```

## Testing and Debugging

- Use `bcdedit /set testsigning on` to run unsigned driver builds
- Enable Debug tab in Sandboxie Plus: see issue #2134
- Trace logs: see issue #1208 for instructions
- Use Process Monitor (Procmon) to track file and registry access
- LogApiDll tool provides verbose API call logging

## Important Notes

- Always build x86 components before x64 when doing full builds
- The driver requires EV code signing certificate for production releases
- Test mode disables driver signature verification for development
- Qt 5.15.15 supports Windows 7+, Qt 6.x requires Windows 10+ (unless patched)
- The project uses Visual Studio 2019 for maximum compatibility (Windows 7-11)
