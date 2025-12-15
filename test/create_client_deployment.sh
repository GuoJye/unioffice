#!/bin/bash
# 自动创建客户端部署包

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          UniOffice 客户端部署包自动生成脚本                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 配置
DEPLOY_DIR="/tmp/unioffice-client-deployment"
SOURCE_DIR="/workspaces/unioffice"
CUSTOMER_NAME="${1:-CySec}"  # 默认客户名

echo "📋 配置信息"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  源代码目录: $SOURCE_DIR"
echo "  部署目录:   $DEPLOY_DIR"
echo "  客户名称:   $CUSTOMER_NAME"
echo ""

# 清理旧的部署目录
if [ -d "$DEPLOY_DIR" ]; then
    echo "🗑️  清理旧的部署目录..."
    rm -rf "$DEPLOY_DIR"
fi

# 创建部署目录
echo "📁 创建部署目录..."
mkdir -p "$DEPLOY_DIR"

# 复制源代码
echo "📦 复制完整源代码..."
cd "$SOURCE_DIR"

# 直接复制整个目录，排除不需要的
mkdir -p "$DEPLOY_DIR"
rsync -a \
  --exclude='.git' \
  --exclude='test' \
  --exclude='*.md' \
  --exclude='*.txt' \
  --exclude='LICENSE*' \
  --exclude='ACKNOWLEDGEMENTS*' \
  --exclude='CLA*' \
  ./ "$DEPLOY_DIR/unioffice/"

echo "   ✅ 源代码复制完成"

# 创建客户端验证程序
echo "📝 创建客户端验证程序..."
cat > "$DEPLOY_DIR/client_verify.go" << 'EOF'
package main

import (
	"fmt"
	"os"
	"github.com/unidoc/unioffice/v2/common/license"
	"github.com/unidoc/unioffice/v2/document"
)

func main() {
	// 读取许可证文件
	licenseContent, err := os.ReadFile("license.key")
	if err != nil {
		fmt.Printf("❌ 无法读取许可证: %v\n", err)
		return
	}

	// 验证许可证（客户名称必须与生成时一致）
	customerName := "CUSTOMER_NAME_PLACEHOLDER"  // ⚠️ 将被替换
	err = license.SetLicenseKey(string(licenseContent), customerName)
	if err != nil {
		fmt.Printf("❌ 许可证验证失败: %v\n", err)
		fmt.Println("\n💡 可能的原因:")
		fmt.Println("   1. 源代码中的公钥与签名密钥不匹配")
		fmt.Println("   2. go.mod 缺少 replace 指令")
		fmt.Println("   3. 客户名称不一致")
		return
	}

	fmt.Println("✅ 许可证验证成功！")
	fmt.Printf("   客户: %s\n", customerName)

	// 测试创建文档
	doc := document.New()
	para := doc.AddParagraph()
	run := para.AddRun()
	run.AddText("Hello UniOffice! 许可证验证成功！")

	err = doc.SaveToFile("output.docx")
	if err != nil {
		fmt.Printf("❌ 文档保存失败: %v\n", err)
		return
	}

	fmt.Println("✅ 文档创建成功: output.docx")
}
EOF

# 替换客户名称
sed -i "s/CUSTOMER_NAME_PLACEHOLDER/$CUSTOMER_NAME/g" "$DEPLOY_DIR/client_verify.go"

# 创建 go.mod
echo "📝 创建 go.mod..."
cat > "$DEPLOY_DIR/go.mod" << 'EOF'
module client-verify

go 1.21

// ⚠️ 关键配置：使用本地修改后的代码
replace github.com/unidoc/unioffice/v2 => ./unioffice

require github.com/unidoc/unioffice/v2 v2.0.0
EOF

# 创建 README
echo "📝 创建 README.txt..."
cat > "$DEPLOY_DIR/README.txt" << EOF
═══════════════════════════════════════════════════════════════
              UniOffice 客户端部署包
═══════════════════════════════════════════════════════════════

客户名称: $CUSTOMER_NAME
创建时间: $(date '+%Y-%m-%d %H:%M:%S')

📦 文件清单
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

unioffice/          完整源代码（包含修改后的公钥）
client_verify.go    验证程序（已配置客户名: $CUSTOMER_NAME）
go.mod              模块配置（包含 replace 指令）
README.txt          本说明文件

📋 使用步骤
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ 将许可证文件（license.key）放到此目录

