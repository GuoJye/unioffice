package main

import (
"fmt"
"os"
"github.com/unidoc/unioffice/v2/common/license"
"github.com/unidoc/unioffice/v2/document"
)

func main() {
// 加载许可证
content, _ := os.ReadFile("demo_license.key")

// 验证许可证
err := license.SetLicenseKey(string(content), "DemoCompany")
if err != nil {
tf("❌ 验证失败: %v\n", err)

}

// 获取许可证信息
key := license.GetLicenseKey()
fmt.Printf("✅ 许可证验证成功！\n")
fmt.Printf("   客户: %s\n", key.CustomerName)
fmt.Printf("   级别: %s\n", key.Tier)
fmt.Printf("   授权: %v\n", key.IsLicensed())

// 创建文档
doc := document.New()
para := doc.AddParagraph()
run := para.AddRun()
run.AddText("这是使用自定义许可证创建的文档 - DemoCompany")
doc.SaveToFile("demo_output.docx")

info, _ := os.Stat("demo_output.docx")
fmt.Printf("   文档: demo_output.docx (%d bytes)\n", info.Size())
}
