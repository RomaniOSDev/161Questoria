import Combine
import Foundation

enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

enum ActivityIdentifier: String, CaseIterable, Identifiable {
    case elementalConvergence
    case elementalCascade
    case arcaneRhythm
    case bossGauntlet

    var id: String { rawValue }

    /// Activities shown as standard lanes on the Play tab (excludes boss).
    static let standardActivities: [ActivityIdentifier] = [.elementalConvergence, .elementalCascade, .arcaneRhythm]

    var title: String {
        switch self {
        case .elementalConvergence: return "Elemental Convergence"
        case .elementalCascade: return "Elemental Cascade"
        case .arcaneRhythm: return "Arcane Rhythm"
        case .bossGauntlet: return "Boss Gauntlet"
        }
    }

    var subtitle: String {
        switch self {
        case .elementalConvergence: return "Tap, combine, and strike before the shield reacts."
        case .elementalCascade: return "Drag elements along paths to match weak zones."
        case .arcaneRhythm: return "Charge runes and release with precise timing."
        case .bossGauntlet: return "One relentless convergence trial — endurance and combos decide victory."
        }
    }
}

enum ActivityOutcome {
    case victory
    case defeat
}

struct SessionAttemptLog: Codable, Identifiable, Equatable {
    let id: UUID
    let endedAt: Date
    let activityRaw: String
    let difficultyRaw: String
    let level: Int
    let outcomeRaw: String
    let stars: Int
    let practice: Bool

    var outcome: ActivityOutcome {
        outcomeRaw == "victory" ? .victory : .defeat
    }
}

final class ProgressStore: ObservableObject {
    private enum Keys {
        static let prefix = "questoria.progress."
        static let hasSeenOnboarding = prefix + "hasSeenOnboarding"
        static let totalActivitiesPlayed = prefix + "totalActivitiesPlayed"
        static let totalStarsEarned = prefix + "totalStarsEarned"
        static let totalPlayTimeSeconds = prefix + "totalPlayTimeSeconds"
        static let streakCount = prefix + "streakCount"
        static let starsPayload = prefix + "starsPayload"
        static let unlockedPayload = prefix + "unlockedPayload"
        static let lastPlayDay = prefix + "lastPlayDay"
        static let weekStarsAnchor = prefix + "weekStarsAnchor"
        static let weekStarsEarned = prefix + "weekStarsEarned"
        static let dayStarsAnchor = prefix + "dayStarsAnchor"
        static let dayStarsEarned = prefix + "dayStarsEarned"
        static let attemptHistoryPayload = prefix + "attemptHistory"
        static let bossGauntletDefeated = prefix + "bossGauntletDefeated"
    }

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var totalActivitiesPlayed: Int
    @Published private(set) var totalStarsEarned: Int
    @Published private(set) var totalPlayTimeSeconds: Int
    @Published private(set) var streakCount: Int
    @Published private(set) var starsPerActivity: [String: [String: [Int]]]
    @Published private(set) var unlockedLevels: [String: [String: Int]]
    @Published private(set) var weeklyStarsEarned: Int
    @Published private(set) var dailyStarsEarned: Int
    @Published private(set) var attemptLogs: [SessionAttemptLog]
    @Published private(set) var bossGauntletDefeated: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalActivitiesPlayed = defaults.integer(forKey: Keys.totalActivitiesPlayed)
        totalStarsEarned = defaults.integer(forKey: Keys.totalStarsEarned)
        totalPlayTimeSeconds = defaults.integer(forKey: Keys.totalPlayTimeSeconds)
        streakCount = defaults.integer(forKey: Keys.streakCount)
        starsPerActivity = ProgressStore.decodeStars(defaults.string(forKey: Keys.starsPayload))
        unlockedLevels = ProgressStore.decodeUnlocked(defaults.string(forKey: Keys.unlockedPayload))
        weeklyStarsEarned = defaults.integer(forKey: Keys.weekStarsEarned)
        dailyStarsEarned = defaults.integer(forKey: Keys.dayStarsEarned)
        attemptLogs = ProgressStore.decodeAttempts(defaults.string(forKey: Keys.attemptHistoryPayload))
        bossGauntletDefeated = defaults.bool(forKey: Keys.bossGauntletDefeated)

        reconcileWeekBucketIfNeeded()
        reconcileDayBucketIfNeeded()

        NotificationCenter.default.publisher(for: .progressReset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalActivitiesPlayed = defaults.integer(forKey: Keys.totalActivitiesPlayed)
        totalStarsEarned = defaults.integer(forKey: Keys.totalStarsEarned)
        totalPlayTimeSeconds = defaults.integer(forKey: Keys.totalPlayTimeSeconds)
        streakCount = defaults.integer(forKey: Keys.streakCount)
        starsPerActivity = ProgressStore.decodeStars(defaults.string(forKey: Keys.starsPayload))
        unlockedLevels = ProgressStore.decodeUnlocked(defaults.string(forKey: Keys.unlockedPayload))
        weeklyStarsEarned = defaults.integer(forKey: Keys.weekStarsEarned)
        dailyStarsEarned = defaults.integer(forKey: Keys.dayStarsEarned)
        attemptLogs = ProgressStore.decodeAttempts(defaults.string(forKey: Keys.attemptHistoryPayload))
        bossGauntletDefeated = defaults.bool(forKey: Keys.bossGauntletDefeated)
        reconcileWeekBucketIfNeeded()
        reconcileDayBucketIfNeeded()
    }

