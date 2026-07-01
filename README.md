FinTrack — Personal Finance Tracker

Features

- **Dashboard** — total balance, a computed "% saved" indicator, income/expense
  summary, quick-add actions, and recent activity.
- **Full CRUD** — create, read, update, and delete both **transactions** and
  **categories**, with form validation.
- **Transactions** — searchable history grouped by date (Today / Yesterday /
  date), with income/expense filters and swipe-to-delete.
- **Statistics** — a custom-painted **donut chart** plus per-category spending
  bars and a transaction overview.
- **Categories** — manage income/expense categories with custom icons & colours.
- **Accounts** — email/password and Google sign-in via Firebase Auth.
- **Cloud persistence** — categories and transactions are stored in Firestore,
  reached through a dedicated backend (not directly from the client); nothing
  is lost on restart and data follows the user across devices.
- **5… now 4 switchable themes** — a custom theming engine offering **Original**
  (clean Material), **Gundam** and **Hello Kitty** (retro pixel), and
  **Luxury — "Old Money"** (elegant serif). One widget set renders every theme.

📱 Screenshots

| Dashboard (Original) | Dashboard (Luxury) | Statistics |
|---|---|---|
| ![Home](fintrack-mobile/screenshots/home_original.png) | ![Luxury](fintrack-mobile/screenshots/home_luxury.png) | ![Statistics](fintrack-mobile/screenshots/statistics.png) |

| Transactions | Add Transaction | Categories |
|---|---|---|
| ![Transactions](fintrack-mobile/screenshots/transactions.png) | ![Add](fintrack-mobile/screenshots/add_transaction.png) | ![Categories](fintrack-mobile/screenshots/categories.png) |

🛠 Tech Stack

| Concern | Choice |
|---|---|
| Framework / language (client) | Flutter · Dart |
| Backend | FastAPI (Python) |
| State management | `provider` (`ChangeNotifier`) |
| Auth | Firebase Auth (email/password + Google), called directly from the client |
| Data persistence | Firestore — written only by the backend, via the Firebase Admin SDK |
| Formatting | `intl` (currency & dates) |
| Theming | Custom `ThemeExtension` (`PixelColors`) + style-knobs |
| Charts / mascots | Hand-written `CustomPainter` (no chart dependency) |

🏗 Architecture

The repository is a monorepo with two parts, both active:

```
fintrack/
├── fintrack-mobile/   # Flutter app
└── fintrack-api/      # FastAPI backend
```

**Two separate connections, two separate trust models** (see
[current_structure.md](current_structure.md) for the full breakdown):

1. **Auth** — the Flutter app talks to Firebase Auth *directly*. Sign-in,
   sign-up, Google sign-in, and password reset never touch the backend.
2. **Data** — categories and transactions go through `fintrack-api`, which
   is the only thing that talks to Firestore. The client has no Firestore
   dependency at all; `firestore.rules` denies the client SDK entirely, so
   the API is the sole writer.

```
fintrack-mobile (Flutter)                 fintrack-api (FastAPI)              Firebase
─────────────────────────                 ──────────────────────              ────────
AuthService ─────────────────────────────────────────────────────────────▶ Firebase Auth
  (sign in/up, Google, reset)                                               (identity)

TransactionProvider
  → HttpRepository ───── Bearer <ID token> ─────▶ get_current_uid()
                          GET/POST/PUT/DELETE        verifies token, derives uid
                          /categories, /transactions  ↓
                                                    Admin SDK ──────────────▶ Firestore
                                                    (bypasses firestore.rules    (data)
                                                     by design)
```

The Flutter app (`fintrack-mobile/`) follows a layered structure with clear
separation of concerns:

