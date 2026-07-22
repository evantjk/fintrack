# fintrack-api

FastAPI backend for FinTrack. Mirrors the data currently stored in Firestore
exactly (same fields, same sort order, same default-category seeding) so it
can later replace direct Firestore access from `fintrack-mobile`. See
`../current_structure.md` and `../proceeding_plan.md` for the full context
and pivot plan — this README only covers running and testing this service.

## Setup

```
cd fintrack-api
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### Firebase Admin credentials (manual step — required before the server can start)

1. Firebase console → project `mobile-development-b86da` → Project Settings
   → Service Accounts tab → "Generate new private key". This downloads a
   JSON file.
2. Save it as `fintrack-api/serviceAccountKey.json` (already gitignored —
   never commit this file).
3. Copy `.env.example` to `.env` if you haven't already, and confirm
   `GOOGLE_APPLICATION_CREDENTIALS` points at that file.

Without this file, `firebase_client.py` raises a clear error on first use
rather than failing silently.

## Running

```
uvicorn app.main:app --reload --port 8000
```

Then open **http://127.0.0.1:8000/docs** for the interactive Swagger UI —
every endpoint below is testable there without writing any client code.

- `GET /health` — confirms the server is up and Firestore credentials load.
- `GET/POST /categories`, `PUT/DELETE /categories/{id}`, `POST /categories/seed`
- `GET/POST /transactions`, `PUT/DELETE /transactions/{id}`

All `/categories` and `/transactions` routes require an
`Authorization: Bearer <firebase-id-token>` header — there's no OAuth
scheme wired into Swagger, just a plain header field to paste a token into.

## Testing in Swagger with a real Firebase ID token

Firebase ID tokens are JWTs that expire after an hour and can't be
fabricated by hand — they have to come from an actual sign-in. The
easiest way to get one without touching the Flutter app is the Firebase
Auth REST API, using the project's public web API key (already shipped in
the client at `fintrack-mobile/lib/firebase_options.dart` — not a secret,
it only identifies the project):

**1. Create a throwaway test account (once):**
```powershell
$apiKey = "AIzaSyA2xcq6s2nwR6AsQb-mDLRmxeIMOK37d6g"
Invoke-RestMethod -Method Post `
  -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey" `
  -ContentType "application/json" `
  -Body '{"email":"apitest@example.com","password":"TestPass123!","returnSecureToken":true}'
```

**2. Sign in to mint a fresh token (repeat whenever it expires):**
```powershell
$apiKey = "AIzaSyA2xcq6s2nwR6AsQb-mDLRmxeIMOK37d6g"
$resp = Invoke-RestMethod -Method Post `
  -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey" `
  -ContentType "application/json" `
  -Body '{"email":"apitest@example.com","password":"TestPass123!","returnSecureToken":true}'
$resp.idToken | Set-Clipboard
```

**3. In `/docs`,** paste the clipboard contents into any endpoint's
`authorization` field as `Bearer <pasted-token>` and click Execute.

## Verification checklist

1. `uvicorn app.main:app --reload` starts without error.
2. `/docs` loads and lists both routers.
3. `GET /categories` on a brand-new test uid auto-seeds and returns the 12
   default categories, sorted income-then-expense, alphabetical within each.
4. Calling `GET /categories` again returns the same 12 (seeding is
   idempotent).
5. `POST /transactions` returns 201 + a generated id; `GET /transactions`
   shows it, newest first.
6. `PUT`/`DELETE` round-trip correctly; `DELETE` then `GET` confirms removal.
7. Omitting the `Authorization` header, or sending a garbage token, returns
   401 on every `/categories`/`/transactions` route.
