import Combine
import SwiftUI

@MainActor
final class ArcaneRhythmViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case resolved(ActivityOutcome, Int, Double)
    }

    @Published var creatureHP: Double
    let creatureMaxHP: Double
    @Published var enemyY: CGFloat = 120
    @Published var banner = "Hold a rune, release when the inner sigil glows steady."
    @Published var phase: Phase = .playing

    private var timers = Set<AnyCancellable>()
    private var hits = 0
    private var attempts = 0
    private var lastRelease = Date.distantPast

    let difficulty: GameDifficulty
    let levelIndex: Int

    @Published private(set) var hintsRemaining: Int

    private let loseLine: CGFloat = 600

    init(difficulty: GameDifficulty, levelIndex: Int) {
        self.difficulty = difficulty
        self.levelIndex = levelIndex
        hintsRemaining = QuestoriaGame.hintsPerRegularSession
        let base = 118 + Double(levelIndex) * 18 + (difficulty == .hard ? 46 : difficulty == .normal ? 24 : 0)
        creatureHP = base
        creatureMaxHP = base
    }

    func start() {
        let speedPerSecond: CGFloat
        switch difficulty {
        case .easy:
            speedPerSecond = 56
        case .normal:
            speedPerSecond = 78
        case .hard:
            speedPerSecond = 102
        }

        Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.advanceEnemy(speedPerSecond: speedPerSecond)
            }
            .store(in: &timers)
    }

    func requestHint() {
        guard phase == .playing else { return }
        guard hintsRemaining > 0 else {
            banner = "No harmonic hints remain."
            return
        }
        hintsRemaining -= 1
        banner = "Hint: hold roughly 0.55–0.72s, release when the inner ring feels steady."
    }

    func stop() {
        timers.removeAll()
    }

    private func advanceEnemy(speedPerSecond: CGFloat) {
        guard phase == .playing else { return }
        enemyY += speedPerSecond / 60.0
        if enemyY >= loseLine {
            phase = .resolved(.defeat, 0, accuracy())
            stop()
        }
    }

    func attemptCast(chargeDuration: TimeInterval) {
        guard phase == .playing else { return }

        let now = Date()
        if now.timeIntervalSince(lastRelease) < 0.34 {
            attempts += 1
            FeedbackEffects.failureNotify()
            FeedbackEffects.playFailSound()
            banner = "The arc collapses from rushed chanting."
            return
        }
        lastRelease = now

        attempts += 1

        let damage: Double
        let qualityHit: Bool

        switch chargeDuration {
        case 0.55 ... 0.72:
            damage = 28 + Double(levelIndex)
            qualityHit = true
            FeedbackEffects.successNotify()
            FeedbackEffects.playSuccessSound()
            banner = "Perfect resonance splits the night."
        case 0.42 ..< 0.55, 0.72 ... 0.92:
            damage = 18 + Double(levelIndex) * 0.6
            qualityHit = true
            FeedbackEffects.eventTap()
            FeedbackEffects.playSuccessSound()
            banner = "Solid harmonic thrust."
        default:
            damage = 9
            qualityHit = false
            FeedbackEffects.playFailSound()
            banner = "Timing slips—the spell flickers unevenly."
        }

        if qualityHit {
            hits += 1
        }

        creatureHP = max(creatureHP - damage, 0)

        if creatureHP <= 0 {
            let accuracyValue = accuracy()
            let stars = Self.starRating(accuracy: accuracyValue)
            phase = .resolved(.victory, stars, accuracyValue)
            stop()
        }
    }

    private func accuracy() -> Double {
        Double(hits) / Double(max(attempts, 1))
    }

    static func starRating(accuracy: Double) -> Int {
        if accuracy >= 0.90 {
            return 3
        }
        if accuracy >= 0.75 {
            return 2
        }
        if accuracy >= 0.60 {
            return 1
        }
        return 1
    }
}
