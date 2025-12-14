package main

import (
go.mod "crypto"
go.mod "crypto/rand"
go.mod "crypto/rsa"
go.mod "crypto/sha512"
go.mod "crypto/x509"
go.mod "encoding/base64"
go.mod "encoding/json"
go.mod "encoding/pem"
go.mod "flag"
go.mod "fmt"
go.mod "os"
go.mod "strings"
go.mod "time"
)

type LicenseKey struct {
go.mod LicenseId     string  
go.mod CustomerId    string  
go.mod CustomerName  string  
go.mod Tier          string  
go.mod CreatedAtInt  int64   
go.mod ExpiresAtInt  int64   
go.mod CreatedBy     string  
go.mod CreatorName   string  
go.mod CreatorEmail  string  
go.mod UniPDF        bool    
go.mod UniOffice     bool    
go.mod UniHTML       bool    
go.mod Trial         bool    
}

func (k LicenseKey) MarshalJSON() ([]byte, error) {
go.mod return json.Marshal(map[string]interface{}{
go.mod go.mod "license_id": k.LicenseId,
go.mod go.mod "customer_id": k.CustomerId,
go.mod go.mod "customer_name": k.CustomerName,
go.mod go.mod "tier": k.Tier,
go.mod go.mod "created_at": k.CreatedAtInt,
go.mod go.mod "expires_at": k.ExpiresAtInt,
go.mod go.mod "created_by": k.CreatedBy,
go.mod go.mod "creator_name": k.CreatorName,
go.mod go.mod "creator_email": k.CreatorEmail,
go.mod go.mod "unipdf": k.UniPDF,
go.mod go.mod "unioffice": k.UniOffice,
go.mod go.mod "unihtml": k.UniHTML,
go.mod go.mod "trial": k.Trial,
go.mod })
}

func main() {
go.mod genKeys := flag.Bool("genkeys", false, "Generate RSA keys")
go.mod privKeyFile := flag.String("privkey", "private.pem", "Private key file")
go.mod pubKeyFile := flag.String("pubkey", "public.pem", "Public key file")
go.mod customerName := flag.String("customer", "TestCustomer", "Customer name")
go.mod licenseFile := flag.String("output", "license.key", "Output license file")
go.mod flag.Parse()

go.mod if *genKeys {
go.mod go.mod if err := generateKeys(*privKeyFile, *pubKeyFile); err != nil {
go.mod go.mod go.mod fmt.Fprintf(os.Stderr, "Error: %v\n", err)
go.mod go.mod go.mod os.Exit(1)
go.mod go.mod }
go.mod go.mod fmt.Println("Keys generated!")
go.mod go.mod fmt.Printf("  Private: %s\n", *privKeyFile)
go.mod go.mod fmt.Printf("  Public: %s\n", *pubKeyFile)
go.mod go.mod 
go.mod go.mod if err := printPublicKeyHex(*pubKeyFile); err != nil {
go.mod go.mod go.mod fmt.Fprintf(os.Stderr, "Error: %v\n", err)
go.mod go.mod go.mod os.Exit(1)
go.mod go.mod }
go.mod go.mod return
go.mod }

go.mod if err := generateLicense(*privKeyFile, *customerName, *licenseFile); err != nil {
go.mod go.mod fmt.Fprintf(os.Stderr, "Error: %v\n", err)
go.mod go.mod os.Exit(1)
go.mod }

go.mod fmt.Println("License generated!")
go.mod fmt.Printf("  File: %s\n", *licenseFile)
go.mod fmt.Printf("  Customer: %s\n", *customerName)
}

func generateKeys(privFile, pubFile string) error {
go.mod privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
go.mod if err != nil {
go.mod go.mod return err
go.mod }

go.mod privBytes := x509.MarshalPKCS1PrivateKey(privateKey)
go.mod privPEM := pem.EncodeToMemory(&pem.Block{
go.mod go.mod Type:  "RSA PRIVATE KEY",
go.mod go.mod Bytes: privBytes,
go.mod })
go.mod if err := os.WriteFile(privFile, privPEM, 0600); err != nil {
go.mod go.mod return err
go.mod }

go.mod pubBytes, err := x509.MarshalPKIXPublicKey(&privateKey.PublicKey)
go.mod if err != nil {
go.mod go.mod return err
go.mod }
go.mod pubPEM := pem.EncodeToMemory(&pem.Block{
go.mod go.mod Type:  "PUBLIC KEY",
go.mod go.mod Bytes: pubBytes,
go.mod })
go.mod return os.WriteFile(pubFile, pubPEM, 0644)
}

func printPublicKeyHex(pubFile string) error {
go.mod pubPEM, err := os.ReadFile(pubFile)
go.mod if err != nil {
go.mod go.mod return err
go.mod }

go.mod block, _ := pem.Decode(pubPEM)
go.mod if block == nil {
go.mod go.mod return fmt.Errorf("failed to decode PEM")
go.mod }

go.mod hexStr := fmt.Sprintf("%x", block.Bytes)
go.mod 
go.mod fmt.Println("\n" + strings.Repeat("=", 80))
go.mod fmt.Println("Replace this HEX in internal/license/license.go (const _afbd):")
go.mod fmt.Println(strings.Repeat("=", 80))
go.mod fmt.Println(hexStr)
go.mod fmt.Println(strings.Repeat("=", 80) + "\n")

go.mod return nil
}

func generateLicense(privFile, customerName, outputFile string) error {
go.mod privPEM, err := os.ReadFile(privFile)
go.mod if err != nil {
go.mod go.mod return err
go.mod }

go.mod block, _ := pem.Decode(privPEM)
go.mod if block == nil {
go.mod go.mod return fmt.Errorf("failed to decode PEM")
go.mod }

go.mod privateKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
go.mod if err != nil {
go.mod go.mod return err
go.mod }

go.mod now := time.Now().UTC()
go.mod license := LicenseKey{
go.mod go.mod LicenseId:    "1234567890ABCDEF",
go.mod go.mod CustomerId:   "CUST1234567890",
go.mod go.mod CustomerName: customerName,
go.mod go.mod Tier:         "business",
go.mod go.mod CreatedAtInt: now.Unix(),
go.mod go.mod ExpiresAtInt: 0,
go.mod go.mod CreatedBy:    "license-generator",
go.mod go.mod CreatorName:  "License Generator",
go.mod go.mod CreatorEmail: "admin@example.com",
go.mod go.mod UniPDF:       true,
go.mod go.mod UniOffice:    true,
go.mod go.mod UniHTML:      true,
go.mod go.mod Trial:        false,
go.mod }

go.mod jsonData, err := json.Marshal(license)
go.mod if err != nil {
go.mod go.mod return err
go.mod }

go.mod hasher := sha512.New()
go.mod hasher.Write(jsonData)
go.mod hashed := hasher.Sum(nil)

go.mod signature, err := rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA512, hashed)
go.mod if err != nil {
go.mod go.mod return err
go.mod }

go.mod part1 := base64.StdEncoding.EncodeToString(jsonData)
go.mod part2 := base64.StdEncoding.EncodeToString(signature)

go.mod licenseContent := "-----BEGIN UNIDOC LICENSE KEY-----\n" +
go.mod go.mod part1 + "\n+\n" + part2 + "\n" +
go.mod go.mod "-----END UNIDOC LICENSE KEY-----\n"

go.mod if err := os.WriteFile(outputFile, []byte(licenseContent), 0644); err != nil {
go.mod go.mod return err
go.mod }

go.mod fmt.Println("\nGenerated license:")
go.mod fmt.Println(licenseContent)

go.mod return nil
}
