#!/bin/bash
# 客户端环境检查脚本

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        客户端许可证验证失败 - 诊断检查脚本                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 检查清单"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. 检查源代码中的公钥
echo "1️⃣ 检查源代码中的公钥 (const _dba)"
echo "   位置: internal/license/license.go:881"
echo ""

if [ -f "../internal/license/license.go" ]; then
    # 提取公钥（前100个字符）
    PUBLIC_KEY_IN_CODE=$(grep "const _dba" ../internal/license/license.go | head -c 150)
    echo "   源代码中的公钥 (前150字符):"
    echo "   $PUBLIC_KEY_IN_CODE..."
    echo ""
    
    # 检查是否是修改后的公钥（包含 new_public_pem.pem 的特征）
    if grep -q "\\\\u0071\\\\u006a\\\\u0034\\\\u0032" ../internal/license/license.go; then
        echo "   ✅ 检测到修改后的公钥 (new_public_pem.pem)"
    else
        echo "   ⚠️  这可能是原始公钥，不是 new_public_pem.pem！"
    fi
else
    echo "   ❌ 找不到 ../internal/license/license.go"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 2. 检查 go.mod
echo "2️⃣ 检查 go.mod 配置"
echo ""

if [ -f "../go.mod" ]; then
    echo "   go.mod 内容:"
    cat ../go.mod
    echo ""
    
    if grep -q "replace.*unioffice" ../go.mod; then
        echo "   ✅ 找到 replace 指令"
    else
        echo "   ❌ 没有 replace 指令 - 可能使用远程仓库代码！"
        echo "   💡 需要添加: replace github.com/unidoc/unioffice/v2 => ./"
    fi
else
    echo "   ❌ 找不到 ../go.mod"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 3. 检查私钥文件
echo "3️⃣ 检查私钥文件"
echo ""

if [ -f "new_private.pem" ]; then
    echo "   ✅ new_private.pem 存在"
    ls -lh new_private.pem
else
    echo "   ❌ new_private.pem 不存在"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 4. 生成测试许可证
echo "4️⃣ 生成测试许可证"
echo ""

if [ -f "license_gen.go" ] && [ -f "new_private.pem" ]; then
    echo "   生成测试许可证..."
    go run license_gen.go \
        -customer "DiagnosticTest" \
        -output /tmp/diagnostic_test.key \
        -privkey new_private.pem
    
    if [ $? -eq 0 ]; then
        echo "   ✅ 许可证生成成功"
    else
        echo "   ❌ 许可证生成失败"
    fi
else
    echo "   ❌ license_gen.go 或 new_private.pem 不存在"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 5. 验证许可证
echo "5️⃣ 验证许可证 (关键步骤)"
echo ""

cat > /tmp/diagnostic_verify.go << 'VERIFY_EOF'
package main

import (
    "fmt"
    "os"
    "github.com/unidoc/unioffice/v2/common/license"
)

func main() {
    data, err := os.ReadFile("/tmp/diagnostic_test.key")
    if err != nil {
        fmt.Printf("❌ 读取失败: %v\n", err)
        os.Exit(1)
    }
    
    err = license.SetLicenseKey(string(data), "DiagnosticTest")
    if err != nil {
        fmt.Printf("❌ 验证失败: %v\n", err)
        os.Exit(1)
    }
    
    fmt.Println("✅ 验证成功!")
}
VERIFY_EOF

cat > /tmp/go.mod << 'MOD_EOF'
module diagnostic-verify

go 1.21

replace github.com/unidoc/unioffice/v2 => ../

require github.com/unidoc/unioffice/v2 v2.0.0
MOD_EOF

cd /tmp
echo "   运行验证测试..."
go run diagnostic_verify.go

if [ $? -eq 0 ]; then
    echo ""
    echo "   ✅ 验证成功 - 您的本地环境配置正确！"
else
    echo ""
    echo "   ❌ 验证失败 - 配置有问题！"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 诊断总结"
echo ""
echo "如果验证失败，请检查："
echo "  1. 客户端机器是否有完整的修改后的源代码"
echo "  2. go.mod 是否包含 replace 指令"
echo "  3. 是否清除了 Go 模块缓存 (go clean -modcache)"
echo ""
echo "═══════════════════════════════════════════════════════════════"

