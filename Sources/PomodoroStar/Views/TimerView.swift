import AppKit
import Combine
import Foundation
import PomodoroStarCore
import SwiftUI

struct TimerView: View {
    @State private var engine: TimerEngine
    @State private var config: PomodoroConfig
    @State private var statsStore: StatsStore
    @State private var todayStats: DayStats
    @State private var today: String
    @State private var completionBanner: String?
    @State private var completionHandled = false
    @State private var completionBannerTask: Task<Void, Never>?
    @State private var ringTask: Task<Void, Never>?

    /// 完成铃声持续时长（秒）
    private let ringDuration: TimeInterval = 20

    private let focusMinutes: Int
    private let shortBreakMinutes: Int
    private let longBreakMinutes: Int
    private let selectedPhase: Phase
    private let ticker = Timer.publish(
        every: 0.25,
        on: .main,
        in: .common
    ).autoconnect()

    init(
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
        selectedPhase: Phase = .focus
    ) {
        let config = PomodoroConfig(
            focusMinutes: max(1, focusMinutes),
            shortBreakMinutes: max(1, shortBreakMinutes),
            longBreakMinutes: max(1, longBreakMinutes)
        )
        let today = Self.makeTodayString()
        let statsStore = StatsStore(fileURL: StatsStore.defaultURL())

        self.focusMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.selectedPhase = selectedPhase
        _config = State(initialValue: config)
        _engine = State(initialValue: TimerEngine(config: config, phase: selectedPhase))
        _statsStore = State(initialValue: statsStore)
        _todayStats = State(initialValue: statsStore.load(today: today))
        _today = State(initialValue: today)
    }

