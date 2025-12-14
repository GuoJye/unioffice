package main

import (
	"fmt"
	"os"

	"github.com/unidoc/unioffice/v2/common/license"
	"github.com/unidoc/unioffice/v2/document"
)

func main() {
	fmt.Println("========================================")
	fmt.Println("UniOffice 许可证完整功能测试")
	fmt.Println("========================================\n")

	// 测试1: 加载许可证
	fmt.Println("【测试1】加载许可证文件")
	licenseContent, err := os.ReadFile("license.key")
	if err != nil {
		fmt.Printf("❌ 失败: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("✓ 许可证文件已加载 (%d 字节)\n\n", len(licenseContent))

	// 测试2: 验证许可证
	fmt.Println("【测试2】验证许可证")
	customerName := "TestCustomer"
	err = license.SetLicenseKey(string(licenseContent), customerName)
	if err != nil {
		fmt.Printf("❌ 验证失败: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✓ 许可证验证成功\n")

	// 测试3: 获取许可证信息
	fmt.Println("【测试3】读取许可证信息")
	key := license.GetLicenseKey()
	if key == nil {
		fmt.Println("❌ 无法获取许可证信息")
		os.Exit(1)
	}
	fmt.Printf("  许可证ID: %s\n", key.LicenseId)
	fmt.Printf("  客户名称: %s\n", key.CustomerName)
	fmt.Printf("  许可级别: %s\n", key.Tier)
	fmt.Printf("  创建时间: %s\n", key.CreatedAt.Format("2006-01-02 15:04:05"))
	fmt.Printf("  是否授权: %v\n", key.IsLicensed())
	fmt.Printf("  UniPDF: %v\n", key.UniPDF)
	fmt.Printf("  UniOffice: %v\n", key.UniOffice)
	fmt.Printf("  UniHTML: %v\n", key.UniHTML)
	fmt.Println("✓ 许可证信息读取成功\n")

	// 测试4: 创建简单文档
	fmt.Println("【测试4】创建Word文档")
	doc := document.New()

	// 添加段落
	para := doc.AddParagraph()
	run := para.AddRun()
	run.AddText("这是一个测试文档")

	// 添加更多内容
	para2 := doc.AddParagraph()
	run2 := para2.AddRun()
	run2.AddText("使用自定义许可证生成器创建")

	// 保存文档
	err = doc.SaveToFile("test_advanced.docx")
	if err != nil {
		fmt.Printf("❌ 文档保存失败: %v\n", err)
		os.Exit(1)
	}

	info, _ := os.Stat("test_advanced.docx")
	fmt.Printf("✓ 文档已创建: test_advanced.docx (%d 字节)\n\n", info.Size())

	// 测试5: 创建包含多个段落的文档
	fmt.Println("【测试5】创建复杂Word文档")
	doc2 := document.New()

	// 添加标题
	title := doc2.AddParagraph()
	titleRun := title.AddRun()
	titleRun.AddText("许可证测试报告")
	titleRun.Properties().SetBold(true)
	titleRun.Properties().SetSize(16)

	// 添加内容段落
	for i := 1; i <= 5; i++ {
		p := doc2.AddParagraph()
		r := p.AddRun()
		r.AddText(fmt.Sprintf("第 %d 段内容：许可证生成器工作正常", i))
	}

	// 保存
	err = doc2.SaveToFile("test_complex.docx")
	if err != nil {
		fmt.Printf("❌ 复杂文档保存失败: %v\n", err)
		os.Exit(1)
	}

	info2, _ := os.Stat("test_complex.docx")
	fmt.Printf("✓ 复杂文档已创建: test_complex.docx (%d 字节)\n\n", info2.Size())

	// 测试6: 读取已存在的文档
	fmt.Println("【测试6】读取并修改文档")
	existingDoc, err := document.Open("test_advanced.docx")
	if err != nil {
		fmt.Printf("❌ 打开文档失败: %v\n", err)
		os.Exit(1)
	}

	// 添加新段落
	newPara := existingDoc.AddParagraph()
	newRun := newPara.AddRun()
	newRun.AddText("这是后来添加的内容")

	// 保存修改
	err = existingDoc.SaveToFile("test_modified.docx")
	if err != nil {
		fmt.Printf("❌ 保存修改失败: %v\n", err)
		os.Exit(1)
	}

	info3, _ := os.Stat("test_modified.docx")
	fmt.Printf("✓ 文档已修改并保存: test_modified.docx (%d 字节)\n\n", info3.Size())

	// 总结
	fmt.Println("========================================")
	fmt.Println("✅ 所有测试通过！")
	fmt.Println("========================================")
	fmt.Println("\n生成的文件:")
	fmt.Println("  - test_advanced.docx  (简单文档)")
	fmt.Println("  - test_complex.docx   (复杂文档)")
	fmt.Println("  - test_modified.docx  (修改后的文档)")
	fmt.Println("\n许可证生成器完全可用！")
}
