import SwiftUI

struct ArcaneRhythmContainerView: View {
    let difficulty: GameDifficulty
    let level: Int
    let isPractice: Bool
    @State private var activeLevel: Int
    @State private var sessionKey = UUID()

    init(difficulty: GameDifficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
        _activeLevel = State(initialValue: level)
    }

    var body: some View {
        ArcaneRhythmSessionView(difficulty: difficulty, level: activeLevel, isPractice: isPractice) { command in
            switch command {
            case .retry:
                sessionKey = UUID()
            case .next:
                if activeLevel < QuestoriaGame.maxLevelIndex {
                    activeLevel += 1
                    sessionKey = UUID()
                }
            case .exitToLevels:
                break
            }
        }
        .id("\(activeLevel)-\(sessionKey)")
    }
}

struct ArcaneRhythmSessionView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    let difficulty: GameDifficulty
    let level: Int
    let isPractice: Bool
    let onFlowCommand: (LevelFlowCommand) -> Void

    @StateObject private var viewModel: ArcaneRhythmViewModel
    @State private var sessionStartedAt = Date()
    @State private var baselineAchievements = Set<AchievementDefinition>()
    @State private var resultPayload: ActivitySessionResultPayload?
    @State private var didFinalizeSession = false

    @State private var chargingStart: Date?
    @State private var chargingRune: Int?
    @State private var explosionActive = false

    init(difficulty: GameDifficulty, level: Int, isPractice: Bool = false, onFlowCommand: @escaping (LevelFlowCommand) -> Void) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
        self.onFlowCommand = onFlowCommand
        _viewModel = StateObject(wrappedValue: ArcaneRhythmViewModel(difficulty: difficulty, levelIndex: level))
    }

    var body: some View {
        ZStack {
            LayeredBackgroundView()

            GeometryReader { geo in
                let scaler = GeometryScaler(size: geo.size)

                ZStack {
                    baseLine(scaler: scaler)

                    creatureSigil(scaler: scaler)

                    spellArcOverlay(scaler: scaler)

                    runeRow(scaler: scaler)

                    statusPanel
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.12)
                }

                if explosionActive && reducedEffects == false {
                    ExplosionBurstView()
                        .position(scaler.point(x: 200, y: 560))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Arcane Rhythm")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Hint") {
                    FeedbackEffects.buttonTap()
                    viewModel.requestHint()
                }
                .disabled(viewModel.phase != .playing || viewModel.hintsRemaining <= 0)
                .foregroundStyle(Color.appAccent)
                .font(.subheadline.weight(.semibold))
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            sessionStartedAt = Date()
            baselineAchievements = ActivityPersistenceHelper.baselineAchievements(for: progress)
            progress.recordPlaySessionStart()
            viewModel.start()
            didFinalizeSession = false
            explosionActive = false
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.phase) { newPhase in
            guard didFinalizeSession == false else { return }
            guard case let .resolved(outcome, stars, accuracy) = newPhase else { return }
            didFinalizeSession = true

            if outcome == .defeat {
                explosionActive = true
                FeedbackEffects.failureNotify()
            }

            presentResult(outcome: outcome, stars: stars, accuracy: accuracy)
        }
        .sheet(item: $resultPayload, onDismiss: {
            resultPayload = nil
        }, content: { payload in
            LevelResultSheetView(
                payload: payload,
                onNext: {
                    resultPayload = nil
                    onFlowCommand(.next)
                },
                onRetry: {
                    resultPayload = nil
                    onFlowCommand(.retry)
                },
                onLevels: {
                    resultPayload = nil
                    dismiss()
                }
            )
        })
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.banner)
                .foregroundStyle(Color.appTextSecondary)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 280)

            healthBar(title: "Warden", value: viewModel.creatureHP, maxHP: viewModel.creatureMaxHP)

            Text(String(format: "Rhythm drift • %.0f pts along descent", viewModel.enemyY))
                .foregroundStyle(Color.appAccent)
                .font(.caption2.weight(.semibold))

            HStack {
                Label("Hints", systemImage: "lightbulb.fill")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(viewModel.hintsRemaining)")
                    .foregroundStyle(Color.appAccent)
                    .font(.caption.monospacedDigit())
            }
        }
        .padding()
        .background(Color.appSurface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func healthBar(title: String, value: Double, maxHP: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(Swift.max(value, 0))) HP")
                    .foregroundStyle(Color.appTextSecondary)
                    .font(.caption2)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.appSurface.opacity(0.55))
                    Capsule()
                        .fill(Color.appAccent.opacity(0.92))
                        .frame(width: geo.size.width * CGFloat(min(Swift.max(value / Swift.max(maxHP, 1), 0), 1)))
                }
            }
            .frame(height: 12)
        }
    }

    private func baseLine(scaler: GeometryScaler) -> some View {
        Rectangle()
            .fill(Color.appPrimary.opacity(0.35))
            .frame(width: scaler.size.width * 0.92, height: 4)
            .position(scaler.point(x: 200, y: 605))
    }

    private func creatureSigil(scaler: GeometryScaler) -> some View {
        RhythmCreatureCanvas()
            .frame(width: scaler.size.width * 0.42, height: scaler.size.height * 0.22)
            .position(scaler.point(x: 150, y: viewModel.enemyY))
    }

    @ViewBuilder
    private func spellArcOverlay(scaler: GeometryScaler) -> some View {
        if chargingStart != nil, let runeIndex = chargingRune {
            let xs: [CGFloat] = [50, 150, 250]
            let start = scaler.point(x: xs[runeIndex], y: 120)
            let end = scaler.point(x: 150, y: max(viewModel.enemyY - 20, 70))

            Path { path in
                path.move(to: start)
                path.addQuadCurve(to: end, control: CGPoint(x: (start.x + end.x) / 2, y: start.y - 80))
            }
            .stroke(Color.appAccent.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 10]))
        }
    }

    private func runeRow(scaler: GeometryScaler) -> some View {
        let xs: [CGFloat] = [50, 150, 250]
        return ZStack {
            ForEach(xs.indices, id: \.self) { idx in
                runeCell(index: idx, center: scaler.point(x: xs[idx], y: 120), scaler: scaler)
            }
        }
    }

    private func runeCell(index: Int, center: CGPoint, scaler _: GeometryScaler) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let elapsed: TimeInterval = {
                if chargingRune == index, let start = chargingStart {
                    return timeline.date.timeIntervalSince(start)
                }
                return 0
            }()

            let shrink = CGFloat(min(Swift.max(elapsed, 0), 0.85)) * 28

            ZStack {
                Circle()
                    .stroke(Color.appAccent.opacity(0.45), lineWidth: 3)
                    .frame(width: 92, height: 92)
                Circle()
                    .stroke(Color.green.opacity(elapsed > 0 ? 0.85 : 0.15), lineWidth: 2)
                    .frame(width: Swift.max(46, 74 - shrink), height: Swift.max(46, 74 - shrink))

                RuneGlyphCanvas(index: index)
                    .frame(width: 48, height: 48)
            }
            .position(center)
            .gesture(runeGesture(for: index))
        }
    }

    private func runeGesture(for index: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if chargingStart == nil {
                    chargingStart = Date()
                    chargingRune = index
                    FeedbackEffects.eventTap()
                }
            }
            .onEnded { _ in
                guard chargingRune == index, let start = chargingStart else { return }
                let duration = Date().timeIntervalSince(start)
                chargingStart = nil
                chargingRune = nil
                viewModel.attemptCast(chargeDuration: duration)
            }
    }
}

