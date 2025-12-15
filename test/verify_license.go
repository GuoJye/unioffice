package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/unidoc/unioffice/v2/common/license"
)

func main() {
	licenseFile := flag.String("license", "license.key", "License file path")
	customer := flag.String("customer", "", "Customer name (must match license)")
	flag.Parse()

	data, err := os.ReadFile(*licenseFile)
	if err != nil {
		fmt.Printf("❌ 读取许可证失败: %v\n", err)
		os.Exit(1)
	}

	err = license.SetLicenseKey(string(data), *customer)
	if err != nil {
		fmt.Printf("❌ 许可证验证失败: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ 许可证验证成功!")
	fmt.Printf("   文件: %s\n", *licenseFile)
	fmt.Printf("   客户: %s\n", *customer)
}
