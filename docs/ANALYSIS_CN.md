# Sandboxie 项目深度分析

> 本文档提供 Sandboxie 项目的全面技术分析，包括架构、原理和实现细节。

## 📦 项目概述

Sandboxie 是一个 **Windows 沙盒隔离软件**，用于在隔离的虚拟环境中运行程序，保护系统不受不信任软件的影响。

### 主要用途

- 🔒 **安全测试** - 在隔离环境中测试未知或不信任的程序
- 🌐 **安全浏览** - 隔离浏览器，防止恶意网站影响系统
- 🛡️ **防止感染** - 阻止恶意软件修改系统文件和注册表
- 🔬 **软件测试** - 测试软件安装/卸载而不影响真实系统
- 🎮 **多开应用** - 在不同沙盒中运行同一程序的多个实例

### 项目历史

| 时间线 | 维护者 |
|--------|--------|
| 2004 - 2013 | Ronen Tzur |
| 2013 - 2017 | Invincea Inc. |
| 2017 - 2020 | Sophos Group plc |
| 2020年4月8日 | Sophos 开源 |
| 2020年4月9日至今 | David Xanatos（社区分支） |

---

## 🏗️ 核心架构

Sandboxie 采用 **内核驱动 + 用户态DLL注入** 的多层架构：

```
┌─────────────────────────────────────┐
│      应用程序（被沙盒化）              │
├─────────────────────────────────────┤
│   SbieDll.dll（API Hook层）          │
│   - Hook Windows API                │
│   - 路径重定向                       │
├─────────────────────────────────────┤
│   用户态 ↕ 内核态                    │
├─────────────────────────────────────┤
│   SbieDrv.sys（内核驱动）            │
│   - 系统调用拦截                     │
│   - 文件系统过滤                     │
│   - 注册表虚拟化                     │
├─────────────────────────────────────┤
│   Windows 内核                       │
└─────────────────────────────────────┘
```

### 1. 内核层（Driver）

**核心组件：** `SbieDrv.sys`（内核驱动）  
**位置：** `Sandboxie/core/drv/`

**工作机制：**
- **系统调用拦截（Syscall Hooking）** - 拦截所有系统调用（NtCreateFile、NtSetValueKey等）
- **文件系统重定向** - 将文件操作重定向到沙盒目录
- **注册表虚拟化** - 创建虚拟注册表视图
- **进程隔离** - 控制进程创建和访问权限
- **IPC拦截** - 拦截进程间通信

**关键文件：**
- `driver.c` - 驱动入口和初始化
- `syscall.c` - 系统调用拦截管理
- `process.c` - 进程管理和隔离
- `file.c` - 文件系统重定向
- `key.c` - 注册表虚拟化
- `hook.c` - 内核函数 Hook

### 2. 用户态层（DLL）

**核心组件：** `SbieDll.dll`（注入DLL）  
**位置：** `Sandboxie/core/dll/`

**工作机制：**
- **DLL注入** - 在进程启动时注入到目标进程
- **API Hook** - Hook Windows API函数（CreateFile、RegSetValue等）
- **路径转换** - 将真实路径转换为沙盒路径
- **资源重定向** - 重定向文件、注册表、对象访问

**关键文件：**
- `dllmain.c` - DLL 入口和初始化
- `file.c` - 文件操作 Hook
- `key.c` - 注册表操作 Hook
- `proc.c` - 进程操作 Hook
- `gui.c` - GUI 相关 Hook
- `ldr.c` - 加载器和注入逻辑

### 3. 服务层（Service）

**核心组件：** `SbieSvc.exe`（系统服务）  
**位置：** `Sandboxie/core/svc/`

**功能：**
- 管理沙盒配置
- 协调驱动和用户态组件
- 处理权限提升请求
- 文件恢复服务
- 进程监控和管理

### 4. 界面层（GUI）

**Plus版本：** `SandMan.exe`（Qt界面）  
**Classic版本：** `SbieCtrl.exe`（MFC界面）  
**位置：** `SandboxiePlus/SandMan/`

---

## 🔧 核心技术原理

### 文件系统隔离

**Copy-on-Write 机制：**

```
真实路径：C:\Users\User\Documents\file.txt
沙盒路径：C:\Sandbox\DefaultBox\user\current\Documents\file.txt
```

