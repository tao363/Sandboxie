# Certificate.dat 文件格式分析

## 📄 Certificate.dat 是什么？

**Certificate.dat** 是 Sandboxie Plus 的授权证书文件，包含用户的许可证信息和数字签名。

### 文件位置

```
%ProgramData%\Sandboxie-Plus\Certificate.dat
或
C:\ProgramData\Sandboxie-Plus\Certificate.dat
```

### 文件作用

- ✅ 存储授权信息（类型、级别、过期时间）
- ✅ 包含数字签名（ECDSA P-256）
- ✅ 启用高级功能（网络、加密、安全增强等）
- ✅ 防止篡改（签名验证）

---

## 📋 文件格式

### 基本结构

```
NAME: value
TYPE: certificate-type
LEVEL: certificate-level
DATE: DD.MM.YYYY
OPTIONS: feature-flags
UPDATEKEY: unique-key
SIGNATURE: base64-encoded-signature
```

### 完整示例

```
NAME: John Doe
EMAIL: john@example.com
SOFTWARE: Sandboxie-Plus
TYPE: Personal
LEVEL: Advanced
DATE: 01.01.2024 +365
OPTIONS: desk,net,enc,sec
AMOUNT: 1
UPDATEKEY: 1234567890ABCDEF1234567890ABCDEF
HWID: {12345678-1234-1234-1234-123456789012}
SIGNATURE: MEUCIQDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 🔑 字段说明

| 字段 | 必需 | 说明 | 示例 |
|------|------|------|------|
| **NAME** | ✅ | 授权用户名 | John Doe |
| **EMAIL** | ⚠️ | 用户邮箱 | john@example.com |
| **SOFTWARE** | ✅ | 软件名称 | Sandboxie-Plus |
| **TYPE** | ✅ | 证书类型 | Personal, Business, Eternal |
| **LEVEL** | ✅ | 证书级别 | Standard, Advanced, Max |
| **DATE** | ✅ | 过期日期 | 01.01.2025 +365 |
| **DAYS** | ⚠️ | 有效天数 | 365 |
| **OPTIONS** | ⚠️ | 功能标志 | desk,net,enc,sec |
| **AMOUNT** | ⚠️ | 授权数量 | 1 |
| **UPDATEKEY** | ✅ | 更新密钥 | 32位十六进制 |
| **HWID** | ⚠️ | 硬件ID锁定 | UUID格式 |
| **SIGNATURE** | ✅ | 数字签名 | Base64编码 |

---

## 🎫 证书类型（TYPE）

| 类型 | 说明 | 功能 |
|------|------|------|
| **Eternal** | 永久证书 | 所有功能 |
| **Contributor** | 贡献者 | 所有功能 |
| **Business** | 商业版 | 高级功能 |
| **Personal** | 个人版 | 标准功能 |
| **Home** | 家庭版 | 基础功能 |
| **Developer** | 开发者 | 所有功能 |
| **Patreon** | 赞助者 | 根据级别 |
| **Evaluation** | 评估版 | 限时试用 |

---

## 📊 证书级别（LEVEL）

| 级别 | 值 | 功能 |
|------|-----|------|
| **Max** | 7 | 所有功能 |
| **Advanced** | 5 | 高级功能 |
| **Advanced1** | 4 | 高级功能（部分） |
| **Standard2** | 3 | 标准+功能 |
| **Standard** | 2 | 标准功能 |
| **NoLevel** | 0 | 无授权 |

---

## 🔧 功能选项（OPTIONS）

| 选项 | 说明 | 需要的功能 |
|------|------|-----------|
| **desk** | 隔离桌面 | UseSandboxDesktop |
| **net** | 高级网络 | NetworkDnsFilter, NetworkUseProxy |
| **enc** | 加密沙盒 | ConfidentialBox, UseFileImage |
| **sec** | 安全增强 | UseSecurityMode, SysCallLockDown |

---

## 🔐 数字签名验证

### 验证流程

```
1. 读取 Certificate.dat
2. 提取 SIGNATURE 字段
3. 计算其他字段的 SHA-256 哈希
4. 使用硬编码公钥验证签名（ECDSA P-256）
5. 验证通过 → 解析证书信息
6. 验证失败 → 拒绝授权
```

### 签名算法

- **算法**: ECDSA P-256
- **哈希**: SHA-256
- **编码**: Base64

---

## 📝 创建 Certificate.dat 示例

### 手动创建（无效，仅演示格式）

```
NAME: Test User
EMAIL: test@example.com
SOFTWARE: Sandboxie-Plus
TYPE: Personal
LEVEL: Advanced
DATE: 01.01.2025 +365
OPTIONS: desk,net,enc,sec
AMOUNT: 1
UPDATEKEY: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
SIGNATURE: INVALID_SIGNATURE_FOR_DEMO_ONLY
```

⚠️ **注意**: 手动创建的证书无法通过验证，因为没有有效的数字签名。

---

## 🛠️ 如何获取有效的 Certificate.dat

### 方法 1: 购买官方授权（推荐）

1. 访问官网购买授权
2. 收到授权邮件
3. 下载 Certificate.dat
4. 放到 %ProgramData%\Sandboxie-Plus\

### 方法 2: 修改源码移除验证

参考 LICENSE_REMOVAL_GUIDE.md

---

## 🔍 验证代码分析

### 读取证书文件

```c
// verify.c
NTSTATUS KphValidateCertificate() {
    // 1. 构建文件路径
    RtlStringCbPrintfW(path, path_len, 
        L\"%s\\Certificate.dat\", 
        Driver_HomePathDos);
    
    // 2. 打开文件
    status = Stream_Open(&stream, path, 
        FILE_GENERIC_READ, 0, 
        FILE_SHARE_READ, FILE_OPEN, 0);
    
    // 3. 逐行读取
    while (NT_SUCCESS(status = Conf_Read_Line(stream, line, &line_num))) {
        // 解析字段
        if (_wcsicmp(L\"TYPE\", name) == 0) {
            type = value;
        }
        else if (_wcsicmp(L\"LEVEL\", name) == 0) {
            level = value;
        }
        // ... 其他字段
    }
    
    // 4. 验证签名
    status = KphVerifySignature(hash, hashSize, 
        signature, signatureSize);
    
    return status;
}
```

---

## 💡 实际应用

### 检查当前证书

```powershell
# 查看证书文件
Get-Content \"C:\ProgramData\Sandboxie-Plus\Certificate.dat\"
```

### 证书信息示例

```
NAME: Premium User
SOFTWARE: Sandboxie-Plus
TYPE: Business
LEVEL: Max
DATE: 01.01.2025 +730
OPTIONS: desk,net,enc,sec
UPDATEKEY: A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6
SIGNATURE: MEYCIQCxxx...
```

---

## 🎯 总结

### Certificate.dat 的关键点

1. **文本格式** - 易于阅读和编辑
2. **数字签名** - 防止篡改
3. **灵活配置** - 支持多种证书类型和级别
4. **硬件锁定** - 可选的 HWID 绑定
5. **更新密钥** - 用于在线验证和更新

### 安全机制

- ✅ ECDSA P-256 数字签名
- ✅ 硬编码公钥验证
- ✅ 黑名单检查（阻止被撤销的密钥）
- ✅ 硬件ID绑定（可选）
- ✅ 过期时间检查

### 无法伪造的原因

1. 需要开发者的私钥签名
2. 私钥不公开
3. 签名验证使用硬编码公钥
4. 任何修改都会导致签名失效

---

**文档版本**: 1.0  
**创建日期**: 2025-01-02  
**作者**: Claude (Opus 4.6)
