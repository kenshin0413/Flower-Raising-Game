import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.com.kenshin.Flower-Raising-Game"
private let flowerStorageKey = "flower_state_v1"
private let widgetKind = "FlowerCareWidgetV2"

private struct SharedFlowerState: Decodable {
    let name: String
    let water: Double
    let sunlight: Double
    let nutrition: Double
    let mood: Double
    let growth: Double
    let lastOpenedAt: Date
    let lastWateredAt: Date?
    let lastSunlightAt: Date?
    let lastFedAt: Date?
    let lastCareDate: Date?
    let careStreak: Int?
}

private enum CareNeed: String {
    case water
    case sunlight
    case nutrition

    var title: String {
        switch self {
        case .water: "水分"
        case .sunlight: "日光"
        case .nutrition: "栄養"
        }
    }

    var symbol: String {
        switch self {
        case .water: "drop.fill"
        case .sunlight: "sun.max.fill"
        case .nutrition: "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .water: .cyan
        case .sunlight: .orange
        case .nutrition: .green
        }
    }
}

private enum FlowerMood {
    case happy
    case lonely
    case sad
    case heartbroken

    var assetName: String {
        switch self {
        case .happy: "widget_flower_calm"
        case .lonely: "widget_flower_lonely"
        case .sad: "widget_flower_sad"
        case .heartbroken: "widget_flower_heartbroken"
        }
    }

