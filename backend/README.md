# Sedno backend

ASP.NET Core on .NET 10 LTS with EF Core and PostgreSQL. The contract implemented here is [`../contracts/openapi.yaml`](../contracts/openapi.yaml). The earlier `mobile/api/openapi.yaml` is a scaffold draft and is superseded by this contract.

## Local setup

Install .NET 10 SDK and Docker with Compose. From `backend/`:

```sh
export POSTGRES_PASSWORD="$(openssl rand -base64 32)"
docker compose up -d --wait
export ASPNETCORE_ENVIRONMENT=Development
export ConnectionStrings__Postgres="Host=localhost;Port=5432;Database=sedno;Username=sedno;Password=${POSTGRES_PASSWORD}"
export Security__CredentialKey="$(openssl rand -base64 32)"
export Security__FingerprintKey="$(openssl rand -base64 32)"
dotnet tool install --global dotnet-ef --version 10.0.3
dotnet ef database update --project src/Sedno.Infrastructure --startup-project src/Sedno.Api
dotnet run --project src/Sedno.Api
```

The API starts on the URL printed by `dotnet run`. `GET /health/live` checks process liveness; `GET /health/ready` checks PostgreSQL. Use HTTPS for every deployed client connection. HTTP is permitted only in Development on a local machine. The Compose port binds to loopback.
The development Compose database, user, and volume now use `sedno`; an existing
development volume under the previous name is not connected automatically.
Re-enter any local .NET user secrets under the new `sedno-backend-dev` secret ID.

Instead of exported secrets, use `dotnet user-secrets set "Security:CredentialKey" "<base64-32-byte-key>" --project src/Sedno.Api` and similarly set `Security:FingerprintKey` and `ConnectionStrings:Postgres`. Environment variables use double underscores for nested keys. Never put keys or database passwords into tracked configuration. Production uses `appsettings.Production.json` and environment variables or a secret store. The API refuses to start with `Model:Provider=mock` outside Development.

For future schema changes, run `dotnet ef migrations add Name --project src/Sedno.Infrastructure --startup-project src/Sedno.Api --output-dir Migrations`, review the migration, then run `database update`. Production migrations should run as an explicit deployment step. The included initial migration creates the schema in an empty database.

## API and data behavior

`POST /v1/guest-sessions` creates a new guest identity and a random opaque bearer credential. Only an HMAC hash of the credential is stored. The installation ID is stored as a keyed hash for operational correlation, but it never authenticates a caller or retrieves an existing credential. Sessions presenting the same installation ID share one quota bucket. Reinstallation can still bypass guest limits; Play Integrity makes scripted abuse harder but does not solve this. IP rate limiting is an additional brake.

`POST /v1/auth/sessions` accepts a guest bearer and a Firebase ID token from either Google or email/password sign-in. The backend checks the token's RSA signature against Google's published certificates, project audience, issuer, issue/expiry times, and Firebase sign-in provider. It then links guest usage to the verified Firebase UID and issues a new random, revocable account bearer valid for seven days. The old guest bearer is revoked. Sign-out revokes the current bearer. The app stores bearers in Android encrypted storage. Two installations linked to the same Firebase UID share a quota without copying usage records; each successful request is counted once. The account session returns the free quota already used that UTC day. Subscriptions are verified separately through Google Play; purchase and restore require an account session.

Production requires `Firebase:ProjectId`, `PlayIntegrity:PackageName`, and `PlayIntegrity:ServiceAccountJsonPath`. The path points to a service-account JSON file supplied by the deployment secret store, outside the repository. Enable Play Integrity for the app's Google Cloud project and link that project in Play Console. A guest request must carry a standard Play Integrity token whose request hash is Base64URL(SHA-256(UTF-8(`guest-session:` + installation ID))). The backend exchanges it at Google's decode endpoint and requires a matching package/hash, a verdict no older than five minutes, `PLAY_RECOGNIZED`, and `MEETS_DEVICE_INTEGRITY`. `PlayIntegrity:Provider=mock` is available only in Development and is rejected in production. Development uses it by default. A real package name and Play release setup are needed before production rollout.

The development mock returns deterministic text prefixed `Wersja demonstracyjna:`. The OpenAI adapter uses GPT-6 Luna through the Responses API when explicitly enabled (see below). The default `Model:Provider=disabled` makes simplification return 503. The mock and disabled modes need no model key. The client should explain AI provider processing before the first submission and warn that generated text may contain errors. Photos and history have no upload endpoint.

