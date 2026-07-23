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
  let iconCode: Int
}

struct RecentItem: Identifiable {
  let id = UUID()
  let name: String
  let amount: Double
  let isExpense: Bool
  let color: Color
  let iconCode: Int
  let date: Date
}

struct FinanceEntry: TimelineEntry {
  let date: Date
  let income: Double
  let expense: Double
  /// Spent today — the most glanceable number of all.
  let today: Double
  let balance: Double
  let symbol: String
  let categories: [CategoryItem]
  let recent: [RecentItem]
}

// MARK: - Data loading (from the shared App Group store written by home_widget)

private func colorFromARGB(_ argb: Int) -> Color {
  let a = Double((argb >> 24) & 0xFF) / 255.0
  let r = Double((argb >> 16) & 0xFF) / 255.0
  let g = Double((argb >> 8) & 0xFF) / 255.0
  let b = Double(argb & 0xFF) / 255.0
  return Color(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
}

private func loadEntry() -> FinanceEntry {
  let defaults = UserDefaults(suiteName: appGroupId)
  let income = defaults?.double(forKey: "income") ?? 0
  let expense = defaults?.double(forKey: "expense") ?? 0
  let today = defaults?.double(forKey: "today") ?? 0
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
        CategoryItem(
          name: name, value: value, color: colorFromARGB(colorInt),
          iconCode: (item["iconCode"] as? NSNumber)?.intValue ?? 0))
    }
  }

  var recent: [RecentItem] = []
  if let json = defaults?.string(forKey: "recent"),
    let data = json.data(using: .utf8),
    let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
  {
    for item in array {
      let ms = (item["date"] as? NSNumber)?.doubleValue ?? 0
      recent.append(
        RecentItem(
          name: item["name"] as? String ?? "",
          amount: (item["amount"] as? NSNumber)?.doubleValue ?? 0,
          isExpense: item["isExpense"] as? Bool ?? true,
          color: colorFromARGB(
            (item["color"] as? NSNumber)?.intValue ?? 0xFF9E9E_9E),
          iconCode: (item["iconCode"] as? NSNumber)?.intValue ?? 0,
          date: Date(timeIntervalSince1970: ms / 1000)))
    }
  }

  return FinanceEntry(
    date: Date(),
    income: income,
    expense: expense,
    today: today,
    balance: balance,
    symbol: symbol,
    categories: categories,
    recent: recent)
}

