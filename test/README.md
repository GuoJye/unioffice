# UniOffice 许可证生成与测试工具

本目录包含用于生成和测试 UniOffice 自定义许可证的完整工具链。

## 📁 目录结构

```
test/
├── license-generator/    # 许可证生成器
│   ├── main.go
│   └── go.mod
├── license-test/        # 许可证测试工具
│   ├── main.go
│   └── go.mod
└── README.md           # 本文件
```

## 🚀 使用步骤

### 步骤 1: 生成 RSA 密钥对

```bash
cd test/license-generator
go run main.go -genkeys
```

这将生成：
- `private.pem` - 私钥文件（用于签名许可证）
- `public.pem` - 公钥文件

同时会输出公钥的十六进制格式，**请复制这个十六进制字符串**。

### 步骤 2: 替换源代码中的公钥

编辑文件 `internal/license/license.go`，找到常量 `_afbd`（约在第 13 行），将其值替换为步骤 1 输出的十六进制字符串。

原始代码类似：
```go
const _afbd = "305c300d06092a864886f70d0101010500034b003048..."
```

替换为：
```go
const _afbd = "<你生成的十六进制字符串>"
```

### 步骤 3: 生成许可证

```bash
cd test/license-generator
go run main.go -customer "MyCompany" -output ../license.key
```

参数说明：
- `-customer`: 客户名称（必须与测试时使用的名称一致）
- `-output`: 输出的许可证文件路径
- `-privkey`: 私钥文件路径（默认: private.pem）

这将生成许可证文件，格式如下：
```
-----BEGIN UNIDOC LICENSE KEY-----
<Base64 编码的 JSON 数据>
+
<Base64 编码的 RSA 签名>
-----END UNIDOC LICENSE KEY-----
```

### 步骤 4: 测试许可证

```bash
cd test/license-test
go run main.go -license ../license.key -customer "MyCompany"
```

参数说明：
- `-license`: 许可证文件路径
- `-customer`: 客户名称（必须与生成时一致）
- `-output`: 测试输出的文档路径（默认: test_output.docx）

### 步骤 5: 验证结果

如果一切正常，你将看到：

```
============================================================
UniOffice 许可证测试工具
============================================================

[1] 读取许可证文件: ../license.key
✓ 许可证文件读取成功

[2] 设置许可证 (客户名称: MyCompany)
✓ 许可证验证成功！

[3] 许可证信息:
License Id: 1234567890ABCDEF
Customer Id: CUST1234567890
Customer Name: MyCompany
...

[4] 测试创建文档: test_output.docx
✓ 文档创建成功！

[5] 验证文档
✓ 文档文件大小: XXXX 字节

============================================================
✅ 所有测试通过！许可证完全可用！
============================================================
```

## 📝 许可证结构说明

生成的许可证包含以下字段：

```json
{
  "license_id": "1234567890ABCDEF",    // >= 10 字符
  "customer_id": "CUST1234567890",     // >= 10 字符
  "customer_name": "客户名称",
  "tier": "business",                   // business/individual/community
  "created_at": 1702540800,            // Unix 时间戳
  "expires_at": 0,                     // 0 = 永不过期
  "created_by": "license-generator",
  "creator_name": "License Generator",
  "creator_email": "admin@example.com",
  "unipdf": true,
  "unioffice": true,
  "unihtml": true,
  "trial": false
}
```

## ⚙️ 高级选项

### 自定义许可证内容

编辑 `license-generator/main.go` 中的 `generateLicense` 函数，修改 `license` 结构体的字段值：

```go
license := LicenseKey{
    LicenseId:    "YOUR-LICENSE-ID",     // 修改这里
    CustomerId:   "YOUR-CUSTOMER-ID",    // 修改这里
    CustomerName: customerName,
    Tier:         "business",             // 可选: business, individual, community
    CreatedAtInt: now.Unix(),
    ExpiresAtInt: 0,                      // 0=永不过期，或设置具体时间戳
    // ... 其他字段
}
```

### 设置过期时间

```go
// 设置30天后过期
expiresAt := time.Now().UTC().AddDate(0, 0, 30)
license.ExpiresAtInt = expiresAt.Unix()
```

### 生成试用许可证

```go
license.Trial = true
license.ExpiresAtInt = time.Now().UTC().AddDate(0, 0, 7).Unix() // 7天试用
```

## 🔍 故障排除

### 错误: "customer name mismatch"
**原因**: 生成许可证时的客户名称与测试时不一致  
**解决**: 确保 `-customer` 参数在生成和测试时完全相同

### 错误: "invalid license: signature verification failed"
**原因**: 源代码中的公钥未正确替换  
**解决**: 
1. 重新执行步骤 1，复制输出的十六进制字符串
2. 确保完整替换 `internal/license/license.go` 中的 `_afbd` 常量
3. 注意不要有多余的空格或换行

### 错误: "invalid license: License Id" 或 "Customer Id"
**原因**: ID 长度小于 10 个字符  
**解决**: 在 `generateLicense` 函数中使用至少 10 个字符的 ID

### 测试程序无法编译
**原因**: 源代码修改后未重新编译  
**解决**: 清理并重新构建
```bash
cd test/license-test
go clean -cache
go mod tidy
go run main.go -license ../license.key -customer "MyCompany"
```

## 🔐 安全注意事项

1. **私钥保护**: `private.pem` 文件必须妥善保管，不要泄露
2. **源代码修改**: 修改后的源代码包含你的公钥，分发时请注意
3. **许可证分发**: 生成的许可证只在使用相同公钥的版本中有效

## 📚 参考文档

- [许可验证分析报告](./许可验证分析报告.md) - 详细的验证机制分析
- [unioffice校验分析](./unioffice校验---go语言docx第三方库.md) - 原始分析文档

## ✨ 工作原理

1. **密钥生成**: 使用 RSA-2048 算法生成密钥对
2. **许可签名**: 
   - 将许可信息序列化为 JSON
   - 计算 JSON 的 SHA512 哈希
   - 使用私钥对哈希进行 PKCS1v15 签名
3. **许可编码**:
   - JSON 数据 → Base64 编码 → part1
   - RSA 签名 → Base64 编码 → part2
   - 组装: `BEGIN + part1 + "\n+\n" + part2 + END`
4. **许可验证**:
   - 解析许可证格式
   - Base64 解码 part1 和 part2
   - 使用公钥验证签名
   - 检查字段有效性

## 🎯 快速开始（一键脚本）

创建一个自动化脚本 `generate-and-test.sh`:

```bash
#!/bin/bash
set -e

CUSTOMER_NAME="TestCompany"

echo "=== 步骤 1: 生成密钥 ==="
cd license-generator
go run main.go -genkeys > keygen_output.txt
PUBLIC_KEY_HEX=$(grep -A 3 "请将以下十六进制字符串" keygen_output.txt | tail -n 1)

echo "=== 步骤 2: 生成许可证 ==="
go run main.go -customer "$CUSTOMER_NAME" -output ../license.key

echo "=== 步骤 3: 测试许可证 ==="
cd ../license-test
go run main.go -license ../license.key -customer "$CUSTOMER_NAME"

echo ""
echo "✅ 完成！"
echo "注意: 你仍需要手动将公钥替换到 internal/license/license.go 中"
```

运行：
```bash
chmod +x generate-and-test.sh
./generate-and-test.sh
```
