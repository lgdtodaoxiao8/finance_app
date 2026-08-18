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

  /// Glanceable money: grouped below 100k, abbreviated ("250К") above so
  /// high-denomination currencies don't overflow.
  private func compactMoney(_ value: Double) -> String {
    return abbreviatedMoney(value, symbol: entry.symbol)
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

// MARK: - AI digest widget (informative — the cached AiInsight score + summary)
//
// Purely a renderer of the App-Group cache the app publishes (widgets can't call
// the network). No cache → a prompt to open the coach; a non-premium account
// never has a cache, so that doubles as the lock. Adaptive: systemBackground.

private let aiAccent = Color(red: 0.43, green: 0.37, blue: 0.96)

private func scoreColor(_ s: Int) -> Color {
  if s >= 70 { return positive }
  if s >= 40 { return Color(red: 0.96, green: 0.65, blue: 0.14) }
  return Color(red: 0.94, green: 0.30, blue: 0.37)
}

private func aiToneColor(_ tone: String) -> Color {
  switch tone {
  case "positive": return positive
  case "warning": return Color(red: 0.96, green: 0.65, blue: 0.14)
  default: return aiAccent
  }
}

struct AiEntry: TimelineEntry {
  let date: Date
  let has: Bool
  let score: Int
  let label: String
  let summary: String
  let insight: String
  let tone: String
}

private func loadAiEntry() -> AiEntry {
  let d = UserDefaults(suiteName: appGroupId)
  return AiEntry(
    date: Date(),
    has: d?.bool(forKey: "ai_has") ?? false,
    score: Int((d?.double(forKey: "ai_score") ?? 0).rounded()),
    label: d?.string(forKey: "ai_label") ?? "",
    summary: d?.string(forKey: "ai_summary") ?? "",
    insight: d?.string(forKey: "ai_insight") ?? "",
    tone: d?.string(forKey: "ai_tone") ?? "neutral")
}

struct AiProvider: TimelineProvider {
  func placeholder(in context: Context) -> AiEntry {
    AiEntry(
      date: Date(), has: false, score: 0, label: "", summary: "", insight: "",
      tone: "neutral")
  }
  func getSnapshot(in context: Context, completion: @escaping (AiEntry) -> Void) {
    completion(loadAiEntry())
  }
  func getTimeline(
    in context: Context, completion: @escaping (Timeline<AiEntry>) -> Void
  ) {
    completion(Timeline(entries: [loadAiEntry()], policy: .never))
  }
}

struct AiInsightEntryView: View {
  var entry: AiEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      if !entry.has {
        emptyView
      } else if family == .systemSmall {
        smallView
      } else {
        mediumView
      }
    }
    // Premium coach if signed-in premium; otherwise the app opens to Home,
    // whose gated card routes to the paywall. `homeWidget` is required for the
    // home_widget plugin to forward the launch.
    .widgetURL(URL(string: "financeapp://insights?homeWidget"))
  }

  private var aiLabel: some View {
    HStack(spacing: 4) {
      Image(systemName: "sparkles").font(.system(size: 10, weight: .bold))
      Text("AI").font(.system(size: 11, weight: .heavy))
    }
    .foregroundColor(aiAccent)
  }

  private func ring(_ diameter: CGFloat, scoreFont: CGFloat) -> some View {
    let c = scoreColor(entry.score)
    let lw = diameter * 0.10
    return ZStack {
      Circle().stroke(Color.primary.opacity(0.10), lineWidth: lw)
      Circle()
        .trim(from: 0, to: CGFloat(min(max(entry.score, 0), 100)) / 100)
        .stroke(c, style: StrokeStyle(lineWidth: lw, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(entry.score)")
        .font(.system(size: scoreFont, weight: .heavy, design: .rounded))
        .foregroundColor(c)
    }
    .frame(width: diameter, height: diameter)
  }

  // Small — the ring is the hero: score + label + "financial health".
  private var smallView: some View {
    VStack(alignment: .leading, spacing: 0) {
      aiLabel
      Spacer(minLength: 4)
      VStack(spacing: 5) {
        ring(72, scoreFont: 25)
        Text(entry.label)
          .font(.system(size: 12.5, weight: .bold))
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .minimumScaleFactor(0.8)
        Text("Financial health")
          .font(.system(size: 9.5))
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity)
      Spacer(minLength: 0)
    }
  }

  // Medium — ring + summary + one insight line.
  private var mediumView: some View {
    HStack(spacing: 16) {
      ring(88, scoreFont: 27)
      VStack(alignment: .leading, spacing: 7) {
        aiLabel
        Text(entry.summary)
          .font(.system(size: 14.5, weight: .bold))
          .foregroundColor(.primary)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
        if !entry.insight.isEmpty {
          HStack(alignment: .top, spacing: 7) {
            RoundedRectangle(cornerRadius: 2)
              .fill(aiToneColor(entry.tone))
              .frame(width: 7, height: 7)
              .padding(.top, 4)
            Text(entry.insight)
              .font(.system(size: 12))
              .foregroundColor(.secondary)
              .lineLimit(2)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // Empty / locked — no cached digest yet: a prompt to run the coach.
  private var emptyView: some View {
    VStack(alignment: .leading, spacing: 8) {
      aiLabel
      Spacer(minLength: 0)
      Image(systemName: "sparkles")
        .font(.system(size: family == .systemSmall ? 24 : 28))
        .foregroundColor(aiAccent)
      Text("Open the AI coach to see your score")
        .font(.system(size: family == .systemSmall ? 12 : 14, weight: .semibold))
        .foregroundColor(.primary)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct AiInsightWidget: Widget {
  let kind = "AiInsightWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AiProvider()) { entry in
      if #available(iOS 17.0, *) {
        AiInsightEntryView(entry: entry)
          .containerBackground(Color(UIColor.systemBackground), for: .widget)
      } else {
        AiInsightEntryView(entry: entry)
          .background(Color(UIColor.systemBackground))
      }
    }
    .configurationDisplayName("AI digest")
    .description("Your financial-health score and a key insight.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Widget bundle

@main
struct FinanceWidgets: WidgetBundle {
  var body: some Widget {
    FinanceWidget()
    QuickAddWidget()
    QuickIncomeWidget()
    AiInsightWidget()
  }
}

// MARK: - Interactive quick-add (iOS 17+)

// App Group keys for the small-widget amount builder (see the builder intents
// and QuickAddEntryView.amountBuilder). `builder_shortcut` holds the id of the
// "ask each time" shortcut whose builder is open ("" = the plain grid);
// `builder_amount` is the running total being assembled tap by tap.
private let builderShortcutKey = "builder_shortcut"
private let builderAmountKey = "builder_amount"

/// Queues `{categoryId, amount, flow}` for the app to drain into a real
/// transaction, and optimistically updates the shared snapshot (totals, today,
/// recent list, per-category spend/income) so the widgets reflect it
/// immediately. Shared by the one-tap `QuickAddIntent` and the amount builder's
/// `ConfirmBuilderIntent`. [flow] is "income" for the quick-income widget,
/// "expense" otherwise — it decides the transaction type and which side of the
/// snapshot moves.
@available(iOS 17.0, *)
private func performQuickAddLog(
  categoryId: Int, amount: Double, shortcutId: String,
  categoryName: String, colorValue: Int, iconCode: Int, flow: String
) {
  let defaults = UserDefaults(suiteName: appGroupId)
  let isIncome = flow == "income"

  // Queue the real write for the app to drain on next open/resume.
  var queue: [[String: Any]] = []
  if let json = defaults?.string(forKey: "pending_quickadd"),
    let data = json.data(using: .utf8),
    let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
  {
    queue = arr
  }
  queue.append(["categoryId": categoryId, "amount": amount, "flow": flow])
  if let out = try? JSONSerialization.data(withJSONObject: queue),
    let outStr = String(data: out, encoding: .utf8)
  {
    defaults?.set(outStr, forKey: "pending_quickadd")
  }

  // Optimistic updates so BOTH widgets reflect the change immediately — totals,
  // the recent list and the medium per-category bars — until the app
  // republishes the real snapshot. Income lifts the balance and income total;
  // expense lowers the balance, raises expense + "spent today".
  if isIncome {
    defaults?.set(
      (defaults?.double(forKey: "income") ?? 0) + amount, forKey: "income")
    defaults?.set(
      (defaults?.double(forKey: "balance") ?? 0) + amount, forKey: "balance")
  } else {
    defaults?.set(
      (defaults?.double(forKey: "expense") ?? 0) + amount, forKey: "expense")
    defaults?.set(
      (defaults?.double(forKey: "balance") ?? 0) - amount, forKey: "balance")
    defaults?.set(
      (defaults?.double(forKey: "today") ?? 0) + amount, forKey: "today")
  }

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
      "name": categoryName, "amount": amount, "isExpense": !isIncome,
      "color": colorValue, "iconCode": iconCode, "date": nowMs,
    ], at: 0)
  recent = Array(recent.prefix(6))
  if let out = try? JSONSerialization.data(withJSONObject: recent),
    let outStr = String(data: out, encoding: .utf8)
  {
    defaults?.set(outStr, forKey: "recent")
  }

  // Bump this category's month-to-date total on the matching side (the medium
  // rows read category_spend for expense, category_income for income).
  let bucketKey = isIncome ? "category_income" : "category_spend"
  var bucket: [String: Double] = [:]
  if let json = defaults?.string(forKey: bucketKey),
    let data = json.data(using: .utf8),
    let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Double]
  {
    bucket = dict
  }
  bucket[String(categoryId)] = (bucket[String(categoryId)] ?? 0) + amount
  if let out = try? JSONSerialization.data(withJSONObject: bucket),
    let outStr = String(data: out, encoding: .utf8)
  {
    defaults?.set(outStr, forKey: bucketKey)
  }

  // Drive the brief logged-state fade on the tapped button.
  defaults?.set(shortcutId, forKey: "last_added_id")
  defaults?.set(Date().timeIntervalSince1970, forKey: "last_added_at")

  WidgetCenter.shared.reloadTimelines(ofKind: "FinanceWidget")
  WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddWidget")
  WidgetCenter.shared.reloadTimelines(ofKind: "QuickIncomeWidget")
}

/// Pure-Swift App Intent (no Flutter dependency): logs one instant quick-add.
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
  // "income" | "expense" — which kind of transaction this logs.
  @Parameter(title: "Flow") var flow: String

  init() {}
  init(
    categoryId: Int, amount: Double, shortcutId: String,
    categoryName: String, colorValue: Int, iconCode: Int, flow: String
  ) {
    self.categoryId = categoryId
    self.amount = amount
    self.shortcutId = shortcutId
    self.categoryName = categoryName
    self.colorValue = colorValue
    self.iconCode = iconCode
    self.flow = flow
  }

  func perform() async throws -> some IntentResult {
    performQuickAddLog(
      categoryId: categoryId, amount: amount, shortcutId: shortcutId,
      categoryName: categoryName, colorValue: colorValue, iconCode: iconCode,
      flow: flow)
    return .result()
  }
}

// MARK: Amount builder intents (small "ask each time" — build a sum in-widget)
//
// Tapping an "ask each time" category flips the small widget into an amount
// builder instead of opening the app: increment buttons assemble a total in
// the App Group, `✓` logs it via performQuickAddLog, `✕` returns to the grid.
// All state lives in the App Group and every intent reloads the timeline, so
// the widget re-renders with the new state — no app launch, no keyboard.

/// Opens the builder for a shortcut (starts a fresh amount at 0).
@available(iOS 17.0, *)
struct OpenBuilderIntent: AppIntent {
  static var title: LocalizedStringResource = "Enter an amount"
  @Parameter(title: "Shortcut") var shortcutId: String

  init() {}
  init(shortcutId: String) { self.shortcutId = shortcutId }

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(shortcutId, forKey: builderShortcutKey)
    defaults?.set(0.0, forKey: builderAmountKey)
    WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddWidget")
    return .result()
  }
}

/// Adds an increment to the amount being built.
@available(iOS 17.0, *)
struct BuilderAddIntent: AppIntent {
  static var title: LocalizedStringResource = "Add to amount"
  @Parameter(title: "Amount") var delta: Double

  init() {}
  init(delta: Double) { self.delta = delta }

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)
    let current = defaults?.double(forKey: builderAmountKey) ?? 0
    defaults?.set(current + delta, forKey: builderAmountKey)
    WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddWidget")
    return .result()
  }
}

/// Resets the amount being built back to 0 (⌫).
@available(iOS 17.0, *)
struct BuilderClearIntent: AppIntent {
  static var title: LocalizedStringResource = "Clear amount"

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(0.0, forKey: builderAmountKey)
    WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddWidget")
    return .result()
  }
}

/// Dismisses the builder and returns to the grid (✕), discarding the amount.
@available(iOS 17.0, *)
struct CloseBuilderIntent: AppIntent {
  static var title: LocalizedStringResource = "Close"

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set("", forKey: builderShortcutKey)
    defaults?.set(0.0, forKey: builderAmountKey)
    WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddWidget")
    return .result()
  }
}

