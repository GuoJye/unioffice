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
