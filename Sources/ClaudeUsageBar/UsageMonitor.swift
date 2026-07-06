import Foundation
import Combine

@MainActor
final class UsageMonitor: ObservableObject {
    @Published var state = DisplayState()

    private var timer: Timer?
    private let refreshInterval: TimeInterval = 30

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        let weeklyResetWeekday = UserDefaults.standard.integer(forKey: SettingsKeys.weeklyResetWeekday)
        let weekday = weeklyResetWeekday > 0 ? weeklyResetWeekday : SettingsKeys.defaultWeekday

        Task.detached { [weak self] in
            let activeResult = Self.runCcusage(args: ["claude", "blocks", "--active", "--json"])

            let weekStart = Self.currentWeekStart(resetWeekday: weekday, now: .now)
            let since = Self.formatSince(weekStart)
            let weeklyResult = Self.runCcusage(args: ["claude", "blocks", "--json", "--since", since])

            guard let self else { return }
            await self.apply(active: activeResult, weekly: weeklyResult, weekStart: weekStart)
        }
    }

    private func apply(active: Result<BlocksResponse, Error>, weekly: Result<BlocksResponse, Error>, weekStart: Date) {
        state.lastUpdated = .now

        switch active {
        case .failure(let error):
            state.errorMessage = error.localizedDescription
            state.hasActiveBlock = false
        case .success(let response):
            state.errorMessage = nil
            if let block = response.blocks.first(where: { $0.isActive && !$0.isGap }) {
                state.hasActiveBlock = true
                state.model = block.models.first ?? "?"
                state.costSoFar = block.costUSD
                state.tokensSoFar = block.totalTokens
                state.costPerHour = block.burnRate?.costPerHour ?? 0
                state.startTime = Self.parseISO(block.startTime)
                state.endTime = Self.parseISO(block.endTime)
            } else {
                state.hasActiveBlock = false
            }
        }

        if case .success(let response) = weekly {
            let relevant = response.blocks.filter { !$0.isGap }
            state.weeklyTokensSoFar = relevant.reduce(0) { $0 + $1.totalTokens }
            state.weeklyCostSoFar = relevant.reduce(0) { $0 + $1.costUSD }
        }
        state.weeklyResetDate = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    nonisolated private static func parseISO(_ s: String) -> Date {
        let full = ISO8601DateFormatter()
        full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = full.date(from: s) { return d }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: s) ?? .now
    }

    /// Start of the current weekly quota window: most recent occurrence of
    /// `resetWeekday` at 00:00 local time, at or before `now`.
    nonisolated private static func currentWeekStart(resetWeekday: Int, now: Date) -> Date {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        let todayWeekday = cal.component(.weekday, from: startOfToday)
        var diff = todayWeekday - resetWeekday
        if diff < 0 { diff += 7 }
        return cal.date(byAdding: .day, value: -diff, to: startOfToday) ?? startOfToday
    }

    nonisolated private static func formatSince(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = .current
        return f.string(from: date)
    }

    /// Shells out via a login shell so nvm/PATH customizations in the user's
    /// shell profile are picked up (GUI apps don't inherit the login PATH).
    nonisolated private static func runCcusage(args: [String]) -> Result<BlocksResponse, Error> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", (["ccusage"] + args).joined(separator: " ")]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()

            guard process.terminationStatus == 0 else {
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let errText = String(data: errData, encoding: .utf8) ?? "unknown error"
                return .failure(NSError(domain: "ccusage", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errText]))
            }

            let decoded = try JSONDecoder().decode(BlocksResponse.self, from: outData)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }
}
