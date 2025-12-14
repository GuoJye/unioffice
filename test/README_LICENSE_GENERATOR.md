# UniOffice 许可证生成器使用指南

## 概述

成功创建了一个完全可用的 UniOffice 许可证生成器，可以生成被 unioffice 库接受的有效许可证。

## 成功要点

### 1. 关键发现

在调试过程中发现了几个关键问题：

1. **模块路径问题**：测试程序需要使用正确的导入路径 `github.com/unidoc/unioffice/v2` 而不是 `github.com/unidoc/unioffice`
2. **公钥位置**：实际使用的公钥是常量 `_dba` (PEM格式)，而不是 `_afbd` (十六进制格式)
3. **Go缓存**：需要确保使用本地修改的代码而不是远程包

### 2. 最终工作的配置

**修改的文件：**

1. `internal/license/license.go` (第894行)：
   - 替换 `const _dba` 为新生成的公钥（PEM格式，Unicode转义）

2. `test/go.mod`：
   ```go
   module test-license

   go 1.25.4

   replace github.com/unidoc/unioffice/v2 => ../

   require github.com/unidoc/unioffice/v2 v2.0.0

   require github.com/richardlehane/msoleps v1.0.3 // indirect
   ```

3. `test/test_license.go`：
   - 使用正确的导入路径：
     ```go
     import (
         "github.com/unidoc/unioffice/v2/common/license"
         "github.com/unidoc/unioffice/v2/document"
     )
     ```

## 使用步骤

### 第一步：生成RSA密钥对（仅需一次）

```bash
cd test
go run license_gen.go -genkeys -privkey private.pem -pubkey public.pem
```

这将输出公钥的十六进制格式和PEM格式。

### 第二步：替换源代码中的公钥

1. 复制输出中的 **PEM 格式公钥（Unicode转义）**
2. 打开 `internal/license/license.go`
3. 找到第894行的 `const _dba = "..."`
4. 将整个值替换为新生成的公钥

### 第三步：生成许可证

```bash
cd test
go run license_gen.go \
  -customer "YourCustomerName" \
  -output license.key \
  -privkey private.pem
```

参数说明：
- `-customer`: 客户名称（必须与调用 SetLicenseKey 时的名称一致）
- `-output`: 输出文件名
- `-privkey`: 私钥文件路径
- `-debug`: （可选）显示调试信息

### 第四步：测试许可证

```bash
cd test
go run test_license.go
```

预期输出：
```
============================================================
UniOffice License Test
============================================================

[1] ✓ License file loaded
[2] ✓ License validated successfully!

[3] License Information:
License Id: 1234567890ABCDEF
Customer Id: CUST1234567890
Customer Name: YourCustomerName
Tier: business
Created At: ...
Expires At: ...
Creator: License Generator <admin@example.com>

Type: Commercial License - Business
Licensed: true

[4] Testing document creation...
✓ Document created: test_output.docx (5252 bytes)

============================================================
✅ All tests passed! License is working!
============================================================
```

## 许可证格式说明

生成的许可证文件格式：

```
-----BEGIN UNIDOC LICENSE KEY-----
<Base64编码的JSON数据>
+
<Base64编码的RSA签名>
-----END UNIDOC LICENSE KEY-----
```

### JSON数据结构

```json
{
  "license_id": "1234567890ABCDEF",
  "customer_id": "CUST1234567890",
  "customer_name": "YourCustomerName",
  "tier": "business",
  "created_at": 1765688190,
  "expires_at": 0,
  "created_by": "license-generator",
  "creator_name": "License Generator",
  "creator_email": "admin@example.com",
  "unipdf": true,
  "unioffice": true,
  "unihtml": true,
  "trial": false
}
```

### 加密算法

- **哈希算法**：SHA512
- **签名算法**：RSA-2048 with PKCS1v15
- **编码方式**：Base64 (StdEncoding)

## 验证流程

1. 解析许可证文件，提取 JSON 和签名部分
2. 加载公钥（PEM格式）
3. 计算 JSON 数据的 SHA512 哈希
4. 使用 RSA 公钥验证签名
5. 反序列化 JSON 到 LicenseKey 结构
6. 验证客户名称匹配
7. 调用 Validate() 检查许可证有效性

## 故障排查

### 问题：验证失败 "crypto/rsa: verification error"

可能原因：
1. **公钥未正确替换**：确保替换的是 `const _dba` 而不是 `const _afbd`
2. **使用了远程包**：检查 `go.mod` 和导入路径是否正确
3. **私钥/公钥不匹配**：确保使用同一对密钥
4. **JSON格式不匹配**：使用 Go 生成器而不是 Python

### 问题：模块导入错误

确保：
- `go.mod` 中有正确的 `replace` 指令
- 导入路径使用 `/v2` 后缀
- 运行 `go mod tidy` 清理依赖

### 问题：调试输出不显示

可能是使用了缓存的远程包：
```bash
go clean -cache -modcache
go mod tidy
```

## 文件清单

### 生成器文件
- `test/license_gen.go` - Go许可证生成器（推荐）
- `test/generate_license.py` - Python生成器（已废弃，有JSON序列化问题）

### 测试文件
- `test/test_license.go` - 许可证验证测试程序
- `test/go.mod` - 测试模块配置

### 密钥文件
- `test/private.pem` - RSA私钥（PKCS1格式）
- `test/public.pem` - RSA公钥（PKIX格式）

### 许可证文件
- `test/license.key` - 生成的许可证文件
- `test/license_go.key` - Go生成器输出（同上）

### 文档
- `test/许可验证分析报告.md` - 详细的验证机制分析
- `test/unioffice校验---go语言docx第三方库.md` - 原始参考文档

## 技术细节

### RSA密钥生成

使用 Go 的 `crypto/rsa` 包生成 2048 位密钥：

```go
privateKey, _ := rsa.GenerateKey(rand.Reader, 2048)
```

### 签名生成

```go
hashed := sha512.Sum512(jsonData)
signature, _ := rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA512, hashed[:])
```

### 签名验证

```go
hashed := sha512.Sum512(jsonData)
err := rsa.VerifyPKCS1v15(publicKey, crypto.SHA512, hashed[:], signature)
```

## 安全注意事项

⚠️ **重要提示**：

1. **保护私钥**：私钥文件（`private.pem`）必须妥善保管，不要提交到代码库
2. **定期轮换**：建议定期生成新的密钥对
3. **访问控制**：限制许可证生成器的访问权限
4. **审计日志**：记录所有许可证生成操作

## 成功验证

最终测试结果确认：

✅ 许可证生成成功  
✅ 签名验证通过  
✅ 客户名称匹配  
✅ 许可证信息正确  
✅ 文档创建功能正常  

## 下一步

可以根据需求自定义：

1. **许可证字段**：修改 `license_gen.go` 中的字段值
2. **有效期**：调整 `expires_at` 字段（Unix时间戳）
3. **许可级别**：修改 `tier` 字段（community/individual/business）
4. **功能开关**：控制 `unipdf`、`unioffice`、`unihtml` 标志

---

生成时间：2025年12月14日  
版本：1.0  
状态：已验证可用 ✅
