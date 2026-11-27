package httpapi

import (
	"encoding/base64"
	"encoding/json"
	"mime"
	"net/http"
	"strings"
	"unicode/utf16"

	"github.com/mbombka/SednoApp/backend/internal/store"
)

type identityInput struct {
	IDToken string `json:"idToken"`
}

func validToken(token string) bool {
	return strings.TrimSpace(token) != "" && len(utf16.Encode([]rune(token))) <= 8192
}

func (a *API) link(w http.ResponseWriter, r *http.Request, session *store.Session) error {
	var input *identityInput
	if err := decode(w, r, &input); err != nil {
		return err
	}
	if input == nil || !validToken(input.IDToken) {
		return problemError{400, "invalid_id_token", "Nieprawidłowy token tożsamości."}
	}
	if a.VerifyIdentity == nil {
		return problemError{401, "invalid_id_token", "Nie można potwierdzić tożsamości."}
	}
	verified := a.VerifyIdentity(r.Context(), input.IDToken)
	if verified == nil {
		return problemError{401, "invalid_id_token", "Nie można potwierdzić tożsamości."}
	}
	if verified.Provider == "email" && !verified.EmailVerified {
		return problemError{403, "email_not_verified", "Potwierdź adres e-mail, aby dokończyć logowanie."}
	}
	result, err := a.Store.Link(r.Context(), session, *verified, a.CredentialKey, a.FreshAccountAccess)
	if err != nil {
		return err
	}
	if result == nil {
		return problemError{409, "account_conflict", "Nie można połączyć tego konta."}
	}
	paid, err := a.paid(r.Context(), &store.Session{AccountID: &result.Account.ID})
	if err != nil {
		return err
	}
	if paid {
		result.Quota, err = a.Store.AccountQuota(r.Context(), result.Account.ID)
		if err != nil {
			return err
		}
	}
	writeJSON(w, 200, result)
	return nil
}

func (a *API) deleteAccount(w http.ResponseWriter, r *http.Request, session *store.Session) error {
	if session.AccountID == nil {
		return problemError{403, "account_required", "Zaloguj się, aby usunąć konto."}
	}
	reauth := problemError{403, "reauthentication_required", "Zaloguj się ponownie, aby usunąć konto."}
	contentType, _, _ := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if r.ContentLength == 0 || (contentType != "application/json" && !strings.HasSuffix(contentType, "+json")) {
		return reauth
	}
	var input *identityInput
	if err := decode(w, r, &input); err != nil {
		return err
	}
	if input == nil || !validToken(input.IDToken) || a.VerifyIdentity == nil {
		return reauth
	}
	verified := a.VerifyIdentity(r.Context(), input.IDToken)
	if verified == nil {
		return reauth
	}
	deleted, err := a.Store.DeleteAccount(r.Context(), session, *verified, a.FreshAccountAccess, a.DeleteIdentity)
	if err != nil {
		return err
	}
	if !deleted {
		return reauth
	}
	w.WriteHeader(http.StatusNoContent)
	return nil
}

func (a *API) billingAccount(session *store.Session, action string) error {
	if session.AccountID == nil {
		return problemError{403, "account_required", "Zaloguj się, aby " + action + "."}
	}
	if a.Billing == nil {
		return problemError{503, "billing_unavailable", "Płatności są niedostępne."}
	}
	return nil
}

func (a *API) currentSubscription(w http.ResponseWriter, r *http.Request, session *store.Session) error {
	if err := a.billingAccount(session, "korzystać z subskrypcji"); err != nil {
		return err
	}
	result, err := a.Billing.Current(r.Context(), *session.AccountID)
	if err != nil {
		return err
	}
	writeJSON(w, 200, result)
	return nil
}

func (a *API) verifyPurchase(w http.ResponseWriter, r *http.Request, session *store.Session) error {
	if err := a.billingAccount(session, "kupić subskrypcję"); err != nil {
		return err
	}
	var input *struct {
		PurchaseToken string `json:"purchaseToken"`
	}
	if err := decode(w, r, &input); err != nil {
		return err
	}
	if input == nil || !validToken(input.PurchaseToken) {
		return problemError{400, "invalid_purchase", "Nieprawidłowy zakup."}
	}
	result, err := a.Billing.Verify(r.Context(), *session.AccountID, input.PurchaseToken)
	if err != nil {
		return err
	}
	writeJSON(w, 200, result)
	return nil
}

func (a *API) notification(w http.ResponseWriter, r *http.Request) {
	if a.Billing == nil {
		w.WriteHeader(503)
		return
	}
	token := bearer(r)
	if !validToken(token) || a.VerifyNotification == nil || !a.VerifyNotification(r.Context(), token) {
		w.WriteHeader(401)
		return
	}
	var envelope struct {
		Message *struct{ Data, MessageID string }
	}
	if err := decode(w, r, &envelope); err != nil {
		handleError(w, r, err)
		return
	}
	message := envelope.Message
	if message == nil || message.Data == "" || message.MessageID == "" || len(utf16.Encode([]rune(message.MessageID))) > 200 {
		w.WriteHeader(400)
		return
	}
	data, err := base64.StdEncoding.DecodeString(message.Data)
	var event struct {
		PackageName                                                            string
		TestNotification, VoidedPurchaseNotification, SubscriptionNotification json.RawMessage
	}
	if err != nil || json.Unmarshal(data, &event) != nil || event.PackageName != a.BillingPackage {
		w.WriteHeader(400)
		return
	}
	if len(event.TestNotification) > 0 {
		w.WriteHeader(204)
		return
	}
	raw := event.VoidedPurchaseNotification
	if raw == nil {
		raw = event.SubscriptionNotification
	}
	if raw == nil {
		w.WriteHeader(204)
		return
	}
	var purchase struct{ PurchaseToken string }
	if json.Unmarshal(raw, &purchase) != nil || !validToken(purchase.PurchaseToken) {
		w.WriteHeader(400)
		return
	}
	if err := a.Billing.Notify(r.Context(), message.MessageID, purchase.PurchaseToken); err != nil {
		handleError(w, r, err)
		return
	}
	w.WriteHeader(204)
}