// MARK: - Timeline

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> FinanceEntry {
    FinanceEntry(
      date: Date(), income: 0, expense: 0, today: 0, balance: 0, symbol: "$",
      categories: [], recent: [])
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

// MARK: - Summary UI
//
// The informational widget speaks the app's tint language: category glyphs
// in TINTED circles (information), unlike the quick-add widget whose SOLID
// circles mean "tap to log". Amounts use the rounded design, labels plain SF.

private let positive = Color(red: 0.12, green: 0.71, blue: 0.45)

struct FinanceWidgetEntryView: View {
  var entry: FinanceEntry
  @Environment(\.widgetFamily) var family

  /// "1 700 $" — glanceable money: grouped, no decimals.
  private func compactMoney(_ value: Double) -> String {
    return money(value, symbol: entry.symbol)
  }

  var body: some View {
    Group {
      switch family {
      case .systemSmall: smallView
      case .systemLarge: largeView
      default: mediumView
      }
    }
    // This is the informational summary widget; the dedicated QuickAddWidget
    // owns interactive one-tap logging. Tapping here opens the add screen.
    // The `homeWidget` query param is REQUIRED: the home_widget plugin only
    // forwards URLs that carry it (isWidgetUrl in SwiftHomeWidgetPlugin).
    .widgetURL(URL(string: "financeapp://add?homeWidget"))
  }

  /// Tinted category circle with the real Material glyph.
  private func tintCircle(
    color: Color, iconCode: Int, name: String, diameter: CGFloat
  ) -> some View {
    ZStack {
      Circle().fill(color.opacity(0.16))
      Glyph(iconCode: iconCode, fallback: name, size: diameter * 0.5)
        .foregroundColor(color)
    }
    .frame(width: diameter, height: diameter)
  }

  private var spentHeader: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("This month").font(.caption).foregroundColor(.secondary)
      Text(compactMoney(entry.expense))
        .font(.system(size: 26, weight: .bold, design: .rounded))
        .foregroundColor(.primary)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
      HStack(spacing: 4) {
        Text("Today").font(.caption2).foregroundColor(.secondary)
        Text(compactMoney(entry.today))
          .font(.system(size: 11, weight: .semibold, design: .rounded))
          .foregroundColor(.secondary)
      }
    }
  }

  // MARK: small — the headline number + the top categories as tinted dots.

  private var smallView: some View {
    VStack(alignment: .leading, spacing: 0) {
      spentHeader
      Spacer(minLength: 6)
      HStack(spacing: 8) {
        ForEach(entry.categories.prefix(3)) { c in
          tintCircle(color: c.color, iconCode: c.iconCode, name: c.name,
                     diameter: 30)
        }
        Spacer(minLength: 0)
      }
    }
  }

  // MARK: medium — numbers on the left, top categories on the right.

  private var mediumView: some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(alignment: .leading, spacing: 3) {
        spentHeader
        Spacer(minLength: 4)
        HStack(spacing: 4) {
          Text("Income").font(.caption2).foregroundColor(.secondary)
          Text(compactMoney(entry.income))
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(positive)
        }
      }
      VStack(spacing: 0) {
        // Rows share the column height evenly — no clustering at the top.
        ForEach(entry.categories.prefix(3)) { c in
          categoryRow(c).frame(maxHeight: .infinity)
        }
        if entry.categories.isEmpty { Spacer() }
      }
      .frame(maxWidth: .infinity)
    }
  }

  // One shared row grid for the whole widget: 28pt circle, 8pt gap — so the
  // text column starts at the same x in every section.
  private let rowCircle: CGFloat = 28
  private let rowGap: CGFloat = 8

  private func categoryRow(_ c: CategoryItem) -> some View {
    HStack(spacing: rowGap) {
      tintCircle(color: c.color, iconCode: c.iconCode, name: c.name,
                 diameter: rowCircle)
      Text(c.name)
        .font(.caption)
        .foregroundColor(.primary)
        .lineLimit(1)
      Spacer(minLength: 4)
      Text(compactMoney(c.value))
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundColor(.secondary)
    }
  }

  // MARK: large — summary + category bars + recent transactions.

  private var largeView: some View {
    // No outer spacers: the header hugs the top content margin and the recent
    // list hugs the bottom one, so the vertical insets equal iOS's default
    // side margins. Leftover height is distributed BETWEEN sections (min 14),
    // never around them.
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        spentHeader
        Spacer()
        VStack(alignment: .trailing, spacing: 6) {
          statChip(label: Text("Income"), value: entry.income, tint: positive)
          statChip(label: Text("Balance"), value: entry.balance,
                   tint: entry.balance < 0 ? .secondary : positive)
        }
      }
      if !entry.categories.isEmpty {
        Spacer(minLength: 14)
        let maxValue = entry.categories.map(\.value).max() ?? 1
        VStack(spacing: 10) {
          ForEach(entry.categories.prefix(3)) { c in
            VStack(spacing: 5) {
              categoryRow(c)
              GeometryReader { geo in
                ZStack(alignment: .leading) {
                  Capsule().fill(c.color.opacity(0.13))
                  Capsule().fill(c.color)
                    .frame(
                      width: geo.size.width
                        * (maxValue > 0 ? c.value / maxValue : 0))
                }
              }
              .frame(height: 5)
              // The bar sits on the text column, not under the circle —
              // one left edge for everything that reads.
              .padding(.leading, rowCircle + rowGap)
            }
          }
        }
      }
      if !entry.recent.isEmpty {
        Spacer(minLength: 14)
        VStack(alignment: .leading, spacing: 8) {
          Text("Recent").font(.caption).foregroundColor(.secondary)
          VStack(spacing: 9) {
            ForEach(entry.recent.prefix(3)) { t in
              recentRow(t)
            }
          }
        }
      }
    }
  }

  private func statChip(label: Text, value: Double, tint: Color) -> some View {
    HStack(spacing: 4) {
      label.font(.caption2).foregroundColor(.secondary)
      Text(compactMoney(value))
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundColor(tint)
    }
  }

  private func recentRow(_ t: RecentItem) -> some View {
    HStack(spacing: rowGap) {
      tintCircle(color: t.color, iconCode: t.iconCode, name: t.name,
                 diameter: rowCircle)
      VStack(alignment: .leading, spacing: 1) {
        Text(t.name).font(.caption).foregroundColor(.primary).lineLimit(1)
        Text(t.date, format: .dateTime.day().month())
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      Spacer(minLength: 4)
      Text(
        (t.isExpense ? "−" : "+") + compactMoney(abs(t.amount))
      )
      .font(.system(size: 12, weight: .semibold, design: .rounded))
      .foregroundColor(t.isExpense ? .primary : positive)
    }
  }
}

