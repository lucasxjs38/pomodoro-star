import PomodoroStarCore
import SwiftUI

struct StatsView: View {
    @State private var stats: DayStats
    @State private var today: String

    private let accent = Color(red: 0.96, green: 0.49, blue: 0.10)
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible())
    ]

    init() {
        let today = Self.makeTodayString()
        let loaded = StatsStore(fileURL: StatsStore.defaultURL()).load(today: today)
        _stats = State(initialValue: loaded)
        _today = State(initialValue: today)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("今日统计")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)

                Text(Self.displayDate(for: today))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                if isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        statCard(
                            title: "完成番茄",
                            value: "\(stats.completedFocus)",
                            unit: "个"
                        )
                        statCard(
                            title: "累计专注",
                            value: "\(focusMinutes)",
                            unit: "分钟"
                        )
                        statCard(
                            title: "中断次数",
                            value: "\(stats.interrupted)",
                            unit: "次"
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: reload)
    }

    private var focusMinutes: Int {
        Int((Double(stats.focusSeconds) / 60.0).rounded())
    }

    private var isEmpty: Bool {
        stats.completedFocus == 0 && stats.focusSeconds == 0 && stats.interrupted == 0
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(accent.opacity(0.7))

            Text("今天还没有开始，加油！")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private func statCard(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accent)

                Text(unit)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value) \(unit)")
    }

    private func reload() {
        let currentDay = Self.makeTodayString()
        today = currentDay
        stats = StatsStore(fileURL: StatsStore.defaultURL()).load(today: currentDay)
    }

    private static func displayDate(for day: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.calendar = Calendar(identifier: .gregorian)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: day) else { return day }

        let output = DateFormatter()
        output.locale = Locale(identifier: "zh_CN")
        output.calendar = Calendar(identifier: .gregorian)
        output.dateFormat = "M月d日"
        return output.string(from: date)
    }

    private static func makeTodayString(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
