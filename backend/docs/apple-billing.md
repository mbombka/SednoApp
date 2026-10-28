# Apple billing on the shared Sedno API

Apple extends the existing API and Firestore database. Google Play/RTDN are
unchanged; the entitlement resolver ORs store evidence into one 400-use daily
allowance. Purchases and quota linking remain transactional.

Apple billing is disabled by default. Before enabling, obtain the values in
`missing-information.md`. Configure `AppleBilling` in server settings:

- `Enabled`, `BundleId`, `ProductId`, numeric `AppAppleId` (production).
- `Environment`: `Production` or `Sandbox`. TestFlight transactions are Sandbox;
  production App Attest is a separate setting and still required for TestFlight.
- `IssuerId`, `KeyId`, `PrivateKeyPath`: App Store Server API credentials.
- `RootCertificatePaths`: administrator-installed trusted Apple PKI certificates,
  obtained from the official Apple certificate authority. Never trust roots
  supplied by the client. Private keys belong in the existing secrets mechanism.

Routes: authenticated `GET/POST /v1/subscription/apple` (`transactionId` for POST),
and Apple-signed `POST /notifications/apple` (`signedPayload`). The callback
must be registered in App Store Connect for the intended environment. Its
traffic bucket is independent of Google RTDN. Server HTTP client logging is
disabled because store requests contain transaction identifiers.

Verification validates signed transaction/renewal data, chain trust, certificate
policy, online revocation, bundle/product/environment and account binding.
The current App Store status is fetched; a historical signed receipt alone
cannot grant access. Apple API credentials and Apple signing certificate trust
are different things. Signature and revocation failures do not grant entitlement.

`apple_purchases` stores environment, account, subscription identifiers/state,
expiry and verification time. `apple_notifications` stores account and processed
date under a hashed notification ID, and expires after 30 days through the
existing cleanup. Account deletion removes both collections' matching records.
Purchase records remain until account deletion; review their retention before
public rollout. No simplification text or audio is stored in these collections.

Verification freshness is at most 15 minutes, bounded by subscription validity.
Expired evidence refreshes on demand with the existing account lease, a 2-second
timeout and a shared one-minute failure cooldown. Failure preserves usage and
falls back to free access. No background polling of inactive accounts is added.
Store calls are outside retrying Firestore transactions. Notifications trigger
a fresh authoritative lookup so out-of-order delivery cannot replay old state.

Deploy compatible code with Apple disabled first; update Android to understand
the new `apple` account provider and `store` response field. Test real Apple
JWS/OCSP connectivity, callback retry, sandbox purchase, restore, renewal,
revocation, shared quota and deletion before enabling purchases publicly.
Changing environment does not convert Sandbox purchases to production rights.
Do not provision another database/backend to complete these tests.

See `mobile/docs/apple_subscription_sandbox.md` for the device checklist and
`contracts/openapi.yaml` for the wire contract. Local synthetic tests do not
establish actual Apple account configuration, signed IPA validity or App Review acceptance.