**工作流程：**
1. 应用程序尝试写入 `C:\Users\User\Documents\file.txt`
2. SbieDll.dll 拦截 CreateFile API
3. 检查文件是否已在沙盒中
4. 如果不存在，从真实位置复制到沙盒
5. 重定向操作到沙盒路径
6. 返回沙盒文件句柄

**读操作优先级：**
- 先查沙盒目录
- 如果不存在，再查真实系统
- 透明合并两个视图

### 注册表虚拟化

**虚拟注册表键：**

```
真实键：HKEY_CURRENT_USER\Software\App
沙盒键：HKEY_USERS\Sandbox_<SID>_DefaultBox\Software\App
```

**实现方式：**
- Hook 注册表 API（RegCreateKey、RegSetValue等）
- 创建独立的注册表 Hive
- 合并真实注册表和沙盒注册表的视图
- 写操作重定向到沙盒 Hive

### 进程隔离

**令牌（Token）修改：**
- 降低进程权限级别
- 移除敏感权限（SeDebugPrivilege等）
- 添加限制性 SID
- 创建独立的安全上下文

**访问控制：**
- 限制访问系统进程
- 阻止跨沙盒进程通信
- 控制对系统资源的访问
- 防止提权操作

### 系统调用拦截

**拦截流程：**

```
应用程序调用 NtCreateFile
    ↓
NTDLL.dll 中的 NtCreateFile
    ↓
被 Hook 重定向到 SbieDll.dll
    ↓
SbieDll 检查并修改参数
    ↓
通过 NtDeviceIoControlFile 发送到驱动
    ↓
SbieDrv.sys 验证并执行
    ↓
返回结果给应用程序
```

**Hook 技术：**
- 用户态：修改 NTDLL 导出表或函数入口
- 内核态：修改 SSDT（System Service Descriptor Table）
- 使用 Detour 技术保存原始函数

---

## 🔬 汇编代码的关键作用

Sandboxie 中的汇编代码是整个沙盒隔离机制的底层基础，处理 C/C++ 无法高效或无法实现的关键任务。

### 1. 代码注入与启动（entry_asm.asm）

**作用：** 实现 DLL 注入的入口点

**关键代码：**
```asm
_Start:
    sub rsp, 28h        ; 标准栈帧
    call $+5            ; 获取当前 RIP
_001:
    pop rcx
    add rcx, offset SbieLowData - _001
    call EntrypointC    ; 调用 C 初始化
    jmp rax             ; 跳转到 LdrInitializeThunk
```

**为什么需要汇编：**
- 注入的代码以 Shellcode 方式执行（不是正常加载的 DLL）
- 需要在任意内存地址执行（位置无关代码）
- 必须手动设置栈帧和寄存器
- C 代码无法精确控制这些底层细节

### 2. 系统调用拦截（_SystemService）

**作用：** 拦截所有 Windows 系统调用

**工作原理：**
```asm
_SystemService:
    mov rax, [SbieLowData]      ; 获取沙盒数据
    mov qword ptr [rcx+1*8], r10 ; 保存系统调用号
    call NtDeviceIoControlFile   ; 通过驱动处理
```

**为什么需要汇编：**
- 系统调用使用特殊的 syscall/sysenter 指令
- 需要精确控制寄存器状态（r10, rax, rcx 等）
- 必须保持调用约定（x64 fastcall）
- 性能关键路径，汇编效率最高

### 3. 函数 Hook 与 Detour（_DetourCode）

**作用：** 劫持 Windows API 函数

**实现方式：**
```asm
_DetourCode:
    mov rax, qword ptr [inject_data_area]
    call DetourFunc              ; 调用 Hook 处理
    jmp [RtlFindActCtx]         ; 跳转到原始函数
```

**Hook 技术：**
- 修改目标函数前几个字节为 `jmp _DetourCode`
- 保存原始指令到 trampoline
- 执行自定义逻辑后跳回原函数

### 4. 内核级操作（util_asm.asm）

**作用：** 执行特权指令

**关键功能：**
```asm
DisableWriteProtect:
    mov rax, cr0
    and eax, not 10000h  ; 清除 WP 位
    mov cr0, rax         ; 允许写入只读内存
    ret
```

**应用场景：**
- 修改内核内存保护
- 实现内核级 Hook
- CPUID 检测（反虚拟机检测）
- 获取当前进程结构

### 5. 架构兼容性

