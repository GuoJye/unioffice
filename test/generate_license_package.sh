#!/bin/bash
# 一键生成客户端部署包和许可证

set -e

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <客户名称>"
    echo "示例: $0 \"CySec\""
    exit 1
fi

CUSTOMER_NAME="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="/tmp/license_${CUSTOMER_NAME}_${TIMESTAMP}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         UniOffice 许可证一键部署包生成工具                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "客户名称: $CUSTOMER_NAME"
echo "输出目录: $OUTPUT_DIR"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 1. 创建部署包
echo "1️⃣ 创建客户端部署包..."
./create_client_deployment.sh "$CUSTOMER_NAME" > /dev/null 2>&1
cp /tmp/unioffice-client-deployment.tar.gz "$OUTPUT_DIR/"
echo "   ✅ 部署包: $OUTPUT_DIR/unioffice-client-deployment.tar.gz"

# 2. 生成许可证
echo "2️⃣ 生成许可证..."
go run license_gen.go \
    -customer "$CUSTOMER_NAME" \
    -output "$OUTPUT_DIR/license.key" \
    -privkey new_private.pem > /dev/null 2>&1
echo "   ✅ 许可证: $OUTPUT_DIR/license.key"

# 3. 创建使用说明
echo "3️⃣ 创建使用说明..."
cat > "$OUTPUT_DIR/部署说明.txt" << EOF
═══════════════════════════════════════════════════════════════
              UniOffice 许可证部署包
═══════════════════════════════════════════════════════════════

客户名称: $CUSTOMER_NAME
创建时间: $(date '+%Y-%m-%d %H:%M:%S')
创建者:   $(whoami)

📦 文件清单
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(ls -lh "$OUTPUT_DIR" | awk 'NR>1 {printf "%-40s %8s\n", $9, $5}')

📋 部署步骤（客户端机器）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ 解压部署包
   tar xzf unioffice-client-deployment.tar.gz
   cd unioffice-client-deployment

2️⃣ 复制许可证到部署目录
   cp /path/to/license.key .

3️⃣ 安装 Go（如果没有）
   Ubuntu: sudo apt install golang-go
   CentOS: sudo yum install golang
   macOS:  brew install go

4️⃣ 检查环境
   ./check.sh

5️⃣ 整理依赖
   go mod tidy

6️⃣ 运行验证
   go run client_verify.go

预期输出：
   ✅ 许可证验证成功！
      客户: $CUSTOMER_NAME
   ✅ 文档创建成功: output.docx

⚠️ 重要提示
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• 不要修改 unioffice/ 目录下的任何文件
• 不要删除 go.mod 中的 replace 指令
• 客户名称已自动配置为: $CUSTOMER_NAME
• license.key 必须放在 unioffice-client-deployment 目录下

故障排除
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

如果验证失败：
  1. 运行 ./check.sh 检查环境
  2. 确保 license.key 在当前目录
  3. 运行 go clean -modcache
  4. 运行 go mod tidy
  5. 重新运行 go run client_verify.go

技术支持: support@example.com

═══════════════════════════════════════════════════════════════
EOF
echo "   ✅ 说明: $OUTPUT_DIR/部署说明.txt"

# 4. 创建校验文件
echo "4️⃣ 生成校验信息..."
cd "$OUTPUT_DIR"
sha256sum * > checksums.txt 2>/dev/null
echo "   ✅ 校验: $OUTPUT_DIR/checksums.txt"

# 5. 打包所有文件
echo "5️⃣ 打包最终文件..."
cd /tmp
FINAL_PACKAGE="license_${CUSTOMER_NAME}_${TIMESTAMP}.tar.gz"
tar czf "$FINAL_PACKAGE" "license_${CUSTOMER_NAME}_${TIMESTAMP}/"
FINAL_SIZE=$(du -h "$FINAL_PACKAGE" | awk '{print $1}')

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    ✅ 生成完成！                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 最终文件"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  完整包: /tmp/$FINAL_PACKAGE ($FINAL_SIZE)"
echo ""
echo "📂 或者使用独立文件（在 $OUTPUT_DIR）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$OUTPUT_DIR" | awk 'NR>1 {printf "  %-40s %8s\n", $9, $5}'
echo ""
echo "🚀 下一步"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  发送给客户:"
echo "    方式1: 发送完整包"
echo "           scp /tmp/$FINAL_PACKAGE client@host:/tmp/"
echo ""
echo "    方式2: 发送独立文件"
echo "           scp $OUTPUT_DIR/* client@host:/tmp/"
echo ""
echo "  客户端操作:"
echo "    1. 解压: tar xzf $FINAL_PACKAGE"
echo "    2. 进入: cd license_${CUSTOMER_NAME}_${TIMESTAMP}"
echo "    3. 查看: cat 部署说明.txt"
echo "    4. 部署: 按说明操作"
echo ""
echo "═══════════════════════════════════════════════════════════════"
