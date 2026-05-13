import SwiftUI

struct ActivitySessionResultPayload: Identifiable {
    let id = UUID()
    let outcome: ActivityOutcome
    let earnedStars: Int
    let headlineTitle: String
    let headlineValue: String
    let newlyUnlockedAchievements: [AchievementDefinition]
    let showsNextLevel: Bool
    let isPractice: Bool
}

enum ActivityPersistenceHelper {
    static func baselineAchievements(for progress: ProgressStore) -> Set<AchievementDefinition> {
        Set(AchievementDefinition.allCases.filter { $0.isUnlocked(progress: progress) })
    }

    static func finalizeSession(
        progress: ProgressStore,
        activity: ActivityIdentifier,
        difficulty: GameDifficulty,
        level: Int,
        outcome: ActivityOutcome,
        earnedStars: Int,
        playedSeconds: Int,
        baselineAchievements: Set<AchievementDefinition>,
        isPractice: Bool
    ) -> Set<AchievementDefinition> {
        progress.recordAttempt(
            activity: activity,
            difficulty: difficulty,
            level: level,
            outcome: outcome,
            stars: earnedStars,
            practice: isPractice
        )

        if isPractice {
            let updated = Set(AchievementDefinition.allCases.filter { $0.isUnlocked(progress: progress) })
            return updated.subtracting(baselineAchievements)
        }

        progress.incrementActivitiesPlayed()
        progress.addPlayTime(seconds: playedSeconds)
        if outcome == .victory {
            progress.applyLevelResult(
                activity: activity,
                difficulty: difficulty,
                level: level,
                earnedStars: earnedStars,
                outcome: outcome
            )
        }

        let updated = Set(AchievementDefinition.allCases.filter { $0.isUnlocked(progress: progress) })
        return updated.subtracting(baselineAchievements)
    }
}