项目包含多个架构的汇编实现：
- `util_32.asm` - x86 32位
- `util_64.asm` - x64 64位
- `util_arm.asm` - ARM64
- `util_EC.asm` - ARM64EC（模拟兼容）

### 汇编代码重要性评估

| 组件 | 汇编文件 | 关键性 |
|------|---------|--------|
| 代码注入 | entry_asm.asm | ⭐⭐⭐⭐⭐ 核心 |
| 系统调用拦截 | _SystemService | ⭐⭐⭐⭐⭐ 核心 |
| 函数 Hook | _DetourCode | ⭐⭐⭐⭐⭐ 核心 |
| 内核操作 | util_asm.asm | ⭐⭐⭐⭐ 重要 |
| RPC 拦截 | util_64.asm | ⭐⭐⭐⭐ 重要 |
| 加密优化 | aes_*.asm | ⭐⭐⭐ 性能 |

---

## 🦀 使用 Rust 重写的可行性分析

### 可以用 Rust 替代的部分（60-70%）

#### 1. 内联汇编

Rust 从 1.59 版本开始支持稳定的内联汇编：

```rust
use core::arch::asm;

#[cfg(target_arch = "x86_64")]
unsafe fn disable_write_protect() {
    asm!(
        "mov {tmp}, cr0",
        "and {tmp}, {mask}",
        "mov cr0, {tmp}",
        tmp = out(reg) _,
        mask = in(reg) !0x10000u64,
        options(nostack, preserves_flags)
    );
}
```

#### 2. 函数 Hook 框架

```rust
struct FunctionHook {
    target: *mut u8,
    detour: *const u8,
    original_bytes: Vec<u8>,
}

impl FunctionHook {
    unsafe fn install(&mut self) -> Result<(), &'static str> {
        // 保存原始字节
        self.original_bytes = std::slice::from_raw_parts(
            self.target, 14
        ).to_vec();
        
        // 写入跳转指令
        let jump_code = self.create_absolute_jump(self.detour);
        self.make_writable()?;
        ptr::copy_nonoverlapping(
            jump_code.as_ptr(),
            self.target,
            jump_code.len()
        );
        
        Ok(())
    }
}
```

#### 3. 加密算法（SIMD）

```rust
#[cfg(target_arch = "x86_64")]
use core::arch::x86_64::*;

#[target_feature(enable = "aes")]
unsafe fn aes_encrypt_block(block: &mut [u8; 16], keys: &[[u8; 16]]) {
    let mut state = _mm_loadu_si128(block.as_ptr() as *const __m128i);
    
    for i in 1..10 {
        state = _mm_aesenc_si128(state, 
            _mm_loadu_si128(keys[i].as_ptr() as *const __m128i));
    }
    
    _mm_storeu_si128(block.as_mut_ptr() as *mut __m128i, state);
}
```

### 难以用 Rust 替代的部分（30-40%）

#### 1. Shellcode 注入入口

**问题：**
- Rust 无法保证生成完全位置无关的代码
- 编译器会插入额外代码（栈检查、panic handler）
- 需要精确的内存布局控制

**解决方案：** 使用 `#[naked]` 函数（不稳定特性）

```rust
#![feature(naked_functions)]

#[naked]
#[no_mangle]
unsafe extern "C" fn injection_entry() {
    asm!(
        "call get_pc",
        "get_pc:",
        "pop rcx",
        "call EntrypointC",
        "jmp rax",
        options(noreturn)
    );
}
```

#### 2. 内核驱动代码

**问题：**
- 微软不官方支持 Rust 内核驱动
- 缺少 WDK（Windows Driver Kit）绑定
- 内核 ABI 不稳定

**现状：**
- 微软正在实验性支持 Rust 驱动（2023+）
- 需要大量 unsafe 代码和 FFI

#### 3. 精确的寄存器控制

某些场景需要精确控制所有寄存器，即使用内联汇编也难以保证编译器不破坏寄存器状态。

### 混合方案：Rust + 汇编

最实际的方案是 **Rust 为主，关键部分保留汇编**：

```
sandboxie-rs/
├── src/
│   ├── lib.rs           # Rust 主代码
│   ├── hook.rs          # Hook 框架
│   ├── sandbox.rs       # 沙盒逻辑
│   └── syscall.rs       # 系统调用处理
├── asm/
│   ├── entry_x64.asm    # 注入入口（必须汇编）
│   ├── syscall_x64.asm  # 系统调用（必须汇编）
│   └── detour_x64.asm   # Detour 代码（可选汇编）
└── driver/
    └── src/
        └── lib.rs       # 驱动代码（实验性 Rust）
```

