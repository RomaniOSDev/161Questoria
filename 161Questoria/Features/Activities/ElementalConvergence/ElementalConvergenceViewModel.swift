import Combine
import SwiftUI

enum ElementOrbKind: CaseIterable, Hashable {
    case fire
    case water
    case earth

    /// Logical layout coordinates (matches orb row in `ElementalConvergenceSessionView`).
    var convergenceCastOrigin: CGPoint {
        switch self {
        case .fire:
            return CGPoint(x: 50, y: 500)
        case .water:
            return CGPoint(x: 200, y: 500)
        case .earth:
            return CGPoint(x: 350, y: 500)
        }
    }
}

@MainActor
final class ElementalConvergenceViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case resolved(ActivityOutcome, Int, Double)
    }

    @Published var creaturePoint: CGPoint = CGPoint(x: 200, y: 300)
    @Published var playerHP: Double
    @Published var creatureHP: Double
    @Published var shieldActive = false
    @Published var comboPrimed = false
    @Published var bannerText = "Tap an orb, then double tap to cast."
    @Published var phase: Phase = .playing

    @Published private(set) var strikeSequence: Int = 0
    @Published private(set) var strikeBoltStart: CGPoint = .zero
    @Published private(set) var strikeBoltEnd: CGPoint = .zero
    @Published private(set) var lastStrikeDamage: Double = 0
    @Published private(set) var lastStrikeWasEffectiveHit: Bool = false
    @Published private(set) var lastStrikeWasCombo: Bool = false
    @Published private(set) var lastStrikeElement: ElementOrbKind = .fire

    let creatureMaxHP: Double
    let playerMaxHP: Double = 100

    private var timers = Set<AnyCancellable>()
    private var recentTaps: [(Date, ElementOrbKind)] = []

    private var hits = 0
    private var attempts = 0

    let difficulty: GameDifficulty
    let levelIndex: Int

    @Published private(set) var hintsRemaining: Int

    init(difficulty: GameDifficulty, levelIndex: Int, bossFight: Bool = false) {
        self.difficulty = difficulty
        self.levelIndex = levelIndex
        hintsRemaining = QuestoriaGame.hintsPerRegularSession
        playerHP = 100
        let modifier = Double(levelIndex) * 18
        var startingCreatureHP: Double
        switch difficulty {
        case .easy:
            startingCreatureHP = 110 + modifier
        case .normal:
            startingCreatureHP = 135 + modifier
        case .hard:
            startingCreatureHP = 165 + modifier
        }
        if bossFight {
            startingCreatureHP *= 1.42
        }
        creatureHP = startingCreatureHP
        creatureMaxHP = startingCreatureHP
    }

    func requestHint() {
        guard phase == .playing else { return }
        guard hintsRemaining > 0 else {
            bannerText = "No convergence hints remain."
            return
        }
        hintsRemaining -= 1
        if shieldActive {
            shieldActive = false
            bannerText = "Hint: veil shredded early—strike before another arises."
        } else {
            comboPrimed = true
            bannerText = "Hint: weave aligned—double tap any orb for a resonant burst."
        }
    }

    func start() {
        Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.shuffleCreature()
            }
            .store(in: &timers)

        Timer.publish(every: 9, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.raiseShield()
            }
            .store(in: &timers)

        Timer.publish(every: 7, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.enemyStrike()
            }
            .store(in: &timers)
    }

    func stop() {
        timers.removeAll()
    }

    private var comboWindow: TimeInterval {
        switch difficulty {
        case .easy:
            return 2
        case .normal:
            return 1
        case .hard:
            return 0.5
        }
    }

    private func shuffleCreature() {
        let options = [
            CGPoint(x: 200, y: 300),
            CGPoint(x: 100, y: 300),
            CGPoint(x: 300, y: 200)
        ]
        let next = options.randomElement() ?? options[0]
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            creaturePoint = next
        }
    }

    private func raiseShield() {
        shieldActive = true
        bannerText = "A protective veil rises—combine elements to pierce it."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            guard let self else { return }
            shieldActive = false
            bannerText = "The veil fades—strike swiftly."
        }
    }

    private func enemyStrike() {
        guard phase == .playing else { return }
        playerHP = Swift.max(playerHP - Double(7 + levelIndex), 0)
        if playerHP <= 0 {
            resolveDefeat()
        }
    }

    func registerOrbTap(kind: ElementOrbKind) {
        guard phase == .playing else { return }
        FeedbackEffects.eventTap()
        let now = Date()
        recentTaps.append((now, kind))
        recentTaps.removeAll { now.timeIntervalSince($0.0) > comboWindow }
        let distinct = Set(recentTaps.map { $1 })
        comboPrimed = distinct.count >= 2
    }

    func castSpell(with focus: ElementOrbKind, usesCombo: Bool) {
        guard phase == .playing else { return }
        attempts += 1
        FeedbackEffects.eventTap()

        let comboExecution = usesCombo && comboPrimed
        var damage = 0.0

        if comboExecution {
            damage = Double(28 + levelIndex * 3)
            bannerText = "Resonant convergence pierces the veil!"
            comboPrimed = false
            recentTaps.removeAll()
            shieldActive = false
        } else if shieldActive {
            damage = 0
            bannerText = "The shield swallowed your spell."
            playerHP = Swift.max(playerHP - 6, 0)
        } else {
            damage = Double(12 + levelIndex * 2)
            bannerText = "Focused bolt strikes true."
        }

        let targetSnapshot = creaturePoint
        strikeBoltStart = focus.convergenceCastOrigin
        strikeBoltEnd = targetSnapshot
        lastStrikeDamage = damage
        lastStrikeWasEffectiveHit = damage > 0
        lastStrikeWasCombo = comboExecution
        lastStrikeElement = focus
        strikeSequence += 1

        if damage > 0 {
            hits += 1
            creatureHP = Swift.max(creatureHP - damage, 0)
            FeedbackEffects.playSuccessSound()
        } else {
            FeedbackEffects.playFailSound()
        }

        if playerHP <= 0 {
            resolveDefeat()
            return
        }

        if creatureHP <= 0 {
            let accuracy = Double(hits) / Double(Swift.max(attempts, 1))
            if accuracy >= 0.7 {
                let stars = Self.starRating(accuracy: accuracy)
                phase = .resolved(.victory, stars, accuracy)
                stop()
            } else {
                bannerText = "The creature endures—you need sharper focus."
                creatureHP = 35
                FeedbackEffects.failureNotify()
            }
        }
    }

    private func resolveDefeat() {
        let accuracy = Double(hits) / Double(Swift.max(attempts, 1))
        phase = .resolved(.defeat, 0, accuracy)
        stop()
    }

    static func starRating(accuracy: Double) -> Int {
        if accuracy >= 0.95 {
            return 3
        }
        if accuracy >= 0.80 {
            return 2
        }
        if accuracy >= 0.60 {
            return 1
        }
        return 1
    }
}
