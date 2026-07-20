//
//  FinanceWidget.swift
//  FinanceWidget
//

import AppIntents
import CoreText
import SwiftUI
import UIKit
import WidgetKit

// Must match WidgetService.appGroupId in the Flutter app and the App Group
// capability added to both the Runner and this extension target.
private let appGroupId = "group.com.lgdtodaoxiao.financeApp"

// MARK: - Model

struct CategoryItem: Identifiable {
  let id = UUID()
  let name: String
  let value: Double
  let color: Color
}

struct FinanceEntry: TimelineEntry {
  let date: Date
  let income: Double
  let expense: Double
  let balance: Double
  let symbol: String
  let categories: [CategoryItem]
}

// MARK: - Data loading (from the shared App Group store written by home_widget)

private func colorFromARGB(_ argb: Int) -> Color {
  let a = Double((argb >> 24) & 0xFF) / 255.0
  let r = Double((argb >> 16) & 0xFF) / 255.0
  let g = Double((argb >> 8) & 0xFF) / 255.0
  let b = Double(argb & 0xFF) / 255.0
  return Color(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
}

private func money(_ value: Double, _ symbol: String) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  formatter.minimumFractionDigits = 2
  formatter.maximumFractionDigits = 2
  let text = formatter.string(from: NSNumber(value: value)) ?? "0.00"
  return symbol.isEmpty ? text : "\(text) \(symbol)"
}

private func loadEntry() -> FinanceEntry {
  let defaults = UserDefaults(suiteName: appGroupId)
  let income = defaults?.double(forKey: "income") ?? 0
  let expense = defaults?.double(forKey: "expense") ?? 0
  let balance = defaults?.double(forKey: "balance") ?? 0
  let symbol = defaults?.string(forKey: "symbol") ?? ""

  var categories: [CategoryItem] = []
  if let json = defaults?.string(forKey: "categories"),
    let data = json.data(using: .utf8),
    let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
  {
    for item in array {
      let name = item["name"] as? String ?? ""
      let value = (item["value"] as? NSNumber)?.doubleValue ?? 0
      let colorInt = (item["color"] as? NSNumber)?.intValue ?? 0xFF9E9E_9E
      categories.append(
        CategoryItem(name: name, value: value, color: colorFromARGB(colorInt)))
    }
  }

  return FinanceEntry(
    date: Date(),
    income: income,
    expense: expense,
    balance: balance,
    symbol: symbol,
    categories: categories)
}

// MARK: - Timeline

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> FinanceEntry {
    FinanceEntry(
      date: Date(), income: 0, expense: 0, balance: 0, symbol: "$",
      categories: [])
  }

  func getSnapshot(
    in context: Context, completion: @escaping (FinanceEntry) -> Void
  ) {
    completion(loadEntry())
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<FinanceEntry>) -> Void
  ) {
    completion(Timeline(entries: [loadEntry()], policy: .never))
  }
}

// MARK: - UI

private let accent = Color(red: 0.23, green: 0.51, blue: 0.96)
private let negative = Color(red: 0.94, green: 0.31, blue: 0.37)

struct FinanceWidgetEntryView: View {
  var entry: FinanceEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("This month")
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
        // Tapping the widget body (outside buttons) opens the full add screen.
        Image(systemName: "plus.circle.fill")
          .foregroundColor(accent)
      }
      Text(money(entry.expense, entry.symbol))
        .font(.title2).bold()
        .foregroundColor(negative)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
      Text("Spent")
        .font(.caption2)
        .foregroundColor(.secondary)

      if family != .systemSmall {
        Spacer(minLength: 2)
        ForEach(entry.categories.prefix(2)) { category in
          HStack(spacing: 6) {
            Circle().fill(category.color).frame(width: 8, height: 8)
            Text(category.name).font(.caption).lineLimit(1)
            Spacer()
            Text(money(category.value, entry.symbol)).font(.caption).bold()
          }
        }
      }
      Spacer(minLength: 0)
    }
    .padding(14)
    // This is the informational summary widget; the dedicated QuickAddWidget
    // now owns interactive one-tap logging. Tapping here opens the add screen.
    // The `homeWidget` query param is REQUIRED: the home_widget plugin only
    // forwards URLs that carry it (isWidgetUrl in SwiftHomeWidgetPlugin).
    .widgetURL(URL(string: "financeapp://add?homeWidget"))
  }
}