    init() {
        let defaults = PomodoroConfig.default
        self.init(
            focusMinutes: defaults.focusMinutes,
            shortBreakMinutes: defaults.shortBreakMinutes,
            longBreakMinutes: defaults.longBreakMinutes
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let ringSize = min(
                max(220, proxy.size.width - 120),
                max(220, proxy.size.height - 270),
                350
            )

            VStack(spacing: 0) {
                Spacer(minLength: 28)

                timerRing(size: ringSize)
                    .frame(width: ringSize, height: ringSize)

                Text(phaseTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(phaseColor)
                    .padding(.top, 22)
                    .accessibilityAddTraits(.isHeader)

                controls
                    .padding(.top, 28)

                completionBannerView
                    .padding(.top, 16)

                Spacer(minLength: 20)

                Text("今日完成 \(todayStats.completedFocus) 个番茄")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 26)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear {
            stopRinging()
        }
        .onReceive(ticker) { now in
            update(for: now)
        }
        .onChange(of: focusMinutes) { _ in
            adoptConfigIfIdle()
        }
        .onChange(of: shortBreakMinutes) { _ in
            adoptConfigIfIdle()
        }
        .onChange(of: longBreakMinutes) { _ in
            adoptConfigIfIdle()
        }
        .onChange(of: selectedPhase) { _ in
            adoptConfigIfIdle()
        }
    }

    /// 仅在空闲时采用新时长或新模式；运行或暂停中的会话保持不变。
    private func adoptConfigIfIdle() {
        let updated = PomodoroConfig(
            focusMinutes: max(1, focusMinutes),
            shortBreakMinutes: max(1, shortBreakMinutes),
            longBreakMinutes: max(1, longBreakMinutes)
        )
        guard case .idle = engine.state else { return }
        if updated != config {
            config = updated
            engine.updateConfig(updated)
        }
        if currentPhase != selectedPhase {
            engine.reset(to: selectedPhase)
        }
    }

    @ViewBuilder
    private var completionBannerView: some View {
        ZStack {
            if let completionBanner {
                Text(completionBanner)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(phaseColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        phaseColor.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phaseColor.opacity(0.35), lineWidth: 1)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .frame(minHeight: 56)
        .animation(.easeInOut(duration: 0.2), value: completionBanner)
    }

    private var currentState: TimerState {
        engine.state
    }

    private var currentPhase: Phase {
        switch currentState {
        case .idle(let phase),
             .running(let phase, _),
             .paused(let phase, _),
             .finished(let phase):
            return phase
        }
    }

    private var phaseTitle: String {
        switch currentPhase {
        case .focus: return "专注"
        case .shortBreak: return "短休息"
        case .longBreak: return "长休息"
        }
    }

    private var phaseColor: Color {
        switch currentPhase {
        case .focus:
            return Color(red: 0.96, green: 0.49, blue: 0.10)
        case .shortBreak, .longBreak:
            return Color(red: 0.04, green: 0.62, blue: 0.52)
        }
    }

    private var remainingTime: TimeInterval {
        switch currentState {
        case .idle(let phase):
            return config.duration(for: phase)
        case .running(_, let remaining), .paused(_, let remaining):
            return max(0, remaining)
        case .finished:
            return 0
        }
    }

    private var totalTime: TimeInterval {
        config.duration(for: currentPhase)
    }

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return min(1, max(0, remainingTime / totalTime))
    }

    private var formattedTime: String {
        let seconds = Int(ceil(remainingTime))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func timerRing(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(
                    phaseColor.opacity(0.16),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(formattedTime)
                .font(
                    .system(
                        size: size * 0.21,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("剩余时间 \(formattedTime)")
    }

    @ViewBuilder
    private var controls: some View {
        switch currentState {
        case .idle:
            primaryButton(title: "开始", systemImage: "play.fill") {
                stopRinging()
                completionBannerTask?.cancel()
                completionBannerTask = nil
                completionBanner = nil
                engine.start(at: Date())
            }

        case .running:
            HStack(spacing: 16) {
                primaryButton(title: "暂停", systemImage: "pause.fill") {
                    engine.pause(at: Date())
                }

                abandonButton
            }

        case .paused:
            HStack(spacing: 16) {
                primaryButton(title: "继续", systemImage: "play.fill") {
                    engine.resume(at: Date())
                }

                abandonButton
            }

        case .finished:
            primaryButton(title: "再来一次", systemImage: "arrow.clockwise") {
                stopRinging()
                completionBannerTask?.cancel()
                completionBannerTask = nil
                completionBanner = nil
                completionHandled = false
                engine.reset(to: selectedPhase)
            }
        }
    }

    private func primaryButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(minWidth: 112)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(phaseColor)
        .controlSize(.large)
    }

    private var abandonButton: some View {
        Button(role: .destructive) {
            abandonTimer()
        } label: {
            Label("放弃", systemImage: "xmark")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(minWidth: 112)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func abandonTimer() {
        let interruptedFocus: Bool
        switch currentState {
        case .running(.focus, _), .paused(.focus, _):
            interruptedFocus = true
        default:
            interruptedFocus = false
        }

        engine.abandon()

        guard interruptedFocus else { return }
        var store = statsStore
        store.recordInterruption(today: today)
        statsStore = store
        todayStats = store.load(today: today)
    }

    private func update(for now: Date) {
        refreshDay(for: now)
        adoptConfigIfIdle()

        let stateBeforeTick = engine.state
        engine.tick(at: now)

        guard case .running = stateBeforeTick,
              case .finished(let phase) = engine.state,
              !completionHandled else {
            return
        }

        completionHandled = true

        if phase == .focus {
            var store = statsStore
            store.recordFocus(
                seconds: Int(config.duration(for: .focus)),
                today: today
            )
            statsStore = store
            todayStats = store.load(today: today)
        }

        presentCompletion(for: phase)
    }

    private func presentCompletion(for phase: Phase) {
        let message: String
        switch phase {
        case .focus:
            message = "专注完成！休息一下吧"
        case .shortBreak:
            message = "休息结束，继续加油"
        case .longBreak:
            message = "长休息结束，准备好了吗"
        }

        completionBannerTask?.cancel()
        completionBanner = message
        completionBannerTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 4_000_000_000)
            } catch {
                return
            }

            guard completionBanner == message else { return }
            completionBanner = nil
            completionBannerTask = nil
        }

        startRinging(for: phase)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    /// 完成后连续响铃 20 秒，期间用户点「再来一次」或开始新一段会立即停止。
    private func startRinging(for phase: Phase) {
        ringTask?.cancel()
        let soundName = phase == .focus ? "Glass" : "Ping"
        let interval: UInt64 = 2_000_000_000
        let deadline = Date().addingTimeInterval(ringDuration)

        ringTask = Task { @MainActor in
            while Date() < deadline {
                if Task.isCancelled { return }
                if let sound = NSSound(named: NSSound.Name(soundName)) {
                    sound.play()
                } else {
                    NSSound.beep()
                }
                try? await Task.sleep(nanoseconds: interval)
            }
            ringTask = nil
        }
    }

    private func stopRinging() {
        ringTask?.cancel()
        ringTask = nil
    }

    private func refreshDay(for date: Date) {
        let currentDay = Self.makeTodayString(for: date)
        guard currentDay != today else { return }
        today = currentDay
        todayStats = statsStore.load(today: currentDay)
    }

    private static func makeTodayString(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
