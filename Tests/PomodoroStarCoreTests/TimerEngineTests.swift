import XCTest
@testable import PomodoroStarCore

final class TimerEngineTests: XCTestCase {
    func testInitialStateIsIdleFocus() {
        let engine = TimerEngine(config: .default)
        XCTAssertEqual(engine.state, .idle(.focus))
    }

    func testStartEntersRunningWithFullDuration() {
        var engine = TimerEngine(config: .default)
        engine.start(at: Date(timeIntervalSince1970: 0))
        guard case .running(.focus, let remaining) = engine.state else {
            return XCTFail("expected running focus")
        }
        XCTAssertEqual(remaining, 20 * 60, accuracy: 0.001)
    }

    func testTickDecrementsByAbsoluteTime() {
        var engine = TimerEngine(config: .default)
        let start = Date(timeIntervalSince1970: 1000)
        engine.start(at: start)
        engine.tick(at: start.addingTimeInterval(60))

        guard case .running(.focus, let remaining) = engine.state else {
            return XCTFail("expected running")
        }
        XCTAssertEqual(remaining, 20 * 60 - 60, accuracy: 0.001)
    }

    func testLargeGapAfterSleepIsHandled() {
        var engine = TimerEngine(config: .default)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(at: start)
        engine.tick(at: start.addingTimeInterval(600))
        guard case .running(.focus, let remaining) = engine.state else {
            return XCTFail("expected running")
        }
        XCTAssertEqual(remaining, 10 * 60, accuracy: 0.001)
    }

    func testFirstCompletionLeadsToShortBreak() {
        var engine = TimerEngine(config: .default)
        engine.start(at: Date(timeIntervalSince1970: 0))
        engine.tick(at: Date(timeIntervalSince1970: 20 * 60))
        engine.advance()

        XCTAssertEqual(engine.completedFocusCount, 1)
        XCTAssertEqual(engine.state, .idle(.shortBreak))
    }

    func testFourthCompletionLeadsToLongBreak() {
        var engine = TimerEngine(config: .default)
        var now = Date(timeIntervalSince1970: 0)
        for _ in 0..<4 {
            // full focus cycle
            engine.start(at: now)
            now = now.addingTimeInterval(20 * 60)
            engine.tick(at: now)
            engine.advance()

            // skip the break unless the long break cycle has been reached
            if engine.completedFocusCount < 4 {
                engine.start(at: now)
                now = now.addingTimeInterval(5 * 60)
                engine.tick(at: now)
                engine.advance()
            }
        }

        XCTAssertEqual(engine.completedFocusCount, 4)
        XCTAssertEqual(engine.state, .idle(.longBreak))
    }

    func testBreakCompletionReturnsToFocus() {
        var engine = TimerEngine(config: .default)
        engine.start(at: Date(timeIntervalSince1970: 0))
        engine.tick(at: Date(timeIntervalSince1970: 20 * 60))
        engine.advance() // -> shortBreak idle
        engine.start(at: Date(timeIntervalSince1970: 1300))
        engine.tick(at: Date(timeIntervalSince1970: 1300 + 5 * 60))
        engine.advance()

        XCTAssertEqual(engine.state, .idle(.focus))
    }

    func testPauseFreezesRemaining() {
        var engine = TimerEngine(config: .default)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(at: start)
        engine.tick(at: start.addingTimeInterval(60))
        engine.pause(at: start.addingTimeInterval(60))
        engine.tick(at: start.addingTimeInterval(600))

        guard case .paused(.focus, let remaining) = engine.state else {
            return XCTFail("expected paused")
        }
        XCTAssertEqual(remaining, 19 * 60, accuracy: 0.001)
    }

    func testResumeContinuesCountdown() {
        var engine = TimerEngine(config: .default)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(at: start)
        engine.tick(at: start.addingTimeInterval(60))
        engine.pause(at: start.addingTimeInterval(60))
        engine.resume(at: start.addingTimeInterval(120))
        engine.tick(at: start.addingTimeInterval(180))

        guard case .running(.focus, let remaining) = engine.state else {
            return XCTFail("expected running")
        }
        XCTAssertEqual(remaining, 18 * 60, accuracy: 0.001)
    }

