# Interactive quick-add (iOS 17+)

The medium widget has `+5 / +10 / +20` buttons that log an expense **without
opening the app**. No manual Xcode wiring is needed — it's all in code.

## How it works

- **Widget (pure Swift, no Flutter):** `QuickAddIntent` in `FinanceWidget.swift`
  is an `AppIntent`. On tap it appends the amount to a JSON queue
  (`pending_quickadd`) in the shared App Group store, optimistically bumps the
  displayed `expense`/`balance`, and reloads the widget — so the change shows
  instantly. Because it's pure Swift it doesn't drag Flutter into the extension.
- **App (Dart):** `drainPendingQuickAdds()` reads the queue, writes each amount
  as a real expense (first account, base currency, first category) via the
  repositories, clears the queue and republishes the snapshot. It runs at
  startup (`main.dart`) and whenever the app resumes (`FinanceApp` lifecycle
  observer).

So a tapped amount is reflected on the widget immediately and persisted to the
database the next time the app runs (launch/resume) — no manual open required.

## Requirements / caveats

- iOS 17+ (App Intents `Button(intent:)`); buttons are `#available`-gated.
- Test on a **real device** — App Groups and widget registration are unreliable
  on the simulator.
- The widget extension deployment target is set to iOS 17.0.
- The transaction is written by the app process (which owns the Drift DB), so it
  lands in the DB on the next app run; the widget total updates optimistically
  in the meantime.
