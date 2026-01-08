import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalSpending: "₺0,00", remainingBudget: "₺0,00", usagePercent: 0, currentDate: "Bugün")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = getEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func getEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.fismatik.widget")
        
        // Use better defaults if values are missing
        let totalSpending = userDefaults?.string(forKey: "total_spending") ?? "₺0,00"
        let remainingBudget = userDefaults?.string(forKey: "remaining_budget") ?? "₺0,00"
        let usagePercent = userDefaults?.integer(forKey: "usage_percent") ?? 0
        let currentDate = userDefaults?.string(forKey: "current_date") ?? "FişMatik"

        return SimpleEntry(
            date: Date(),
            totalSpending: totalSpending,
            remainingBudget: remainingBudget,
            usagePercent: usagePercent,
            currentDate: currentDate
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalSpending: String
    let remainingBudget: String
    let usagePercent: Int
    let currentDate: String
}

struct FismatikWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FişMatik")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
                Text(entry.currentDate)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Kalan Bütçe")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(entry.remainingBudget)
                    .font(.system(size: 18, weight: .bold))
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry.usagePercent > 90 ? Color.red : Color.blue)
                        .frame(width: geometry.size.width * CGFloat(entry.usagePercent) / 100, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Harcama: \(entry.totalSpending)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("%\(entry.usagePercent)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(entry.usagePercent > 90 ? .red : .primary)
            }
        }
        .padding()
        .widgetBackground(Color(.systemBackground))
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}


struct FismatikWidget: Widget {
    let kind: String = "FismatikWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FismatikWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FişMatik Özet")
        .description("Günlük harcama ve kalan bütçe takibi.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
