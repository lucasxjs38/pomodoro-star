import Foundation

public enum Phase: String, Codable, Equatable {
    case focus
    case shortBreak
    case longBreak
}

public struct PomodoroConfig: Equatable {
    public var focusMinutes: Int
    public var shortBreakMinutes: Int
    public var longBreakMinutes: Int
    public var roundsBeforeLongBreak: Int

    public static let `default` = PomodoroConfig()

    public init(focusMinutes: Int = 20,
                shortBreakMinutes: Int = 5,
                longBreakMinutes: Int = 15,
                roundsBeforeLongBreak: Int = 4) {
        self.focusMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.roundsBeforeLongBreak = roundsBeforeLongBreak
    }

    public func duration(for phase: Phase) -> TimeInterval {
        switch phase {
        case .focus: return TimeInterval(focusMinutes * 60)
        case .shortBreak: return TimeInterval(shortBreakMinutes * 60)
        case .longBreak: return TimeInterval(longBreakMinutes * 60)
        }
    }
}

public enum TimerState: Equatable {
    case idle(Phase)
    case running(Phase, remaining: TimeInterval)
    case paused(Phase, remaining: TimeInterval)
    case finished(Phase)
}
