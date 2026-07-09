# Finance App

A cross-platform personal-finance app built with Flutter — one codebase for iOS, Android
and web. Local-first and fast, with multi-currency support, an analytics dashboard, a native
iOS home-screen widget, and an optional AI insights layer.

> **Status:** in active development (v0.1). Core tracking, analytics, multi-currency and the
> iOS widget are working; account sync and the paid AI layer run against a Supabase backend
> and can be toggled off to run fully local-first.

<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 37 04" src="https://github.com/user-attachments/assets/b3688799-080c-423b-9d67-6c9c4a1fc21a" />
<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 38 36" src="https://github.com/user-attachments/assets/54d03242-d8cd-41aa-be3a-b1eae5920a0a" />
<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 37 58" src="https://github.com/user-attachments/assets/506a29f6-290f-4745-ae49-0d4408e797b5" />



<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 44 26" src="https://github.com/user-attachments/assets/cd785af2-c4ac-467c-a3b8-c3a59e41e244" />






## What it does

- **Transactions** — expense, income and transfer, with full create/edit/delete
- **Accounts & categories** — custom icons and colors, protected from deletion when in use
- **Multi-currency** — hold money in several currencies; everything rolls up to one base
- **Analytics dashboard** — balance, KPIs, spending trends and per-category breakdown (`fl_chart`)
- **iOS home-screen widget** — see your balance and log a spend in 1–2 taps without opening the app
- **AI insights (optional, paid)** — narrative coaching and forecasts over your own numbers
- **Account & sync (optional)** — sign in to sync across devices; runs local-first without it

<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 37 44" src="https://github.com/user-attachments/assets/cf4a6476-8703-46fc-85fa-593d0830e772" />


## Architecture

Feature-first structure with clean layer separation, so each feature owns its screens, state
and data access, and the shared plumbing stays in `core/`.

- **State:** `flutter_bloc` (Cubit-first), with `equatable` for value states
- **Data:** `drift` — type-safe SQL over SQLite. Repositories expose `Stream`s (`watch…()`),
  so the UI rebuilds itself when data changes instead of being told to refresh
- **DI:** `get_it` — dependencies wired in a single injector, which also makes tests trivial
- **Domain behind repositories:** business logic is unit-tested without touching the UI

```
lib/
├── core/         # database (Drift), DI, config, preferences, sync, shared widgets
├── data/         # models + repositories (the domain boundary)
└── features/     # accounts · add_item · add_transaction · home · ai · auth · widget_bridge
```

### Multi-currency, done honestly

Each currency stores a single `rate_to_base` (its value expressed in the base currency), and
every transaction caches its base-currency amount — so reports just sum one column. When the
user picks a **new** base currency, the whole rate grid is re-expressed with one SQL statement
instead of recalculating everywhere:

```sql
UPDATE currencies SET rate_to_base = rate_to_base * ? WHERE rate_to_base IS NOT NULL;
```

<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 44 42" src="https://github.com/user-attachments/assets/aa9da62f-e49f-4061-9d8f-25e1f7e70cb8" />

### Native iOS widget

A WidgetKit extension (`ios/FinanceWidget`, Swift + SwiftUI) shows a compact snapshot and, via
**App Intents** (iOS 17+), lets you add an expense straight from the home screen. The Flutter
side (`features/widget_bridge`) subscribes to the reactive data streams, recomputes a small
snapshot and hands it to the widget through a shared **App Group** — so the widget updates
automatically whenever data changes anywhere in the app. Setup steps are documented in
[`ios/FinanceWidget/README_SETUP.md`](ios/FinanceWidget/README_SETUP.md).

<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 57 28" src="https://github.com/user-attachments/assets/fdfcccc8-c534-4517-a774-373ddaf7e7ee" />

### AI insights, with cost discipline

The heavy maths (totals, forecasts, exchange math) is computed **locally for free**. Only the
narrative/coaching layer calls the model, and it does so through a **Supabase Edge Function**
that keeps the OpenAI key server-side. Results are cached against a fingerprint of the spending,
so re-opening the AI Coach with unchanged data returns instantly and costs nothing — a real
request only fires when the numbers actually change.

<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 37 27" src="https://github.com/user-attachments/assets/04d94075-6fab-48ec-9730-955ae3b2e8bf" />
<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 37 53" src="https://github.com/user-attachments/assets/ffc45130-e065-4717-98d8-74f65f2a2484" />
<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 37 36" src="https://github.com/user-attachments/assets/63846dff-e08a-431a-9a4d-fa094a7999fb" />


### Backend & sync

Optional, powered by **Supabase** (auth + Postgres + Edge Functions). The schema is sync-aware
from the start: `uuid` + `updatedAt` columns and a `Tombstones` table for soft-deletes, so
data can converge across devices. Until a backend is configured, the app hides account/sync UI
and runs entirely on-device.

<img width="353" height="766" alt="Simulator Screenshot - just 16 - 2026-07-10 at 00 38 07" src="https://github.com/user-attachments/assets/6c2a5a13-0c92-4ed6-924e-351ed8e0943b" />

## Monetization

Freemium: core tracking is free; the "wow" layer (AI insights, forecasts, advanced analytics,
sync) is a subscription. Subscriptions are sold **on the web**, not via in-app purchase — the
in-app Upgrade button opens the pricing page in a browser, so Apple's 30% cut doesn't apply.

## Tech stack

Flutter · Dart · flutter_bloc · Drift (SQLite) · get_it · fl_chart · home_widget ·
Swift / WidgetKit / App Intents · Supabase · flutter_svg · url_launcher

## Testing

Unit tests cover the cubits and repositories — including the multi-currency logic and
base-currency re-basing — using an in-memory Drift database, so they run fast and hit real SQL.

```bash
flutter test
```

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates Drift code
flutter run
```

Deployment endpoints live in
`lib/core/config/app_config.dart`. With the placeholders left in, the app runs fully
local-first; fill them in to enable accounts, sync and AI. For the iOS widget, follow the App
Group / target setup in `ios/FinanceWidget/README_SETUP.md`.

## Note

This is a personal project I'm building to go deep on Flutter, clean architecture, and
Flutter↔native integration. It's under active development and not yet released to the stores.
