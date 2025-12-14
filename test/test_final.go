package main

import (
"fmt"
"os"
"strings"

"github.com/unidoc/unioffice/common/license"
"github.com/unidoc/unioffice/document"
)

func main() {
fmt.Println(strings.Repeat("=", 60))
fmt.Println("UniOffice License Test")
fmt.Println(strings.Repeat("=", 60))

licenseContent, err := os.ReadFile("license_go.key")
if err != nil {
tf("❌ Failed to read license file: %v\n", err)
tln("\n[1] ✓ License file loaded")

customerName := "TestCustomer"
err = license.SetLicenseKey(string(licenseContent), customerName)
if err != nil {
tf("❌ License validation failed: %v\n", err)
tln("\nPossible reasons:")
tln("  1. Customer name mismatch")
tln("  2. Public key not replaced in source code")
tln("  3. License format error")
tln("  4. Signature verification failed")
tln("[2] ✓ License validated successfully!")

key := license.GetLicenseKey()
if key == nil {
tln("❌ Cannot get license info")

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

testDoc := "test_output_final.docx"
err = doc.SaveToFile(testDoc)
if err != nil {
tf("❌ Failed to save document: %v\n", err)
fo, _ := os.Stat(testDoc)
fmt.Printf("✓ Document created: %s (%d bytes)\n", testDoc, fileInfo.Size())

fmt.Println("\n" + strings.Repeat("=", 60))
fmt.Println("✅ All tests passed! License is working!")
fmt.Println(strings.Repeat("=", 60))
}