    func testAbandonCountsInterruptionNotCompletion() {
        var engine = TimerEngine(config: .default)
        engine.start(at: Date(timeIntervalSince1970: 0))
        engine.abandon()

        XCTAssertEqual(engine.completedFocusCount, 0)
        XCTAssertEqual(engine.interruptedCount, 1)
        XCTAssertEqual(engine.state, .idle(.focus))
    }

    func testAbandonDuringBreakDoesNotCountInterruption() {
        var engine = TimerEngine(config: .default)
        engine.start(at: Date(timeIntervalSince1970: 0))
        engine.tick(at: Date(timeIntervalSince1970: 20 * 60))
        engine.advance()
        engine.start(at: Date(timeIntervalSince1970: 1300))
        engine.abandon()

        XCTAssertEqual(engine.interruptedCount, 0)
        XCTAssertEqual(engine.state, .idle(.shortBreak))
    }

    func testAdvanceDoesNotTrapWhenRoundsIsZero() {
        var engine = TimerEngine(config: PomodoroConfig(roundsBeforeLongBreak: 0))
        engine.start(at: Date(timeIntervalSince1970: 0))
        engine.tick(at: Date(timeIntervalSince1970: 20 * 60))
        engine.advance()
        XCTAssertEqual(engine.state, .idle(.shortBreak))
    }

    func testSleepPastDeadlineFinishesOnce() {
        var engine = TimerEngine(config: .default)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(at: start)
        engine.tick(at: start.addingTimeInterval(3600))
        XCTAssertEqual(engine.state, .finished(.focus))
        XCTAssertEqual(engine.completedFocusCount, 1)
        engine.tick(at: start.addingTimeInterval(3700))
        engine.tick(at: start.addingTimeInterval(3800))
        XCTAssertEqual(engine.completedFocusCount, 1)
    }

    func testUpdateConfigAppliesToNextSession() {
        var engine = TimerEngine(config: .default)
        engine.updateConfig(PomodoroConfig(shortBreakMinutes: 10))
        engine.start(at: Date(timeIntervalSince1970: 0))
        engine.tick(at: Date(timeIntervalSince1970: 20 * 60))
        engine.advance()

        XCTAssertEqual(engine.state, .idle(.shortBreak))
        engine.start(at: Date(timeIntervalSince1970: 1300))
        guard case .running(.shortBreak, let remaining) = engine.state else {
            return XCTFail("expected running short break")
        }
        XCTAssertEqual(remaining, 10 * 60, accuracy: 0.001)
    }

    func testUpdateConfigIsIgnoredWhileRunning() {
        var engine = TimerEngine(config: .default)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(at: start)
        engine.updateConfig(PomodoroConfig(focusMinutes: 5))
        engine.tick(at: start.addingTimeInterval(60))

        guard case .running(.focus, let remaining) = engine.state else {
            return XCTFail("expected running focus")
        }
        XCTAssertEqual(remaining, 20 * 60 - 60, accuracy: 0.001)
    }

    func testInitialPhaseCanBeBreakMode() {
        let engine = TimerEngine(config: .default, phase: .shortBreak)
        XCTAssertEqual(engine.state, .idle(.shortBreak))
    }

    func testResetReturnsToChosenMode() {
        var engine = TimerEngine(config: .default, phase: .longBreak)
        engine.start(at: Date(timeIntervalSince1970: 0))
        engine.tick(at: Date(timeIntervalSince1970: 15 * 60))
        XCTAssertEqual(engine.state, .finished(.longBreak))

        engine.reset(to: .longBreak)
        XCTAssertEqual(engine.state, .idle(.longBreak))
        engine.start(at: Date(timeIntervalSince1970: 1000))
        guard case .running(.longBreak, let remaining) = engine.state else {
            return XCTFail("expected running long break")
        }
        XCTAssertEqual(remaining, 15 * 60, accuracy: 0.001)
    }
}