struct FinanceWidget: Widget {
  let kind = "FinanceWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        FinanceWidgetEntryView(entry: entry)
          .containerBackground(Color(UIColor.systemBackground), for: .widget)
      } else {
        FinanceWidgetEntryView(entry: entry)
          .background(Color(UIColor.systemBackground))
      }
    }
    .configurationDisplayName("Finance")
    .description("Your spending at a glance. Tap to add a transaction.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
  // Category display info, so the optimistic recent item is complete without
  // any app / DB round-trip.
  @Parameter(title: "Name") var categoryName: String
  @Parameter(title: "Color") var colorValue: Int
  @Parameter(title: "Icon") var iconCode: Int

  init() {}
  init(
    categoryId: Int, amount: Double, shortcutId: String,
    categoryName: String, colorValue: Int, iconCode: Int
  ) {
    self.categoryId = categoryId
    self.amount = amount
    self.shortcutId = shortcutId
    self.categoryName = categoryName
    self.colorValue = colorValue
    self.iconCode = iconCode
  }

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)

    // Queue the real write for the app to drain on next open/resume.
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

    // Optimistic updates so BOTH widgets reflect the spend immediately —
    // totals, today, the recent list and the medium per-category spend — until
    // the app republishes the real snapshot.
    defaults?.set((defaults?.double(forKey: "expense") ?? 0) + amount, forKey: "expense")
    defaults?.set((defaults?.double(forKey: "balance") ?? 0) - amount, forKey: "balance")
    defaults?.set((defaults?.double(forKey: "today") ?? 0) + amount, forKey: "today")

    // Prepend a recent row (keep the newest few).
    var recent: [[String: Any]] = []
    if let json = defaults?.string(forKey: "recent"),
      let data = json.data(using: .utf8),
      let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    {
      recent = arr
    }
    let nowMs = Date().timeIntervalSince1970 * 1000
    recent.insert(
      [
        "name": categoryName, "amount": amount, "isExpense": true,
        "color": colorValue, "iconCode": iconCode, "date": nowMs,
      ], at: 0)
    recent = Array(recent.prefix(6))
    if let out = try? JSONSerialization.data(withJSONObject: recent),
      let outStr = String(data: out, encoding: .utf8)
    {
      defaults?.set(outStr, forKey: "recent")
    }

    // Bump this category's month-to-date spend (medium widget bars).
    var spend: [String: Double] = [:]
    if let json = defaults?.string(forKey: "category_spend"),
      let data = json.data(using: .utf8),
      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Double]
    {
      spend = dict
    }
    spend[String(categoryId)] = (spend[String(categoryId)] ?? 0) + amount
    if let out = try? JSONSerialization.data(withJSONObject: spend),
      let outStr = String(data: out, encoding: .utf8)
    {
      defaults?.set(outStr, forKey: "category_spend")
    }

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
  /// Raw ARGB of [color] — passed to QuickAddIntent for the optimistic
  /// recent-item update.
  let colorValue: Int
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

/// Loads the shortcuts for one group. Each group is published under
/// `shortcuts.<id>`; falls back to the legacy `shortcuts` key (default group).
private func loadShortcuts(groupId: String?) -> [Shortcut] {
  let defaults = UserDefaults(suiteName: appGroupId)
  let json =
    (groupId.flatMap { defaults?.string(forKey: "shortcuts.\($0)") })
    ?? defaults?.string(forKey: "shortcuts")
  guard let json,
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
      colorValue: argb,
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

/// Grouped money with the symbol after the number. Small amounts keep their
/// cents (individual spends read exactly); big aggregates round to stay
/// glanceable.
private func money(_ value: Double, symbol: String) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  let small = abs(value) < 100
  formatter.maximumFractionDigits = small ? 2 : 0
  let n = small ? value : value.rounded()
  let text = formatter.string(from: NSNumber(value: n)) ?? "0"
  return symbol.isEmpty ? text : "\(text) \(symbol)"
}

// MARK: Group configuration (per-widget category sets)

/// One named shortcut group, mirrored from the app's `widget_groups` JSON.
private struct WidgetGroupInfo {
  let id: String
  let name: String
}

