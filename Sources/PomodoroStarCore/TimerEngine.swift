import Foundation

public struct TimerEngine {
    public private(set) var state: TimerState = .idle(.focus)
    public private(set) var completedFocusCount: Int = 0
    public private(set) var interruptedCount: Int = 0

    private var config: PomodoroConfig
    private var deadline: Date?

    public init(config: PomodoroConfig, phase: Phase = .focus) {
        self.config = config
        self.state = .idle(phase)
    }

    /// 仅在空闲状态替换配置，保留当前阶段；下一段开始时使用新时长。
    public mutating func updateConfig(_ newConfig: PomodoroConfig) {
        guard case .idle = state else { return }
        config = newConfig
    }

    /// 回到指定模式的空闲状态，用于「再来一次」或切换模式。
    public mutating func reset(to phase: Phase) {
        deadline = nil
        state = .idle(phase)
    }

    public mutating func start(at now: Date) {
        guard case .idle(let phase) = state else { return }
        let duration = config.duration(for: phase)
        deadline = now.addingTimeInterval(duration)
        state = .running(phase, remaining: duration)
    }

    public mutating func tick(at now: Date) {
        guard case .running(let phase, _) = state,
              let deadline else { return }
        let remaining = deadline.timeIntervalSince(now)
        if remaining <= 0 {
            finish(phase: phase)
        } else {
            state = .running(phase, remaining: remaining)
        }
    }

    public mutating func advance() {
        guard case .finished(let phase) = state else { return }
        let next: Phase
        switch phase {
        case .focus:
            let rounds = config.roundsBeforeLongBreak
            let isLongBreakRound = rounds > 0 && completedFocusCount % rounds == 0
            next = isLongBreakRound ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            next = .focus
        }
        state = .idle(next)
    }

    public mutating func pause(at now: Date) {
        guard case .running(let phase, _) = state, let deadline else { return }
        let remaining = max(0, deadline.timeIntervalSince(now))
        self.deadline = nil
        state = .paused(phase, remaining: remaining)
    }

    public mutating func resume(at now: Date) {
        guard case .paused(let phase, let remaining) = state else { return }
        deadline = now.addingTimeInterval(remaining)
        state = .running(phase, remaining: remaining)
    }

    public mutating func abandon() {
        switch state {
        case .running(.focus, _), .paused(.focus, _):
            interruptedCount += 1
            deadline = nil
            state = .idle(.focus)
        case .running(let phase, _), .paused(let phase, _):
            deadline = nil
            state = .idle(phase)
        default:
            break
        }
    }

    private mutating func finish(phase: Phase) {
        deadline = nil
        state = .finished(phase)
        if phase == .focus {
            completedFocusCount += 1
        }
    }
}
