import XCTest
@testable import PomodoroStarCore

final class StatsStoreTests: XCTestCase {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("stats-\(UUID().uuidString).json")
    }

    func testFreshStoreReturnsZeroStats() {
        let store = StatsStore(fileURL: tempURL())
        let stats = store.load(today: "2026-11-15")
        XCTAssertEqual(stats.completedFocus, 0)
        XCTAssertEqual(stats.focusSeconds, 0)
        XCTAssertEqual(stats.interrupted, 0)
    }

    func testSaveThenLoadRoundTrips() {
        let url = tempURL()
        var store = StatsStore(fileURL: url)
        store.recordFocus(seconds: 1200, today: "2026-11-15")
        let reloaded = StatsStore(fileURL: url).load(today: "2026-11-15")

        XCTAssertEqual(reloaded.completedFocus, 1)
        XCTAssertEqual(reloaded.focusSeconds, 1200)
    }

    func testDayChangeResetsStats() {
        let url = tempURL()
        var store = StatsStore(fileURL: url)
        store.recordFocus(seconds: 1200, today: "2026-11-15")
        let nextDay = store.load(today: "2026-11-16")

        XCTAssertEqual(nextDay.completedFocus, 0)
        XCTAssertEqual(nextDay.focusSeconds, 0)
    }

    func testCorruptFileReturnsEmptyStats() throws {
        let url = tempURL()
        try Data("not json".utf8).write(to: url)
        let stats = StatsStore(fileURL: url).load(today: "2026-11-15")
        XCTAssertEqual(stats.completedFocus, 0)
    }

    func testSaveFailureDoesNotCrashAndPersistsNothing() {
        let badURL = URL(fileURLWithPath: "/nonexistent-dir-\(UUID().uuidString)/stats.json")
        var store = StatsStore(fileURL: badURL)
        store.recordFocus(seconds: 60, today: "2026-11-15")
        let stats = store.load(today: "2026-11-15")
        XCTAssertEqual(stats.completedFocus, 0)
    }
}
