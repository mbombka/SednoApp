# Apple App Attest

Android continues to use Play Integrity at `/v1/guest-sessions`. iOS has a
separate verification path within the same API, service account and Firestore
`(default)` database. Both issue the same Sedno guest credentials and use the
existing transactional quota and account linking implementation.

Apple verification is disabled by default. Before activation, configure:

```text
AppleAppAttest__Enabled=true
AppleAppAttest__TeamId=<10-character App ID prefix>
AppleAppAttest__BundleId=xyz.sedno.app
AppleAppAttest__Environment=production
```

Use the actual App ID prefix shown by Apple; usually this is the Team ID.
Development attestations require both `ASPNETCORE_ENVIRONMENT=Development` and
an explicit `AppleAppAttest__Environment=development`. TestFlight uses production.
There is no mock, simulator bypass, or configurable root certificate.

1. The app generates an App Attest key on the device.
2. `POST /v1/ios/attestation/challenges` with `installationId`, `keyId` and
   `purpose=register` returns `challengeId`, `challenge`, `expiresAt`.
3. Construct this exact UTF-8 string (without quotes or a trailing newline):
   `sedno:app-attest:v1:{purpose}:{installationId}:{keyId}:{challengeId}:{challenge}`.
   The SHA256 digest is the 32-byte `clientDataHash` supplied to Apple's API.
4. Call `attestKey`, then submit `installationId`, `keyId`, `challengeId` and
   standard-base64 `attestation` to `POST /v1/ios/attestation/keys`.
5. For a guest session request a fresh challenge with `purpose=session`, call
   `generateAssertion` with the corresponding hash, then submit `installationId`,
   `keyId`, `challengeId` and standard-base64 `assertion` to
   `POST /v1/ios/guest-sessions`.

`keyId` is standard padded base64 encoding of 32 bytes; `challenge` is standard
padded base64 of 32 random bytes; `challengeId` is 32 lowercase hexadecimal
characters. Installation IDs allow ASCII letters, digits, hyphens and underscores
and optional trailing base64 padding (at most two `=` characters), with at most
200 characters in total. Padding is accepted for identifiers persisted by earlier
clients. Fields are never trimmed or case-normalized, preserving quota continuity.
Challenges expire after five minutes. Each assertion consumes its challenge and
advances a strictly increasing counter in one Firestore transaction, including
across Cloud Run replicas. A consumed assertion cannot mint another session.
If session delivery fails, create a new challenge and assertion.

The client must save the pending registration before sending it. Retrying the
same registration is idempotent: the server stores the registration ID and a
SHA256 fingerprint of the encoded attestation, never resets a registered key's
counter, and never transfers a key to another installation. An absent/expired key
returns `app_attest_key_unknown`; perform at most one key rotation and registration
attempt. Other cryptographic failures return `integrity_failed`; disabled endpoints
return `app_attest_unavailable`. Do not silently fall back to unauthenticated access.

Validation checks the Apple chain using the embedded App Attestation Root CA,
nonce extension, App ID hash, development/production AAGUID, initial zero counter,
credential ID, certificate public key hash and COSE key consistency. Assertions
check the App ID hash, ECDSA signature and counter. Certificate downloads and
system-root fallback are disabled. The pinned root SHA256 fingerprint is
`1cb9823ba28ba6ad2d33a006941de2ae4f513ef1d4e831b9f7e0fa7b6242c932`.
The CBOR decoder is bounded and rejects duplicate keys, trailing bytes and
unsupported encodings. Rejection paths do not log proofs or installation IDs.

`apple_attest_challenges` stores the challenge, installation HMAC, key ID, purpose
and expiry. `apple_attest_keys` stores installation HMAC, verified public key,
environment, counter, registration fingerprint and dates. Keys expire after 90
days without a successful assertion. The scheduled metadata job deletes expired
records; reads reject expired records immediately. Account deletion removes
associated keys and challenges. This implementation does not perform Apple's
optional device fraud-metric assessment or retain the attestation receipt.

Synthetic cryptographic unit tests cover certificate trust, challenge binding,
application/environment identity, credential key, signatures and replay. Firestore
emulator tests cover cross-replica challenge consumption, counters, registration
retries, expiry and cleanup. Before enabling on a server, validate the full flow
on a signed physical iPhone, including TestFlight production attestations. Synthetic
tests do not establish acceptance of real Apple proofs.

Sources:

- [Apple: validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server)
- [Apple App Attestation Root CA](https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem)
- [Apple: mitigate fraud with App Attest and DeviceCheck](https://developer.apple.com/videos/play/wwdc2021/10244/)
