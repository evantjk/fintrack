# Current structure — how fintrack-mobile, fintrack-api, and Firebase connect

This replaces the earlier version of this file (which documented the
pre-pivot, Firebase-direct architecture). All three pivot stages from
`proceeding_plan.md` are now done: the FastAPI backend is built, the Flutter
app talks to it instead of Firestore, and `firestore.rules` has been
deployed to deny direct client access. This is a study reference — nothing
described here is planned work, it's what's actually running right now.

## The shape of it, in one picture

```
┌─────────────────┐         ┌──────────────────┐         ┌───────────────────┐
│  fintrack-mobile │  HTTPS* │   fintrack-api    │  Admin  │      Firebase      │
│    (Flutter)     │────────▶│    (FastAPI)      │   SDK   │ Auth + Firestore   │
│                  │         │                   │────────▶│                    │
│  AuthService ────┼─────────┼───────────────────┼────────▶│  Firebase Auth     │
│  (direct, auth   │  Firebase Auth SDK (unchanged)         │  (identity)        │
│   only)          │                                        │                    │
└─────────┬────────┘         └─────────┬─────────┘         └─────────┬──────────┘
          │                            │                               │
   HttpRepository              get_current_uid()                Admin SDK reads/
   (all data: categories,      verifies the Bearer               writes bypass
   transactions)               token, derives uid                firestore.rules
                                server-side                       entirely (by design)
```
\* local dev only right now — plain HTTP to `localhost:8000`/`10.0.2.2:8000`, not deployed.

**Two separate connections, two separate trust models:**
1. **Auth** — the Flutter app still talks to Firebase Auth *directly*. Sign-in/sign-up/Google OAuth/password reset never touch the backend. This didn't change in the pivot.
2. **Data** — categories and transactions now go through `fintrack-api`, which is the only thing that ever talks to Firestore. The client never touches Firestore at all anymore — confirmed by the `cloud_firestore` package being removed entirely (`fintrack-mobile/pubspec.yaml`) and `firestore_repository.dart` deleted.

## Side A: fintrack-mobile (Flutter)

### Auth — unchanged, still direct to Firebase

**[`services/auth_service.dart`](fintrack-mobile/lib/services/auth_service.dart)**
is the only file that calls `FirebaseAuth` methods (sign in/up, Google OAuth,
password reset, sign out). One addition from the pivot:
```dart
Future<String?> getIdToken() async => _auth.currentUser?.getIdToken();
```
This is the bridge between the two trust models — it's how a Firebase-issued
identity becomes something `fintrack-api` can verify.

**[`screens/auth/auth_gate.dart`](fintrack-mobile/lib/screens/auth/auth_gate.dart)**
still listens to `FirebaseAuth.instance.authStateChanges()` directly (bypassing
`AuthService`, as before) and, once signed in, calls
`TransactionProvider.setUser(uid)` — the handoff point from "who is this" to
"load their data."

### Data — new, goes through the API

**[`services/api_config.dart`](fintrack-mobile/lib/services/api_config.dart)**
— the base URL: `http://10.0.2.2:8000` on Android emulator (the special
loopback alias, since `localhost` from inside the emulator means the emulator
itself, not the host machine), `http://localhost:8000` everywhere else
(desktop, iOS sim, web). Local-dev only — no deployed URL yet.

**[`services/http_repository.dart`](fintrack-mobile/lib/services/http_repository.dart)**
— `implements FinanceRepository` (the same interface
`firestore_repository.dart` used to implement). Every method is one HTTP
call:

| `FinanceRepository` method | HTTP call |
|---|---|
| `ensureSeeded()` | `POST /categories/seed` |
| `getCategories()` | `GET /categories` |
| `getTransactions()` | `GET /transactions` |
| `addCategory(cat)` | `POST /categories` → returns `{id}` |
| `updateCategory(cat)` | `PUT /categories/{id}` |
| `deleteCategory(id)` | `DELETE /categories/{id}` |
| `addTransaction(tx)` | `POST /transactions` → returns `{id}` |
| `updateTransaction(tx)` | `PUT /transactions/{id}` |
| `deleteTransaction(id)` | `DELETE /transactions/{id}` |

Every request calls `AuthService.getIdToken()` first and sends
`Authorization: Bearer <token>`. Note what's *not* sent: no uid, anywhere,
in any request. The server derives it from the verified token — the client
couldn't lie about whose data it's accessing even if it tried.

