//
//  FinanceWidget.swift
//  FinanceWidget
//

import WidgetKit
import SwiftUI

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
        ForEach(entry.categories.prefix(3)) { category in
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
    .widgetURL(URL(string: "financeapp://add"))
  }
}

@main
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