struct FinanceWidget: Widget {
  let kind = "FinanceWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        FinanceWidgetEntryView(entry: entry)
          .containerBackground(.white, for: .widget)
      } else {
        FinanceWidgetEntryView(entry: entry)
          .background(Color.white)
      }
    }
    .configurationDisplayName("Finance")
    .description("Your spending at a glance. Tap to add a transaction.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Widget bundle

@main
struct FinanceWidgets: WidgetBundle {
  var body: some Widget {
    FinanceWidget()
    QuickAddWidget()
  }
}

// MARK: - Interactive quick-add (iOS 17+)

/// Pure-Swift App Intent (no Flutter dependency): queues `{categoryId, amount}`
/// in the shared App Group store and optimistically updates the widget totals.
/// The Flutter app drains the queue and writes the real transaction into that
/// category on next launch / resume (see drainPendingQuickAdds in Dart).
@available(iOS 17.0, *)
struct QuickAddIntent: AppIntent {
  static var title: LocalizedStringResource = "Quick add expense"

  @Parameter(title: "Category") var categoryId: Int
  @Parameter(title: "Amount") var amount: Double
  @Parameter(title: "Shortcut") var shortcutId: String

  init() {}
  init(categoryId: Int, amount: Double, shortcutId: String) {
    self.categoryId = categoryId
    self.amount = amount
    self.shortcutId = shortcutId
  }

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)

    var queue: [[String: Any]] = []
    if let json = defaults?.string(forKey: "pending_quickadd"),
      let data = json.data(using: .utf8),
      let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    {
      queue = arr
    }
    queue.append(["categoryId": categoryId, "amount": amount])
    if let out = try? JSONSerialization.data(withJSONObject: queue),
      let outStr = String(data: out, encoding: .utf8)
    {
      defaults?.set(outStr, forKey: "pending_quickadd")
    }

    // Optimistic update so the widget reflects the spend immediately.
    let expense = defaults?.double(forKey: "expense") ?? 0
    defaults?.set(expense + amount, forKey: "expense")
    let balance = defaults?.double(forKey: "balance") ?? 0
    defaults?.set(balance - amount, forKey: "balance")

    // Drive the brief logged-state fade on the tapped button.
    defaults?.set(shortcutId, forKey: "last_added_id")
    defaults?.set(Date().timeIntervalSince1970, forKey: "last_added_at")

    WidgetCenter.shared.reloadTimelines(ofKind: "FinanceWidget")
    WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddWidget")
    return .result()
  }
}

// NOTE: interactive widget buttons cannot open the app — iOS 17 ignores
// `openAppWhenRun` for widget intents (they always run in the background).
// "Ask each time" shortcuts therefore go through deep links instead:
// `Link` in the medium widget, `widgetURL` in the small one.

// MARK: - Quick-add widget (configurable category shortcuts)

/// One configured shortcut, mirrored from the Flutter app's `shortcuts` JSON.
struct Shortcut: Identifiable {
  let id: String
  let categoryId: Int
  let name: String
  let color: Color
  /// Legible foreground on top of [color] (white on dark fills, near-black on
  /// light ones) — computed from the fill, NOT the category's icon colour,
  /// which is free-form and often clashes (e.g. black on saturated blue).
  let onColor: Color
  /// MaterialIcons codepoint of the category icon.
  let iconCode: Int
  let mode: String  // "fixed" | "presets" | "open"
  let amount: Double?
  let presets: [Double]

  /// The amount a single tap should log (fixed value, or the first preset).
  var primaryAmount: Double? {
    switch mode {
    case "fixed": return amount
    case "presets": return presets.first
    default: return nil
    }
  }
}

/// White or near-black, whichever is legible on the given ARGB fill.
private func contrastingOn(_ argb: Int) -> Color {
  let r = Double((argb >> 16) & 0xFF) / 255.0
  let g = Double((argb >> 8) & 0xFF) / 255.0
  let b = Double(argb & 0xFF) / 255.0
  let luminance = 0.299 * r + 0.587 * g + 0.114 * b
  return luminance > 0.62 ? Color.black.opacity(0.82) : .white
}

