package googleapi

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"log/slog"
	"net/http"
	"net/url"
	"slices"
	"strconv"
	"strings"
	"time"
	"unicode/utf16"

	"github.com/mbombka/SednoApp/backend/internal/store"
)

type Integrity struct {
	Client  *Client
	Package string
}

func (p Integrity) Verify(ctx context.Context, installation, token string) bool {
	switch {
	case strings.TrimSpace(token) == "":
		return reject("missing_token")
	case len(utf16.Encode([]rune(token))) > 8192:
		return reject("token_too_long")
	}
	var result struct {
		TokenPayloadExternal struct {
			RequestDetails  struct{ RequestPackageName, RequestHash, TimestampMillis string }
			AppIntegrity    struct{ AppRecognitionVerdict string }
			DeviceIntegrity struct{ DeviceRecognitionVerdict []string }
		}
	}
	code, err := p.Client.call(ctx, http.MethodPost, "https://playintegrity.googleapis.com/v1/"+url.PathEscape(p.Package)+":decodeIntegrityToken", map[string]string{"integrityToken": token}, &result)
	if code > 0 && code/100 != 2 {
		return reject("decode_http_error", "HttpStatus", code)
	}
	if err != nil {
		return reject("transport_error")
	}
	payload := result.TokenPayloadExternal
	details := payload.RequestDetails
	issued, err := strconv.ParseInt(details.TimestampMillis, 10, 64)
	if err != nil {
		return reject("invalid_response")
	}
	age := time.Since(time.UnixMilli(issued))
	if age < -5*time.Second {
		return reject("token_from_future", "TokenAgeSeconds", age.Seconds())
	}
	if age > 5*time.Minute {
		return reject("token_expired", "TokenAgeSeconds", age.Seconds())
	}
	if details.RequestPackageName != p.Package {
		return reject("package_mismatch")
	}
	hash := sha256.Sum256([]byte("guest-session:" + installation))
	if details.RequestHash != base64.RawURLEncoding.EncodeToString(hash[:]) {
		return reject("request_hash_mismatch")
	}
	if payload.AppIntegrity.AppRecognitionVerdict != "PLAY_RECOGNIZED" {
		return reject("app_not_recognized")
	}
	if !slices.Contains(payload.DeviceIntegrity.DeviceRecognitionVerdict, "MEETS_DEVICE_INTEGRITY") {
		return reject("device_not_trusted")
	}
	return true
}

func reject(reason string, metadata ...any) bool {
	slog.Warn("Play Integrity rejected", append([]any{"EventId", 4101, "Reason", reason}, metadata...)...)
	return false
}

type Billing struct {
	Client           *Client
	Package, Product string
}

func (p Billing) base() string {
	return "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" + url.PathEscape(p.Package) + "/purchases/"
}

func (p Billing) Lookup(ctx context.Context, token string) (store.PlaySubscription, error) {
	var result struct {
		SubscriptionState, AcknowledgementState, LinkedPurchaseToken string
		ExternalAccountIdentifiers                                   struct{ ObfuscatedExternalAccountId string }
		LineItems                                                    []struct {
			ProductID  string
			ExpiryTime *time.Time
		}
	}
	code, err := p.Client.call(ctx, http.MethodGet, p.base()+"subscriptionsv2/tokens/"+url.PathEscape(token), nil, &result)
	if code == 404 || code == 410 {
		return store.PlaySubscription{State: "SUBSCRIPTION_STATE_EXPIRED", Acknowledged: true}, nil
	}
	if err != nil || code/100 != 2 || len(result.LineItems) != 1 || result.LineItems[0].ProductID != p.Product || result.SubscriptionState == "" {
		return store.PlaySubscription{}, errUnavailable
	}
	return store.PlaySubscription{
		State: result.SubscriptionState, ExpiresAt: result.LineItems[0].ExpiryTime,
		Acknowledged: result.AcknowledgementState == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
		Binding:      result.ExternalAccountIdentifiers.ObfuscatedExternalAccountId, LinkedToken: result.LinkedPurchaseToken,
	}, nil
}

func (p Billing) Acknowledge(ctx context.Context, token string) error {
	code, err := p.Client.call(ctx, http.MethodPost, p.base()+"subscriptions/"+url.PathEscape(p.Product)+"/tokens/"+url.PathEscape(token)+":acknowledge", struct{}{}, nil)
	if err != nil || code/100 != 2 {
		return errUnavailable
	}
	return nil
}

func (p Billing) LookupPack(ctx context.Context, token string) (store.PlayPack, error) {
	var result struct {
		PurchaseStateContext        struct{ PurchaseState string }
		ObfuscatedExternalAccountID string
		ProductLineItem             []struct {
			ProductID           string
			ProductOfferDetails struct {
				RefundableQuantity *int
				ConsumptionState   string
			}
		}
	}
	code, err := p.Client.call(ctx, http.MethodGet, p.base()+"productsv2/tokens/"+url.PathEscape(token), nil, &result)
	if code == 404 || code == 410 {
		return store.PlayPack{State: "UNAVAILABLE"}, nil
	}
	state := result.PurchaseStateContext.PurchaseState
	if err != nil || code/100 != 2 || state == "" || len(result.ProductLineItem) != 1 {
		return store.PlayPack{}, errUnavailable
	}
	item := result.ProductLineItem[0]
	details := item.ProductOfferDetails
	quantity := 0
	if state == "PURCHASED" && item.ProductID == store.PackProductID {
		if details.RefundableQuantity == nil {
			return store.PlayPack{}, errUnavailable
		}
		quantity = *details.RefundableQuantity
	}
	return store.PlayPack{
		State: state, Product: item.ProductID, Binding: result.ObfuscatedExternalAccountID,
		Quantity: quantity, Consumed: details.ConsumptionState == "CONSUMPTION_STATE_CONSUMED",
	}, nil
}

func (p Billing) ConsumePack(ctx context.Context, token string) error {
	endpoint := p.base() + "products/" + store.PackProductID + "/tokens/" + url.PathEscape(token) + ":consume"
	code, err := p.Client.call(ctx, http.MethodPost, endpoint, nil, nil)
	if err == nil && code/100 == 2 {
		return nil
	}
	status, err := p.LookupPack(ctx, token)
	if err == nil && status.Product == store.PackProductID && status.Consumed {
		return nil
	}
	return errUnavailable
}
