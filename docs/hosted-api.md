# Dewey Hosted API — Wire Contract v1.1

This document is the normative specification for the HTTP interface between the
open-source Dewey CLI and the commercial Dewey Hosted service. Both sides MUST
implement and test against this document. Anything not described here is
out-of-contract and MUST NOT be relied on by the CLI.

---

## 1. Overview

**Open-core boundary**

- **CLI (open source)**: `dewey-telemetry.sh`, `install.sh`, any future client
  code. Sends events and validates license keys. This is the side described as
  "client" throughout.
- **Hosted service (commercial)**: `ckoglmeier/dewey-cloud` (private repo).
  Receives events, validates keys, processes billing webhooks. Routes
  `/v1/webhooks/checkout` and `/v1/admin/*` are service-internal and out of
  contract (§8).

**Contract version**: v1.1. The base path `/v1/` is the version discriminator.
v1.0 clients (no `install_id` field) remain valid — `install_id` is optional.

---

## 2. Authentication

**Key format**: `dwy_` prefix followed by exactly 32 lowercase hex characters
(16 random bytes, `secrets.token_hex(16)`). Example: `dwy_a1b2c3d4e5f6...`

**Transport**: License keys MUST be sent as HTTP Bearer tokens.

```
Authorization: Bearer dwy_<32 hex chars>
```

The server stores only the SHA-256 hash of the key. The plaintext key is
transmitted once at issuance and never persisted server-side.

**Key lifecycle states** and their meaning per endpoint:

| State | `/v1/events` | `/v1/license/validate` |
|---|---|---|
| `active` | 200 Accepted | `{"valid": true}` |
| `past_due` | 200 Accepted (grace period; service still processes events) | `{"valid": true}` |
| `canceled` | 403 Subscription canceled | `{"valid": false}` |
| `revoked` (internal) | 401 (treated as key-not-found) | `{"valid": false}` |

**License file on the client**: `~/.claude/dewey-license`, mode 0600. The file
MUST contain only the raw license key (no trailing newline required). The
installer MUST write this file with mode 0600 and MUST NOT log or echo the key.
The key MUST NOT appear in process argument lists (`ps`/`/proc/<pid>/cmdline`);
`install.sh` pipes the key over stdin to `curl --data @-`.

---

## 3. Telemetry event schema

Events are JSONL: one JSON object per line, UTF-8, newline-terminated.

### Required fields

| Field | Type | Description |
|---|---|---|
| `ts` | string | ISO-8601 UTC timestamp, format `YYYY-MM-DDTHH:MM:SSZ` (emitted by `datetime.now(timezone.utc).strftime(...)`) |
| `event` | string | Event name (e.g. `skill_invoke`, `extension_created`) |

### Optional fields

| Field | Type | Description |
|---|---|---|
| `install_id` | string | Pseudonymous install identifier. Exactly 16 lowercase hex characters. Generated once at install time via CSPRNG (`secrets.token_hex(8)`); stored in `~/.claude/dewey-install-id` (mode 0600). Never derived from hostname, username, MAC address, or any other machine-identifying information. Absent when the file does not exist (e.g. hand-built environments). The server MAY use distinct `install_id` counts per org per billing period for seat measurement. |
| `org` | string | Org identifier (see resolution order below). Overridden server-side. |
| `skill` | string | Skill name |
| `plugin` | string | Plugin name |
| `parent_plugin` | string | Plugin that owns the invoked skill |
| `additions` | string | User-authored extension body (body field — stripped by default) |
| `user_intent` | string | One-line user description (body field — stripped by default) |
| `via` | string | How the skill was reached |
| `path` | string | Path file identifier |
| `tools_added` | array of strings | Tools added (from comma-separated `tools_added=` kv) |
| `plugins` | array of strings | Plugins involved (from comma-separated `plugins=` kv) |

### Org resolution order (client side)

1. `$DEWEY_ORG` environment variable (stripped of whitespace)
2. First line of `~/.claude/dewey-active-org` (if the file exists)
3. Literal string `"default"`

**Server override**: the server MUST discard any `org` or `org_id` field
supplied by the client and substitute the org associated with the authenticated
license key. Client-claimed org values are never trusted.

### Body-stripping default

The fields `additions` and `user_intent` are sensitive prose. They are logged
locally but MUST be stripped from any batch sent to the endpoint unless the
client has `DEWEY_TELEMETRY_FORWARD_BODIES=1`. The `strip-bodies` subcommand of
`dewey-telemetry.sh` enforces this: it removes both fields from any event where
`event == "extension_created"` unless the env var is set.

---

## 4. POST /v1/events

Ingest a batch of telemetry events.

**Authentication**: Bearer license key (required).