/// Logs the built amount (✓) and returns to the grid. A zero amount just
/// closes the builder without logging.
@available(iOS 17.0, *)
struct ConfirmBuilderIntent: AppIntent {
  static var title: LocalizedStringResource = "Log amount"
  @Parameter(title: "Category") var categoryId: Int
  @Parameter(title: "Amount") var amount: Double
  @Parameter(title: "Shortcut") var shortcutId: String
  @Parameter(title: "Name") var categoryName: String
  @Parameter(title: "Color") var colorValue: Int
  @Parameter(title: "Icon") var iconCode: Int
  @Parameter(title: "Flow") var flow: String

  init() {}
  init(
    categoryId: Int, amount: Double, shortcutId: String,
    categoryName: String, colorValue: Int, iconCode: Int, flow: String
  ) {
    self.categoryId = categoryId
    self.amount = amount
    self.shortcutId = shortcutId
    self.categoryName = categoryName
    self.colorValue = colorValue
    self.iconCode = iconCode
    self.flow = flow
  }

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)
    // Close the builder either way.
    defaults?.set("", forKey: builderShortcutKey)
    defaults?.set(0.0, forKey: builderAmountKey)
    if amount > 0 {
      // performQuickAddLog reloads the widgets; the grid then shows the brief
      // just-logged fade on this shortcut's cell.
      performQuickAddLog(
        categoryId: categoryId, amount: amount, shortcutId: shortcutId,
        categoryName: categoryName, colorValue: colorValue, iconCode: iconCode,
        flow: flow)
    } else {
      WidgetCenter.shared.reloadTimelines(ofKind: "QuickAddWidget")
      WidgetCenter.shared.reloadTimelines(ofKind: "QuickIncomeWidget")
    }
    return .result()
  }
}

