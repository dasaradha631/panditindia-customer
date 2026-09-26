# PanditIndia API Contract (v1)

Reference contract for the customer app's service layer (PDF section 17).
The app talks to these endpoints through `lib/services/api_service.dart`;
while `USE_MOCK_API=true` (the default) the same calls are served by
`MockAuthService` with no network traffic.

## Conventions

- Base URL: `--dart-define=API_BASE_URL=...` (fallback `https://api.panditindia.com/v1`)
- All requests/responses are `application/json; charset=utf-8`.
- Authenticated calls send `Authorization: Bearer <access_token>`.
- Timestamps are ISO-8601 UTC. Amounts are integer paise. Currency is `INR`.

### Success envelope

```json
{ "status": "ok", "data": { } }
```

Bare objects are also accepted by the client (`data` unwrapping is
defensive - see `ApiService._request`).

### Error envelope

```json
{
  "status": "error",
  "error": {
    "code": "invalid_credentials",
    "message": "The email/mobile or password you entered is incorrect.",
    "fields": { "mobile": "This mobile number is already registered" }
  }
}
```

| HTTP | `error.code` | Meaning |
| ---- | ------------ | ------- |
| 400 | `invalid_otp` | Verification code incorrect |
| 400 | `weak_password` | Password fails the policy |
| 401 | `invalid_credentials` | Login rejected |
| 401 | `session_expired` | Refresh failed; re-login required |
| 404 | `not_found` | Unknown resource |
| 409 | `mobile_exists` | Mobile already registered |
| 409 | `email_exists` | Email already registered |
| 410 | `otp_expired` | OTP no longer valid |
| 422 | `validation_error` | Field-level errors in `fields` |
| 429 | `rate_limited` | Too many attempts; retry later |
| 500 | `unknown_error` | Unhandled server error |
| 501 | `social_not_configured` | OAuth keys not provisioned |
| - | `network_error` | Client-side connectivity failure |

## Authentication

### `POST /auth/login`

```json
{ "identifier": "9876543210", "password": "Passw0rd" }
```

`identifier` is an email address or a 10 digit Indian mobile number.

```json
{
  "status": "ok",
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "expires_in": 3600,
    "user": { "id": "cus_1001", "full_name": "Rahul Sharma", "mobile": "9876543210",
              "email": "demo@panditindia.com", "city": "Hyderabad" }
  }
}
```

### `POST /auth/register`

```json
{ "full_name": "Priya Iyer", "mobile": "9123456780", "email": "priya@example.com",
  "password": "Secret12", "accept_terms": true, "referral_code": null }
```

Response: same shape as login (`201 Created`).

### `POST /auth/forgot-password`

```json
{ "identifier": "9876543210" }
```

```json
{ "status": "ok", "data": { "otp_token": "...", "masked_destination": "******43210" } }
```

The destination is masked by the server; unknown identifiers return `200`
with the same shape (no user enumeration).

### `POST /auth/verify-otp`

```json
{ "otp_token": "...", "otp": "123456" }
```

```json
{ "status": "ok", "data": { "reset_token": "..." } }
```

### `POST /auth/reset-password`

```json
{ "reset_token": "...", "new_password": "NewPass12" }
```

`204 No Content` on success.

### `POST /auth/refresh`

```json
{ "refresh_token": "..." }
```

```json
{ "status": "ok", "data": { "access_token": "...", "refresh_token": "...", "expires_in": 3600 } }
```

Rotates the refresh token. `401` when expired/revoked - the client clears
the stored session (`ApiService._refresh`).

### `POST /auth/social-login`

```json
{ "provider": "google", "id_token": "...", "access_token": null }
```

Returns the login envelope. Returns `501 social_not_configured` until the
OAuth client ids are provisioned.

### `GET /auth/me` (authenticated)

```json
{ "status": "ok", "data": { "id": "cus_1001", "full_name": "Rahul Sharma", "...": "..." } }
```

### `POST /auth/logout` (authenticated)

`204 No Content`. Revokes the refresh token server-side.

## Token handling (client)

1. Tokens are persisted with `flutter_secure_storage` (`SessionService`).
2. Every request attaches `Authorization: Bearer ...`.
3. On `401` the client performs **one** refresh (`POST /auth/refresh`) and
   replays the original request once; a second `401` clears the session and
   surfaces `session_expired`.
4. Concurrent 401s share a single in-flight refresh (single-flight).

## Mock credentials (`USE_MOCK_API=true`)

| Field | Value |
| ----- | ----- |
| Mobile | `9876543210` |
| Email | `demo@panditindia.com` |
| Password | `Passw0rd` |
| OTP | `123456` (`000000` simulates expiry) |
