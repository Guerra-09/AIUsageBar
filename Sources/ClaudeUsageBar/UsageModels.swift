import Foundation

struct BlocksResponse: Decodable {
    let blocks: [UsageBlock]
}

struct UsageBlock: Decodable {
    let id: String
    let startTime: String
    let endTime: String
    let isActive: Bool
    let isGap: Bool
    let entries: Int
    let models: [String]
    let totalTokens: Int
    let costUSD: Double
    let tokenCounts: TokenCounts
    let burnRate: BurnRate?
    let projection: Projection?

    struct TokenCounts: Decodable {
        let inputTokens: Int
        let outputTokens: Int
        let cacheCreationInputTokens: Int
        let cacheReadInputTokens: Int
    }

    struct BurnRate: Decodable {
        let costPerHour: Double
        let tokensPerMinute: Double
    }

    struct Projection: Decodable {
        let totalCost: Double
        let totalTokens: Int
        let remainingMinutes: Int
    }
}

enum SettingsKeys {
    static let sessionTokenLimit = "sessionTokenLimit"
    static let weeklyTokenLimit = "weeklyTokenLimit"
    static let weeklyResetWeekday = "weeklyResetWeekday" // Calendar convention: 1=Sunday...7=Saturday

    // Calibrated against real Pro-plan data points (2026-07-06):
    // - 2,317,018 tokens showed as 5% session usage => ~46M session limit.
    // - 169,115,006 tokens (since Wed reset) showed as 15% week usage => ~1.127B weekly limit.
    // Anthropic doesn't publish an exact token quota, so these are estimates,
    // not official constants. Re-calibrate via Settings if they drift.
    static let defaultSessionLimit = 46_000_000
    static let defaultWeeklyLimit = 1_127_000_000
    static let defaultWeekday = 2 // Monday
}

struct DisplayState {
    var hasActiveBlock: Bool = false
    var model: String = ""
    var costSoFar: Double = 0
    var tokensSoFar: Int = 0
    var costPerHour: Double = 0
    var startTime: Date = .now
    var endTime: Date = .now

    var weeklyTokensSoFar: Int = 0
    var weeklyCostSoFar: Double = 0
    var weeklyResetDate: Date = .now

    var lastUpdated: Date = .now
    var errorMessage: String? = nil

    private var defaults: UserDefaults { .standard }

    var sessionTokenLimit: Int {
        let v = defaults.integer(forKey: SettingsKeys.sessionTokenLimit)
        return v > 0 ? v : SettingsKeys.defaultSessionLimit
    }

    var weeklyTokenLimit: Int {
        let v = defaults.integer(forKey: SettingsKeys.weeklyTokenLimit)
        return v > 0 ? v : SettingsKeys.defaultWeeklyLimit
    }

    var sessionPercent: Int {
        Int((Double(tokensSoFar) / Double(sessionTokenLimit) * 100).rounded(.down))
    }

    var weeklyPercent: Int {
        Int((Double(weeklyTokensSoFar) / Double(weeklyTokenLimit) * 100).rounded(.down))
    }

    var elapsedFraction: Double {
        let total = endTime.timeIntervalSince(startTime)
        guard total > 0 else { return 0 }
        let elapsed = Date.now.timeIntervalSince(startTime)
        return min(max(elapsed / total, 0), 1)
    }

    var timeRemainingText: String {
        let seconds = max(endTime.timeIntervalSince(.now), 0)
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return "\(h)h \(m)m"
    }

    var weeklyResetText: String {
        weeklyResetDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    var menuBarText: String {
        if errorMessage != nil { return "Claude: --" }
        guard hasActiveBlock else { return "Claude: --" }
        return "\(sessionPercent)% · \(timeRemainingText)"
    }
}
