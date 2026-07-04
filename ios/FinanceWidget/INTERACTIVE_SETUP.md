# Interactive quick-add (iOS 17+) — wiring

The read-only widget + deep-link already work. This adds **buttons inside the
widget** that log an expense without opening the app. It runs the Flutter
`widgetInteractiveCallback` (already registered in `main.dart`) via
`home_widget`'s background engine.

> Test on a **real device** (App Groups + interactive widgets are unreliable on
> the simulator). iOS 17+ required. When the app is fully suspended iOS may
> briefly foreground it to run the callback — "no-open" is fully silent only
> while the app is in memory (an iOS + Flutter limitation).

Already in the repo (safe, don't break the current build):
- Dart: `lib/features/widget_bridge/widget_interactivity.dart` + registration in
  `main.dart` + `WidgetService.publishOnce()`.
- Swift: `ios/Runner/BackgroundIntent.swift`, and `AppDelegate` registers the
  background plugin registrant.

## Steps (on device)

1. **Add `BackgroundIntent.swift` to both targets.** In Xcode select
   `Runner/BackgroundIntent.swift` → File inspector → **Target Membership** →
   check **Runner** and **FinanceWidgetExtension**.

2. **Link `home_widget` to the widget extension** (so `BackgroundIntent`
   compiles there). In `ios/Podfile` add:
   ```ruby
   target 'FinanceWidgetExtension' do
     use_frameworks!
     pod 'home_widget', :path => '.symlinks/plugins/home_widget/ios'
   end
   ```
   then run `cd ios && pod install`.
   (Alternative: add the `home_widget` Swift package via SPM to the extension.)

3. **Enable the buttons** in `FinanceWidget/FinanceWidget.swift` — paste the
   `quickAddButton(_:)` helper and the `HStack` of buttons from the commented
   block at the bottom of that file into `FinanceWidgetEntryView`.

4. **Run on your iPhone** (Runner scheme). Add the medium widget; the `+5 / +10
   / +20` buttons log an expense (first account, base currency, first category)
   and the widget refreshes.

If the build complains about Flutter embedding in the extension, ping me — we'll
adjust the linking (this is the finicky part and best iterated on-device).
