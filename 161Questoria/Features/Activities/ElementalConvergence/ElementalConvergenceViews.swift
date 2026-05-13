import SwiftUI

struct ElementalConvergenceContainerView: View {
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
        ElementalConvergenceSessionView(
            difficulty: difficulty,
            level: activeLevel,
            activityIdentifier: .elementalConvergence,
            isPractice: isPractice,
            isBossFight: false,
            onFlowCommand: { command in
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
        )
        .id("\(activeLevel)-\(sessionKey)")
    }
}

struct ElementalConvergenceSessionView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    let difficulty: GameDifficulty
    let level: Int
    let activityIdentifier: ActivityIdentifier
    let isPractice: Bool
    let isBossFight: Bool
    let onFlowCommand: (LevelFlowCommand) -> Void

    @StateObject private var viewModel: ElementalConvergenceViewModel
    @State private var sessionStartedAt = Date()
    @State private var baselineAchievements = Set<AchievementDefinition>()
    @State private var resultPayload: ActivitySessionResultPayload?
    @State private var didFinalizeSession = false

    @State private var boltTrim: CGFloat = 0
    @State private var creaturePulseScale: CGFloat = 1
    @State private var strikeCaptionOpacity: Double = 0
    init(
        difficulty: GameDifficulty,
        level: Int,
        activityIdentifier: ActivityIdentifier = .elementalConvergence,
        isPractice: Bool = false,
        isBossFight: Bool = false,
        onFlowCommand: @escaping (LevelFlowCommand) -> Void
    ) {
        self.difficulty = difficulty
        self.level = level
        self.activityIdentifier = activityIdentifier
        self.isPractice = isPractice
        self.isBossFight = isBossFight
        self.onFlowCommand = onFlowCommand
        _viewModel = StateObject(
            wrappedValue: ElementalConvergenceViewModel(
                difficulty: difficulty,
                levelIndex: level,
                bossFight: isBossFight
            )
        )
    }

    var body: some View {
        ZStack {
            LayeredBackgroundView()
            GeometryReader { geo in
                let scaler = GeometryScaler(size: geo.size)

                ZStack {
                    strikeVisualization(scaler: scaler)

                    creatureView
                        .scaleEffect(creaturePulseScale)
                        .position(scaler.point(x: viewModel.creaturePoint.x, y: viewModel.creaturePoint.y))

                    if viewModel.shieldActive {
                        shieldRipple
                            .position(scaler.point(x: viewModel.creaturePoint.x, y: viewModel.creaturePoint.y))
                    }

                    VStack {
                        Spacer()
                        statusPanel
                        orbRow(scaler: scaler)
                            .padding(.bottom, 12)
                    }

                    comboBadge
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(activityIdentifier == .bossGauntlet ? "Boss Gauntlet" : "Elemental Convergence")
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
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.strikeSequence) { newValue in
            guard newValue > 0 else { return }
            boltTrim = 0
            withAnimation(.easeOut(duration: 0.2)) {
                boltTrim = 1
            }
            if viewModel.lastStrikeWasEffectiveHit {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                    creaturePulseScale = 1.13
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.68)) {
                        creaturePulseScale = 1
                    }
                }
            } else {
                creaturePulseScale = 1
            }
            strikeCaptionOpacity = 0
            withAnimation(.easeOut(duration: 0.08)) {
                strikeCaptionOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
                withAnimation(.easeOut(duration: 0.28)) {
                    strikeCaptionOpacity = 0
                }
            }
        }
        .onChange(of: viewModel.phase) { newPhase in
            guard didFinalizeSession == false else { return }
            guard case let .resolved(outcome, stars, accuracy) = newPhase else { return }
            didFinalizeSession = true
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
            Text(viewModel.bannerText)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            healthBar(title: "Creature", value: viewModel.creatureHP, maxHP: viewModel.creatureMaxHP, tint: Color.appAccent)
            healthBar(title: "Traveler", value: viewModel.playerHP, maxHP: viewModel.playerMaxHP, tint: Color.appPrimary)

            if viewModel.comboPrimed {
                Text("Combo ready — double tap to converge.")
                    .font(.caption)
                    .foregroundStyle(Color.appAccent)
            }

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
        .padding(.horizontal, 16)
    }

    private func healthBar(title: String, value: Double, maxHP: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(Swift.max(value, 0))) HP")
                    .foregroundStyle(Color.appTextSecondary)
                    .font(.caption)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSurface.opacity(0.55))
                    Capsule()
                        .fill(tint.opacity(0.92))
                        .frame(width: geo.size.width * CGFloat(min(max(value / Swift.max(maxHP, 1), 0), 1)))
                }
            }
            .frame(height: 12)
        }
    }

    private var creatureView: some View {
        ZStack {
            RadialGradient(colors: [Color.appAccent.opacity(0.35), Color.clear], center: .center, startRadius: 10, endRadius: 70)
                .frame(width: 140, height: 140)
            CreatureGlyphView()
                .frame(width: 120, height: 120)
        }
    }

    private func orbRow(scaler _: GeometryScaler) -> some View {
        HStack(spacing: 26) {
            ForEach(ElementOrbKind.allCases, id: \.self) { kind in
                orb(kind: kind)
            }
        }
        .padding(.horizontal, 18)
    }

    private func orb(kind: ElementOrbKind) -> some View {
        let gradientColors: [Color] = {
            switch kind {
            case .fire:
                return [Color.red.opacity(0.85), Color.orange.opacity(0.75)]
            case .water:
                return [Color.blue.opacity(0.85), Color.cyan.opacity(0.65)]
            case .earth:
                return [Color.green.opacity(0.85), Color.brown.opacity(0.65)]
            }
        }()

        return ZStack {
            Circle()
                .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 74, height: 74)
                .overlay(
                    Circle()
                        .stroke(Color.appPrimary.opacity(0.85), lineWidth: 2)
                )
                .shadow(
                    color: reducedEffects ? .clear : Color.appAccent.opacity(0.35),
                    radius: reducedEffects ? 0 : 10,
                    x: 0,
                    y: reducedEffects ? 0 : 6
                )

            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                .frame(width: 58, height: 58)
        }
        .contentShape(Circle())
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                viewModel.castSpell(with: kind, usesCombo: viewModel.comboPrimed)
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                viewModel.registerOrbTap(kind: kind)
            }
        )
    }

    private func strikeVisualization(scaler: GeometryScaler) -> some View {
        let start = scaler.point(x: viewModel.strikeBoltStart.x, y: viewModel.strikeBoltStart.y)
        let end = scaler.point(x: viewModel.strikeBoltEnd.x, y: viewModel.strikeBoltEnd.y)

        let headX = start.x + (end.x - start.x) * boltTrim
        let headY = start.y + (end.y - start.y) * boltTrim

        return ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .trim(from: 0, to: boltTrim)
            .stroke(
                strikeEnergyGradient(for: viewModel.lastStrikeElement, combo: viewModel.lastStrikeWasCombo),
                style: StrokeStyle(
                    lineWidth: viewModel.lastStrikeWasCombo ? 8 : 5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .shadow(
                color: reducedEffects ? .clear : strikeTint(for: viewModel.lastStrikeElement).opacity(0.65),
                radius: reducedEffects ? 0 : 14,
                x: 0,
                y: 0
            )

            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: viewModel.lastStrikeWasCombo ? 20 : 14, height: viewModel.lastStrikeWasCombo ? 20 : 14)
                .overlay(Circle().stroke(strikeTint(for: viewModel.lastStrikeElement), lineWidth: 3))
                .position(x: headX, y: headY)
                .opacity(Double(Swift.min(boltTrim * 1.25, 1)))

            Circle()
                .stroke(Color.appAccent.opacity(0.88), lineWidth: 2)
                .frame(width: 52, height: 52)
                .scaleEffect(strikeCaptionOpacity > 0 ? 1.45 : 0.35)
                .opacity(viewModel.lastStrikeWasEffectiveHit ? strikeCaptionOpacity * 0.85 : strikeCaptionOpacity * 0.4)
                .position(end)

            Text(strikeCaptionText)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(strikeCaptionForeground)
                .shadow(
                    color: reducedEffects ? .clear : Color.black.opacity(0.38),
                    radius: reducedEffects ? 0 : 4,
                    x: 0,
                    y: reducedEffects ? 0 : 2
                )
                .position(x: end.x, y: end.y - 52)
                .opacity(strikeCaptionOpacity)
        }
        .allowsHitTesting(false)
    }

    private var strikeCaptionText: String {
        viewModel.lastStrikeWasEffectiveHit ? "-\(Int(viewModel.lastStrikeDamage))" : "Blocked"
    }

    private var strikeCaptionForeground: Color {
        viewModel.lastStrikeWasEffectiveHit ? Color.appAccent : Color.appTextSecondary
    }

    private func strikeTint(for kind: ElementOrbKind) -> Color {
        switch kind {
        case .fire:
            return Color.red.opacity(0.92)
        case .water:
            return Color.blue.opacity(0.92)
        case .earth:
            return Color.green.opacity(0.92)
        }
    }

    private func strikeEnergyGradient(for kind: ElementOrbKind, combo: Bool) -> LinearGradient {
        let head = strikeTint(for: kind)
        let tail = combo ? Color.appPrimary : Color.appAccent
        return LinearGradient(colors: [head, tail.opacity(0.95)], startPoint: .leading, endPoint: .trailing)
    }

    private var comboBadge: some View {
        VStack {
            HStack {
                Spacer()
                if viewModel.comboPrimed {
                    Text("COMBO")
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appPrimary.opacity(0.85))
                        .foregroundStyle(Color.appBackground)
                        .clipShape(Capsule())
                        .padding(.trailing, 16)
                        .padding(.top, 24)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            Spacer()
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.comboPrimed)
    }

    private var shieldRipple: some View {
        Circle()
            .stroke(Color.appAccent.opacity(0.45), lineWidth: 10)
            .scaleEffect(1.45)
            .blur(radius: 2)
            .allowsHitTesting(false)
    }

    private func presentResult(outcome: ActivityOutcome, stars: Int, accuracy: Double) {
        let secondsPlayed = Int(Date().timeIntervalSince(sessionStartedAt))
        let earnedStars = outcome == .victory ? stars : 0
        let persistenceLevel = activityIdentifier == .bossGauntlet ? 0 : level
        let unlocked = ActivityPersistenceHelper.finalizeSession(
            progress: progress,
            activity: activityIdentifier,
            difficulty: difficulty,
            level: persistenceLevel,
            outcome: outcome,
            earnedStars: earnedStars,
            playedSeconds: Swift.max(secondsPlayed, 1),
            baselineAchievements: baselineAchievements,
            isPractice: isPractice
        )

        let canAdvanceLevels = activityIdentifier != .bossGauntlet
        let showsNext = outcome == .victory && canAdvanceLevels && level < QuestoriaGame.maxLevelIndex
        let headlineValue = String(format: "%.0f%% accuracy", accuracy * 100)

        resultPayload = ActivitySessionResultPayload(
            outcome: outcome,
            earnedStars: earnedStars,
            headlineTitle: "Cast Precision",
            headlineValue: headlineValue,
            newlyUnlockedAchievements: Array(unlocked),
            showsNextLevel: showsNext,
            isPractice: isPractice
        )

        baselineAchievements.formUnion(unlocked)
    }
}