// NOTE: interactive widget buttons cannot open the app — iOS 17 ignores
// `openAppWhenRun` for widget intents (they always run in the background). So
// "ask each time" shortcuts assemble their amount IN the widget (small: the
// amount builder above; medium: preset chips + an `…` Link). The only path
// that opens the app is the `…`/exact escape: a `Link` in the medium widget,
// and the small builder's fall-through `widgetURL` (carrying the built amount).

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
  /// Phosphor icon codepoint of the category icon.
  let iconCode: Int
  let mode: String  // "fixed" | "presets" | "open"
  let amount: Double?
  let presets: [Double]
  /// Amount-builder increment steps ("ask each time" mode). Resolved on the
  /// Dart side — custom values, or a currency-adaptive ladder from spending.
  let steps: [Double]
}

/// The pleasant green of the income widget's add "+" (matches the app's
/// `AppColors.positive`). The expense widget's add "+" uses the accent (blue).
private let incomeGreen = Color(
  red: 0x1F / 255, green: 0xB5 / 255, blue: 0x74 / 255)

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
    let steps = (item["steps"] as? [Any] ?? []).compactMap {
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
      presets: presets,
      steps: steps)
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

// MARK: Compact money — keep amounts narrow at any currency scale
//
// `100/500/1000` fits dollars; the same real value in tenge is `50 000/250 000/
// 500 000` and blows past the layout. These abbreviate large numbers to "50К" /
// "1,2М" (locale suffix — the widget follows the system language). Thresholds
// are absolute, so dollar-scale amounts stay full and only high-denomination
// currencies get abbreviated.

/// "50К" / "1,864М" — a number abbreviated with a localized thousands/millions
/// suffix. Millions keep 3 decimals (where the lost precision matters), thousands
/// just 1 ("253,7К") so they stay short and don't wrap in tight rows.
private func abbrev(_ value: Double) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  if abs(value) >= 1_000_000 {
    formatter.maximumFractionDigits = 3
    let n = formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "0"
    return n + String(localized: "M")
  }
  formatter.maximumFractionDigits = 1
  let n = formatter.string(from: NSNumber(value: value / 1_000)) ?? "0"
  return n + String(localized: "K")
}

