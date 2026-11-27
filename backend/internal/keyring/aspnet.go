// Package keyring reads the ASP.NET Core AES_256_CBC/HMACSHA256 key ring
// used for Sedno's Google Play purchase tokens.
package keyring

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/base64"
	"encoding/binary"
	"encoding/xml"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

var errKey = errors.New("billing key ring is missing or unsupported")
var errToken = errors.New("invalid protected purchase token")

const magic uint32 = 0x09f0c9f0
const outerLength = 4 + 16
const tokenLimit = 32768

type key struct {
	id                       [16]byte
	secret                   []byte
	created, active, expires time.Time
}
type ring struct {
	keys      map[[16]byte]key
	preferred key
}

type Protector struct {
	path      string
	mu        sync.Mutex
	ring      ring
	refreshAt time.Time
}

type entry struct {
	XMLName    xml.Name
	ID         string    `xml:"id,attr"`
	Version    string    `xml:"version,attr"`
	Created    time.Time `xml:"creationDate"`
	Active     time.Time `xml:"activationDate"`
	Expires    time.Time `xml:"expirationDate"`
	RevokedAt  time.Time `xml:"revocationDate"`
	RevokedKey struct {
		ID string `xml:"id,attr"`
	} `xml:"key"`
}

type descriptor struct {
	Raw struct {
		Encryption struct {
			Algorithm string `xml:"algorithm,attr"`
		} `xml:"encryption"`
		Validation struct {
			Algorithm string `xml:"algorithm,attr"`
		} `xml:"validation"`
		Master string `xml:"masterKey>value"`
	} `xml:"descriptor>descriptor"`
}

func Open(path string) (*Protector, error) {
	p := &Protector{path: path}
	if _, err := p.snapshot(); err != nil {
		return nil, err
	}
	return p, nil
}

func (p *Protector) snapshot() (ring, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	now := time.Now()
	if now.Before(p.refreshAt) && now.Before(p.ring.preferred.expires) {
		return p.ring, nil
	}
	value, err := load(p.path, now)
	if err != nil {
		return ring{}, err
	}
	p.ring, p.refreshAt = value, now.Add(2*time.Minute)
	return value, nil
}

func load(dir string, now time.Time) (ring, error) {
	files, err := os.ReadDir(dir)
	if err != nil {
		return ring{}, errKey
	}
	r := ring{keys: make(map[[16]byte]key)}
	revoked := make(map[[16]byte]bool)
	var revokeBefore time.Time
	for _, file := range files {
		if file.IsDir() || !strings.HasSuffix(file.Name(), ".xml") {
			continue
		}
		f, err := os.Open(filepath.Join(dir, file.Name()))
		if err != nil {
			return ring{}, errKey
		}
		raw, err := io.ReadAll(io.LimitReader(f, 1<<20))
		f.Close()
		if err != nil || len(raw) >= 1<<20 {
			return ring{}, errKey
		}
		raw = bytes.TrimPrefix(raw, []byte{0xef, 0xbb, 0xbf})
		var metadata entry
		if xml.Unmarshal(raw, &metadata) != nil {
			return ring{}, errKey
		}
		switch metadata.XMLName.Local {
		case "key":
			id, err := wireID(metadata.ID)
			if err != nil || metadata.Version != "1" || metadata.Created.IsZero() || metadata.Active.IsZero() || !metadata.Expires.After(metadata.Active) {
				return ring{}, errKey
			}
			var d descriptor
			if xml.Unmarshal(raw, &d) != nil || d.Raw.Encryption.Algorithm != "AES_256_CBC" || d.Raw.Validation.Algorithm != "HMACSHA256" {
				return ring{}, errKey
			}
			secret, err := base64.StdEncoding.DecodeString(strings.TrimSpace(d.Raw.Master))
			if err != nil || len(secret) != 64 {
				return ring{}, errKey
			}
			if _, exists := r.keys[id]; exists {
				return ring{}, errKey
			}
			r.keys[id] = key{id, secret, metadata.Created, metadata.Active, metadata.Expires}
		case "revocation":
			if metadata.Version != "1" || metadata.RevokedAt.IsZero() {
				return ring{}, errKey
			}
			if metadata.RevokedKey.ID == "*" {
				if metadata.RevokedAt.After(revokeBefore) {
					revokeBefore = metadata.RevokedAt
				}
			} else {
				id, err := wireID(metadata.RevokedKey.ID)
				if err != nil {
					return ring{}, errKey
				}
				revoked[id] = true
			}
		default:
			return ring{}, errKey
		}
	}
	for id, k := range r.keys {
		if revoked[id] || k.created.Before(revokeBefore) {
			delete(r.keys, id)
			continue
		}
		if !k.active.After(now) && now.Before(k.expires) &&
			(r.preferred.secret == nil || k.active.After(r.preferred.active) || k.active.Equal(r.preferred.active) && bytes.Compare(k.id[:], r.preferred.id[:]) > 0) {
			r.preferred = k
		}
	}
	if r.preferred.secret == nil {
		return ring{}, errKey
	}
	return r, nil
}

