# Simplyfi_it backend

ASP.NET Core on .NET 10 LTS with EF Core and PostgreSQL. The contract implemented here is [`../contracts/openapi.yaml`](../contracts/openapi.yaml). The earlier `mobile/api/openapi.yaml` is a scaffold draft and is superseded by this contract.

## Local setup

Install .NET 10 SDK and Docker with Compose. From `backend/`:

```sh
export POSTGRES_PASSWORD="$(openssl rand -base64 32)"
docker compose up -d --wait
export ASPNETCORE_ENVIRONMENT=Development
export ConnectionStrings__Postgres="Host=localhost;Port=5432;Database=simplifier;Username=simplifier;Password=${POSTGRES_PASSWORD}"
export Security__CredentialKey="$(openssl rand -base64 32)"
export Security__FingerprintKey="$(openssl rand -base64 32)"
dotnet tool install --global dotnet-ef --version 10.0.3
dotnet ef database update --project src/Simplifier.Infrastructure --startup-project src/Simplifier.Api
dotnet run --project src/Simplifier.Api
```

The API starts on the URL printed by `dotnet run`. `GET /health/live` checks process liveness; `GET /health/ready` checks PostgreSQL. Use HTTPS for every deployed client connection. HTTP is permitted only in Development on a local machine. The Compose port binds to loopback.

Instead of exported secrets, use `dotnet user-secrets set "Security:CredentialKey" "<base64-32-byte-key>" --project src/Simplifier.Api` and similarly set `Security:FingerprintKey` and `ConnectionStrings:Postgres`. Environment variables use double underscores for nested keys. Never put keys or database passwords into tracked configuration. Production uses `appsettings.Production.json` and environment variables or a secret store. The API refuses to start with `Model:Provider=mock` outside Development.

For future schema changes, run `dotnet ef migrations add Name --project src/Simplifier.Infrastructure --startup-project src/Simplifier.Api --output-dir Migrations`, review the migration, then run `database update`. Production migrations should run as an explicit deployment step. The included initial migration creates the schema in an empty database.

## API and data behavior

`POST /v1/guest-sessions` creates a new guest identity and a random opaque bearer credential. Only an HMAC hash of the credential is stored. The installation ID is stored as a keyed hash for operational correlation, but it never authenticates a caller or retrieves an existing credential. Sessions presenting the same installation ID share one quota bucket. Reinstallation can still bypass guest limits; Play Integrity makes scripted abuse harder but does not solve this. IP rate limiting is an additional brake.

`POST /v1/auth/sessions` accepts a guest bearer and a Firebase ID token from either Google or email/password sign-in. The backend checks the token's RSA signature against Google's published certificates, project audience, issuer, issue/expiry times, and Firebase sign-in provider. It then links guest usage to the verified Firebase UID and issues a new random, revocable account bearer valid for seven days. The old guest bearer is revoked. Sign-out revokes the current bearer. The app stores bearers in Android encrypted storage. Two installations linked to the same Firebase UID share a quota without copying usage records; each successful request is counted once. The account session returns the free quota already used that UTC day. Billing remains a separate task; production still resolves free tier only.

Production requires `Firebase:ProjectId`, `PlayIntegrity:PackageName`, and `PlayIntegrity:ServiceAccountJsonPath`. The path points to a service-account JSON file supplied by the deployment secret store, outside the repository. Enable Play Integrity for the app's Google Cloud project and link that project in Play Console. A guest request must carry a standard Play Integrity token whose request hash is Base64URL(SHA-256(UTF-8(`guest-session:` + installation ID))). The backend exchanges it at Google's decode endpoint and requires a matching package/hash, a verdict no older than five minutes, `PLAY_RECOGNIZED`, and `MEETS_DEVICE_INTEGRITY`. `PlayIntegrity:Provider=mock` is available only in Development and is rejected in production. Development uses it by default. A real package name and Play release setup are needed before production rollout.

The development mock returns deterministic text prefixed `Wersja demonstracyjna:`. Production has no model adapter yet; `Model:Provider=disabled` makes simplification return 503. No model key is required or stored. The client should explain AI provider processing before the first submission and warn that generated text may contain errors. Photos and history have no upload endpoint.

The server counts Unicode grapheme clusters and rejects whitespace-only input or more than 4,000 clusters. It also caps HTTP bodies at 128 KiB. Errors use Problem Details with a stable `code` and Polish `title`. The basic rate limiter allows 60 requests per minute per remote IP, independently of daily quota. Configure a trusted reverse proxy to pass the real client IP before deploying at scale; do not trust arbitrary forwarded headers.

Quota reservation is serialized per hashed installation bucket with a PostgreSQL transaction advisory lock. Request status and idempotency remain scoped to the authenticated identity. The transaction commits before calling the model. Active reservations reduce `remaining`, while `used` counts only successful requests. Reservations expire after five minutes; reads mark expired reservations and release their capacity. A late model response cannot commit an expired reservation. A request crossing 00:00 UTC stays on its reservation day. Quota queries use server time. The paid policy is 400 total uses per UTC day, including any free uses; production currently resolves every identity as free.

The database stores guest identity/session metadata, keyed input fingerprints, request status, and reservation day/timestamps. It stores neither submitted text nor result text. The idempotency key is scoped to the bearer identity. An active duplicate returns 202 and a status URL. A completed duplicate returns 409 `result_unavailable`; the result cannot be replayed if the original response was lost. The client must keep a received result locally. A new key can start a new simplification and may consume quota. Failed or expired keys remain terminal, so use a new key to retry. `GET /v1/simplifications/requests/{requestId}` reports status only to the owner.

Operational request metadata is retained for eight days, then deleted hourly. Expired guest sessions are deleted hourly; guest credentials expire after 90 days. Orphaned guest identities older than 90 days are deleted once their sessions and requests are gone. These periods are operational policy, not a statement of legal compliance. The app's privacy notice must separately specify controller details, providers, legal bases, and retention. Do not log request bodies, bearer tokens, fingerprints, or model responses; default sensitive-data logging must remain disabled.

## Tests

```sh
dotnet test Simplifier.Backend.sln
```

Unit tests cover input and quota policy. Integration tests use an isolated Testcontainers PostgreSQL instance, apply the migration, and exercise authentication, request validation, quota and idempotency concurrency, UTC boundaries, reservation recovery, provider failure, and log exclusion. Docker must be running and `docker info` must work for the user running tests; see [Docker's Linux post-installation guide](https://docs.docker.com/engine/install/linux-postinstall) for socket access.