private func loadGroups() -> [WidgetGroupInfo] {
  let defaults = UserDefaults(suiteName: appGroupId)
  guard let json = defaults?.string(forKey: "widget_groups"),
    let data = json.data(using: .utf8),
    let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
  else {
    return [WidgetGroupInfo(id: "default", name: String(localized: "Main"))]
  }
  return array.map {
    let raw = $0["name"] as? String ?? ""
    return WidgetGroupInfo(
      id: $0["id"] as? String ?? "default",
      // The default group is stored nameless; show a localized label.
      name: raw.isEmpty ? String(localized: "Main") : raw)
  }
}

/// The "Category set" a QuickAdd widget instance is bound to (chosen in the
/// system "Edit Widget" sheet).
struct GroupEntity: AppEntity {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    "Category set"
  }
  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
  static var defaultQuery = GroupQuery()
}

struct GroupQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [GroupEntity] {
    loadGroups()
      .filter { identifiers.contains($0.id) }
      .map { GroupEntity(id: $0.id, name: $0.name) }
  }
  func suggestedEntities() async throws -> [GroupEntity] {
    loadGroups().map { GroupEntity(id: $0.id, name: $0.name) }
  }
  func defaultResult() async -> GroupEntity? {
    loadGroups().first.map { GroupEntity(id: $0.id, name: $0.name) }
  }
}

/// Widget configuration: which category set this instance shows.
struct SelectGroupIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Quick Add"
  static var description = IntentDescription(
    "Choose which category set this widget shows.")

  @Parameter(title: "Category set") var group: GroupEntity?

  init() {}
}

/// Month-to-date expense per category id (base currency), for the medium rows.
private func loadCategorySpend() -> [Int: Double] {
  let defaults = UserDefaults(suiteName: appGroupId)
  guard let json = defaults?.string(forKey: "category_spend"),
    let data = json.data(using: .utf8),
    let dict = try? JSONSerialization.jsonObject(with: data)
      as? [String: NSNumber]
  else { return [:] }
  var out: [Int: Double] = [:]
  for (key, value) in dict {
    if let id = Int(key) { out[id] = value.doubleValue }
  }
  return out
}

struct QuickAddEntry: TimelineEntry {
  let date: Date
  let symbol: String
  let shortcuts: [Shortcut]
  let spend: [Int: Double]
  let lastAddedId: String
  let lastAddedAt: Date

  /// True while the just-tapped button should show its quiet logged state
  /// (dimmed fill + hairline ring; no icons, no checkmarks).
  func isJustAdded(_ shortcut: Shortcut) -> Bool {
    return shortcut.id == lastAddedId
      && date.timeIntervalSince(lastAddedAt) < 2.5
  }
}

private func loadQuickAddEntry(groupId: String?, at date: Date = Date())
  -> QuickAddEntry
{
  let defaults = UserDefaults(suiteName: appGroupId)
  let lastAt = defaults?.double(forKey: "last_added_at") ?? 0
  return QuickAddEntry(
    date: date,
    symbol: defaults?.string(forKey: "symbol") ?? "",
    shortcuts: loadShortcuts(groupId: groupId),
    spend: loadCategorySpend(),
    lastAddedId: defaults?.string(forKey: "last_added_id") ?? "",
    lastAddedAt: Date(timeIntervalSince1970: lastAt))
}

