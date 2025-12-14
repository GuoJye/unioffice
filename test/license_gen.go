package main

import (
"crypto"
"crypto/rand"
"crypto/rsa"
"crypto/sha512"
"crypto/x509"
"encoding/base64"
"encoding/json"
"encoding/pem"
"flag"
"fmt"
"os"
"strings"
"time"
)

// LicenseKey 必须与 unioffice 中的结构完全一致
type LicenseKey struct {
LicenseId     string `json:"license_id"`
CustomerId    string `json:"customer_id"`
CustomerName  string `json:"customer_name"`
Tier          string `json:"tier"`
CreatedAtInt  int64  `json:"created_at"`
ExpiresAtInt  int64  `json:"expires_at"`
CreatedBy     string `json:"created_by"`
CreatorName   string `json:"creator_name"`
CreatorEmail  string `json:"creator_email"`
UniPDF        bool   `json:"unipdf"`
UniOffice     bool   `json:"unioffice"`
UniHTML       bool   `json:"unihtml"`
Trial         bool   `json:"trial"`
}

func main() {
genKeys := flag.Bool("genkeys", false, "Generate RSA key pair")
privKeyFile := flag.String("privkey", "private.pem", "Private key file")
pubKeyFile := flag.String("pubkey", "public.pem", "Public key file")
customerName := flag.String("customer", "TestCustomer", "Customer name")
licenseFile := flag.String("output", "license.key", "Output license file")
debug := flag.Bool("debug", false, "Enable debug output")
flag.Parse()

if *genKeys {
if err := generateKeys(*privKeyFile, *pubKeyFile); err != nil {
fmt.Fprintf(os.Stderr, "Error generating keys: %v\n", err)
os.Exit(1)
}
fmt.Println("✓ Keys generated successfully!")
fmt.Printf("  Private: %s\n", *privKeyFile)
fmt.Printf("  Public: %s\n", *pubKeyFile)

if err := printPublicKeyHex(*pubKeyFile); err != nil {
fmt.Fprintf(os.Stderr, "Error: %v\n", err)
os.Exit(1)
}
return
}

if err := generateLicense(*privKeyFile, *customerName, *licenseFile, *debug); err != nil {
fmt.Fprintf(os.Stderr, "Error generating license: %v\n", err)
os.Exit(1)
}

fmt.Println("✓ License generated successfully!")
fmt.Printf("  File: %s\n", *licenseFile)
fmt.Printf("  Customer: %s\n", *customerName)
}

func generateKeys(privFile, pubFile string) error {
privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
if err != nil {
return fmt.Errorf("failed to generate key: %w", err)
}

// Save private key
privBytes := x509.MarshalPKCS1PrivateKey(privateKey)
privPEM := pem.EncodeToMemory(&pem.Block{
Type:  "RSA PRIVATE KEY",
Bytes: privBytes,
})
if err := os.WriteFile(privFile, privPEM, 0600); err != nil {
return fmt.Errorf("failed to save private key: %w", err)
}

// Save public key
pubBytes, err := x509.MarshalPKIXPublicKey(&privateKey.PublicKey)
if err != nil {
return fmt.Errorf("failed to marshal public key: %w", err)
}
pubPEM := pem.EncodeToMemory(&pem.Block{
Type:  "PUBLIC KEY",
Bytes: pubBytes,
})
return os.WriteFile(pubFile, pubPEM, 0644)
}

func printPublicKeyHex(pubFile string) error {
pubPEM, err := os.ReadFile(pubFile)
if err != nil {
return err
}

block, _ := pem.Decode(pubPEM)
if block == nil {
return fmt.Errorf("failed to decode PEM")
}

hexStr := fmt.Sprintf("%x", block.Bytes)

fmt.Println("\n" + strings.Repeat("=", 80))
fmt.Println("Replace this HEX in internal/license/license.go (const _afbd):")
fmt.Println(strings.Repeat("=", 80))
fmt.Println(hexStr)
fmt.Println(strings.Repeat("=", 80) + "\n")

return nil
}

func generateLicense(privFile, customerName, outputFile string, debug bool) error {
// Read private key
privPEM, err := os.ReadFile(privFile)
if err != nil {
return fmt.Errorf("failed to read private key: %w", err)
}

block, _ := pem.Decode(privPEM)
if block == nil {
return fmt.Errorf("failed to decode PEM")
}

privateKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
if err != nil {
return fmt.Errorf("failed to parse private key: %w", err)
}

// Create license data - 字段顺序必须与 JSON tag 定义的顺序一致
now := time.Now().UTC()
license := LicenseKey{
LicenseId:    "1234567890ABCDEF",
CustomerId:   "CUST1234567890",
CustomerName: customerName,
Tier:         "business",
CreatedAtInt: now.Unix(),
ExpiresAtInt: 0,  // 0 = never expires
CreatedBy:    "license-generator",
CreatorName:  "License Generator",
CreatorEmail: "admin@example.com",
UniPDF:       true,
UniOffice:    true,
UniHTML:      true,
Trial:        false,
}

// Marshal to JSON - Go's json.Marshal preserves field order
jsonData, err := json.Marshal(license)
if err != nil {
return fmt.Errorf("failed to marshal JSON: %w", err)
}

if debug {
fmt.Println("\n=== DEBUG: License JSON ===")
fmt.Printf("JSON: %s\n", string(jsonData))
fmt.Printf("JSON Length: %d bytes\n", len(jsonData))
}

// Calculate SHA512 hash
hasher := sha512.New()
hasher.Write(jsonData)
hashed := hasher.Sum(nil)

if debug {
fmt.Printf("\n=== DEBUG: Hash ===")
fmt.Printf("SHA512: %x\n", hashed)
}

// Sign with private key using PKCS1v15
signature, err := rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA512, hashed)
if err != nil {
return fmt.Errorf("failed to sign: %w", err)
}

if debug {
fmt.Printf("\n=== DEBUG: Signature ===")
fmt.Printf("Signature: %x\n", signature)
fmt.Printf("Signature Length: %d bytes\n", len(signature))
}

// Base64 encode
part1 := base64.StdEncoding.EncodeToString(jsonData)
part2 := base64.StdEncoding.EncodeToString(signature)

if debug {
fmt.Printf("\n=== DEBUG: Base64 ===")
fmt.Printf("Part1 Length: %d\n", len(part1))
fmt.Printf("Part2 Length: %d\n", len(part2))
}

// Assemble license
licenseContent := "-----BEGIN UNIDOC LICENSE KEY-----\n" +
part1 + "\n+\n" + part2 + "\n" +
"-----END UNIDOC LICENSE KEY-----\n"

// Save to file
if err := os.WriteFile(outputFile, []byte(licenseContent), 0644); err != nil {
return fmt.Errorf("failed to save license: %w", err)
}

// Also verify the signature immediately
if debug {
fmt.Println("\n=== DEBUG: Verification ===")
pubKey := &privateKey.PublicKey
err = rsa.VerifyPKCS1v15(pubKey, crypto.SHA512, hashed, signature)
if err != nil {
fmt.Printf("❌ Self-verification FAILED: %v\n", err)
} else {
fmt.Println("✓ Self-verification PASSED")
}
}

fmt.Println("\nGenerated license content:")
fmt.Println(licenseContent)

return nil
}
