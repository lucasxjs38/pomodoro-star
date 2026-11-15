import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedMode") private var selectedMode: String = "focus"
    @AppStorage("focusMinutes") private var focusMinutes: Int = 20
    @AppStorage("shortBreakMinutes") private var shortBreakMinutes: Int = 5
    @AppStorage("longBreakMinutes") private var longBreakMinutes: Int = 15

    private let focusOptions = [10, 15, 20, 25]
    private let shortBreakOptions = [3, 5, 10]
    private let longBreakOptions = [10, 15, 20]

    private let accent = Color(red: 0.96, green: 0.49, blue: 0.10)
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("选择模式")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)

                Text("一次只运行一个模式")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                modeRow

                Divider()
                    .padding(.vertical, 6)

                Text("时长")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)

                Text("下一段开始时生效")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(currentOptions, id: \.self) { minutes in
                        optionCard(minutes: minutes, selected: currentMinutes == minutes) {
                            setCurrentMinutes(minutes)
                        }
                    }
                }

                Text(modeNote)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var modeRow: some View {
        HStack(spacing: 14) {
            modeCard(id: "focus", title: "专注", symbol: "brain.head.profile")
            modeCard(id: "shortBreak", title: "短休息", symbol: "cup.and.saucer")
            modeCard(id: "longBreak", title: "长休息", symbol: "moon.stars")
        }
    }

    private func modeCard(id: String, title: String, symbol: String) -> some View {
        let isSelected = selectedMode == id

        return Button {
            selectedMode = id
        } label: {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .semibold))

                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.16) : Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? accent : Color.primary.opacity(0.10),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .foregroundStyle(isSelected ? accent : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var currentOptions: [Int] {
        switch selectedMode {
        case "shortBreak": return shortBreakOptions
        case "longBreak": return longBreakOptions
        default: return focusOptions
        }
    }

    private var currentMinutes: Int {
        switch selectedMode {
        case "shortBreak": return shortBreakMinutes
        case "longBreak": return longBreakMinutes
        default: return focusMinutes
        }
    }

    private var modeNote: String {
        switch selectedMode {
        case "shortBreak": return "短休息：放松一下眼睛和身体"
        case "longBreak": return "长休息：起来走动、喝点水"
        default: return "专注：一次只做一件事"
        }
    }

    private func setCurrentMinutes(_ minutes: Int) {
        switch selectedMode {
        case "shortBreak": shortBreakMinutes = minutes
        case "longBreak": longBreakMinutes = minutes
        default: focusMinutes = minutes
        }
    }

    private func optionCard(minutes: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(minutes)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("分钟")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? accent : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? accent.opacity(0.16) : Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        selected ? accent : Color.primary.opacity(0.10),
                        lineWidth: selected ? 3 : 1
                    )
            )
            .foregroundStyle(selected ? accent : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) 分钟")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
