package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/unidoc/unioffice/v2/common/license"
	"github.com/unidoc/unioffice/v2/document"
)

func main() {
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println("UniOffice License Test")
	fmt.Println(strings.Repeat("=", 60))

	licenseContent, err := os.ReadFile("license.key")
	if err != nil {
		fmt.Printf("❌ Failed to read license file: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("\n[1] ✓ License file loaded")

	customerName := "TestCustomer"
	err = license.SetLicenseKey(string(licenseContent), customerName)
	if err != nil {
		fmt.Printf("❌ License validation failed: %v\n", err)
		fmt.Println("\nPossible reasons:")
		fmt.Println("  1. Customer name mismatch")
		fmt.Println("  2. Public key not replaced in source code")
		fmt.Println("  3. License format error")
		fmt.Println("  4. Signature verification failed")
		os.Exit(1)
	}
	fmt.Println("[2] ✓ License validated successfully!")

	key := license.GetLicenseKey()
	if key == nil {
		fmt.Println("❌ Cannot get license info")
		os.Exit(1)
	}

	fmt.Println("\n[3] License Information:")
	fmt.Println(key.ToString())
	fmt.Printf("Type: %s\n", key.TypeToString())
	fmt.Printf("Licensed: %v\n", key.IsLicensed())

	fmt.Println("\n[4] Testing document creation...")
	doc := document.New()

	para := doc.AddParagraph()
	run := para.AddRun()
	run.AddText("This is a test document created with custom license!")

	para2 := doc.AddParagraph()
	run2 := para2.AddRun()
	run2.AddText(fmt.Sprintf("Customer: %s", customerName))

	para3 := doc.AddParagraph()
	run3 := para3.AddRun()
	run3.AddText(fmt.Sprintf("Tier: %s", key.Tier))

	testDoc := "test_output.docx"
	err = doc.SaveToFile(testDoc)
	if err != nil {
		fmt.Printf("❌ Failed to save document: %v\n", err)
		os.Exit(1)
	}

	fileInfo, _ := os.Stat(testDoc)
	fmt.Printf("✓ Document created: %s (%d bytes)\n", testDoc, fileInfo.Size())

	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Println("✅ All tests passed! License is working!")
	fmt.Println(strings.Repeat("=", 60))
}
