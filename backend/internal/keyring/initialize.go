package keyring

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
)

func Initialize(path string) error {
	if err := os.MkdirAll(path, 0700); err != nil {
		return errKey
	}
	entries, err := os.ReadDir(path)
	if err != nil || len(entries) != 0 {
		return errKey
	}
	now := time.Now().UTC()
	id := uuid.NewString()
	var secret [64]byte
	rand.Read(secret[:])
	defer clear(secret[:])
	raw := fmt.Sprintf(`<?xml version="1.0" encoding="utf-8"?>
<key id="%s" version="1">
  <creationDate>%s</creationDate>
  <activationDate>%s</activationDate>
  <expirationDate>%s</expirationDate>
  <descriptor deserializerType="Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption.ConfigurationModel.AuthenticatedEncryptorDescriptorDeserializer, Microsoft.AspNetCore.DataProtection, Version=10.0.0.0, Culture=neutral, PublicKeyToken=adb9793829ddae60">
    <descriptor>
      <encryption algorithm="AES_256_CBC" />
      <validation algorithm="HMACSHA256" />
      <masterKey p:requiresEncryption="true" xmlns:p="http://schemas.asp.net/2015/03/dataProtection">
        <value>%s</value>
      </masterKey>
    </descriptor>
  </descriptor>
</key>
`, id, now.Format(time.RFC3339Nano), now.Format(time.RFC3339Nano), now.AddDate(1, 0, 0).Format(time.RFC3339Nano), base64.StdEncoding.EncodeToString(secret[:]))
	file, err := os.OpenFile(filepath.Join(path, "key-"+id+".xml"), os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return errKey
	}
	_, writeErr := file.WriteString(raw)
	closeErr := file.Close()
	if writeErr != nil || closeErr != nil {
		return errKey
	}
	return nil
}