private func loadShortcuts() -> [Shortcut] {
  let defaults = UserDefaults(suiteName: appGroupId)
  guard let json = defaults?.string(forKey: "shortcuts"),
    let data = json.data(using: .utf8),
    let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
  else { return [] }

  return array.map { item in
    let presets = (item["presets"] as? [Any] ?? []).compactMap {
      ($0 as? NSNumber)?.doubleValue
    }
    let argb = (item["color"] as? NSNumber)?.intValue ?? 0xFF9E9E_9E
    return Shortcut(
      id: item["id"] as? String ?? UUID().uuidString,
      categoryId: (item["categoryId"] as? NSNumber)?.intValue ?? 0,
      name: item["name"] as? String ?? "",
      color: colorFromARGB(argb),
      onColor: contrastingOn(argb),
      iconCode: (item["iconCode"] as? NSNumber)?.intValue ?? 0,
      mode: item["mode"] as? String ?? "open",
      amount: (item["amount"] as? NSNumber)?.doubleValue,
      presets: presets)
  }
}

private func shortAmount(_ value: Double) -> String {
  if value == value.rounded() {
    return String(Int(value))
  }
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  formatter.maximumFractionDigits = 2
  return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

struct QuickAddEntry: TimelineEntry {
  let date: Date
  let symbol: String
  let shortcuts: [Shortcut]
  let lastAddedId: String
  let lastAddedAt: Date

  /// True while the just-tapped button should show its quiet logged state
  /// (dimmed fill + hairline ring; no icons, no checkmarks).
  func isJustAdded(_ shortcut: Shortcut) -> Bool {
    return shortcut.id == lastAddedId
      && date.timeIntervalSince(lastAddedAt) < 2.5
  }
}

private func loadQuickAddEntry(at date: Date = Date()) -> QuickAddEntry {
  let defaults = UserDefaults(suiteName: appGroupId)
  let lastAt = defaults?.double(forKey: "last_added_at") ?? 0
  return QuickAddEntry(
    date: date,
    symbol: defaults?.string(forKey: "symbol") ?? "",
    shortcuts: loadShortcuts(),
    lastAddedId: defaults?.string(forKey: "last_added_id") ?? "",
    lastAddedAt: Date(timeIntervalSince1970: lastAt))
}

struct QuickAddProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickAddEntry {
    QuickAddEntry(
      date: Date(), symbol: "$", shortcuts: [], lastAddedId: "",
      lastAddedAt: Date(timeIntervalSince1970: 0))
  }

  func getSnapshot(
    in context: Context, completion: @escaping (QuickAddEntry) -> Void
  ) {
    completion(loadQuickAddEntry())
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void
  ) {
    // A second entry a few seconds out crossfades the logged state away.
    let now = loadQuickAddEntry()
    let clear = loadQuickAddEntry(at: Date().addingTimeInterval(2.6))
    completion(Timeline(entries: [now, clear], policy: .never))
  }
}

// MARK: Quick-add UI

/// Registers the bundled MaterialIcons font once (UIAppFonts is unreliable in
/// widget extensions, so fall back to manual CoreText registration).
private let materialIconsAvailable: Bool = {
  if UIFont(name: "MaterialIcons-Regular", size: 12) != nil { return true }
  guard
    let url = Bundle.main.url(
      forResource: "MaterialIcons-Regular", withExtension: "otf")
  else { return false }
  CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  return UIFont(name: "MaterialIcons-Regular", size: 12) != nil
}()

/// The category's Material icon glyph; falls back to the category's initial
/// letter when the font or codepoint is unavailable.
private struct CategoryGlyph: View {
  let shortcut: Shortcut
  let size: CGFloat

  var body: some View {
    if materialIconsAvailable, let scalar = UnicodeScalar(shortcut.iconCode),
      shortcut.iconCode > 0
    {
      Text(String(Character(scalar)))
        .font(.custom("MaterialIcons-Regular", size: size))
    } else {
      Text(String(shortcut.name.prefix(1)).uppercased())
        .font(.system(size: size * 0.78, weight: .semibold, design: .rounded))
    }
  }
}

@available(iOS 17.0, *)
struct QuickAddEntryView: View {
  var entry: QuickAddEntry
  @Environment(\.widgetFamily) var family

  /// "500 $" — mirrors the app's money formatting (symbol after the number).
  private func amountCaption(_ value: Double) -> String {
    let number = shortAmount(value)
    return entry.symbol.isEmpty ? number : "\(number) \(entry.symbol)"
  }

  var body: some View {
    if family == .systemSmall {
      smallGrid
    } else {
      mediumList
    }
  }