func wireID(id string) ([16]byte, error) {
	value, err := uuid.Parse(id)
	if err != nil {
		return [16]byte{}, errKey
	}
	// System.Guid serializes its first three fields little endian.
	return [16]byte{value[3], value[2], value[1], value[0], value[5], value[4], value[7], value[6],
		value[8], value[9], value[10], value[11], value[12], value[13], value[14], value[15]}, nil
}

func derive(secret, label, header, modifier []byte) [64]byte {
	// SP800-108 counter mode. The 512-bit result fits in one HMAC block.
	input := binary.BigEndian.AppendUint32(nil, 1)
	input = append(input, label...)
	input = append(input, 0)
	input = append(input, header...)
	input = append(input, modifier...)
	input = binary.BigEndian.AppendUint32(input, 512)
	mac := hmac.New(sha512.New, secret)
	mac.Write(input)
	return [64]byte(mac.Sum(nil))
}

var cbcContext = func() []byte {
	header := []byte{0, 0}
	for _, size := range []uint32{32, 16, 32, 32} {
		header = binary.BigEndian.AppendUint32(header, size)
	}
	temp := derive(nil, nil, nil, nil)
	block, _ := aes.NewCipher(temp[:32])
	padding := bytes.Repeat([]byte{16}, 16)
	block.Encrypt(padding, padding)
	header = append(header, padding...)
	return append(header, tag(temp[32:], nil)...)
}()

func tag(key, message []byte) []byte {
	hash := hmac.New(sha256.New, key)
	hash.Write(message)
	return hash.Sum(nil)
}

func additionalData(prefix []byte) []byte {
	label := binary.BigEndian.AppendUint32(bytes.Clone(prefix), 2)
	for _, purpose := range []string{"Sedno", "Sedno.PlayPurchase.v1"} {
		label = binary.AppendUvarint(label, uint64(len(purpose)))
		label = append(label, purpose...)
	}
	return label
}

func (p *Protector) Protect(value string) (string, error) {
	if value == "" || len(value) > tokenLimit || !utf8.ValidString(value) {
		return "", errToken
	}
	r, err := p.snapshot()
	if err != nil {
		return "", err
	}
	k := r.preferred
	payload := binary.BigEndian.AppendUint32(nil, magic)
	payload = append(payload, k.id[:]...)
	var random [32]byte
	rand.Read(random[:])
	keys := derive(k.secret, additionalData(payload), cbcContext, random[:16])
	defer clear(keys[:])
	payload = append(payload, random[:]...)
	pad := aes.BlockSize - len(value)%aes.BlockSize
	plain := append([]byte(value), bytes.Repeat([]byte{byte(pad)}, pad)...)
	defer clear(plain)
	block, _ := aes.NewCipher(keys[:32])
	cipher.NewCBCEncrypter(block, random[16:]).CryptBlocks(plain, plain)
	payload = append(payload, plain...)
	payload = append(payload, tag(keys[32:], payload[outerLength+16:])...)
	return base64.RawURLEncoding.EncodeToString(payload), nil
}

func (p *Protector) Unprotect(value string) (string, error) {
	const header = outerLength + 2*aes.BlockSize
	if len(value) > 2*tokenLimit {
		return "", errToken
	}
	payload, err := base64.RawURLEncoding.DecodeString(value)
	if err != nil || len(payload) < header+aes.BlockSize+sha256.Size ||
		(len(payload)-header-sha256.Size)%aes.BlockSize != 0 || binary.BigEndian.Uint32(payload) != magic {
		return "", errToken
	}
	r, err := p.snapshot()
	if err != nil {
		return "", err
	}
	k, ok := r.keys[[16]byte(payload[4:outerLength])]
	if !ok {
		return "", errToken
	}
	keys := derive(k.secret, additionalData(payload[:outerLength]), cbcContext, payload[outerLength:outerLength+16])
	defer clear(keys[:])
	end := len(payload) - sha256.Size
	if !hmac.Equal(payload[end:], tag(keys[32:], payload[outerLength+16:end])) {
		return "", errToken
	}
	data := payload[header:end]
	block, _ := aes.NewCipher(keys[:32])
	cipher.NewCBCDecrypter(block, payload[outerLength+16:header]).CryptBlocks(data, data)
	defer clear(data)
	pad := int(data[len(data)-1])
	if pad == 0 || pad > aes.BlockSize || pad >= len(data) || !bytes.Equal(data[len(data)-pad:], bytes.Repeat([]byte{byte(pad)}, pad)) {
		return "", errToken
	}
	data = data[:len(data)-pad]
	if !utf8.Valid(data) || len(data) > tokenLimit {
		return "", errToken
	}
	return string(data), nil
}