private struct RhythmCreatureCanvas: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outline = Path(ellipseIn: CGRect(x: center.x - 55, y: center.y - 40, width: 110, height: 86))
            context.fill(outline, with: .color(Color.appSurface.opacity(0.95)))
            context.stroke(outline, with: .color(Color.appPrimary.opacity(0.85)), lineWidth: 3)

            let hornLeft = Path(ellipseIn: CGRect(x: center.x - 68, y: center.y - 46, width: 26, height: 44))
            let hornRight = Path(ellipseIn: CGRect(x: center.x + 42, y: center.y - 46, width: 26, height: 44))
            context.fill(hornLeft, with: .color(Color.appAccent.opacity(0.85)))
            context.fill(hornRight, with: .color(Color.appAccent.opacity(0.85)))
        }
    }
}

private struct RuneGlyphCanvas: View {
    let index: Int

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            var diamond = Path()
            diamond.move(to: CGPoint(x: center.x, y: center.y - 18))
            diamond.addLine(to: CGPoint(x: center.x + 16, y: center.y))
            diamond.addLine(to: CGPoint(x: center.x, y: center.y + 18))
            diamond.addLine(to: CGPoint(x: center.x - 16, y: center.y))
            diamond.closeSubpath()
            context.stroke(diamond, with: .color(Color.appPrimary.opacity(0.95)), lineWidth: 3)

            let slash = Path { path in
                path.move(to: CGPoint(x: center.x - 10, y: center.y + 8))
                path.addLine(to: CGPoint(x: center.x + 10, y: center.y - 8))
            }
            context.stroke(slash, with: .color(Color.appAccent.opacity(0.85)), lineWidth: index == 1 ? 4 : 2)
        }
    }
}

private struct ExplosionBurstView: View {
    @State private var expand = false

    var body: some View {
        ZStack {
            ForEach(0 ..< 3, id: \.self) { ring in
                Circle()
                    .stroke(Color.appPrimary.opacity(0.85 - Double(ring) * 0.2), lineWidth: 4)
                    .scaleEffect(expand ? CGFloat(2 + ring) : 0.2)
                    .opacity(expand ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                expand = true
            }
        }
    }
}

private extension ArcaneRhythmSessionView {
    func presentResult(outcome: ActivityOutcome, stars: Int, accuracy: Double) {
        let secondsPlayed = Int(Date().timeIntervalSince(sessionStartedAt))
        let earnedStars = outcome == .victory ? stars : 0
        let unlocked = ActivityPersistenceHelper.finalizeSession(
            progress: progress,
            activity: .arcaneRhythm,
            difficulty: difficulty,
            level: level,
            outcome: outcome,
            earnedStars: earnedStars,
            playedSeconds: Swift.max(secondsPlayed, 1),
            baselineAchievements: baselineAchievements,
            isPractice: isPractice
        )

        let showsNext = outcome == .victory && level < QuestoriaGame.maxLevelIndex
        let headlineValue = String(format: "%.0f%% accuracy", accuracy * 100)

        resultPayload = ActivitySessionResultPayload(
            outcome: outcome,
            earnedStars: earnedStars,
            headlineTitle: "Timing Precision",
            headlineValue: headlineValue,
            newlyUnlockedAchievements: Array(unlocked),
            showsNextLevel: showsNext,
            isPractice: isPractice
        )

        baselineAchievements.formUnion(unlocked)
    }
}