  // MARK: small — a strict 2×2 grid; unused cells stay as quiet placeholders
  // so a single shortcut still reads as part of the grid.

  /// Where a tap outside the instant-log buttons lands: the quick-add sheet
  /// for the first "ask each time" shortcut (its circles aren't buttons —
  /// small widgets can't open the app from a Button, only via widgetURL),
  /// or the plain add screen when there is none.
  private var smallURL: URL? {
    // `homeWidget` marks the URL for the home_widget plugin — without it the
    // plugin ignores the launch and widgetClicked never fires.
    if let open = entry.shortcuts.prefix(4).first(where: { $0.mode == "open" })
    {
      return URL(
        string: "financeapp://quickadd?category=\(open.categoryId)&homeWidget")
    }
    return URL(string: "financeapp://add?homeWidget")
  }

  // Cell metrics shared by real cells and placeholders so the grid never
  // shifts. Sized to fill the small widget generously (circle-first design).
  private var circleSize: CGFloat { 52 }
  private var glyphSize: CGFloat { 24 }
  private var captionSize: CGFloat { 11 }

  // No extra padding anywhere below: iOS 17 already applies default widget
  // content margins (~16pt); stacking our own on top squeezed the layout and
  // made it look non-native.
  private var smallGrid: some View {
    VStack(spacing: 6) {
      gridRowView(0)
      gridRowView(1)
    }
    .widgetURL(smallURL)
  }

  private func gridRowView(_ row: Int) -> some View {
    HStack(spacing: 6) {
      gridCell(row * 2)
      gridCell(row * 2 + 1)
    }
  }

  @ViewBuilder
  private func gridCell(_ index: Int) -> some View {
    if index < entry.shortcuts.count {
      circleButton(entry.shortcuts[index])
    } else {
      VStack(spacing: 3) {
        Circle()
          .fill(Color.primary.opacity(0.05))
          .frame(width: circleSize, height: circleSize)
        Text(" ")
          .font(.system(size: captionSize))
      }
      .frame(maxWidth: .infinity)
    }
  }

  @ViewBuilder
  private func circleButton(_ shortcut: Shortcut) -> some View {
    if let amount = shortcut.primaryAmount {
      Button(intent: QuickAddIntent(
        categoryId: shortcut.categoryId, amount: amount, shortcutId: shortcut.id)
      ) {
        circleCell(shortcut, caption: amountCaption(amount))
      }
      .buttonStyle(.plain)
    } else {
      // "open" mode — a plain cell, so the tap falls through to widgetURL
      // (Buttons can't open the app from a widget; see smallURL).
      circleCell(shortcut, caption: shortcut.name)
    }
  }

