import SwiftUI

enum AchievementDefinition: String, CaseIterable, Identifiable {
    case firstStar
    case spellCaster
    case masterWizard
    case perfectCast
    case levelMaster
    case dailyWizard
    case journeyStarter
    case bossSlayer
    case starCollector

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstStar: return "First Star"
        case .spellCaster: return "Spell Caster"
        case .masterWizard: return "Master Wizard"
        case .perfectCast: return "Perfect Cast"
        case .levelMaster: return "Level Master"
        case .dailyWizard: return "Daily Wizard"
        case .journeyStarter: return "Journey Starter"
        case .bossSlayer: return "Gauntlet Slayer"
        case .starCollector: return "Star Collector"
        }
    }

    var detail: String {
        switch self {
        case .firstStar: return "Earned your first star."
        case .spellCaster: return "Played ten activities."
        case .masterWizard: return "Reached one hour of playtime."
        case .perfectCast: return "Earned all stars in an activity row."
        case .levelMaster: return "Unlocked twenty-eight cumulative stage tiers."
        case .dailyWizard: return "Played daily for three days."
        case .journeyStarter: return "Completed onboarding steps."
        case .bossSlayer: return "Cleared the Boss Gauntlet."
        case .starCollector: return "Collected fifty stars."
        }
    }

    func isUnlocked(progress: ProgressStore) -> Bool {
        switch self {
        case .firstStar:
            return progress.totalStarsEarned >= 1
        case .spellCaster:
            return progress.totalActivitiesPlayed >= 10
        case .masterWizard:
            return progress.totalPlayTimeSeconds >= 3600
        case .perfectCast:
            return progress.hasEarnedPerfectThreeStarsOnAnyLevel()
        case .levelMaster:
            return progress.unlockedLevelsScoreSum() >= 28
        case .dailyWizard:
            return progress.streakCount >= 3
        case .journeyStarter:
            return progress.hasSeenOnboarding
        case .bossSlayer:
            return progress.bossGauntletDefeated
        case .starCollector:
            return progress.totalStarsEarned >= 50
        }
    }
}
