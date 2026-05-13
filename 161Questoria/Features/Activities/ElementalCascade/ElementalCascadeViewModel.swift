import Combine
import CoreGraphics
import SwiftUI

enum CascadeElement: String, CaseIterable, Hashable, Identifiable {
    case fire
    case water
    case earth
    case air

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

struct CascadeWeakFocus: Identifiable, Equatable {
    let id = UUID()
    var point: CGPoint
    let element: CascadeElement
}

struct PolylineSampler {
    private let points: [CGPoint]
    private let cumulative: [CGFloat]
    let totalLength: CGFloat

    init(points: [CGPoint]) {
        self.points = points
        var running: [CGFloat] = [0]
        var sum: CGFloat = 0
        if let first = points.first {
            var previous = first
            for index in 1 ..< points.count {
                let current = points[index]
                let delta = hypot(current.x - previous.x, current.y - previous.y)
                sum += delta
                running.append(sum)
                previous = current
            }
        }
        cumulative = running
        totalLength = Swift.max(sum, 0.000_001)
    }

    func point(at progress: CGFloat) -> CGPoint {
        let clamped = max(0, min(1, progress)) * totalLength
        guard points.count > 1 else { return points.first ?? .zero }
        if clamped <= 0 {
            return points[0]
        }
        for index in 1 ..< cumulative.count {
            let previousLength = cumulative[index - 1]
            let currentLength = cumulative[index]
            if clamped <= currentLength {
                let segmentLength = max(currentLength - previousLength, 0.000_001)
                let local = (clamped - previousLength) / segmentLength
                let a = points[index - 1]
                let b = points[index]
                return CGPoint(
                    x: a.x + (b.x - a.x) * local,
                    y: a.y + (b.y - a.y) * local
                )
            }
        }
        return points.last ?? .zero
    }
}

@MainActor
final class ElementalCascadeViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case resolved(ActivityOutcome, Int)
    }

    @Published var phase: Phase = .playing
    @Published var score: Int = 0
    @Published var remainingOrbs: Int
    @Published var selectedElement: CascadeElement?
    @Published var dragProgress: CGFloat = 0
    @Published var shakeToken = UUID()
    @Published var banner = "Pick an orb that matches the sigil letter, then drag up along the path."

    private(set) var weakSpots: [CascadeWeakFocus] = []
    private(set) var channelPoints: [CGPoint] = []

    @Published private(set) var hintsRemaining: Int
    @Published var hintHighlightedSpotID: UUID?

    private let difficulty: GameDifficulty
    private let levelIndex: Int

    init(difficulty: GameDifficulty, levelIndex: Int) {
        self.difficulty = difficulty
        self.levelIndex = levelIndex
        hintsRemaining = QuestoriaGame.hintsPerRegularSession
        switch difficulty {
        case .easy:
            remainingOrbs = 14
        case .normal:
            remainingOrbs = 12
        case .hard:
            remainingOrbs = 9
        }

        remainingOrbs -= levelIndex / 2
        remainingOrbs = max(remainingOrbs, 6)

        configureChannel()
        configureWeakSpots()
    }

    private func configureWeakSpots() {
        let count: Int
        switch difficulty {
        case .easy:
            count = 2
        case .normal:
            count = 3
        case .hard:
            count = 4
        }

        let sampler = PolylineSampler(points: channelPoints)
        let palette = CascadeElement.allCases.shuffled()
        weakSpots = []
        guard count > 0 else { return }

        let startT: CGFloat = 0.5
        let endT: CGFloat = 0.98
        let denom = CGFloat(max(count - 1, 1))
        for index in 0 ..< count {
            let t = startT + (endT - startT) * CGFloat(index) / denom
            let point = sampler.point(at: t)
            let element = palette[index % palette.count]
            weakSpots.append(CascadeWeakFocus(point: point, element: element))
        }
    }

    private func configureChannel() {
        channelPoints = [
            CGPoint(x: 200, y: 560),
            CGPoint(x: 130, y: 470),
            CGPoint(x: 260, y: 410),
            CGPoint(x: 140, y: 340),
            CGPoint(x: 230, y: 290),
            CGPoint(x: 200, y: 240)
        ]
    }

    var sampler: PolylineSampler {
        PolylineSampler(points: channelPoints)
    }

    func registerOrbSelection(_ element: CascadeElement) {
        guard phase == .playing else { return }
        FeedbackEffects.eventTap()
        selectedElement = element
        dragProgress = 0
        hintHighlightedSpotID = nil
        banner = "Drag upward along the glowing channel."
    }

    func requestHint() {
        guard phase == .playing else { return }
        guard hintsRemaining > 0 else {
            banner = "No hints remain this attempt."
            return
        }
        hintsRemaining -= 1
        guard let target = weakSpots.first else {
            banner = "Nothing left to illuminate."
            return
        }
        hintHighlightedSpotID = target.id
        banner = "Pulse marks the sigil—match its letter, then trace the path."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            self?.hintHighlightedSpotID = nil
        }
    }

    func handleDragChanged(progress: CGFloat) {
        dragProgress = max(0, min(1, progress))
    }

    func releaseSpell() {
        guard phase == .playing else { return }
        guard let element = selectedElement else {
            FeedbackEffects.playFailSound()
            banner = "Select an orb before casting."
            return
        }

        guard remainingOrbs > 0 else {
            resolveDefeat()
            return
        }

        remainingOrbs -= 1

        let sampler = PolylineSampler(points: channelPoints)
        let dropLogical = sampler.point(at: dragProgress)

        var bestIndex: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for (index, spot) in weakSpots.enumerated() {
            guard spot.element == element else { continue }
            let distance = hypot(dropLogical.x - spot.point.x, dropLogical.y - spot.point.y)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        let hitRadius: CGFloat = 80

        if let matchedIndex = bestIndex, bestDistance <= hitRadius {
            weakSpots.remove(at: matchedIndex)
            score += 1700
            FeedbackEffects.playSuccessSound()
            banner = "The weakness flares—another strike lands!"
            if weakSpots.isEmpty {
                resolveVictory()
            }
        } else {
            FeedbackEffects.playFailSound()
            shakeToken = UUID()
            banner = bestIndex == nil
                ? "Wrong element — choose an orb that matches the sigil letter."
                : "Finish the drag nearer to the glowing sigil along the channel."
        }

        selectedElement = nil
        dragProgress = 0

        if remainingOrbs <= 0, weakSpots.isEmpty == false {
            resolveDefeat()
        }
    }

    private func resolveVictory() {
        let stars = Self.starRating(score: score)
        phase = .resolved(.victory, stars)
    }

    private func resolveDefeat() {
        phase = .resolved(.defeat, 0)
    }

    static func starRating(score: Int) -> Int {
        if score >= 8000 {
            return 3
        }
        if score >= 5000 {
            return 2
        }
        if score >= 3000 {
            return 1
        }
        return 1
    }
}