  /// Icon in a coloured circle, caption below.
  ///
  /// The tap outcome is readable at a glance: instant-log buttons (fixed /
  /// presets) are SOLID circles captioned with the amount; "ask each time"
  /// cells are quiet TINTED circles wearing a small "+" badge and captioned
  /// with the category name — tinted + badge narrates "opens input".
  /// The just-logged state is a quiet fade: fill drops to a tint, the glyph
  /// takes the category colour and a hairline ring appears, then crossfades
  /// back.
  private func circleCell(_ shortcut: Shortcut, caption: String) -> some View {
    let isOpen = shortcut.primaryAmount == nil
    return VStack(spacing: 4) {
      modeCircle(shortcut, diameter: circleSize, glyph: glyphSize)
      Text(caption)
        .font(
          isOpen
            ? .system(size: captionSize)
            : .system(size: captionSize, weight: .semibold, design: .rounded)
        )
        .foregroundColor(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity)
  }

  /// The mode-aware circle shared by both families.
  private func modeCircle(
    _ shortcut: Shortcut, diameter: CGFloat, glyph: CGFloat
  ) -> some View {
    let logged = entry.isJustAdded(shortcut)
    let isOpen = shortcut.primaryAmount == nil
    let tinted = isOpen || logged
    return ZStack(alignment: .bottomTrailing) {
      ZStack {
        Circle().fill(shortcut.color.opacity(tinted ? 0.16 : 1))
        if logged {
          Circle().strokeBorder(shortcut.color.opacity(0.6), lineWidth: 1)
        }
        CategoryGlyph(shortcut: shortcut, size: glyph)
          .foregroundColor(tinted ? shortcut.color : shortcut.onColor)
      }
      .frame(width: diameter, height: diameter)
      if isOpen {
        ZStack {
          Circle().fill(Color(UIColor.systemBackground))
          Circle().fill(shortcut.color).padding(1.5)
          Image(systemName: "plus")
            .font(.system(size: diameter * 0.16, weight: .bold))
            .foregroundColor(.white)
        }
        .frame(width: diameter * 0.36, height: diameter * 0.36)
        .offset(x: 3, y: 3)
      }
    }
  }

  // MARK: medium — three fixed row slots (same grid discipline as small).

  private var mediumList: some View {
    VStack(spacing: 10) {
      ForEach(0..<3, id: \.self) { index in
        if index < entry.shortcuts.count {
          rowView(entry.shortcuts[index])
        } else {
          placeholderRow
        }
      }
    }
  }

  private var rowCircleSize: CGFloat { 34 }

  private var placeholderRow: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(Color.primary.opacity(0.05))
        .frame(width: rowCircleSize, height: rowCircleSize)
      RoundedRectangle(cornerRadius: 4)
        .fill(Color.primary.opacity(0.05))
        .frame(width: 72, height: 9)
      Spacer(minLength: 0)
    }
    .frame(maxHeight: .infinity)
  }

  private func rowView(_ shortcut: Shortcut) -> some View {
    let logged = entry.isJustAdded(shortcut)
    return HStack(spacing: 10) {
      modeCircle(shortcut, diameter: rowCircleSize, glyph: 17)
      Text(shortcut.name)
        .font(.subheadline.weight(.medium))
        .foregroundColor(.primary)
        .lineLimit(1)
      Spacer(minLength: 8)
      rowActions(shortcut)
        .opacity(logged ? 0.35 : 1)
    }
    .frame(maxHeight: .infinity)
  }

  @ViewBuilder
  private func rowActions(_ shortcut: Shortcut) -> some View {
    switch shortcut.mode {
    case "fixed":
      if let amount = shortcut.amount {
        amountChip(shortcut, amount)
      }
    case "presets":
      // As many preset chips as actually fit next to the category name —
      // ViewThatFits tries the widest layout first and steps down.
      ViewThatFits(in: .horizontal) {
        presetChips(shortcut, showing: 4)
        presetChips(shortcut, showing: 3)
        presetChips(shortcut, showing: 2)
        presetChips(shortcut, showing: 1)
      }
    default:
      linkChip(shortcut, systemName: "plus")
    }
  }

  private func presetChips(_ shortcut: Shortcut, showing: Int) -> some View {
    HStack(spacing: 6) {
      // Bare numbers: the currency symbol would repeat on every chip and
      // costs the width of a whole extra preset.
      ForEach(Array(shortcut.presets.prefix(showing)), id: \.self) { preset in
        amountChip(shortcut, preset, withSymbol: false)
      }
      // Custom amount → open the app prefilled (Link works in medium).
      linkChip(shortcut, systemName: "ellipsis")
    }
  }

  /// Quiet tinted capsule that logs the amount instantly.
  private func amountChip(
    _ shortcut: Shortcut, _ amount: Double, withSymbol: Bool = true
  ) -> some View {
    Button(intent: QuickAddIntent(
      categoryId: shortcut.categoryId, amount: amount, shortcutId: shortcut.id)
    ) {
      Text(withSymbol ? amountCaption(amount) : shortAmount(amount))
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundColor(shortcut.color)
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(shortcut.color.opacity(0.13))
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }

  private func linkChip(_ shortcut: Shortcut, systemName: String) -> some View {
    Link(
      destination: URL(
        string:
          "financeapp://quickadd?category=\(shortcut.categoryId)&homeWidget")!
    ) {
      Image(systemName: systemName)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(shortcut.color)
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(shortcut.color.opacity(0.13))
        .clipShape(Capsule())
    }
  }
}

struct QuickAddWidget: Widget {
  let kind = "QuickAddWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuickAddProvider()) { entry in
      if #available(iOS 17.0, *) {
        QuickAddEntryView(entry: entry)
          .containerBackground(Color(UIColor.systemBackground), for: .widget)
      } else {
        // Interactive quick-add needs iOS 17; older systems see a hint.
        VStack {
          Image(systemName: "plus.circle.fill")
          Text("Requires iOS 17").font(.caption2)
        }
        .background(Color(UIColor.systemBackground))
      }
    }
    .configurationDisplayName("Quick Add")
    .description("Log a spend in one tap. Configure categories in the app.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