2️⃣ 安装 Go（如果没有）
   Ubuntu: sudo apt install golang-go
   CentOS: sudo yum install golang
   macOS:  brew install go

3️⃣ 下载依赖
   go mod download

4️⃣ 运行验证
   go run client_verify.go

预期输出：
   ✅ 许可证验证成功！
      客户: $CUSTOMER_NAME
   ✅ 文档创建成功: output.docx

⚠️ 重要提示
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• 不要修改 unioffice/ 目录下的任何文件
• 不要删除 go.mod 中的 replace 指令
• 许可证必须是为客户"$CUSTOMER_NAME"生成的
• 确保 license.key 文件在当前目录

故障排除
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

如果遇到 "crypto/rsa: verification error":
  1. 检查 go.mod 是否包含 replace 指令
  2. 运行: go clean -modcache
  3. 运行: go mod download
  4. 重新运行: go run client_verify.go

如果遇到 "package not found":
  1. 检查 unioffice/ 目录是否完整
  2. 检查 go.mod 中的 replace 路径是否正确

═══════════════════════════════════════════════════════════════
EOF

# 创建快速检查脚本
echo "📝 创建检查脚本..."
cat > "$DEPLOY_DIR/check.sh" << 'EOF'
#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "          客户端环境快速检查"
echo "═══════════════════════════════════════════════════════════"
echo ""

errors=0

# 检查目录结构
echo "1️⃣ 检查目录结构..."
if [ -d "unioffice" ]; then
    echo "   ✅ unioffice/ 目录存在"
else
    echo "   ❌ unioffice/ 目录不存在"
    ((errors++))
fi

# 检查 go.mod
echo "2️⃣ 检查 go.mod..."
if [ -f "go.mod" ]; then
    if grep -q "replace.*unioffice" go.mod; then
        echo "   ✅ go.mod 包含 replace 指令"
    else
        echo "   ❌ go.mod 缺少 replace 指令"
        ((errors++))
    fi
else
    echo "   ❌ go.mod 不存在"
    ((errors++))
fi

# 检查许可证文件
echo "3️⃣ 检查许可证文件..."
if [ -f "license.key" ]; then
    echo "   ✅ license.key 存在"
else
    echo "   ⚠️  license.key 不存在（请先复制许可证文件）"
fi

# 检查 Go
echo "4️⃣ 检查 Go 环境..."
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    echo "   ✅ Go 已安装 ($GO_VERSION)"
else
    echo "   ❌ Go 未安装"
    ((errors++))
fi

echo ""
if [ $errors -eq 0 ]; then
    echo "✅ 所有检查通过！"
    if [ -f "license.key" ]; then
        echo ""
        echo "可以运行验证程序:"
        echo "  go run client_verify.go"
    else
        echo ""
        echo "下一步:"
        echo "  1. 复制 license.key 到当前目录"
        echo "  2. 运行: go run client_verify.go"
    fi
else
    echo "❌ 发现 $errors 个错误，请修复后再试"
fi
echo ""
EOF

chmod +x "$DEPLOY_DIR/check.sh"

# 打包
echo "📦 打包部署文件..."
cd /tmp
tar czf unioffice-client-deployment.tar.gz unioffice-client-deployment/

# 计算大小
SIZE=$(du -h unioffice-client-deployment.tar.gz | awk '{print $1}')

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    ✅ 部署包创建成功！                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 部署包信息"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  文件: /tmp/unioffice-client-deployment.tar.gz"
echo "  大小: $SIZE"
echo "  客户: $CUSTOMER_NAME"
echo ""
echo "📋 包含文件"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$DEPLOY_DIR"
find . -type f | head -20
echo "  ... 等更多文件"
echo ""
echo "🚀 下一步"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. 生成许可证:"
echo "     cd $SOURCE_DIR/test"
echo "     go run license_gen.go -customer \"$CUSTOMER_NAME\" -privkey new_private.pem"
echo ""
echo "  2. 传输到客户端:"
echo "     scp /tmp/unioffice-client-deployment.tar.gz user@client:/tmp/"
echo "     scp license.key user@client:/tmp/"
echo ""
echo "  3. 客户端部署:"
echo "     tar xzf unioffice-client-deployment.tar.gz"
echo "     cd unioffice-client-deployment"
echo "     cp /tmp/license.key ."
echo "     ./check.sh"
echo "     go run client_verify.go"
echo ""
echo "═══════════════════════════════════════════════════════════════"
