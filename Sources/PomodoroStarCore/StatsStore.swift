import Foundation

public struct DayStats: Codable, Equatable {
    public var date: String
    public var completedFocus: Int
    public var focusSeconds: Int
    public var interrupted: Int

    public init(date: String = "",
                completedFocus: Int = 0,
                focusSeconds: Int = 0,
                interrupted: Int = 0) {
        self.date = date
        self.completedFocus = completedFocus
        self.focusSeconds = focusSeconds
        self.interrupted = interrupted
    }
}

public struct StatsStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
            .appendingPathComponent("PomodoroStar", isDirectory: true)
        try? FileManager.default.createDirectory(at: base,
                                                 withIntermediateDirectories: true)
        return base.appendingPathComponent("stats.json")
    }

    public func load(today: String) -> DayStats {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                Self.warn("could not read stats at \(fileURL.path): \(error)")
            }
            return DayStats(date: today)
        }

        let decoded: DayStats
        do {
            decoded = try JSONDecoder().decode(DayStats.self, from: data)
        } catch {
            Self.warn("could not decode stats at \(fileURL.path): \(error)")
            return DayStats(date: today)
        }

        guard decoded.date == today else { return DayStats(date: today) }
        return decoded
    }

    public mutating func recordFocus(seconds: Int, today: String) {
        var stats = load(today: today)
        stats.date = today
        stats.completedFocus += 1
        stats.focusSeconds += seconds
        save(stats)
    }

    public mutating func recordInterruption(today: String) {
        var stats = load(today: today)
        stats.date = today
        stats.interrupted += 1
        save(stats)
    }

    @discardableResult
    func save(_ stats: DayStats) -> Bool {
        let data: Data
        do {
            data = try JSONEncoder().encode(stats)
        } catch {
            Self.warn("could not encode stats: \(error)")
            return false
        }

        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            Self.warn("could not write stats to \(fileURL.path): \(error)")
            return false
        }
    }

    private static func warn(_ message: String) {
        let line = "PomodoroStar warning: \(message)\n"
        if let bytes = line.data(using: .utf8) {
            FileHandle.standardError.write(bytes)
        }
    }
}