private struct CreatureGlyphView: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let body = Path(ellipseIn: CGRect(x: center.x - 42, y: center.y - 40, width: 84, height: 86))
            context.fill(body, with: .color(Color.appSurface.opacity(0.95)))
            context.stroke(body, with: .color(Color.appAccent.opacity(0.85)), lineWidth: 3)

            let eyeLeft = Path(ellipseIn: CGRect(x: center.x - 28, y: center.y - 16, width: 14, height: 18))
            let eyeRight = Path(ellipseIn: CGRect(x: center.x + 14, y: center.y - 16, width: 14, height: 18))
            context.fill(eyeLeft, with: .color(Color.appPrimary.opacity(0.95)))
            context.fill(eyeRight, with: .color(Color.appPrimary.opacity(0.95)))

            var horns = Path()
            horns.move(to: CGPoint(x: center.x - 34, y: center.y - 46))
            horns.addLine(to: CGPoint(x: center.x - 48, y: center.y - 78))
            horns.addLine(to: CGPoint(x: center.x - 18, y: center.y - 52))
            horns.closeSubpath()
            context.fill(horns, with: .color(Color.appAccent.opacity(0.85)))

            var horns2 = Path()
            horns2.move(to: CGPoint(x: center.x + 34, y: center.y - 46))
            horns2.addLine(to: CGPoint(x: center.x + 48, y: center.y - 78))
            horns2.addLine(to: CGPoint(x: center.x + 18, y: center.y - 52))
            horns2.closeSubpath()
            context.fill(horns2, with: .color(Color.appAccent.opacity(0.85)))
        }
    }
}
