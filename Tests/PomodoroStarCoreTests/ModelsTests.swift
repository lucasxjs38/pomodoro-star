import XCTest
@testable import PomodoroStarCore

final class ModelsTests: XCTestCase {
    func testDefaultConfigIsTwentyMinutes() {
        let config = PomodoroConfig.default
        XCTAssertEqual(config.focusMinutes, 20)
        XCTAssertEqual(config.shortBreakMinutes, 5)
        XCTAssertEqual(config.longBreakMinutes, 15)
        XCTAssertEqual(config.roundsBeforeLongBreak, 4)
    }

    func testPhaseDurations() {
        let config = PomodoroConfig(focusMinutes: 15)
        XCTAssertEqual(config.duration(for: .focus), 15 * 60)
        XCTAssertEqual(config.duration(for: .shortBreak), 5 * 60)
        XCTAssertEqual(config.duration(for: .longBreak), 15 * 60)
    }
}
