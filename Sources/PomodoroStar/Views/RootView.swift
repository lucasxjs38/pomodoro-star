import SwiftUI
import PomodoroStarCore

struct RootView: View {
    @AppStorage("focusMinutes") private var focusMinutes: Int = 20
    @AppStorage("shortBreakMinutes") private var shortBreakMinutes: Int = 5
    @AppStorage("longBreakMinutes") private var longBreakMinutes: Int = 15
    @AppStorage("selectedMode") private var selectedMode: String = "focus"
    @State private var selection: Tab = .timer

    enum Tab: String, CaseIterable, Identifiable {
        case timer
        case stats
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .timer: return "计时"
            case .stats: return "统计"
            case .settings: return "设置"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("页面", selection: $selection) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 10)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .timer:
            TimerView(
                focusMinutes: focusMinutes,
                shortBreakMinutes: shortBreakMinutes,
                longBreakMinutes: longBreakMinutes,
                selectedPhase: selectedPhase
            )
        case .stats:
            StatsView()
        case .settings:
            SettingsView()
        }
    }

    private var selectedPhase: Phase {
        switch selectedMode {
        case "shortBreak": return .shortBreak
        case "longBreak": return .longBreak
        default: return .focus
        }
    }
}