/// Money for display: full grouped value below 100k, abbreviated above.
private func abbreviatedMoney(_ value: Double, symbol: String) -> String {
  if abs(value) < 100_000 { return money(value, symbol: symbol) }
  let text = abbrev(value)
  return symbol.isEmpty ? text : "\(text) \(symbol)"
}

/// A builder step / chip label: full number up to 10k ("100", "1000"), then
/// abbreviated ("50К") so tenge-scale steps still fit a chip.
private func stepLabel(_ value: Double) -> String {
  return abs(value) >= 10_000 ? abbrev(value) : shortAmount(value)
}

// MARK: Group configuration (per-widget category sets)

/// One named shortcut group, mirrored from the app's `widget_groups` JSON.
private struct WidgetGroupInfo {
  let id: String
  let name: String
  /// "expense" | "income" — which widget kind offers this group.
  let flow: String
}

private func loadGroups() -> [WidgetGroupInfo] {
  let defaults = UserDefaults(suiteName: appGroupId)
  guard let json = defaults?.string(forKey: "widget_groups"),
    let data = json.data(using: .utf8),
    let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
  else {
    return [
      WidgetGroupInfo(id: "default", name: String(localized: "Main"),
        flow: "expense")
    ]
  }
  return array.map {
    let raw = $0["name"] as? String ?? ""
    return WidgetGroupInfo(
      id: $0["id"] as? String ?? "default",
      // The default group is stored nameless; show a localized label.
      name: raw.isEmpty ? String(localized: "Main") : raw,
      flow: $0["flow"] as? String ?? "expense")
  }
}

/// The groups offered to a widget of the given flow — an expense widget lists
/// only expense groups, an income widget only income groups.
private func loadGroups(flow: String) -> [WidgetGroupInfo] {
  loadGroups().filter { $0.flow == flow }
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
  // Resolving a stored selection matches by id across every group, so a bound
  // widget keeps its set; the PICKER (suggested/default) only offers expense
  // groups.
  func entities(for identifiers: [String]) async throws -> [GroupEntity] {
    loadGroups()
      .filter { identifiers.contains($0.id) }
      .map { GroupEntity(id: $0.id, name: $0.name) }
  }
  func suggestedEntities() async throws -> [GroupEntity] {
    loadGroups(flow: "expense").map { GroupEntity(id: $0.id, name: $0.name) }
  }
  func defaultResult() async -> GroupEntity? {
    loadGroups(flow: "expense").first.map {
      GroupEntity(id: $0.id, name: $0.name)
    }
  }
}

/// Widget configuration: which category set this instance shows.
struct SelectGroupIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Quick Expense"
  static var description = IntentDescription(
    "Choose which category set this widget shows.")

  @Parameter(title: "Category set") var group: GroupEntity?

  init() {}
}

/// The income counterpart of [GroupEntity] — its own type so the income
/// widget's picker (via [IncomeGroupQuery]) offers only income groups.
struct IncomeGroupEntity: AppEntity {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    "Category set"
  }
  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
  static var defaultQuery = IncomeGroupQuery()
}

struct IncomeGroupQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [IncomeGroupEntity] {
    loadGroups()
      .filter { identifiers.contains($0.id) }
      .map { IncomeGroupEntity(id: $0.id, name: $0.name) }
  }
  func suggestedEntities() async throws -> [IncomeGroupEntity] {
    loadGroups(flow: "income").map {
      IncomeGroupEntity(id: $0.id, name: $0.name)
    }
  }
  func defaultResult() async -> IncomeGroupEntity? {
    loadGroups(flow: "income").first.map {
      IncomeGroupEntity(id: $0.id, name: $0.name)
    }
  }
}

/// Income-widget configuration: which income category set this instance shows.
struct SelectIncomeGroupIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Quick Income"
  static var description = IntentDescription(
    "Choose which income category set this widget shows.")

  @Parameter(title: "Category set") var group: IncomeGroupEntity?

  init() {}
}

/// Month-to-date total per category id (base currency), for the medium rows.
/// Reads `category_spend` for the expense widget, `category_income` for the
/// income widget.
private func loadCategoryBucket(_ storeKey: String) -> [Int: Double] {
  let defaults = UserDefaults(suiteName: appGroupId)
  guard let json = defaults?.string(forKey: storeKey),
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
  /// Id of the shortcut whose small-widget amount builder is open ("" = grid).
  let builderShortcutId: String
  /// Running total being assembled in the builder.
  let builderAmount: Double
  /// "expense" (Quick Expense widget) | "income" (Quick Income widget) — drives
  /// the logged transaction type and the green "+" income accent.
  let flow: String

  var isIncome: Bool { flow == "income" }

  /// True while the just-tapped button should show its quiet logged state
  /// (dimmed fill + hairline ring; no icons, no checkmarks).
  func isJustAdded(_ shortcut: Shortcut) -> Bool {
    return shortcut.id == lastAddedId
      && date.timeIntervalSince(lastAddedAt) < 2.5
  }
}

private func loadQuickAddEntry(
  groupId: String?, flow: String, at date: Date = Date()
) -> QuickAddEntry {
  let defaults = UserDefaults(suiteName: appGroupId)
  let lastAt = defaults?.double(forKey: "last_added_at") ?? 0
  let bucketKey = flow == "income" ? "category_income" : "category_spend"
  return QuickAddEntry(
    date: date,
    symbol: defaults?.string(forKey: "symbol") ?? "",
    shortcuts: loadShortcuts(groupId: groupId),
    spend: loadCategoryBucket(bucketKey),
    lastAddedId: defaults?.string(forKey: "last_added_id") ?? "",
    lastAddedAt: Date(timeIntervalSince1970: lastAt),
    builderShortcutId: defaults?.string(forKey: builderShortcutKey) ?? "",
    builderAmount: defaults?.double(forKey: builderAmountKey) ?? 0,
    flow: flow)
}

