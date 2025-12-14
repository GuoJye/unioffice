#!/bin/bash
set -e

echo "================================"
echo "UniOffice License Generator & Tester"
echo "================================"

# 步骤 1: 使用 openssl 生成 RSA 密钥对
echo -e "\n[1] Generating RSA key pair..."
openssl genrsa -out private.pem 2048 2>/dev/null
openssl rsa -in private.pem -pubout -out public.pem 2>/dev/null
echo "✓ Keys generated: private.pem, public.pem"

# 步骤 2: 提取公钥的十六进制格式
echo -e "\n[2] Extracting public key hex..."
openssl rsa -pubin -in public.pem -outform DER -out public.der 2>/dev/null
PUBLIC_KEY_HEX=$(xxd -p public.der | tr -d '\n')
echo "✓ Public key hex extracted (length: ${#PUBLIC_KEY_HEX})"

echo -e "\n" + "="*80
echo "请将以下十六进制字符串替换到 internal/license/license.go 的 _afbd 常量:"
echo "="*80
echo "$PUBLIC_KEY_HEX"
echo "="*80

# 保存十六进制到文件
echo "$PUBLIC_KEY_HEX" > public_key_hex.txt
echo "✓ Saved to public_key_hex.txt"

# 步骤 3: 创建一个简单的Python脚本来生成许可证
echo -e "\n[3] Creating license generator script..."
cat > generate_license.py << 'PYSCRIPT'
#!/usr/bin/env python3
import json
import base64
import hashlib
import time
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.backends import default_backend
import sys

def generate_license(customer_name="TestCustomer"):
    # 读取私钥
    with open('private.pem', 'rb') as f:
        private_key = serialization.load_pem_private_key(
            f.read(),
            password=None,
            backend=default_backend()
        )
    
    # 创建许可证数据
    license_data = {
        "license_id": "1234567890ABCDEF",
        "customer_id": "CUST1234567890",
        "customer_name": customer_name,
        "tier": "business",
        "created_at": int(time.time()),
        "expires_at": 0,  # 0 = 永不过期
        "created_by": "license-generator",
        "creator_name": "License Generator",
        "creator_email": "admin@example.com",
        "unipdf": True,
        "unioffice": True,
        "unihtml": True,
        "trial": False
    }
    
    # 序列化为JSON
    json_data = json.dumps(license_data, separators=(',', ':')).encode()
    
    # 计算SHA512哈希
    hash_obj = hashlib.sha512()
    hash_obj.update(json_data)
    hashed = hash_obj.digest()
    
    # 使用私钥签名
    signature = private_key.sign(
        hashed,
        padding.PKCS1v15(),
        hashes.SHA512()
    )
    
    # Base64编码
    part1 = base64.b64encode(json_data).decode()
    part2 = base64.b64encode(signature).decode()
    
    # 组装许可证
    license_content = (
        "-----BEGIN UNIDOC LICENSE KEY-----\n" +
        part1 + "\n+\n" + part2 + "\n" +
        "-----END UNIDOC LICENSE KEY-----\n"
    )
    
    # 保存到文件
    with open('license.key', 'w') as f:
        f.write(license_content)
    
    print("\n生成的许可证内容:")
    print(license_content)
    print(f"✓ License saved to license.key for customer: {customer_name}")
    
    return license_content

if __name__ == "__main__":
    customer = sys.argv[1] if len(sys.argv) > 1 else "TestCustomer"
    generate_license(customer)
PYSCRIPT

chmod +x generate_license.py
echo "✓ License generator created: generate_license.py"

# 检查是否安装了cryptography
echo -e "\n[4] Checking Python dependencies..."
if python3 -c "import cryptography" 2>/dev/null; then
    echo "✓ cryptography library installed"
else
    echo "Installing cryptography library..."
    pip install cryptography -q
fi

# 步骤 4: 生成许可证
echo -e "\n[5] Generating license..."
python3 generate_license.py "TestCustomer"

echo -e "\n================================"
echo "Setup completed!"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Replace the hex string in internal/license/license.go (const _afbd)"
echo "2. Run the test application to verify the license"
echo ""
echo "Files created:"
echo "  - private.pem (keep secret!)"
echo "  - public.pem"
echo "  - public_key_hex.txt"
echo "  - license.key"
echo "  - generate_license.py"
