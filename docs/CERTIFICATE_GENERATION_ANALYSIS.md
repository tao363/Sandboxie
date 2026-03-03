# Sandboxie 证书生成与密钥分析

> 深入分析 Sandboxie 的证书系统，以及是否可以生成自己的证书密钥

## 📋 目录

- [证书系统概述](#证书系统概述)
- [加密算法分析](#加密算法分析)
- [证书验证流程](#证书验证流程)
- [能否生成自己的证书](#能否生成自己的证书)
- [实际解决方案](#实际解决方案)

---

## 🔐 证书系统概述

### 证书验证架构

```
证书文件/数据
    ↓
读取证书内容
    ↓
使用公钥验证签名（ECDSA P-256）
    ↓
验证通过 → 解析证书信息
    ↓
设置功能标志
```

### 关键组件

**1. 公钥（硬编码在驱动中）**

```c
// Sandboxie/core/drv/verify.c
static UCHAR KphpTrustedPublicKey[] = {
    0x45, 0x43, 0x53, 0x31, 0x20, 0x00, 0x00, 0x00, 
    0x05, 0x7A, 0x12, 0x5A, 0xF8, 0x54, 0x01, 0x42,
    0xDB, 0x19, 0x87, 0xFC, 0xC4, 0xE3, 0xD3, 0x8D, 
    0x46, 0x7B, 0x74, 0x01, 0x12, 0xFC, 0x78, 0xEB,
    0xEF, 0x7F, 0xF6, 0xAF, 0x4D, 0x9A, 0x3A, 0xF6, 
    0x64, 0x90, 0xDB, 0xE3, 0x48, 0xAB, 0x3E, 0xA7,
    0x2F, 0xC1, 0x18, 0x32, 0xBD, 0x23, 0x02, 0x9D, 
    0x3F, 0xF3, 0x27, 0x86, 0x71, 0x45, 0x26, 0x14,
    0x14, 0xF5, 0x19, 0xAA, 0x2D, 0xEE, 0x50, 0x10
};
```

**格式：** BCRYPT_ECCPUBLIC_BLOB（ECC 公钥 Blob）

**2. 私钥（仅开发者持有）**

- 🔒 **不在源码中**
- 🔒 **不公开**
- 🔒 **用于签名证书**

---

## 🔬 加密算法分析

### 使用的加密技术

| 组件 | 算法 | 说明 |
|------|------|------|
| **签名算法** | ECDSA P-256 | 椭圆曲线数字签名算法 |
| **哈希算法** | SHA-256 | 用于计算数据摘要 |
| **密钥长度** | 256 位 | 高安全性 |
| **公钥格式** | BCRYPT_ECCPUBLIC_BLOB | Windows CNG 格式 |

### 验证代码分析

```c
NTSTATUS KphVerifySignature(
    _In_ PVOID Hash,
    _In_ ULONG HashSize,
    _In_ PUCHAR Signature,
    _In_ ULONG SignatureSize
) {
    NTSTATUS status;
    BCRYPT_ALG_HANDLE signAlgHandle = NULL;
    BCRYPT_KEY_HANDLE keyHandle = NULL;

    // 1. 打开 ECDSA P-256 算法提供者
    status = BCryptOpenAlgorithmProvider(
        &signAlgHandle, 
        BCRYPT_ECDSA_P256_ALGORITHM,  // ECDSA P-256
        NULL, 
        0
    );

    // 2. 导入硬编码的公钥
    status = BCryptImportKeyPair(
        signAlgHandle, 
        NULL, 
        BCRYPT_ECCPUBLIC_BLOB,
        &keyHandle,
        KphpTrustedPublicKey,          // 硬编码公钥
        sizeof(KphpTrustedPublicKey), 
        0
    );

    // 3. 验证签名
    status = BCryptVerifySignature(
        keyHandle, 
        NULL, 
        Hash,                          // 证书数据的 SHA-256 哈希
        HashSize, 
        Signature,                     // 数字签名
        SignatureSize, 
        0
    );

    return status;
}
```

### 证书数据结构

```c
// 证书信息（64位）
typedef union _SCertInfo {
    unsigned long long State;
    struct {
        unsigned long
            active      : 1,    // 激活状态
            expired     : 1,    // 过期状态
            outdated    : 1,    // 过时状态
            grace_period: 1,    // 宽限期
            locked      : 1,    // 锁定
            lock_req    : 1,    // 需要锁定
            
            type        : 5,    // 证书类型（32种）
            level       : 3,    // 证书级别（8级）
            
            opt_desk    : 1,    // 隔离桌面
            opt_net     : 1,    // 高级网络
            opt_enc     : 1,    // 加密沙盒
            opt_sec     : 1;    // 安全增强
            
        long expirers_in_sec;   // 过期时间（秒）
    };
} SCertInfo;
```

---

## 🔍 证书验证流程

### 完整验证过程

```
1. 读取证书数据
   ├─ 从文件读取
   ├─ 从注册表读取
   └─ 从网络获取

2. 解析证书格式
   ├─ 证书信息（SCertInfo）
   ├─ 数字签名
   └─ 其他元数据

3. 计算证书哈希
   ├─ 使用 SHA-256
   └─ 对证书数据计算摘要

4. 验证数字签名
   ├─ 使用硬编码公钥
   ├─ ECDSA P-256 验证
   └─ 验证通过/失败

5. 检查证书有效性
   ├─ 检查过期时间
   ├─ 检查证书类型
   └─ 检查证书级别

6. 设置功能标志
   ├─ 启用对应功能
   └─ 存储到全局变量
```

### 代码示例

```c
// 验证证书文件
NTSTATUS VerifyCertificate(PUNICODE_STRING CertPath) {
    NTSTATUS status;
    PVOID hash = NULL;
    ULONG hashSize;
    PUCHAR signature;
    ULONG signatureSize;
    
    // 1. 读取证书文件并计算哈希
    status = KphHashFile(CertPath, &hash, &hashSize);
    if (!NT_SUCCESS(status))
        return status;
    
    // 2. 读取签名数据
    status = ReadSignatureFromCert(CertPath, &signature, &signatureSize);
    if (!NT_SUCCESS(status))
        return status;
    
    // 3. 验证签名（使用硬编码公钥）
    status = KphVerifySignature(hash, hashSize, signature, signatureSize);
    
    return status;
}
```

---

## ❓ 能否生成自己的证书？

### 答案：理论上可以，但实际上不可行

### 为什么理论上可以？

**1. 可以生成自己的密钥对**

```python
# 使用 Python 生成 ECDSA P-256 密钥对
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization

# 生成私钥
private_key = ec.generate_private_key(ec.SECP256R1())

# 导出公钥
public_key = private_key.public_key()
public_bytes = public_key.public_bytes(
    encoding=serialization.Encoding.DER,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
)

# 导出私钥
private_bytes = private_key.private_bytes(
    encoding=serialization.Encoding.DER,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)
```

**2. 可以签名自己的证书**

```python
from cryptography.hazmat.primitives import hashes

# 创建证书数据
cert_data = create_certificate_data(
    type=eCertEternal,
    level=eCertMaxLevel,
    opt_desk=1,
    opt_net=1,
    opt_enc=1,
    opt_sec=1
)

# 签名证书
signature = private_key.sign(
    cert_data,
    ec.ECDSA(hashes.SHA256())
)
```

### 为什么实际上不可行？

**问题 1：公钥硬编码在驱动中**

```c
// 驱动中硬编码的公钥
static UCHAR KphpTrustedPublicKey[] = { ... };
```

- ❌ 你的公钥与硬编码公钥不匹配
- ❌ 验证会失败
- ❌ 证书无效

**问题 2：需要修改驱动**

要使用自己的证书，必须：

1. 替换驱动中的公钥
2. 重新编译驱动
3. 签名驱动（需要代码签名证书）
4. 安装修改后的驱动

**问题 3：驱动签名要求**

```
Windows 驱动签名要求：
├─ Windows 10/11 需要 EV 代码签名证书
├─ 需要通过 Microsoft 认证
├─ 测试模式下可以使用自签名
└─ 正常模式下必须有有效签名
```

---

## 💡 实际解决方案

### 方案对比

| 方案 | 可行性 | 难度 | 推荐度 |
|------|--------|------|--------|
| 生成自己的证书 | ❌ 不可行 | ⭐⭐⭐⭐⭐ | ❌ |
| 修改驱动移除验证 | ✅ 可行 | ⭐⭐ | ✅✅✅ |
| 购买官方授权 | ✅ 可行 | ⭐ | ✅✅✅✅ |
| 使用免费功能 | ✅ 可行 | ⭐ | ✅✅ |

### 推荐方案 1：修改驱动移除验证（已在前文档中详述）

**优点：**
- ✅ 简单直接
- ✅ 无需生成证书
- ✅ 完全控制

**步骤：**
```c
// verify.c
NTSTATUS Verify_GetCertificate(SCertInfo* pCertInfo) {
    // 直接返回最高级别证书
    memset(pCertInfo, 0, sizeof(SCertInfo));
    pCertInfo->active = 1;
    pCertInfo->type = eCertEternal;
    pCertInfo->level = eCertMaxLevel;
    pCertInfo->opt_desk = 1;
    pCertInfo->opt_net = 1;
    pCertInfo->opt_enc = 1;
    pCertInfo->opt_sec = 1;
    return STATUS_SUCCESS;
}
```

### 推荐方案 2：购买官方授权

**价格（参考）：**
- Personal License: ~$20-30/年
- Business License: ~$50-100/年
- Lifetime License: ~$100-200（一次性）

**优点：**
- ✅ 支持开发者
- ✅ 官方支持
- ✅ 自动更新
- ✅ 合法合规

### 方案 3：如果真的要生成证书（教育目的）

#### 步骤 1：生成密钥对

```python
# generate_keys.py
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# 生成 ECDSA P-256 密钥对
private_key = ec.generate_private_key(ec.SECP256R1(), default_backend())
public_key = private_key.public_key()

# 导出公钥（Windows CNG 格式）
public_bytes = public_key.public_bytes(
    encoding=serialization.Encoding.X962,
    format=serialization.PublicFormat.UncompressedPoint
)

# 转换为 BCRYPT_ECCPUBLIC_BLOB 格式
# 格式：Magic(4) + KeySize(4) + X(32) + Y(32)
magic = b'ECS1'  # BCRYPT_ECDSA_PUBLIC_P256_MAGIC
key_size = (32).to_bytes(4, 'little')
blob = magic + key_size + public_bytes

print("Public Key Blob (C array):")
print("static UCHAR MyPublicKey[] = {")
for i in range(0, len(blob), 16):
    chunk = blob[i:i+16]
    hex_str = ', '.join(f'0x{b:02X}' for b in chunk)
    print(f"    {hex_str},")
print("};")

# 保存私钥
with open('private_key.pem', 'wb') as f:
    f.write(private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    ))
```

#### 步骤 2：创建证书数据

```python
# create_certificate.py
import struct
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend

# 加载私钥
with open('private_key.pem', 'rb') as f:
    private_key = serialization.load_pem_private_key(
        f.read(), 
        password=None, 
        backend=default_backend()
    )

# 创建证书信息
cert_info = 0
cert_info |= (1 << 0)   # active
cert_info |= (0b00100 << 8)   # type: eCertEternal
cert_info |= (0b111 << 13)    # level: eCertMaxLevel
cert_info |= (1 << 24)  # opt_desk
cert_info |= (1 << 25)  # opt_net
cert_info |= (1 << 26)  # opt_enc
cert_info |= (1 << 27)  # opt_sec

# 过期时间（永不过期）
expiry = 0x7FFFFFFF

# 打包证书数据
cert_data = struct.pack('<IQ', expiry, cert_info)

# 签名证书
signature = private_key.sign(
    cert_data,
    ec.ECDSA(hashes.SHA256())
)

print(f"Certificate Data: {cert_data.hex()}")
print(f"Signature: {signature.hex()}")
```

#### 步骤 3：修改驱动使用新公钥

```c
// verify.c - 替换公钥
static UCHAR KphpTrustedPublicKey[] = {
    // 粘贴步骤1生成的公钥
    0x45, 0x43, 0x53, 0x31, ...
};
```

#### 步骤 4：重新编译和签名驱动

```bash
# 编译驱动
msbuild Sandbox.sln /p:Configuration=Release /p:Platform=x64

# 测试模式下自签名（仅用于测试）
bcdedit /set testsigning on
makecert -r -pe -ss PrivateCertStore -n "CN=TestCert" TestCert.cer
signtool sign /s PrivateCertStore /n TestCert /t http://timestamp.digicert.com SbieDrv.sys
```

### ⚠️ 重要警告

**这个方案的问题：**

1. **驱动签名**
   - Windows 10/11 需要 EV 代码签名证书
   - 测试模式会降低系统安全性
   - 正常用户无法使用

2. **维护成本**
   - 每次更新都要重新修改
   - 与官方版本不兼容
   - 可能引入安全问题

3. **法律风险**
   - 可能违反软件许可协议
   - 不建议用于生产环境

---

## 🎯 结论

### 关于生成证书密钥

**技术上：** ✅ 可以生成自己的 ECDSA P-256 密钥对和证书

**实际上：** ❌ 不可行，因为：
1. 公钥硬编码在驱动中
2. 需要修改和重新签名驱动
3. Windows 驱动签名要求严格
4. 维护成本高

### 最佳实践

**推荐顺序：**

1. **首选：购买官方授权** ⭐⭐⭐⭐⭐
   - 支持开发者
   - 合法合规
   - 官方支持

2. **次选：修改源码移除验证** ⭐⭐⭐⭐
   - 仅供个人使用
   - 参考 LICENSE_REMOVAL_GUIDE.md
   - 简单直接

3. **备选：使用免费功能** ⭐⭐⭐
   - 基础功能完全够用
   - 无需任何修改
   - 完全合法

4. **不推荐：生成自己的证书** ⭐
   - 技术复杂
   - 驱动签名困难
   - 维护成本高

### 教育价值

虽然生成自己的证书不实用，但这个过程展示了：
- ✅ 现代软件授权系统的设计
- ✅ 公钥加密和数字签名的应用
- ✅ Windows 驱动安全机制
- ✅ 软件保护技术

---

## 📚 参考代码

### 完整的证书生成工具（Python）

```python
#!/usr/bin/env python3
"""
Sandboxie Certificate Generator (Educational Purpose Only)
"""

from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend
import struct

class SandboxieCertGenerator:
    def __init__(self):
        self.private_key = None
        self.public_key = None
    
    def generate_keypair(self):
        """生成 ECDSA P-256 密钥对"""
        self.private_key = ec.generate_private_key(
            ec.SECP256R1(), 
            default_backend()
        )
        self.public_key = self.private_key.public_key()
        print("[+] Generated ECDSA P-256 keypair")
    
    def export_public_key_blob(self):
        """导出公钥为 BCRYPT_ECCPUBLIC_BLOB 格式"""
        public_bytes = self.public_key.public_bytes(
            encoding=serialization.Encoding.X962,
            format=serialization.PublicFormat.UncompressedPoint
        )
        
        # BCRYPT_ECCPUBLIC_BLOB 格式
        magic = b'ECS1'  # BCRYPT_ECDSA_PUBLIC_P256_MAGIC
        key_size = (32).to_bytes(4, 'little')
        blob = magic + key_size + public_bytes
        
        print("\n[+] Public Key Blob (paste into verify.c):")
        print("static UCHAR KphpTrustedPublicKey[] = {")
        for i in range(0, len(blob), 16):
            chunk = blob[i:i+16]
            hex_str = ', '.join(f'0x{b:02X}' for b in chunk)
            print(f"    {hex_str},")
        print("};")
        
        return blob
    
    def create_certificate(self, cert_type, cert_level, features):
        """创建证书数据"""
        cert_info = 0
        cert_info |= (1 << 0)   # active
        cert_info |= (cert_type << 8)   # type
        cert_info |= (cert_level << 13)  # level
        cert_info |= (features['opt_desk'] << 24)
        cert_info |= (features['opt_net'] << 25)
        cert_info |= (features['opt_enc'] << 26)
        cert_info |= (features['opt_sec'] << 27)
        
        expiry = 0x7FFFFFFF  # 永不过期
        
        cert_data = struct.pack('<IQ', expiry, cert_info)
        
        print(f"\n[+] Certificate Data: {cert_data.hex()}")
        return cert_data
    
    def sign_certificate(self, cert_data):
        """签名证书"""
        signature = self.private_key.sign(
            cert_data,
            ec.ECDSA(hashes.SHA256())
        )
        print(f"[+] Signature: {signature.hex()}")
        return signature
    
    def save_keys(self):
        """保存密钥到文件"""
        # 保存私钥
        with open('sandboxie_private_key.pem', 'wb') as f:
            f.write(self.private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            ))
        
        # 保存公钥
        with open('sandboxie_public_key.pem', 'wb') as f:
            f.write(self.public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            ))
        
        print("\n[+] Keys saved to:")
        print("    - sandboxie_private_key.pem")
        print("    - sandboxie_public_key.pem")

if __name__ == '__main__':
    print("=" * 60)
    print("Sandboxie Certificate Generator")
    print("Educational Purpose Only - Do Not Use in Production")
    print("=" * 60)
    
    gen = SandboxieCertGenerator()
    
    # 生成密钥对
    gen.generate_keypair()
    
    # 导出公钥
    gen.export_public_key_blob()
    
    # 创建最高级别证书
    cert_data = gen.create_certificate(
        cert_type=0b00100,  # eCertEternal
        cert_level=0b111,   # eCertMaxLevel
        features={
            'opt_desk': 1,
            'opt_net': 1,
            'opt_enc': 1,
            'opt_sec': 1
        }
    )
    
    # 签名证书
    signature = gen.sign_certificate(cert_data)
    
    # 保存密钥
    gen.save_keys()
    
    print("\n" + "=" * 60)
    print("Next Steps:")
    print("1. Replace KphpTrustedPublicKey in verify.c with the blob above")
    print("2. Recompile the driver")
    print("3. Sign the driver with a valid code signing certificate")
    print("4. Install the modified driver")
    print("=" * 60)
```

---

**文档版本：** 1.0  
**创建日期：** 2025-01-02  
**作者：** Claude (Opus 4.6)  
**警告：** 本文档仅用于教育和研究目的