struct QuickAddProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuickAddEntry {
    QuickAddEntry(
      date: Date(), symbol: "$", shortcuts: [], spend: [:], lastAddedId: "",
      lastAddedAt: Date(timeIntervalSince1970: 0), builderShortcutId: "",
      builderAmount: 0, flow: "expense")
  }

  func snapshot(for configuration: SelectGroupIntent, in context: Context) async
    -> QuickAddEntry
  {
    loadQuickAddEntry(groupId: configuration.group?.id, flow: "expense")
  }

  func timeline(for configuration: SelectGroupIntent, in context: Context) async
    -> Timeline<QuickAddEntry>
  {
    // A second entry a few seconds out crossfades the logged state away.
    let gid = configuration.group?.id
    let now = loadQuickAddEntry(groupId: gid, flow: "expense")
    let clear = loadQuickAddEntry(
      groupId: gid, flow: "expense", at: Date().addingTimeInterval(2.6))
    return Timeline(entries: [now, clear], policy: .never)
  }
}

/// The income widget's provider — identical to [QuickAddProvider] but binds to
/// income groups and stamps the entry with the income flow.
struct QuickIncomeProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuickAddEntry {
    QuickAddEntry(
      date: Date(), symbol: "$", shortcuts: [], spend: [:], lastAddedId: "",
      lastAddedAt: Date(timeIntervalSince1970: 0), builderShortcutId: "",
      builderAmount: 0, flow: "income")
  }

  func snapshot(for configuration: SelectIncomeGroupIntent, in context: Context)
    async -> QuickAddEntry
  {
    loadQuickAddEntry(groupId: configuration.group?.id, flow: "income")
  }

  func timeline(
    for configuration: SelectIncomeGroupIntent, in context: Context
  ) async -> Timeline<QuickAddEntry> {
    let gid = configuration.group?.id
    let now = loadQuickAddEntry(groupId: gid, flow: "income")
    let clear = loadQuickAddEntry(
      groupId: gid, flow: "income", at: Date().addingTimeInterval(2.6))
    return Timeline(entries: [now, clear], policy: .never)
  }
}

// MARK: Quick-add UI

/// Registers the bundled Solar Bold icon font once (UIAppFonts is unreliable in
/// widget extensions, so fall back to manual CoreText registration). Subset to
/// just the app's category/account icon codepoints to fit the widget memory
/// budget — the full font is far too large for the extension.
private let iconFontAvailable: Bool = {
  if UIFont(name: "SolarIconsBold", size: 12) != nil { return true }
  guard
    let url = Bundle.main.url(forResource: "SolarIconsBold", withExtension: "ttf")
  else { return false }
  CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  return UIFont(name: "SolarIconsBold", size: 12) != nil
}()

/// A Material icon glyph from the bundled font; falls back to the item's
/// initial letter when the font or codepoint is unavailable.
struct Glyph: View {
  let iconCode: Int
  let fallback: String
  let size: CGFloat

  var body: some View {
    if iconFontAvailable, iconCode > 0,
      let scalar = UnicodeScalar(iconCode)
    {
      Text(String(Character(scalar)))
        .font(.custom("SolarIconsBold", size: size))
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

  private var isIncome: Bool { entry.isIncome }

  /// "500 $" — chip amount; abbreviates large (tenge-scale) values to "50К".
  /// Flow-neutral: the +/− sign is added ONLY on the fixed amount (see
  /// fixedAmountCaption). The flow itself is carried by the glass rim.
  private func amountCaption(_ value: Double) -> String {
    let number = stepLabel(value)
    return entry.symbol.isEmpty ? number : "\(number) \(entry.symbol)"
  }

  /// The fixed-cost amount with its flow sign ("+5000 $" / "−5000 $"). The sign
  /// appears ONLY here — the badges are otherwise identical across both widgets.
  private func fixedAmountCaption(_ value: Double) -> String {
    return (isIncome ? "+" : "−") + amountCaption(value)
  }

  /// Builds the log intent carrying the category display info + the flow, so the
  /// widget can update its recent list optimistically without an app round-trip.
  private func quickAddIntent(_ s: Shortcut, _ amount: Double) -> QuickAddIntent {
    QuickAddIntent(
      categoryId: s.categoryId, amount: amount, shortcutId: s.id,
      categoryName: s.name, colorValue: s.colorValue, iconCode: s.iconCode,
      flow: entry.flow)
  }

  var body: some View {
    if family == .systemSmall {
      // Tapping a "presets" or "ask each time" category flips this widget into
      // a full-size takeover (no app open): a preset picker or an amount
      // builder. Scoped by shortcut id, so it doesn't affect another instance.
      if let s = activeBuilderShortcut {
        if s.mode == "presets" {
          presetPicker(s)
        } else {
          amountBuilder(s)
        }
      } else {
        smallGrid
      }
    } else {
      mediumList
    }
  }

  /// The "ask each time" shortcut whose builder is currently open, if it belongs
  /// to THIS widget's shortcut set (otherwise the grid stays put).
  private var activeBuilderShortcut: Shortcut? {
    guard !entry.builderShortcutId.isEmpty else { return nil }
    return entry.shortcuts.first { $0.id == entry.builderShortcutId }
  }

  // MARK: small — a strict 2×2 grid; unused cells stay as quiet placeholders
  // so a single shortcut still reads as part of the grid.

  /// Where a tap on the grid's "+" add cell / empty space lands: the fast
  /// quick-add sheet with NO preset category, so the user can log an irregular
  /// spend into any category. "Ask each time" cells are Buttons that open the
  /// in-widget amount builder instead; small widgets can't open the app from a
  /// Button, so the "+" cell is a plain view that falls through to this URL.
  /// (`homeWidget` marks the URL for the home_widget plugin — without it the
  /// plugin ignores the launch and widgetClicked never fires.)
  private var smallURL: URL? {
    URL(string: "financeapp://quickadd?homeWidget\(flowQuery)")
  }

  /// The `&flow=income` deep-link suffix on the income widget (so the app opens
  /// the quick-add sheet in income mode); empty on the expense widget.
  private var flowQuery: String { isIncome ? "&flow=income" : "" }

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
    } else if index == entry.shortcuts.count {
      // First free slot: a "+" for irregular, uncategorised spends. It's a
      // plain view (not a Button) so the tap falls through to the widgetURL →
      // the quick-add sheet with no preset category (pick any).
      addCell
    } else {
      placeholderCell
    }
  }