    var isBossGauntletUnlocked: Bool {
        totalStarsEarned >= QuestoriaGame.bossUnlockTotalStars
    }

    func recordAttempt(
        activity: ActivityIdentifier,
        difficulty: GameDifficulty,
        level: Int,
        outcome: ActivityOutcome,
        stars: Int,
        practice: Bool
    ) {
        let entry = SessionAttemptLog(
            id: UUID(),
            endedAt: Date(),
            activityRaw: activity.rawValue,
            difficultyRaw: difficulty.rawValue,
            level: level,
            outcomeRaw: outcome == .victory ? "victory" : "defeat",
            stars: stars,
            practice: practice
        )
        var next = attemptLogs
        next.insert(entry, at: 0)
        if next.count > QuestoriaGame.attemptHistoryLimit {
            next = Array(next.prefix(QuestoriaGame.attemptHistoryLimit))
        }
        attemptLogs = next
        persistAttempts()
    }

    private func persistAttempts() {
        guard let data = try? JSONEncoder().encode(attemptLogs),
              let text = String(data: data, encoding: .utf8) else {
            return
        }
        defaults.set(text, forKey: Keys.attemptHistoryPayload)
    }

    private func reconcileWeekBucketIfNeeded() {
        let key = ProgressStore.isoWeekAnchor(for: Date())
        if defaults.string(forKey: Keys.weekStarsAnchor) != key {
            defaults.set(key, forKey: Keys.weekStarsAnchor)
            defaults.set(0, forKey: Keys.weekStarsEarned)
            weeklyStarsEarned = 0
        } else {
            weeklyStarsEarned = defaults.integer(forKey: Keys.weekStarsEarned)
        }
    }