struct QuickAddProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuickAddEntry {
    QuickAddEntry(
      date: Date(), symbol: "$", shortcuts: [], spend: [:], lastAddedId: "",
      lastAddedAt: Date(timeIntervalSince1970: 0))
  }

  func snapshot(for configuration: SelectGroupIntent, in context: Context) async
    -> QuickAddEntry
  {
    loadQuickAddEntry(groupId: configuration.group?.id)
  }

  func timeline(for configuration: SelectGroupIntent, in context: Context) async
    -> Timeline<QuickAddEntry>
  {
    // A second entry a few seconds out crossfades the logged state away.
    let gid = configuration.group?.id
    let now = loadQuickAddEntry(groupId: gid)
    let clear = loadQuickAddEntry(
      groupId: gid, at: Date().addingTimeInterval(2.6))
    return Timeline(entries: [now, clear], policy: .never)
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

/// A Material icon glyph from the bundled font; falls back to the item's
/// initial letter when the font or codepoint is unavailable.
struct Glyph: View {
  let iconCode: Int
  let fallback: String
  let size: CGFloat

  var body: some View {
    if materialIconsAvailable, iconCode > 0,
      let scalar = UnicodeScalar(iconCode)
    {
      Text(String(Character(scalar)))
        .font(.custom("MaterialIcons-Regular", size: size))
    } else {
      Text(String(fallback.prefix(1)).uppercased())
        .font(.system(size: size * 0.78, weight: .semibold, design: .rounded))
    }
  }
}

/// The shortcut's category glyph (see Glyph).
private struct CategoryGlyph: View {
  let shortcut: Shortcut
  let size: CGFloat

  var body: some View {
    Glyph(iconCode: shortcut.iconCode, fallback: shortcut.name, size: size)
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

  /// Builds the log intent carrying the category display info, so the widget
  /// can update its recent list optimistically without an app round-trip.
  private func quickAddIntent(_ s: Shortcut, _ amount: Double) -> QuickAddIntent {
    QuickAddIntent(
      categoryId: s.categoryId, amount: amount, shortcutId: s.id,
      categoryName: s.name, colorValue: s.colorValue, iconCode: s.iconCode)
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
      Button(intent: quickAddIntent(shortcut, amount)) {
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
    return ZStack(alignment: .bottomTrailing) {
      ZStack {
        // One-colour style: glyph in the category colour on a faint tint of
        // it (matches ItemAvatar). The just-logged flash briefly inverts to a
        // solid fill with a contrasting glyph, then fades back.
        Circle().fill(shortcut.color.opacity(logged ? 1 : 0.16))
        CategoryGlyph(shortcut: shortcut, size: glyph)
          .foregroundColor(logged ? shortcut.onColor : shortcut.color)
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
    // Rows keep their natural height; the block is centered vertically so the
    // top and bottom breathing room match the (uniform) side margins instead
    // of stretching edge-to-edge.
    VStack(spacing: 9) {
      ForEach(0..<3, id: \.self) { index in
        if index < entry.shortcuts.count {
          rowView(entry.shortcuts[index])
        } else {
          placeholderRow
        }
      }
    }
    .frame(maxHeight: .infinity, alignment: .center)
  }

  private var rowCircleSize: CGFloat { 28 }
  private var rowGap: CGFloat { 10 }

  /// The largest month-to-date spend among the shown categories — scales the
  /// per-row bars so the biggest reads full.
  private var mediumMaxSpend: Double {
    entry.shortcuts.prefix(3)
      .map { entry.spend[$0.categoryId] ?? 0 }
      .max() ?? 0
  }

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
  }

  // Each row is a compact hybrid: icon + name + the category's month-to-date
  // spend + quick-actions on one line (context + action), and a thin progress
  // bar underneath — short enough that three rows leave real top/bottom
  // breathing room instead of filling the widget edge to edge.
  private func rowView(_ shortcut: Shortcut) -> some View {
    let logged = entry.isJustAdded(shortcut)
    let spent = entry.spend[shortcut.categoryId] ?? 0
    let fraction = mediumMaxSpend > 0 ? spent / mediumMaxSpend : 0
    return VStack(spacing: 4) {
      HStack(spacing: rowGap) {
        modeCircle(shortcut, diameter: rowCircleSize, glyph: 16)
        Text(shortcut.name)
          .font(.subheadline.weight(.medium))
          .foregroundColor(.primary)
          .lineLimit(1)
        Spacer(minLength: 6)
        Text(spentCaption(spent))
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundColor(.secondary)
          .fixedSize()
        rowActions(shortcut)
          .opacity(logged ? 0.35 : 1)
          .fixedSize()
      }
      // Thin bar sits on the text column (not under the circle).
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(shortcut.color.opacity(0.13))
          Capsule().fill(shortcut.color)
            .frame(width: geo.size.width * fraction)
        }
      }
      .frame(height: 3)
      .padding(.leading, rowCircleSize + rowGap)
    }
  }

  /// The category's month-to-date spend, e.g. "2 700 $" / "5.51 $".
  private func spentCaption(_ value: Double) -> String {
    return money(value, symbol: entry.symbol)
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
    Button(intent: quickAddIntent(shortcut, amount)) {
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
    // AppIntentConfiguration makes the widget configurable: long-press →
    // "Edit Widget" → pick a category set (GroupEntity). Two instances can
    // therefore show different categories.
    AppIntentConfiguration(
      kind: kind, intent: SelectGroupIntent.self, provider: QuickAddProvider()
    ) { entry in
      QuickAddEntryView(entry: entry)
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }
    .configurationDisplayName("Quick Add")
    .description("Log a spend in one tap. Configure categories in the app.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