**Content-Type**: `application/x-ndjson`

**Request body**: JSONL, one event object per line. Blank lines are ignored.

**Size limit**: 1 048 576 bytes (1 MB). The server reads the full body before
processing; if `Content-Length` exceeds 1 MB the body is drained and a 413 is
returned (so the client receives the response rather than a connection reset).

**Batch behavior**: lines are processed sequentially. Each line that is valid
JSON and a JSON object is stored; each malformed line increments `rejected`.
A malformed line MUST NOT cause a 500 — it is silently counted as rejected.

**Responses**:

| Code | Body | Condition |
|---|---|---|
| 200 | `{"accepted": N, "rejected": M}` | Request processed (N ≥ 0, M ≥ 0) |
| 401 | `{"error": "invalid or missing license key"}` | Missing, unknown, or revoked key |
| 403 | `{"error": "subscription canceled"}` | Key found, org status is `canceled` |
| 413 | `{"error": "request body too large (max 1 MB)"}` | Body exceeds 1 MB |

`past_due` orgs receive 200 (grace period); their events are stored normally.

---

## 5. POST /v1/license/validate

Check whether a license key is valid. Used by `install.sh` immediately after
writing a key to disk, so the user gets immediate feedback.

**Authentication**: none (unauthenticated). The key is in the request body.

**Request body**: `{"key": "<license-key>"}` (JSON)

**Response**: always HTTP 200 (unless body is too large).

```json
{"valid": true}
```
or
```json
{"valid": false}
```

**Security note**: this endpoint is intentionally boolean-only. It MUST NOT
return org name, plan, status, or any other billing-sensitive information.
Those fields are exposed only on bearer-authenticated paths, where the key
itself is the authentication credential.

`canceled` and `revoked` keys return `{"valid": false}`. A key that does not
exist returns `{"valid": false}`.

| Code | Condition |
|---|---|
| 200 | Always (valid or not) |
| 413 | Body exceeds 1 MB |

---

## 6. GET /healthz

Liveness probe. No authentication.

**Response**: `200 {"ok": true}`

---

## 7. Client behavioral requirements

A conforming CLI implementation MUST satisfy all of the following.

**Hard opt-out gates (forward subcommand)**. Before making any network request
the client MUST check all three gates in order and exit 0 silently if any fails:
1. `DEWEY_TELEMETRY=0` — global off
2. `DEWEY_TELEMETRY_ENDPOINT` not set — no endpoint configured
3. `~/.claude/dewey-license` absent or empty — no license key

**Offset tracking**. The client MUST track its position in the local JSONL log
using a byte offset stored in `~/.claude/dewey-forward-offset`. On a successful
200 response, the offset MUST be advanced to the end of the batch just sent.
On any non-200 response or network error, the offset MUST NOT advance (so the
batch is retried on the next run).

**Batch caps**. Each forward run MUST send at most 500 lines or 900 KB,
whichever is reached first. These caps ensure the 1 MB server limit is never
exceeded (900 KB < 1 MB) while keeping individual runs bounded.

**Silent failure**. The client MUST exit 0 on all forward-path failures
(network error, non-200 response, parse error). It MUST NOT print anything to
stdout or stderr that would appear in a Claude Code session. Non-200 responses
MAY be logged to `~/.claude/dewey-refresh.log` (not user-visible).

**License file permissions**. The license file MUST be stored at
`~/.claude/dewey-license` with mode 0600. The install step that writes this file
MUST NOT fail the overall install if the validation call fails or the endpoint
is unreachable — the key is stored and forwarding will authenticate on first
use.

**Body strip before send**. The client MUST run `strip-bodies` on the batch
before POSTing, unless `DEWEY_TELEMETRY_FORWARD_BODIES=1`.

---

## 8. Out of contract

The following routes exist in the server but are service-internal. The CLI
MUST NOT call them, and they MUST NOT be documented as client-facing:

- `POST /v1/webhooks/checkout` — Stripe webhook receiver (HMAC-verified,
  idempotency-gated). Provisions orgs and license keys from billing events.
- `POST /v1/admin/rotate` — Admin token-authenticated key rotation. Operator
  tooling only.

---

## 9. Versioning policy

- **Additive changes** (new optional response fields, new optional request
  fields, new events): no version bump required. Clients MUST ignore unknown
  fields.
- **Minor version bump** (e.g. v1.1): new optional endpoints or behaviors that
  do not break v1.0 clients.
- **Breaking changes**: served under a new path prefix (`/v2/...`). The v1
  path MUST continue to function until all known clients have migrated. A
  breaking change is any removal or semantic change to a required field,
  status code, or auth mechanism.

The contract version (`v1.0`) is encoded in the URL path, not in a header.