### Rust vs 汇编对比

| 功能 | 纯汇编 | Rust 内联汇编 | 纯 Rust | 推荐方案 |
|------|--------|--------------|---------|---------|
| 代码注入入口 | ✅ 完美 | ⚠️ 困难 | ❌ 不可行 | **汇编** |
| 系统调用拦截 | ✅ 完美 | ✅ 可行 | ❌ 不可行 | **Rust 内联汇编** |
| 函数 Hook | ✅ 完美 | ✅ 可行 | ⚠️ 部分可行 | **Rust + 汇编** |
| 内核操作 | ✅ 完美 | ✅ 可行 | ❌ 不可行 | **Rust 内联汇编** |
| 加密算法 | ✅ 最快 | ✅ 接近 | ✅ 可行 | **Rust SIMD** |
| 业务逻辑 | ❌ 繁琐 | ⚠️ 复杂 | ✅ 完美 | **纯 Rust** |
| 内核驱动 | ✅ 成熟 | ⚠️ 实验性 | ⚠️ 实验性 | **C/C++（暂时）** |

### 结论

**可以用 Rust 重写 Sandboxie，但需要混合方案：**

**推荐架构：**
- 70% Rust 代码（业务逻辑、Hook 框架、配置管理）
- 20% Rust 内联汇编（系统调用、内核操作）
- 10% 纯汇编（注入入口、关键 Shellcode）

**优势：**
- ✅ 内存安全（减少漏洞）
- ✅ 现代工具链（Cargo、测试、文档）
- ✅ 更好的可维护性
- ✅ 跨平台潜力

**挑战：**
- ⚠️ 内核驱动支持不成熟
- ⚠️ 需要大量 unsafe 代码
- ⚠️ 学习曲线陡峭
- ⚠️ 生态系统不如 C/C++

---

## 🎯 实现效果

### 安全隔离

- ✅ 沙盒内程序无法修改真实系统文件
- ✅ 无法修改真实注册表
- ✅ 无法访问其他进程内存
- ✅ 可选择性阻止网络访问

### 高级功能（Plus版本）

- **快照管理** - 保存/恢复沙盒状态
- **加密沙盒** - AES加密保护数据
- **网络防火墙** - 基于WFP的网络过滤
- **隐私模式** - 防止数据泄露
- **安全增强** - 限制系统调用
- **DNS控制** - 阻止/重定向DNS查询
- **内存限制** - 限制进程内存使用
- **SOCKS5代理** - 强制使用代理

### 实用特性

- 文件恢复 - 从沙盒恢复需要的文件
- 自动删除 - 关闭后自动清理沙盒
- 模板系统 - 预配置常用程序
- 多沙盒 - 创建无限个独立沙盒
- 便携模式 - 无需安装即可使用

---

## 📚 参考资源

### 官方资源
- [GitHub 仓库](https://github.com/sandboxie-plus/Sandboxie)
- [官方文档](https://sandboxie-plus.github.io/sandboxie-docs)
- [Discord 社区](https://discord.gg/S4tFu6Enne)

### 相关项目
- [windows-kernel-rs](https://github.com/not-matthias/windows-kernel-rs) - Rust 内核驱动框架
- [retour-rs](https://github.com/Hpmason/retour-rs) - Rust 函数 Hook 库
- [detour](https://github.com/darfink/detour-rs) - 另一个 Hook 库
- [winapi-rs](https://github.com/retep998/winapi-rs) - Windows API 绑定

---

## 📝 分析总结

Sandboxie 是一个技术上非常成熟和复杂的系统级安全软件，通过以下核心技术实现了完整的应用程序隔离：

1. **内核驱动** - 在最底层拦截系统调用
2. **DLL 注入** - 在用户态 Hook API 函数
3. **汇编代码** - 处理底层操作和性能关键路径
4. **文件/注册表虚拟化** - 创建隔离的运行环境
5. **进程隔离** - 限制沙盒程序的权限和访问

这是 Windows 平台上最强大的沙盒解决方案之一，其设计和实现值得深入学习。

---

**文档版本：** 1.0  
**创建日期：** 2026-03-02  
**分析工具：** Claude (Opus 4.6)