    var background: LinearGradient {
        switch self {
        case .happy:
            LinearGradient(colors: [Color(red: 0.27, green: 0.77, blue: 0.42), Color(red: 0.08, green: 0.60, blue: 0.34)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .lonely:
            LinearGradient(colors: [Color(red: 0.98, green: 0.75, blue: 0.48), Color(red: 0.89, green: 0.55, blue: 0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sad:
            LinearGradient(colors: [Color(red: 0.42, green: 0.66, blue: 0.82), Color(red: 0.32, green: 0.43, blue: 0.68)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .heartbroken:
            LinearGradient(colors: [Color(red: 0.32, green: 0.38, blue: 0.62), Color(red: 0.18, green: 0.22, blue: 0.43)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct FlowerWidgetEntry: TimelineEntry {
    let date: Date
    let flower: SharedFlowerState?
    let water: Double
    let sunlight: Double
    let nutrition: Double
    let mood: FlowerMood
    let urgentNeed: CareNeed
    let message: String
}

private struct FlowerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlowerWidgetEntry {
        makeEntry(at: Date(), flower: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlowerWidgetEntry) -> Void) {
        completion(makeEntry(at: Date(), flower: loadFlower()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlowerWidgetEntry>) -> Void) {
        let now = Date()
        let flower = loadFlower()
        // 高解像度キャラクターを含む未来スナップショットを一括生成せず、1時間ごとに1件だけ更新します。
        // Widget Extensionの厳しいメモリ上限内で安定して描画するための構成です。
        let entry = makeEntry(at: now, flower: flower)
        completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(3600))))
    }

    private func loadFlower() -> SharedFlowerState? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: flowerStorageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(SharedFlowerState.self, from: data)
    }

    private func makeEntry(at date: Date, flower: SharedFlowerState?) -> FlowerWidgetEntry {
        guard let flower else {
            return FlowerWidgetEntry(date: date, flower: nil, water: 55, sunlight: 55, nutrition: 55, mood: .lonely, urgentNeed: .water, message: "会えるのを待ってるよ")
        }

        let hours = max(0, date.timeIntervalSince(flower.lastOpenedAt) / 3600)
        // アプリ内の時間経過を軽量に近似。開いた直後に本計算と同期されます。
        let water = clamp(flower.water - hours * 0.55)
        let sunlight = clamp(flower.sunlight - hours * 0.28)
        let nutrition = clamp(flower.nutrition - hours * 0.25)
        let values: [(CareNeed, Double)] = [(.water, water), (.sunlight, sunlight), (.nutrition, nutrition)]
        let urgent = values.min(by: { $0.1 < $1.1 })?.0 ?? .water
        let minimum = values.map(\.1).min() ?? 0
        let lastCare = flower.lastCareDate ?? flower.lastOpenedAt
        let ignoredHours = max(0, date.timeIntervalSince(lastCare) / 3600)
        let caredToday = flower.lastCareDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        let completedCareToday = [flower.lastWateredAt, flower.lastSunlightAt, flower.lastFedAt]
            .allSatisfy { careDate in
                guard let careDate else { return false }
                return Calendar.current.isDate(careDate, inSameDayAs: date)
            }

        let mood: FlowerMood
        if caredToday {
            mood = .happy
        } else if minimum < 20 || ignoredHours >= 24 {
            mood = .heartbroken
        } else if minimum < 38 || ignoredHours >= 14 {
            mood = .sad
        } else if minimum < 55 || ignoredHours >= 7 {
            mood = .lonely
        } else {
            mood = .happy
        }

        let message: String
        switch mood {
        case .happy:
            if completedCareToday {
                message = "全部ありがとう！"
            } else if caredToday {
                message = "今日もありがとう！"
            } else {
                message = "よし。ちゃんと見てるね！"
            }
        case .lonely: message = "少し会いたいな"
        case .sad: message = "ちょっと寂しいよ"
        case .heartbroken: message = "\(urgent.title)があるとうれしいな"
        }

        return FlowerWidgetEntry(date: date, flower: flower, water: water, sunlight: sunlight, nutrition: nutrition, mood: mood, urgentNeed: urgent, message: message)
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 100) }
}

private struct StatRow: View {
    let need: CareNeed
    let value: Double
    let urgent: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: need.symbol)
                .foregroundStyle(need.color)
                .frame(width: 16)
            Text(need.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))
            Spacer(minLength: 3)
            Text("\(Int(value.rounded()))%")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .monospacedDigit()
                .fixedSize()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(urgent ? Color.black.opacity(0.48) : Color.black.opacity(0.22), in: Capsule())
        .overlay(Capsule().stroke(urgent ? .white.opacity(0.78) : .clear, lineWidth: 1.25))
    }
}

private struct FlowerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FlowerWidgetEntry

    var body: some View {
        Group {
            if family == .systemSmall { smallView } else { mediumView }
        }
        .containerBackground(for: .widget) { entry.mood.background }
        .widgetURL(URL(string: "flowerraising://care?need=\(entry.urgentNeed.rawValue)"))
    }

    private var smallView: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                decorativeGlow

                Image(entry.mood.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: proxy.size.width * imageScaleForSmall,
                        height: proxy.size.height * imageScaleForSmall
                    )
                    .offset(
                        x: proxy.size.width * imageXForSmall,
                        y: proxy.size.height * imageYForSmall
                    )
                    .shadow(color: .black.opacity(0.20), radius: 3, y: 2)

                Text(entry.message)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 12)
                    .padding(.top, 11)

                compactStats
                    .frame(width: max(proxy.size.width - 30, 0), height: 25)
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height - 27
                    )
            }
        }
    }

    private var mediumView: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                decorativeGlow

                Image(entry.mood.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width * 0.54, height: proxy.size.height * 1.18)
                    .offset(x: -proxy.size.width * 0.055, y: proxy.size.height * 0.05)
                    .shadow(color: .black.opacity(0.20), radius: 3, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(moodKicker)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.72))

                    Text(entry.message)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    VStack(spacing: 3) {
                        StatRow(need: .water, value: entry.water, urgent: entry.urgentNeed == .water)
                        StatRow(need: .sunlight, value: entry.sunlight, urgent: entry.urgentNeed == .sunlight)
                        StatRow(need: .nutrition, value: entry.nutrition, urgent: entry.urgentNeed == .nutrition)
                    }

                }
                .frame(width: proxy.size.width * 0.50, alignment: .leading)
                .offset(x: proxy.size.width * 0.46, y: 8)
            }
        }
    }

    private var urgentBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.urgentNeed.symbol)
                .foregroundStyle(entry.urgentNeed.color)
            Text(entry.urgentNeed.title)
            Text("\(Int(value(for: entry.urgentNeed).rounded()))%")
                .monospacedDigit()
                .fixedSize()
        }
        .font(.system(size: 12, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.black.opacity(0.52), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1.25))
    }

    private var compactStats: some View {
        HStack(spacing: 3) {
            compactStat(need: .water, value: entry.water)
            compactStat(need: .sunlight, value: entry.sunlight)
            compactStat(need: .nutrition, value: entry.nutrition)
        }
        .frame(height: 25)
        .padding(.horizontal, 3)
        .background(.black.opacity(0.46), in: Capsule())
    }

    private func compactStat(need: CareNeed, value: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: need.symbol)
                .foregroundStyle(need.color)
            Text("\(Int(value.rounded()))")
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .font(.system(size: 9, weight: .black, design: .rounded))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(
            entry.urgentNeed == need ? Color.white.opacity(0.18) : Color.clear,
            in: Capsule()
        )
        .overlay(
            Capsule().stroke(
                entry.urgentNeed == need ? Color.white.opacity(0.82) : Color.clear,
                lineWidth: 1
            )
        )
    }

    private var decorativeGlow: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 150, height: 150)
                .offset(x: -55, y: 52)
            Circle()
                .fill(Color.yellow.opacity(entry.mood == .happy ? 0.20 : 0.08))
                .frame(width: 110, height: 110)
                .offset(x: 100, y: -60)
        }
    }

    private var moodKicker: String {
        switch entry.mood {
        case .happy: "TODAY'S FLOWER"
        case .lonely: "また会えたらうれしいな"
        case .sad: "少しさみしい気分"
        case .heartbroken: "そばにいてほしいな"
        }
    }

    private var imageScaleForSmall: CGFloat {
        entry.mood == .heartbroken ? 1.15 : 1.02
    }

    private var imageXForSmall: CGFloat {
        entry.mood == .heartbroken ? 0.02 : 0.13
    }

    private var imageYForSmall: CGFloat {
        entry.mood == .heartbroken ? 0.10 : 0.12
    }

    private func value(for need: CareNeed) -> Double {
        switch need {
        case .water: entry.water
        case .sunlight: entry.sunlight
        case .nutrition: entry.nutrition
        }
    }
}

struct FlowerCareWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: FlowerTimelineProvider()) { entry in
            FlowerWidgetView(entry: entry)
        }
        .configurationDisplayName("花のお世話")
        .description("花の機嫌と、水分・日光・栄養をいつでも確認できます。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct FlowerCareWidgetBundle: WidgetBundle {
    var body: some Widget {
        FlowerCareWidget()
    }
}
