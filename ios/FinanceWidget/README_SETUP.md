# iOS home-screen widget — Xcode setup

The Swift/WidgetKit code lives here (`FinanceWidget.swift`). Creating the
widget **extension target** and enabling the **App Group** are the only steps
that must be done in the Xcode UI (they can't be reliably scripted). Everything
else — the data bridge, deep-link handling, snapshot — is already wired in the
Flutter app.

App Group used everywhere: **`group.com.example.financeApp`**
(matches `WidgetService.appGroupId` and `FinanceWidget.swift`).

## Steps (~5 min)

1. Open the workspace: `open ios/Runner.xcworkspace` (use the **workspace**, not
   the project).
2. **Runner target → Signing & Capabilities → + Capability → App Groups**, then
   add `group.com.example.financeApp`.
3. **File → New → Target… → Widget Extension**. Name it **`FinanceWidget`**.
   Uncheck "Include Live Activity" and "Include Configuration App Intent"
   (we use a static widget). Finish, and **Activate** the scheme when prompted.
4. On the new **FinanceWidget target → Signing & Capabilities → + Capability →
   App Groups**, add the same `group.com.example.financeApp`.
5. Open the auto-generated `FinanceWidget/FinanceWidget.swift` in Xcode and
   **replace its entire contents** with the code from
   `ios/FinanceWidget/FinanceWidget.swift` in this folder.
6. Set the FinanceWidget target's **iOS Deployment Target to 14.0+**.
7. Select the **Runner** scheme and run on your device/simulator. Then on the
   home screen: long-press → **+** → search "Finance" → add the widget.

Tapping the widget opens the app on the quick add-transaction screen
(`financeapp://add`, already handled). The widget refreshes automatically
whenever you add/edit/delete a transaction.

## Notes

- The widget reads the shared store written by `home_widget`
  (`UserDefaults(suiteName: "group.com.example.financeApp")`), keys:
  `income`, `expense`, `balance`, `symbol`, `categories` (JSON).
- True "add without opening the app" (interactive buttons) needs iOS 17
  App Intents — a follow-up on top of this read-only + deep-link version.
- If the deep link doesn't route on tap, confirm the `financeapp` URL scheme is
  present in `ios/Runner/Info.plist` (already added).