The server counts Unicode grapheme clusters and rejects whitespace-only input or more than 4,000 clusters. It also caps HTTP bodies at 128 KiB. Errors use Problem Details with a stable `code` and Polish `title`. The basic rate limiter allows 60 requests per minute per remote IP, independently of daily quota. Configure a trusted reverse proxy to pass the real client IP before deploying at scale; do not trust arbitrary forwarded headers.

Quota reservation is serialized only across overlapping installation buckets with PostgreSQL transaction advisory locks acquired in sorted order. Independent installations reserve concurrently. A shared topology lock allows quota transactions to overlap; linking and account deletion take its exclusive counterpart while changing quota membership. Those less frequent database mutations can still briefly pause quota writes, but their Firebase network calls run before taking the exclusive topology lock, protected by a per-UID lock. Request status and idempotency remain scoped to the authenticated identity. The transaction commits before calling the model. Active reservations reduce `remaining`, while `used` counts only successful requests. Reservations expire after five minutes; reads mark expired reservations and release their capacity. A late model response cannot commit an expired reservation. A request crossing 00:00 UTC stays on its reservation day. Quota queries use server time. The free policy is 5 successful simplifications per UTC day, including guests. The paid policy is 400 total uses per UTC day, including any free uses; Google Play entitlements resolve the paid tier without resetting existing daily usage.

The database stores guest identity/session metadata, keyed input fingerprints, request status, and reservation day/timestamps. It stores neither submitted text nor result text. The idempotency key is scoped to the bearer identity. An active duplicate returns 202 and a status URL. A completed duplicate returns 409 `result_unavailable`; the result cannot be replayed if the original response was lost. The client must keep a received result locally. A new key can start a new simplification and may consume quota. Failed or expired keys remain terminal, so use a new key to retry. `GET /v1/simplifications/requests/{requestId}` reports status only to the owner.

Operational request metadata is retained for eight days, then deleted hourly. Expired guest sessions are deleted hourly; guest credentials expire after 90 days. Orphaned guest identities older than 90 days are deleted once their sessions and requests are gone. These periods are operational policy, not a statement of legal compliance. The app's privacy notice must separately specify controller details, providers, legal bases, and retention. Do not log request bodies, bearer tokens, fingerprints, or model responses; default sensitive-data logging must remain disabled.

## Tests

```sh
dotnet test Sedno.Backend.sln
```