```
fintrack-mobile/lib/
├── main.dart                            # App entry: Firebase.initializeApp, providers, MaterialApp
├── firebase_options.dart                # Firebase project config (generated)
├── models/                              # Plain data models
│   ├── transaction.dart
│   └── category.dart
├── services/
│   ├── auth_service.dart                # All Firebase Auth calls (the only file that touches it)
│   ├── finance_repository.dart          # Storage-agnostic interface (Category/Transaction CRUD)
│   ├── http_repository.dart             # FinanceRepository impl - calls fintrack-api
│   ├── in_memory_repository.dart        # FinanceRepository impl - test double
│   ├── api_config.dart                  # fintrack-api base URL (local-dev only)
│   └── default_categories.dart          # Starter categories seeded for new users
├── providers/                           # State management (ChangeNotifier)
│   ├── transaction_provider.dart        # transactions, categories, totals, aggregation
│   ├── auth_provider.dart               # auth UI state, forwards to AuthService
│   └── theme_provider.dart              # active theme
├── routes/
│   ├── app_router.dart                  # onGenerateRoute
│   └── app_routes.dart                  # route name constants
├── screens/                             # One file per screen
│   ├── home_screen.dart                 # dashboard + bottom navigation host
│   ├── transactions_screen.dart
│   ├── statistics_screen.dart
│   ├── categories_screen.dart
│   ├── add_edit_transaction_screen.dart
│   └── auth/                            # auth_gate, login, signup, forgot_password
├── widgets/                             # Reusable UI components
│   ├── balance_card.dart
│   ├── transaction_tile.dart
│   ├── theme_switcher.dart
│   ├── auth_scaffold.dart
│   └── mascots.dart                     # CustomPainter theme mascots
└── theme/
    └── app_theme.dart                   # PixelColors ThemeExtension + all themes
```

The backend (`fintrack-api/`) is a thin, conventionally-layered FastAPI app:

```
fintrack-api/app/
├── main.py                 # FastAPI() app, CORS (local-dev), router registration, /health
├── firebase_client.py      # Firebase Admin SDK init (service-account credentials)
├── auth.py                 # Verifies the Bearer ID token, derives uid for every request
├── schemas/                # Pydantic request/response models (category.py, transaction.py)
├── routers/                # HTTP layer only (categories.py, transactions.py)
└── services/                # Firestore reads/writes + default-category seed data
```

**Data flow:** UI (screens/widgets) → `Provider` (state) → `FinanceRepository`
(interface) → `HttpRepository` → `fintrack-api` → Firestore. Widgets read
theme tokens via `PixelColors.of(context)` and rebuild when the provider
notifies a change.

🎨 Theming engine

Themes are not just colour swaps. `app_theme.dart` exposes a `PixelColors`
`ThemeExtension` carrying both **role colours** (`income`, `expense`, `accent`,
`surface`, gradient, …) and **style knobs** (`radius`, `borderWidth`,
`hardShadow`, `fontFamily`). The same widgets therefore render:

- **Original** — soft, rounded, Material (Roboto)
- **Gundam / Hello Kitty** — square corners, hard offset shadows, pixel font
  (Press Start 2P)
- **Luxury** — soft rounded, antique-gold accents, elegant **serif** (EB Garamond)

Any new UI must read these tokens (never hard-code colours/fonts) so all themes
keep working.

🚀 Getting Started

Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.12`)
- Python 3.12+ (for the backend)
- A Firebase Admin service-account key for the project (one-time manual step
  — see `fintrack-api/README.md`)

### Run both sides at once

```bash
run-dev.bat
```

This opens the API (`uvicorn`, `http://localhost:8000`) and the Flutter app
(`flutter run -d chrome`) in separate windows. It assumes `fintrack-api/.venv`
already exists with dependencies installed and `serviceAccountKey.json` is in
place — see `fintrack-api/README.md` for that one-time setup.

### Run manually

```bash
# Backend
cd fintrack-api
.venv\Scripts\uvicorn.exe app.main:app --reload --port 8000

# Client (separate terminal)
cd fintrack-mobile
flutter pub get
flutter run -d chrome
```

Build a release APK
```bash
cd fintrack-mobile
flutter build apk --release
```

(A release build talks to `fintrack-api` over `http://localhost`/`10.0.2.2`,
which is local-dev only — pointing a release build at a real device needs a
deployed API URL, not yet set up.)

✅ Quality

```bash
flutter analyze   # static analysis (currently: no issues)
flutter test      # unit / widget tests
```

📁 Data model

| Entity | Key fields |
|---|---|
| **Transaction** | id, title, amount, date, type (income/expense), categoryId, note |
| **Category** | id, name, icon, colorValue, type (income/expense/both) |

Stored in Firestore (`users/{uid}/transactions`, `users/{uid}/categories`),
written only by `fintrack-api`, and aggregated client-side for balance,
totals, and per-category statistics.

References

- [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- [FastAPI](https://fastapi.tiangolo.com) & [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- Client packages: `provider`, `firebase_auth`, `firebase_core`, `http`, `intl`, `uuid`
- Backend packages: `fastapi`, `uvicorn`, `firebase-admin`, `pydantic`, `python-dotenv`
- Fonts: [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) and
  [EB Garamond](https://fonts.google.com/specimen/EB+Garamond) (SIL OFL)
- UI design exploration assisted by **Google Stitch**; development assisted with
  AI tooling. (Disclosed per academic-honesty guidance.)