  private var placeholderCell: some View {
    VStack(spacing: 3) {
      Circle()
        .fill(Color.primary.opacity(0.05))
        .frame(width: circleSize, height: circleSize)
      Text(" ")
        .font(.system(size: captionSize))
    }
    .frame(maxWidth: .infinity)
  }

  private var addCell: some View {
    // The one visual tell between the widgets: the add "+" is a pleasant green
    // on the income widget, blue (accent) on the expense widget.
    let c = isIncome ? incomeGreen : Color.accentColor
    return VStack(spacing: 4) {
      ZStack {
        Circle().fill(c.opacity(0.15))
        Image(systemName: "plus")
          .font(.system(size: glyphSize, weight: .semibold))
          .foregroundColor(c)
      }
      .frame(width: circleSize, height: circleSize)
      Text(String(localized: "Add"))
        .font(.system(size: captionSize))
        .foregroundColor(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func circleButton(_ shortcut: Shortcut) -> some View {
    if shortcut.mode == "fixed", let amount = shortcut.amount {
      // One exact sum: a single tap logs it right away. The amount rides the
      // circle as a badge; the caption is the category name like the others.
      Button(intent: quickAddIntent(shortcut, amount)) {
        circleCell(shortcut, caption: shortcut.name)
      }
      .buttonStyle(.plain)
    } else {
      // "presets" opens the preset picker; "ask each time" opens the amount
      // builder — both take over the widget (no app launch, no dumb logging).
      Button(intent: OpenBuilderIntent(shortcutId: shortcut.id)) {
        circleCell(shortcut, caption: shortcut.name)
      }
      .buttonStyle(.plain)
    }
  }

  /// Icon in a coloured circle + the category name below. The mode is told
  /// apart by the bottom-trailing badge (see modeBadge): the fixed amount on a
  /// pill, two pills for presets, a "+" for "ask each time".
  private func circleCell(_ shortcut: Shortcut, caption: String) -> some View {
    return VStack(spacing: 4) {
      ZStack(alignment: .bottomTrailing) {
        modeCircle(shortcut, diameter: circleSize, glyph: glyphSize)
        modeBadge(shortcut, diameter: circleSize)
      }
      Text(caption)
        .font(.system(size: captionSize))
        .foregroundColor(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity)
  }

  /// The plain tinted icon circle, shared by both families (badges are added by
  /// the small grid's circleCell, not here, so the medium rows stay clean).
  private func modeCircle(
    _ shortcut: Shortcut, diameter: CGFloat, glyph: CGFloat
  ) -> some View {
    let logged = entry.isJustAdded(shortcut)
    // One-colour style: glyph in the category colour on a faint tint of it
    // (matches ItemAvatar). The just-logged flash briefly inverts to the solid
    // category colour with a contrasting glyph, then fades back.
    return ZStack {
      Circle()
        .fill(logged ? shortcut.color : shortcut.color.opacity(0.16))
      CategoryGlyph(shortcut: shortcut, size: glyph)
        .foregroundColor(logged ? shortcut.onColor : shortcut.color)
    }
    .frame(width: diameter, height: diameter)
  }

  /// The bottom-trailing badge that tells the three modes apart at a glance —
  /// all the same height and sitting ON the circle like the "+": fixed = its
  /// amount on a pill; presets = two pills ("several presets"); "ask each time"
  /// = a "+".
  @ViewBuilder
  private func modeBadge(_ s: Shortcut, diameter: CGFloat) -> some View {
    let height = diameter * 0.36  // same footprint as the "+" badge
    let ring = diameter * 0.03  // systemBackground separation, like the "+"
    switch s.mode {
    case "fixed":
      if let amount = s.amount {
        // The fixed amount (with its +/− flow sign + currency symbol) sits in
        // the bottom-right corner in the category colour, with a soft
        // systemBackground halo so it reads over the icon. Width-capped so long
        // sums shrink to fit.
        Text(fixedAmountCaption(amount))
          .font(.system(size: diameter * 0.22, weight: .heavy, design: .rounded))
          .foregroundColor(s.color)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .frame(maxWidth: diameter * 0.95, alignment: .trailing)
          .shadow(color: Color(UIColor.systemBackground), radius: 1)
          .shadow(color: Color(UIColor.systemBackground), radius: 1)
          .offset(x: 2, y: 2)
      }
    case "presets":
      // Two SMALL horizontal pills — a quiet narrative hint ("several presets"),
      // not a functional element, so keep them compact on the circle.
      HStack(spacing: diameter * 0.03) {
        pillBadge(s, ring: ring)
          .frame(width: diameter * 0.3, height: diameter * 0.2)
        pillBadge(s, ring: ring)
          .frame(width: diameter * 0.3, height: diameter * 0.2)
      }
      .offset(x: 3, y: 2)
    default:
      ZStack {
        Circle().fill(Color(UIColor.systemBackground))
        Circle().fill(s.color).padding(ring)
        Image(systemName: "plus")
          .font(.system(size: diameter * 0.16, weight: .bold))
          .foregroundColor(.white)
      }
      .frame(width: height, height: height)
      .offset(x: 3, y: 3)
    }
  }

  /// A category-coloured capsule with a systemBackground ring — the shared shape
  /// behind the preset pills.
  private func pillBadge(_ s: Shortcut, ring: CGFloat) -> some View {
    ZStack {
      Capsule().fill(Color(UIColor.systemBackground))
      Capsule().fill(s.color).padding(ring)
    }
  }

  // MARK: small amount builder — assemble a sum for an "ask each time" category
  // right on the widget, then log it with one tap. No keyboard, no app launch.

  private func confirmIntent(_ s: Shortcut, _ amount: Double)
    -> ConfirmBuilderIntent
  {
    ConfirmBuilderIntent(
      categoryId: s.categoryId, amount: amount, shortcutId: s.id,
      categoryName: s.name, colorValue: s.colorValue, iconCode: s.iconCode,
      flow: entry.flow)
  }

  /// Shared takeover header: category identity + close (✕ → back to the grid).
  private func takeoverHeader(_ s: Shortcut) -> some View {
    HStack(spacing: 7) {
      ZStack {
        Circle().fill(s.color.opacity(0.16))
        Glyph(iconCode: s.iconCode, fallback: s.name, size: 13)
          .foregroundColor(s.color)
      }
      .frame(width: 24, height: 24)
      Text(s.name)
        .font(.caption.weight(.semibold))
        .foregroundColor(.primary)
        .lineLimit(1)
      Spacer(minLength: 2)
      Button(intent: CloseBuilderIntent()) {
        Image(systemName: "xmark")
          .font(.system(size: 10, weight: .bold))
          .foregroundColor(.secondary)
          .frame(width: 22, height: 22)
          .background(Color.primary.opacity(0.06), in: Circle())
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: small preset picker — pick one of the shortcut's preset amounts on a
  // full-size takeover, then log it with one tap (no dumb first-preset logging).

  private func presetButton(_ s: Shortcut, _ amount: Double) -> some View {
    // Logs this preset and returns to the grid (with the just-logged fade). The
    // capsule fills its row cell so the rows can share whatever height is left
    // under the header without squishing it.
    Button(intent: confirmIntent(s, amount)) {
      Text(amountCaption(amount))
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundColor(s.color)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(s.color.opacity(0.14), in: Capsule())
    }
    .buttonStyle(.plain)
  }

  private func presetPicker(_ s: Shortcut) -> some View {
    // Up to six presets (our compact number formatting keeps them short), laid
    // out two-per-row. The header keeps its natural top position and the preset
    // rows share the remaining height evenly (each `.frame(maxHeight:.infinity)`)
    // so six presets shrink the capsules instead of crowding the category name.
    let presets = Array(s.presets.prefix(6))
    let rows = stride(from: 0, to: presets.count, by: 2).map {
      Array(presets[$0..<min($0 + 2, presets.count)])
    }
    return VStack(spacing: 6) {
      takeoverHeader(s)
      ForEach(rows.indices, id: \.self) { r in
        HStack(spacing: 6) {
          ForEach(rows[r], id: \.self) { presetButton(s, $0) }
          // A lone button on the last row shouldn't stretch full width.
          if rows[r].count == 1 { Spacer(minLength: 0) }
        }
        .frame(maxHeight: .infinity)
      }
    }
    // Any tap outside a preset button opens the app prefilled with this
    // category (for a non-preset amount). `homeWidget` is required to route.
    .widgetURL(
      URL(
        string:
          "financeapp://quickadd?category=\(s.categoryId)&homeWidget\(flowQuery)"
      ))
  }

  private func amountBuilder(_ s: Shortcut) -> some View {
    let amount = entry.builderAmount
    let hasAmount = amount > 0
    // Currency-adaptive increments resolved on the Dart side; a sane default if
    // none were published yet.
    let steps = s.steps.isEmpty ? [100.0, 500.0, 1000.0] : s.steps
    return VStack(spacing: 6) {
      takeoverHeader(s)

      // Running amount + clear (⌫). Tapping the number falls through to the
      // widgetURL below → opens the app prefilled for an exact amount.
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text(abbreviatedMoney(amount, symbol: entry.symbol))
          .font(.system(size: 25, weight: .bold, design: .rounded))
          .foregroundColor(hasAmount ? .primary : .secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
        Spacer(minLength: 0)
        if hasAmount {
          Button(intent: BuilderClearIntent()) {
            Image(systemName: "delete.left")
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(.secondary)
          }
          .buttonStyle(.plain)
        }
      }

      // Increment chips. The widest label must fit the narrow small widget
      // without truncating, so cap the font and let it scale down; large
      // (tenge-scale) steps abbreviate to "+50К".
      HStack(spacing: 5) {
        ForEach(steps, id: \.self) { inc in
          Button(intent: BuilderAddIntent(delta: inc)) {
            Text("+" + stepLabel(inc))
              .font(.system(size: 13, weight: .semibold, design: .rounded))
              .lineLimit(1)
              .minimumScaleFactor(0.75)
              .foregroundColor(s.color)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 8)
              .padding(.horizontal, 2)
              .background(s.color.opacity(0.13), in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }

      // Confirm (✓ → log the amount, back to the grid). Dimmed until there is
      // an amount to log.
      Button(intent: confirmIntent(s, amount)) {
        HStack(spacing: 5) {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
          Text(String(localized: "Save"))
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundColor(hasAmount ? s.onColor : .secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
          hasAmount ? s.color : Color.primary.opacity(0.08), in: Capsule())
      }
      .buttonStyle(.plain)
    }
    // Fall-through for any tap outside a button (the amount, empty space): open
    // the app prefilled with this category + the amount built so far, for an
    // exact edit. `homeWidget` is required for the home_widget plugin to route.
    .widgetURL(
      URL(
        string:
          "financeapp://quickadd?category=\(s.categoryId)"
          + "&amount=\(Int(amount.rounded()))&homeWidget\(flowQuery)"))
  }

  // MARK: medium — three fixed row slots (same grid discipline as small).

  private var mediumList: some View {
    // Rows keep their natural height; the block is centered vertically so the
    // top and bottom breathing room match the (uniform) side margins instead
    // of stretching edge-to-edge.
    VStack(spacing: 7) {
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

  // Each row shows the category (icon + name) with its quick-actions. The name
  // is never dropped: when it and the preset chips fit on one line it stays
  // beside the icon (with a thin month-to-date spend bar underneath); when they
  // don't, the name tucks under the icon in a small font so all six presets
  // still fit — ellipsis-truncated only if the name is too long even there.
  private func rowView(_ shortcut: Shortcut) -> some View {
    let logged = entry.isJustAdded(shortcut)
    let spent = entry.spend[shortcut.categoryId] ?? 0
    let fraction = mediumMaxSpend > 0 ? spent / mediumMaxSpend : 0
    return ViewThatFits(in: .horizontal) {
      rowInline(shortcut, spent: spent, logged: logged, fraction: fraction)
      rowStacked(shortcut, logged: logged)
    }
  }

  /// Name beside the icon on one line, month-to-date spend bar under it.
  private func rowInline(
    _ shortcut: Shortcut, spent: Double, logged: Bool, fraction: Double
  ) -> some View {
    VStack(spacing: 4) {
      HStack(spacing: rowGap) {
        modeCircle(shortcut, diameter: rowCircleSize, glyph: 16)
        // fixedSize: report the full name width so ViewThatFits falls through
        // to the stacked layout instead of silently truncating the name here.
        Text(shortcut.name)
          .font(.subheadline.weight(.medium))
          .foregroundColor(.primary)
          .lineLimit(1)
          .fixedSize()
        Spacer(minLength: 6)
        Text(spentCaption(spent))
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundColor(.secondary)
          .fixedSize()
        rowActions(shortcut, scaled: false)
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

  /// Name tucked small under the icon so the preset chips get the whole line.
  private func rowStacked(_ shortcut: Shortcut, logged: Bool) -> some View {
    HStack(spacing: rowGap) {
      VStack(spacing: 1) {
        modeCircle(shortcut, diameter: rowCircleSize, glyph: 16)
        Text(shortcut.name)
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
          .frame(maxWidth: rowCircleSize + 22)
      }
      Spacer(minLength: 6)
      rowActions(shortcut, scaled: true)
        .opacity(logged ? 0.35 : 1)
    }
  }

  /// The category's month-to-date total, e.g. "2 700 $" spent / "250К ₸"
  /// received. Sign-free — the flow is carried by the glass rim.
  private func spentCaption(_ value: Double) -> String {
    return abbreviatedMoney(value, symbol: entry.symbol)
  }

  @ViewBuilder
  private func rowActions(_ shortcut: Shortcut, scaled: Bool) -> some View {
    switch shortcut.mode {
    case "fixed":
      if let amount = shortcut.amount {
        amountChip(shortcut, amount)
      }
    case "presets":
      // Up to six presets, compact + abbreviated so they all fit. In the tight
      // (stacked-name) layout each chip shrinks its number instead of dropping.
      HStack(spacing: 5) {
        ForEach(Array(shortcut.presets.prefix(6)), id: \.self) { preset in
          amountChip(
            shortcut, preset, withSymbol: false, compact: true, scaled: scaled)
        }
        linkChip(shortcut, systemName: "ellipsis")
      }
    default:
      linkChip(shortcut, systemName: "plus")
    }
  }

  /// Quiet category-tinted capsule that logs the amount instantly. The fixed
  /// amount (withSymbol) carries the +/− flow sign; bare preset numbers don't.
  private func amountChip(
    _ shortcut: Shortcut, _ amount: Double,
    withSymbol: Bool = true, compact: Bool = false, scaled: Bool = false
  ) -> some View {
    Button(intent: quickAddIntent(shortcut, amount)) {
      Text(withSymbol ? fixedAmountCaption(amount) : stepLabel(amount))
        .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .rounded))
        .foregroundColor(shortcut.color)
        .lineLimit(1)
        .minimumScaleFactor(scaled ? 0.5 : 1)
        .padding(.vertical, compact ? 4 : 7)
        .padding(.horizontal, compact ? 8 : 12)
        .background(shortcut.color.opacity(0.13))
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }

  private func linkChip(_ shortcut: Shortcut, systemName: String) -> some View {
    Link(
      destination: URL(
        string:
          "financeapp://quickadd?category=\(shortcut.categoryId)&homeWidget"
          + flowQuery)!
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
    .configurationDisplayName("Quick Expense")
    .description("Log a spend in one tap. Configure categories in the app.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

/// The income counterpart of [QuickAddWidget] — a separate gallery tile that
/// logs income (green "+" accent). Shares [QuickAddEntryView]; the entry's
/// income flow flips the accent and the logged transaction type.
struct QuickIncomeWidget: Widget {
  let kind = "QuickIncomeWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: SelectIncomeGroupIntent.self,
      provider: QuickIncomeProvider()
    ) { entry in
      QuickAddEntryView(entry: entry)
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }
    .configurationDisplayName("Quick Income")
    .description("Log income in one tap. Configure categories in the app.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
