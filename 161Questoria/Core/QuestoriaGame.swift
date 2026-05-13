import Foundation

enum QuestoriaGame {
    /// Number of level slots per activity and difficulty (indices `0 ..< levelCountPerActivity`).
    static let levelCountPerActivity = 10

    static var maxLevelIndex: Int {
        levelCountPerActivity - 1
    }

    /// Cumulative lifetime stars required to unlock Boss Gauntlet on Play.
    static let bossUnlockTotalStars = 48

    /// Weekly motivation target (new stars earned this ISO week; counted like lifetime deltas).
    static let weeklyStarGoal = 15

    /// Daily motivation target (stars gained today).
    static let dailyStarGoal = 5

    static let hintsPerRegularSession = 2

    static let attemptHistoryLimit = 45
}