Unit tests cover input and quota policy. Integration tests use an isolated Testcontainers PostgreSQL instance, apply the migration, and exercise authentication, request validation, quota and idempotency concurrency, UTC boundaries, reservation recovery, provider failure, and log exclusion. Docker must be running and `docker info` must work for the user running tests; see [Docker's Linux post-installation guide](https://docs.docker.com/engine/install/linux-postinstall) for socket access.


## Google Play subscriptions

See [sandbox procedure](../mobile/docs/google_play_subscription_sandbox.md).
Billing is disabled by default in both environments. There is no runtime billing
mock. Configure these values via environment variables or a secret store:

- `Billing__Enabled=true`
- `Billing__PackageName`: the exact registered Android application ID
- `Billing__ProductId`: one subscription product with one monthly auto-renewing
  base plan, no trial/introductory offers; configure PLN 9.99 in Play Console
- `Billing__ServiceAccountJsonPath`: deployment-mounted Google service account
  JSON, with Android Publisher API enabled and Play Console access to view
  purchases/subscriptions and manage orders/subscriptions for this app
- `Billing__NotificationAudience`: exact HTTPS Pub/Sub push audience
- `Billing__PushServiceAccountEmail`: exact dedicated push authentication account
- `Billing__DataProtectionKeyPath`: persistent, restricted directory for ASP.NET
  Data Protection keys (required when billing is enabled outside Development)

Use a shared persistent key ring across API replicas, permissions limited to the
service identity, encryption of its volume/backups and a deployment secret store.
Do not lose these keys: purchase tokens in PostgreSQL cannot then be decrypted.
Data Protection uses application name `Sedno`; development uses its default local
key ring. Raw tokens are never logged; the named Google HTTP client has all HTTP
loggers disabled because Publisher URLs contain purchase tokens. Reverse proxies,
APM and outbound tracing must also exclude bodies, authorization and Google URLs.

`GET /v1/subscription` returns the account binding used as Play's obfuscated
account ID. `POST /v1/subscription` verifies/restores a token, rejects mismatched
ownership/product, acknowledges eligible purchases and stores the encrypted token
plus SHA-256 lookup hash and minimal state metadata. Pending purchases receive no
entitlement or acknowledgement. Active/grace-period and canceled-but-unexpired
purchases grant access. Paused, held, pending and expired purchases do not.
Replacement tokens retire the linked old entitlement. Every quota decision
uses the server-side verified purchase snapshot, with no Google network call.
`GET /v1/subscription` refreshes and persists that snapshot; the app starts it
without blocking text input, on startup, resume, session changes, and every five
minutes while running. Store offer loading does not delay server verification.
Successful refresh also updates the displayed server quota. Purchase/restore and
RTDN update the same snapshot. A snapshot is valid for at most 15 minutes and
never past the Google purchase expiry. Missing/stale state uses the free limit
without resetting usage. A missed RTDN can therefore leave access stale for at
most 15 minutes; Google unavailability does not extend that window. Apply the
`CachedSubscriptionVerification` migration before deploying this version.
Verification uses per-account and per-token locks; different accounts refresh
concurrently. Deploy this lock-protocol change with all API instances restarted
together (do not mix old and new writers during a rolling deployment).
This trades immediate verification on every request for bounded staleness and lower latency. Monitor Publisher API quota before scale.

Publish RTDN to a dedicated Pub/Sub topic. Grant
`google-play-developer-notifications@system.gserviceaccount.com` publisher access.
Create an authenticated push subscription targeting
`https://<backend>/notifications/google-play`, using the configured audience and
push account. Grant Pub/Sub's service agent permission to mint that account's
OIDC token. Restrict who can publish to the topic and impersonate the push account.
Configure retry/backoff, dead-letter monitoring and alerting. Google sends a
base64 payload inside a Pub/Sub envelope. Signed pushes are checked for issuer,
audience and verified email. Test events return 204; subscription and voided
purchase events fetch current Google state instead of trusting event type or time.
Concurrent duplicate message IDs are serialized and committed with the state
update. Failures return non-2xx and are retried, including when ownership is not
yet available. Keep dead-letter messages until resolved; never paste tokens into
logs/tickets. Deduplication IDs are retained until an operational purge policy is
chosen; purchase metadata is retained for subscription management and must be
covered by the privacy policy. No simplification content is stored.

A refund with revocation removes entitlement once Google reports expiry. A
refund without revocation follows the entitlement still returned by Google;
it must not revoke a renewed period just because an older order was refunded.

## Privacy and account deletion

`DELETE /v1/account` requires an account bearer; no target ID is accepted.
It deletes the Firebase identity, all linked installation identities, request
metadata, sessions on every device, and encrypted purchase records. Google Play
subscriptions are **not canceled**. Firebase deletion is idempotent for
`USER_NOT_FOUND`; if Firebase succeeds but the PostgreSQL transaction fails,
retry with the same backend bearer. The two systems have no distributed
transaction. A response lost after commit requires checking account status /
support; a 401 alone is not reported as successful deletion by the app.
No submitted/result text is retained. Pub/Sub dedup IDs contain no account/token
link and retain their existing policy. Google retains its own purchase records.

Supply `Firebase__DeletionServiceAccountJsonPath` from the deployment secret
store. Use the same Firebase project, grant `firebaseauth.users.delete` and
`firebaseauth.users.get`, enable Identity Toolkit API, and restrict the credential.
Production refuses startup without this path. Missing configuration in Development
fails deletion closed, with no fake success. Account linking also checks Firebase
account existence so a still-signed token cannot recreate a deleted account.
HTTP logging is disabled for the dedicated identity client; exclude bodies,
credentials, emails and query strings in proxy/APM logs as well.

`GET /usun-konto` is a public, Polish HTML page served by this backend, with a
mailto deletion request, identity verification instructions and the subscription
warning. Set `Privacy__DeletionEmail` to a monitored mailbox (required outside
Development). Deploy the backend at its real HTTPS domain and enter
`https://<backend>/usun-konto` in Play Console. No external site was deployed by
this implementation. Mail is sent by the user's email client; the page does not
store requests or automatically delete an account based on an email address.
Operators must verify ownership, perform deletion through an authorized account
session/support process, and define response and backup-erasure periods before
launch. Never request passwords, tokens, texts or photos by email.

See [draft privacy policy](../docs/privacy-policy-draft.pl.md) and
[Data Safety checklist](../docs/google-play-data-safety.pl.md). Both require the
marked missing facts before production publication.


## OpenAI simplification

There are two explicit modes: `openai-agent` uses a saved Platform Agent (setup
below), and `openai` calls Responses API directly with code-managed instructions.
The following Responses API settings apply only to `openai`.

The adapter is implemented only on the backend; no model key belongs in Flutter,
`--dart-define`, tracked JSON, screenshots or logs. Model availability is documented
by [OpenAI](https://developers.openai.com/api/docs/models/gpt-6-luna); access and
billing on your own project must still be checked. No live call was made as part
of implementation.

From `backend/`, configure the development API using local user secrets:

```sh
dotnet user-secrets set "Model:Provider" "openai" --project src/Sedno.Api
# Enter the key without echoing it or including it literally in shell history.
read -rsp 'OpenAI API key: ' SEDNO_OPENAI_KEY
printf '\n'
dotnet user-secrets set "Model:OpenAI:ApiKey" "$SEDNO_OPENAI_KEY" --project src/Sedno.Api
unset SEDNO_OPENAI_KEY
```

Run the API with `ASPNETCORE_ENVIRONMENT=Development` and the database/security
configuration from Local setup. User secrets override Development's mock setting.
To return to the demo, set `Model:Provider` to `mock` in user secrets. Production
requires a secret store/environment variables `Model__Provider=openai` and
`Model__OpenAI__ApiKey`; it deliberately remains disabled in tracked configuration.
Configure the mobile backend URL following the root README.

Defaults: `Model:OpenAI:Model=gpt-6-luna`, `MaxOutputTokens=4096` (allowed 256–8192),
`TimeoutSeconds=8` (allowed 1–8). The API has a nine-second simplification deadline;
Flutter has one ten-second end-to-end deadline, including retries and session access.
HTTP 504 `simplification_timeout` is terminal and is not automatically retried.
The Flutter HTTP request is aborted when its deadline expires. Only this
model has been enabled; changing models requires evaluation and code review.
Missing/invalid configuration fails startup. Requests have fixed HTTPS destination,
no redirects, no tools, no automatic provider retries, `reasoning.effort=none`,
`store=false`, and a 256 KiB upstream response cap. Input remains limited to 4,000
grapheme clusters; empty, incomplete, refused, malformed or oversized output fails
without returning partial results. Successful output is capped at 16,000 graphemes.
Named-client HTTP loggers are disabled. Also exclude content and credentials in
proxy/APM/outbound tracing at deployment.

The developer instructions preserve meaning, numbers, amounts, dates, conditions
and negations. User text is a separate user message and is explicitly treated as
data, including embedded attempts to override instructions. This is a mitigation,
not proof that a model always preserves meaning or resists prompt injection.
A provider failure returns the existing sanitized 503 and releases the reservation;
client cancellation retains the existing reservation-expiry policy. A retry of a
failed request key is terminal; a new user attempt needs a new key. Provider costs
may still occur after a timeout or disconnect.

`store=false` disables response application-state storage, not all provider
retention. Verify project data controls, contractual entity, regional eligibility
and retention before deployment; see [OpenAI data controls](https://developers.openai.com/api/docs/guides/your-data).
Run the [acceptance procedure](../docs/model-acceptance.pl.md) with synthetic texts
before enabling real user traffic.

## Saved OpenAI Agent

Use this mode for the Agent created in OpenAI Platform → Agents → Setup agent.
The backend reads the existing `OpenAI:ApiKey` and `OpenAI:AgentId` user secrets;
it does not copy, replace or append to the saved agent's prompt or model.
From the repository root, enable the mode:

```sh
dotnet user-secrets set "Model:Provider" "openai-agent" --project backend/src/Sedno.Api
ASPNETCORE_ENVIRONMENT=Development dotnet run --project backend/src/Sedno.Api
```

This assumes PostgreSQL, migrations and the other Local setup secrets are ready.
Keep the model and agreed Polish instructions in the saved agent. Change
`OpenAI:AgentId` to switch agents, then restart the backend. Saved-agent prompt
and model edits apply to new sessions without changing Flutter or backend code.
Production remains disabled by default; enable via the deployment secret store:
`Model__Provider=openai-agent`, `OpenAI__ApiKey`, `OpenAI__AgentId`.
Missing/invalid key or agent ID fails startup. `OpenAI:TimeoutSeconds` defaults
to 8 and accepts 1–8. The API deadline is nine seconds and the mobile deadline is
ten seconds. Existing overrides above eight seconds must be reduced before restart.
Normal cleanup runs in the background.

The restricted application key needs `api.agents.read`, `api.agents.write` and
`api.responses.write`. The Agents scopes also permit configuration management;
use a dedicated Sedno project. See the [official quickstart](https://developers.openai.com/api/docs/guides/agents-api/quickstart).
No live account/model-access verification is implied by mocked tests.

Each simplification creates a fresh session with `OpenAI-Beta: agents=v1` and
the text in a separate user message in `input`. Conversation-only sessions
require initial input; empty session creation is rejected by the live API.
The adapter sends `stream=true` and receives the final answer and completed turn
in that single POST response, with no status polling or items GET. It accepts
one completed `final_answer` message for that turn and waits for the explicit
turn-completed event. Idle, EOF, commentary, reasoning and partial output are
not success. SSE frames are capped at 256 KiB, the full stream at 4 MiB, and
final text at 16,000 graphemes. The saved model and instructions are unchanged. The session
overrides tools to an empty list, disables multi-agent delegation, selects plain
text output and uses `environment.type=none`; model/instructions are inherited.
HTTP redirects and named-client logging are disabled. There are no submission
retries. Proxy/APM tracing must also exclude bodies, credentials and response text.
Existing quota, idempotency and sanitized 503 behavior apply unchanged.

Unlike the direct adapter, Agents API stores conversation state: there is no
`store=false` guarantee here. The backend keeps an in-memory set of session IDs
and retry times, with no cleanup table or migration. Tracking a session wakes the
background service. Completion marks it ready for immediate deletion; failure,
cancellation or timeout marks it for cancellation followed by deletion. The
request never waits for that HTTP cleanup. Each cleanup attempt has a three-second
budget; failures retry after 10, 20, 40 seconds, etc., capped at five minutes.
When no sessions or recovery scans remain, the worker waits for a signal without
polling the database or OpenAI. HTTP 404 counts as already cleaned up.

At startup the worker lists sessions of the configured saved agent, following
pagination. It only touches sessions with metadata
`sedno_purpose=sedno-simplification-v1`, which this adapter sets on creation.
It schedules recovered sessions no earlier than one minute after creation to
avoid interrupting a request on another API replica. A lost create response also
schedules a recovery scan. Failed scans retry with backoff. Recovery can issue
idempotent cleanup calls from multiple replicas; active normal requests remain
protected by the age threshold. Old unmarked sessions and sessions of previously
configured agents require operator reconciliation. Use a dedicated Sedno project.

The set is lost on restart; startup listing reconstructs it from OpenAI. There is
no periodic global scan while idle, so leftovers from another failed replica can
remain until a recovery scan/restart. Provider unavailability and a stopped backend
can delay deletion. Monitor generic cleanup warnings. There is no durable delivery
guarantee and API deletion does not promise immediate physical erasure.
A lost session-creation response may leave submitted content at OpenAI without
a session ID known to this backend. Do not retry creation automatically; include
these sessions in operational reconciliation. API deletion does not promise
immediate physical erasure. See [session deletion](https://developers.openai.com/api/docs/guides/agents-api/sessions/manage).
Upstream HTTP failures log only the numeric status, without response bodies,
URLs, submitted text, credentials or underlying exceptions.

Content-free .NET metrics use Meter `Sedno.OpenAI.Agents`:
`sedno.agent.duration` (seconds; `agent_id`, `outcome`) and `sedno.agent.tokens`
(`agent_id`, `kind=input_tokens|output_tokens`). Token counts come from completed
turns when available; missing/late usage and failed turns make these counters
incomplete, not a final bill. Export this Meter through your monitoring system;
no exporter or admin dashboard is deployed here. Use Platform Usage filtered to
the Sedno project/key for provider billing. Session deletion removes the session
from the API, so do not rely on retaining content-bearing traces for accounting.