    private func reconcileDayBucketIfNeeded() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone.current
        let dayKey = formatter.string(from: Calendar.current.startOfDay(for: Date()))
        if defaults.string(forKey: Keys.dayStarsAnchor) != dayKey {
            defaults.set(dayKey, forKey: Keys.dayStarsAnchor)
            defaults.set(0, forKey: Keys.dayStarsEarned)
            dailyStarsEarned = 0
        } else {
            dailyStarsEarned = defaults.integer(forKey: Keys.dayStarsEarned)
        }
    }

    private func accumulateGoalStars(delta: Int) {
        guard delta > 0 else { return }
        reconcileWeekBucketIfNeeded()
        reconcileDayBucketIfNeeded()

        weeklyStarsEarned += delta
        defaults.set(weeklyStarsEarned, forKey: Keys.weekStarsEarned)

        dailyStarsEarned += delta
        defaults.set(dailyStarsEarned, forKey: Keys.dayStarsEarned)
    }

    private static func isoWeekAnchor(for date: Date) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let y = comps.yearForWeekOfYear ?? 0
        let w = comps.weekOfYear ?? 0
        return "\(y)-W\(w)"
    }

    private static func decodeAttempts(_ text: String?) -> [SessionAttemptLog] {
        guard let text,
              let data = text.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SessionAttemptLog].self, from: data) else {
            return []
        }
        return decoded
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
    }

    func recordPlaySessionStart() {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone.current

        let todayKey = formatter.string(from: todayStart)

        if let previousRaw = defaults.string(forKey: Keys.lastPlayDay),
           let previousDate = formatter.date(from: previousRaw) {
            let previousStart = calendar.startOfDay(for: previousDate)
            if previousStart == todayStart {
                defaults.set(todayKey, forKey: Keys.lastPlayDay)
                defaults.set(streakCount, forKey: Keys.streakCount)
                return
            }

            let dayDifference = calendar.dateComponents([.day], from: previousStart, to: todayStart).day ?? 0
            if dayDifference == 1 {
                streakCount += 1
            } else {
                streakCount = 1
            }
        } else {
            streakCount = 1
        }

        defaults.set(todayKey, forKey: Keys.lastPlayDay)
        defaults.set(streakCount, forKey: Keys.streakCount)
    }

    func incrementActivitiesPlayed() {
        totalActivitiesPlayed += 1
        defaults.set(totalActivitiesPlayed, forKey: Keys.totalActivitiesPlayed)
    }

    func addPlayTime(seconds: Int) {
        guard seconds > 0 else { return }
        totalPlayTimeSeconds += seconds
        defaults.set(totalPlayTimeSeconds, forKey: Keys.totalPlayTimeSeconds)
    }

    func stars(for activity: ActivityIdentifier, difficulty: GameDifficulty, level index: Int) -> Int {
        starsPerActivity[activity.rawValue]?[difficulty.rawValue]?[safe: index] ?? 0
    }

    func highestUnlockedLevel(for activity: ActivityIdentifier, difficulty: GameDifficulty) -> Int {
        unlockedLevels[activity.rawValue]?[difficulty.rawValue] ?? 0
    }

    func isLevelUnlocked(activity: ActivityIdentifier, difficulty: GameDifficulty, level index: Int) -> Bool {
        index <= highestUnlockedLevel(for: activity, difficulty: difficulty)
    }

    func applyLevelResult(
        activity: ActivityIdentifier,
        difficulty: GameDifficulty,
        level index: Int,
        earnedStars: Int,
        outcome _: ActivityOutcome
    ) {
        let persistenceLevelIndex = activity == .bossGauntlet ? 0 : index
        let previousStars = stars(for: activity, difficulty: difficulty, level: persistenceLevelIndex)
        let clamped = min(max(earnedStars, 0), 3)
        let delta = max(0, clamped - previousStars)
        if delta > 0 {
            totalStarsEarned += delta
            defaults.set(totalStarsEarned, forKey: Keys.totalStarsEarned)
            accumulateGoalStars(delta: delta)
        }

        if activity == .bossGauntlet {
            var activityMap = starsPerActivity[activity.rawValue] ?? [:]
            var row = activityMap[difficulty.rawValue] ?? [0]
            if row.isEmpty {
                row = [0]
            }
            row[0] = max(row[0], clamped)
            activityMap[difficulty.rawValue] = row
            starsPerActivity[activity.rawValue] = activityMap
            persistStars()
            if clamped >= 1 {
                bossGauntletDefeated = true
                defaults.set(true, forKey: Keys.bossGauntletDefeated)
            }
            return
        }

        var activityMap = starsPerActivity[activity.rawValue] ?? [:]
        var row = activityMap[difficulty.rawValue] ?? Array(repeating: 0, count: QuestoriaGame.levelCountPerActivity)
        while row.count < QuestoriaGame.levelCountPerActivity {
            row.append(0)
        }
        guard index >= 0, index < row.count else { return }
        row[index] = max(row[index], clamped)
        activityMap[difficulty.rawValue] = row
        starsPerActivity[activity.rawValue] = activityMap
        persistStars()

        if clamped >= 1, index < QuestoriaGame.maxLevelIndex {
            var unlockedForActivity = unlockedLevels[activity.rawValue] ?? [:]
            let current = unlockedForActivity[difficulty.rawValue] ?? 0
            let proposed = max(current, index + 1)
            unlockedForActivity[difficulty.rawValue] = min(proposed, QuestoriaGame.maxLevelIndex)
            unlockedLevels[activity.rawValue] = unlockedForActivity
            persistUnlocked()
        }
    }

    func resetAllProgress() {
        let keys = defaults.dictionaryRepresentation().keys.filter { key in
            key.hasPrefix(Keys.prefix)
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
        reloadFromDefaults()
        NotificationCenter.default.post(name: .progressReset, object: nil)
    }

    func unlockedLevelsScoreSum() -> Int {
        var sum = 0
        for activity in ActivityIdentifier.standardActivities {
            for difficulty in GameDifficulty.allCases {
                sum += unlockedLevels[activity.rawValue]?[difficulty.rawValue] ?? 0
            }
        }
        return sum
    }

    func hasEarnedPerfectThreeStarsOnAnyLevel() -> Bool {
        for activity in ActivityIdentifier.standardActivities {
            guard let difficultyMap = starsPerActivity[activity.rawValue] else { continue }
            for (_, row) in difficultyMap {
                let trimmed = Array(row.prefix(QuestoriaGame.levelCountPerActivity))
                guard trimmed.count == QuestoriaGame.levelCountPerActivity else { continue }
                if trimmed.allSatisfy({ $0 >= 3 }) {
                    return true
                }
            }
        }
        if let bossStars = starsPerActivity[ActivityIdentifier.bossGauntlet.rawValue]?[GameDifficulty.hard.rawValue]?.first,
           bossStars >= 3 {
            return true
        }
        return false
    }

    private func persistStars() {
        guard let data = try? JSONEncoder().encode(starsPerActivity),
              let text = String(data: data, encoding: .utf8) else {
            return
        }
        defaults.set(text, forKey: Keys.starsPayload)
    }

    private func persistUnlocked() {
        guard let data = try? JSONEncoder().encode(unlockedLevels),
              let text = String(data: data, encoding: .utf8) else {
            return
        }
        defaults.set(text, forKey: Keys.unlockedPayload)
    }

    private static func decodeStars(_ text: String?) -> [String: [String: [Int]]] {
        guard let text,
              let data = text.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [String: [Int]]].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func decodeUnlocked(_ text: String?) -> [String: [String: Int]] {
        guard let text,
              let data = text.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
