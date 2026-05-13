import SwiftUI

struct ElementalCascadeContainerView: View {
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
        ElementalCascadeSessionView(difficulty: difficulty, level: activeLevel, isPractice: isPractice) { command in
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

struct ElementalCascadeSessionView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    let difficulty: GameDifficulty
    let level: Int
    let isPractice: Bool
    let onFlowCommand: (LevelFlowCommand) -> Void

    @StateObject private var viewModel: ElementalCascadeViewModel
    @State private var sessionStartedAt = Date()
    @State private var baselineAchievements = Set<AchievementDefinition>()
    @State private var resultPayload: ActivitySessionResultPayload?
    @State private var didFinalizeSession = false
    @State private var dragAnchor: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var isDraggingCast = false

    init(difficulty: GameDifficulty, level: Int, isPractice: Bool = false, onFlowCommand: @escaping (LevelFlowCommand) -> Void) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
        self.onFlowCommand = onFlowCommand
        _viewModel = StateObject(wrappedValue: ElementalCascadeViewModel(difficulty: difficulty, levelIndex: level))
    }

    var body: some View {
        ZStack {
            LayeredBackgroundView()

            GeometryReader { geo in
                let scaler = GeometryScaler(size: geo.size)

                ZStack {
                    creatureArena(scaler: scaler)

                    channelOverlay(scaler: scaler)

                    weakSpotMarkers(scaler: scaler)

                    floatingOrb(scaler: scaler)

                    VStack {
                        statusPanel
                        orbPalette
                        dragSurface(scaler: scaler)
                            .frame(height: 140)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .offset(x: shakeOffset)
                .onChange(of: viewModel.shakeToken) { _ in
                    guard reducedEffects == false else {
                        shakeOffset = 0
                        return
                    }
                    shakeOffset = -18
                    withAnimation(.easeInOut(duration: 0.12)) {
                        shakeOffset = 16
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            shakeOffset = 0
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Elemental Cascade")
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
            didFinalizeSession = false
        }
        .onDisappear {}
        .onChange(of: viewModel.phase) { newPhase in
            guard didFinalizeSession == false else { return }
            guard case let .resolved(outcome, stars) = newPhase else { return }
            didFinalizeSession = true
            presentResult(outcome: outcome, stars: stars)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.banner)
                .foregroundStyle(Color.appTextSecondary)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Label("Score", systemImage: "flame.fill")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(viewModel.score)")
                    .foregroundStyle(Color.appAccent)
                    .font(.caption.monospacedDigit())
            }

            HStack {
                Label("Orbs", systemImage: "circle.grid.cross.fill")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(viewModel.remainingOrbs)")
                    .foregroundStyle(Color.appPrimary)
                    .font(.caption.monospacedDigit())
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
        .padding(.top, 12)
    }

    private var orbPalette: some View {
        HStack(spacing: 14) {
            ForEach(CascadeElement.allCases) { element in
                Button(action: {
                    FeedbackEffects.buttonTap()
                    viewModel.registerOrbSelection(element)
                }) {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(gradient(for: element))
                            .frame(width: 54, height: 54)
                            .overlay(
                                Circle()
                                    .stroke(Color.appPrimary.opacity(viewModel.selectedElement == element ? 1 : 0.35), lineWidth: viewModel.selectedElement == element ? 3 : 1)
                            )
                        Text(element.label.uppercased())
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }

    private func gradient(for element: CascadeElement) -> LinearGradient {
        switch element {
        case .fire:
            return LinearGradient(colors: [Color.red.opacity(0.85), Color.orange.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .water:
            return LinearGradient(colors: [Color.blue.opacity(0.85), Color.cyan.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .earth:
            return LinearGradient(colors: [Color.green.opacity(0.85), Color.brown.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .air:
            return LinearGradient(colors: [Color.white.opacity(0.85), Color.gray.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func creatureArena(scaler: GeometryScaler) -> some View {
        ZStack {
            RadialGradient(colors: [Color.appAccent.opacity(0.35), Color.clear], center: .center, startRadius: 20, endRadius: 160)
                .frame(width: scaler.size.width * 0.85, height: scaler.size.height * 0.42)
                .position(scaler.point(x: 200, y: 230))

            CascadeCreatureCanvas()
                .frame(width: scaler.size.width * 0.55, height: scaler.size.height * 0.28)
                .position(scaler.point(x: 200, y: 230))
        }
    }

    private func channelOverlay(scaler: GeometryScaler) -> some View {
        Path { path in
            let mapped = viewModel.channelPoints.map { scaler.point(x: $0.x, y: $0.y) }
            guard let first = mapped.first else { return }
            path.move(to: first)
            for point in mapped.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color.appAccent.opacity(0.55), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [10, 12]))
    }

    private func weakSpotMarkers(scaler: GeometryScaler) -> some View {
        ForEach(viewModel.weakSpots) { spot in
            let center = scaler.point(x: spot.point.x, y: spot.point.y)
            let ringOpacity = viewModel.hintHighlightedSpotID == spot.id ? 1.0 : 0.85
            let ringWidth: CGFloat = viewModel.hintHighlightedSpotID == spot.id ? 5 : 3

            ZStack {
                Circle()
                    .strokeBorder(Color.appPrimary.opacity(ringOpacity), lineWidth: ringWidth)
                    .background(Circle().fill(Color.appSurface.opacity(0.35)))
                    .frame(width: viewModel.hintHighlightedSpotID == spot.id ? 84 : 70, height: viewModel.hintHighlightedSpotID == spot.id ? 84 : 70)
                Text(spot.element.label.prefix(1))
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.appTextPrimary)
            }
            .position(center)
        }
    }

    private func floatingOrb(scaler: GeometryScaler) -> some View {
        let sampler = viewModel.sampler
        let position = sampler.point(at: viewModel.dragProgress)
        let scaled = scaler.point(x: position.x, y: position.y)

        return Group {
            if let selected = viewModel.selectedElement {
                Circle()
                    .fill(gradient(for: selected))
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(Color.appPrimary, lineWidth: 2))
                    .position(scaled)
            }
        }
    }

    private func dragSurface(scaler: GeometryScaler) -> some View {
        let gesture = DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard viewModel.selectedElement != nil else { return }
                if isDraggingCast == false {
                    isDraggingCast = true
                    dragAnchor = viewModel.dragProgress
                    FeedbackEffects.eventTap()
                }
                let sensitivity = scaler.size.height * 0.65
                let delta = -value.translation.height / sensitivity
                viewModel.handleDragChanged(progress: dragAnchor + delta)
            }
            .onEnded { value in
                defer { isDraggingCast = false }
                guard viewModel.selectedElement != nil else { return }
                viewModel.releaseSpell()
            }

        return Color.clear
            .contentShape(Rectangle())
            .gesture(gesture)
    }

    private func presentResult(outcome: ActivityOutcome, stars: Int) {
        let secondsPlayed = Int(Date().timeIntervalSince(sessionStartedAt))
        let earnedStars = outcome == .victory ? stars : 0
        let unlocked = ActivityPersistenceHelper.finalizeSession(
            progress: progress,
            activity: .elementalCascade,
            difficulty: difficulty,
            level: level,
            outcome: outcome,
            earnedStars: earnedStars,
            playedSeconds: Swift.max(secondsPlayed, 1),
            baselineAchievements: baselineAchievements,
            isPractice: isPractice
        )

        let showsNext = outcome == .victory && level < QuestoriaGame.maxLevelIndex

        resultPayload = ActivitySessionResultPayload(
            outcome: outcome,
            earnedStars: earnedStars,
            headlineTitle: "Cascade Score",
            headlineValue: "\(viewModel.score) pts",
            newlyUnlockedAchievements: Array(unlocked),
            showsNextLevel: showsNext,
            isPractice: isPractice
        )

        baselineAchievements.formUnion(unlocked)
    }
}

private struct CascadeCreatureCanvas: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2 + 6)
            let bodyPath = Path(ellipseIn: CGRect(x: center.x - 70, y: center.y - 40, width: 140, height: 96))
            context.fill(bodyPath, with: .color(Color.appSurface.opacity(0.95)))
            context.stroke(bodyPath, with: .color(Color.appAccent.opacity(0.85)), lineWidth: 3)

            let crest = Path(ellipseIn: CGRect(x: center.x - 24, y: center.y - 70, width: 48, height: 36))
            context.fill(crest, with: .color(Color.appPrimary.opacity(0.85)))

            let eyeLeft = Path(ellipseIn: CGRect(x: center.x - 36, y: center.y - 16, width: 18, height: 22))
            let eyeRight = Path(ellipseIn: CGRect(x: center.x + 18, y: center.y - 16, width: 18, height: 22))
            context.fill(eyeLeft, with: .color(Color.appPrimary.opacity(0.95)))
            context.fill(eyeRight, with: .color(Color.appPrimary.opacity(0.95)))
        }
    }
}