**[`providers/transaction_provider.dart`](fintrack-mobile/lib/providers/transaction_provider.dart)**
— same role as before the pivot (running totals, category filtering,
`getExpenseByCategory()` aggregation, all still computed client-side in
Dart). The *only* change from the old architecture is one line, inside
`setUser(uid)`:
```dart
_repo = _injected ?? HttpRepository();
```
(was `FirestoreRepository(uid)` — note `HttpRepository()` takes no uid
argument at all, for the reason above: the server doesn't trust a
client-supplied uid, so there's nothing useful to pass it.)

Nothing else in the app changed. Every screen still only talks to
`TransactionProvider`/`AuthProvider`; none of them know or care that the
data layer moved.

## Side B: fintrack-api (FastAPI)

```
fintrack-api/app/
├── main.py                 FastAPI() app, CORS (local-dev web testing only),
│                            router registration, /health
├── firebase_client.py       Admin SDK init from GOOGLE_APPLICATION_CREDENTIALS
│                            (a service-account JSON, gitignored, manually
│                            downloaded from the Firebase console — never the
│                            same credential as the client's firebase_options.dart)
├── auth.py                  get_current_uid() — verifies the Bearer token,
│                            returns uid, 401 on anything wrong
├── schemas/                 Pydantic request/response shapes (Category, Transaction)
├── routers/                 HTTP layer only — categories.py, transactions.py
└── services/                Firestore calls live here (category_service.py,
                             transaction_service.py) + the 12-category seed data
```

**Every `/categories` and `/transactions` route** depends on
`get_current_uid` (`app/auth.py`) via FastAPI's `Depends()`. That function:
1. Reads the raw `Authorization` header.
2. Calls `firebase_admin.auth.verify_id_token(token)` — this cryptographically
   verifies the token was actually issued by *this* Firebase project (`mobile-development-b86da`) and hasn't expired, without any network round-trip to Firebase for each request (the Admin SDK caches Google's public signing keys).
3. Returns the `uid` claim from the verified token.

That `uid` is what every service function (`app/services/*.py`) uses to
build the Firestore path: `users/{uid}/categories`, `users/{uid}/transactions`
— same paths as before the pivot, just written server-side now instead of
client-side.

**The Admin SDK bypasses `firestore.rules` entirely** — this is standard
Firebase behavior, not a hole: Admin SDK credentials are trusted by
definition (they're the credentials of the *backend*, not a user), so
`firestore.rules` only ever governed client SDK access. That's exactly why
locking `firestore.rules` down to deny-all (Stage 3) doesn't break
`fintrack-api` — the rules were never in its path to begin with.

## End-to-end example: adding a transaction

```
1. User fills in the Add Transaction form, taps Save.
2. AddEditTransactionScreen → TransactionProvider.addTransaction(tx)
3. TransactionProvider → HttpRepository.addTransaction(tx)
     a. await AuthService.getIdToken()  → a fresh Firebase ID token
     b. POST http://localhost:8000/transactions
        Authorization: Bearer <token>
        body: tx.toMap()  (title, amount, date, category_id, type, note)
4. fintrack-api receives the request:
     a. get_current_uid() verifies the token → uid
     b. routers/transactions.py → services/transaction_service.create_transaction(uid, data)
     c. Firestore (Admin SDK): users/{uid}/transactions.document().set(data)
     d. Returns 201 + {id, ...fields}
5. HttpRepository returns the id to TransactionProvider, which inserts the
   transaction into its in-memory list and notifies listeners.
6. UI rebuilds, shows the new transaction.
```
No step in this chain touches Firestore from the client — verified live by
watching `fintrack-api`'s request log while exercising the app (every
`/categories`/`/transactions` call logged with its status code, all 2xx).

## Security model, before vs. after

| | Before the pivot | Now |
|---|---|---|
| Who can write Firestore | Any signed-in client, for their own `uid` (enforced by `firestore.rules`) | Only `fintrack-api`, via Admin SDK |
| What enforces per-user isolation | `firestore.rules`: `request.auth.uid == userId` | `fintrack-api`'s `get_current_uid()`: the uid comes from a verified token, never from client input |
| `firestore.rules` | Permissive (scoped to own uid) | `allow read, write: if false` — deployed, denies the client SDK entirely |
| Where validation could live | Nowhere really — Firestore Rules syntax is limited | The API layer (not yet added — that's Stage 4, deferred) |

## What's deliberately unchanged / out of scope here

- **Business logic** (totals, category filtering, expense aggregation) is
  still 100% client-side in `TransactionProvider` — the pivot moved *where
  data is stored and fetched from*, not *who computes what*. Per your
  instruction, this stays as-is for now.
- **Stage 4** (splitting `TransactionProvider`'s responsibilities,
  consistent error handling, moving aggregation server-side, fixing the
  stale root README) is explicitly deferred, not started.
- **Deployment** — both sides only run locally right now
  (`http://localhost:8000`). Hosting the API anywhere reachable from a real
  device is a separate, later decision.
