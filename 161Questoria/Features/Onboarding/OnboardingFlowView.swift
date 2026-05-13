import SwiftUI

private enum OnboardingIllustrationKind {
    case spells
    case stars
    case journey
}

private struct OnboardingIllustration: View {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    let kind: OnboardingIllustrationKind
    @Binding var animate: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            switch kind {
            case .spells:
                drawSpells(context: context, center: center, radius: min(size.width, size.height) / 2.8)
            case .stars:
                drawStars(context: context, size: size)
            case .journey:
                drawPath(context: context, size: size)
            }
        }
        .scaleEffect(reducedEffects ? 1 : (animate ? 1 : 0.82))
        .opacity(reducedEffects ? 1 : (animate ? 1 : 0))
        .animation(reducedEffects ? nil : .spring(response: 0.46, dampingFraction: 0.76), value: animate)
    }

    private func drawSpells(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let glowOuter = Path(ellipseIn: CGRect(x: center.x - radius * 1.05, y: center.y - radius * 1.05, width: radius * 2.1, height: radius * 2.1))
        context.fill(glowOuter, with: .color(Color.appAccent.opacity(0.14)))

        let glow = Color.appAccent.opacity(0.42)
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(glow)
        )

        let wedgePairs: [(Color, Color)] = [
            (Color.red.opacity(0.92), Color.orange.opacity(0.55)),
            (Color.blue.opacity(0.92), Color.cyan.opacity(0.5)),
            (Color.green.opacity(0.88), Color.teal.opacity(0.48))
        ]
        for index in 0 ..< 3 {
            var wedge = Path()
            wedge.move(to: center)
            wedge.addArc(
                center: center,
                radius: radius * 0.82,
                startAngle: .degrees(Double(index) * 120 - 90),
                endAngle: .degrees(Double(index + 1) * 120 - 90),
                clockwise: false
            )
            wedge.closeSubpath()
            let pair = wedgePairs[index]
            context.fill(
                wedge,
                with: .linearGradient(
                    Gradient(colors: [pair.0, pair.1]),
                    startPoint: CGPoint(x: center.x - radius * 0.35, y: center.y - radius * 0.35),
                    endPoint: CGPoint(x: center.x + radius * 0.35, y: center.y + radius * 0.35)
                )
            )
        }

        let ring = Path(ellipseIn: CGRect(x: center.x - radius * 0.35, y: center.y - radius * 0.35, width: radius * 0.7, height: radius * 0.7))
        context.stroke(ring, with: .color(Color.white.opacity(0.55)), lineWidth: 2)
        context.stroke(ring, with: .color(Color.appPrimary.opacity(0.92)), lineWidth: 3)
    }

    private func drawStars(context: GraphicsContext, size: CGSize) {
        let stars = [
            CGPoint(x: size.width * 0.25, y: size.height * 0.35),
            CGPoint(x: size.width * 0.55, y: size.height * 0.25),
            CGPoint(x: size.width * 0.72, y: size.height * 0.45),
            CGPoint(x: size.width * 0.45, y: size.height * 0.65)
        ]

        let halo = Path(ellipseIn: CGRect(x: size.width * 0.15, y: size.height * 0.15, width: size.width * 0.7, height: size.height * 0.7))
        context.stroke(halo, with: .color(Color.appAccent.opacity(0.28)), lineWidth: 2)

        for starCenter in stars {
            let starPath = starShape(center: starCenter, radius: min(size.width, size.height) * 0.072)
            context.fill(
                starPath,
                with: .linearGradient(
                    Gradient(colors: [Color.appPrimary.opacity(0.98), Color.appAccent.opacity(0.78)]),
                    startPoint: CGPoint(x: starCenter.x - 8, y: starCenter.y - 8),
                    endPoint: CGPoint(x: starCenter.x + 8, y: starCenter.y + 8)
                )
            )
            context.stroke(starPath, with: .color(Color.white.opacity(0.45)), lineWidth: 1.5)
        }

        let haloInner = Path(ellipseIn: CGRect(x: size.width * 0.22, y: size.height * 0.22, width: size.width * 0.56, height: size.height * 0.56))
        context.stroke(haloInner, with: .color(Color.appPrimary.opacity(0.4)), lineWidth: 2)
    }

    private func drawPath(context: GraphicsContext, size: CGSize) {
        var route = Path()
        route.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.72))
        route.addQuadCurve(
            to: CGPoint(x: size.width * 0.55, y: size.height * 0.45),
            control: CGPoint(x: size.width * 0.35, y: size.height * 0.78)
        )
        route.addQuadCurve(
            to: CGPoint(x: size.width * 0.82, y: size.height * 0.28),
            control: CGPoint(x: size.width * 0.68, y: size.height * 0.38)
        )

        context.stroke(
            route,
            with: .linearGradient(
                Gradient(colors: [Color.appAccent.opacity(0.95), Color.appPrimary.opacity(0.65)]),
                startPoint: CGPoint(x: size.width * 0.12, y: size.height * 0.7),
                endPoint: CGPoint(x: size.width * 0.88, y: size.height * 0.22)
            ),
            style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round, dash: [12, 14])
        )

        let crestBounds = CGRect(x: size.width * 0.68, y: size.height * 0.18, width: size.width * 0.18, height: size.height * 0.18)
        let crest = Path(ellipseIn: crestBounds)
        context.fill(
            crest,
            with: .linearGradient(
                Gradient(colors: [Color.appSurface.opacity(0.98), Color.appSurface.opacity(0.72)]),
                startPoint: CGPoint(x: crestBounds.minX, y: crestBounds.minY),
                endPoint: CGPoint(x: crestBounds.maxX, y: crestBounds.maxY)
            )
        )
        context.stroke(crest, with: .color(Color.appPrimary.opacity(0.95)), lineWidth: 3)

        let beacon = Path(ellipseIn: CGRect(x: size.width * 0.45, y: size.height * 0.08, width: size.width * 0.12, height: size.height * 0.12))
        context.fill(
            beacon,
            with: .radialGradient(
                Gradient(colors: [Color.appPrimary.opacity(1), Color.appAccent.opacity(0.55)]),
                center: CGPoint(x: size.width * 0.51, y: size.height * 0.11),
                startRadius: 2,
                endRadius: size.width * 0.09
            )
        )
        context.stroke(beacon, with: .color(Color.white.opacity(0.35)), lineWidth: 2)
    }

    private func starShape(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        let points = 5
        for index in 0 ..< points * 2 {
            let angle = CGFloat(index) * .pi / CGFloat(points) - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct OnboardingIllustrationStage: View {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    let kind: OnboardingIllustrationKind
    @Binding var animate: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.16),
                            Color.appAccent.opacity(0.1),
                            Color.appSurface.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if reducedEffects == false {
                RadialGradient(
                    colors: [Color.appAccent.opacity(0.28), Color.clear],
                    center: .center,
                    startRadius: 8,
                    endRadius: 140
                )
                .clipShape(RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous))

                RadialGradient(
                    colors: [Color.appPrimary.opacity(0.22), Color.clear],
                    center: UnitPoint(x: 0.85, y: 0.15),
                    startRadius: 4,
                    endRadius: 120
                )
                .clipShape(RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous))
            }

            OnboardingIllustration(kind: kind, animate: $animate)
                .padding(28)
        }
        .frame(height: 268)
        .clipShape(RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(reducedEffects ? 0.06 : 0.22),
                            Color.appAccent.opacity(0.45),
                            Color.appPrimary.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: reducedEffects ? 1 : 1.5
                )
        )
        .shadow(
            color: reducedEffects ? .clear : Color.black.opacity(0.22),
            radius: reducedEffects ? 0 : 22,
            x: 0,
            y: reducedEffects ? 0 : 14
        )
    }
}

private struct OnboardingCopyCard: View {
    let step: Int
    let totalSteps: Int
    let headline: String
    let bodyText: String

    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Step \(step) of \(totalSteps)")
                    .font(.caption.weight(.heavy))
                    .tracking(1.3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appPrimary.opacity(0.88)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                Image(systemName: iconForStep)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appAccent.opacity(0.88))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.appSurface.opacity(0.55))
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.appAccent.opacity(0.28), lineWidth: 1)
                            )
                    )
                    .accessibilityHidden(true)
            }

            Text(headline)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(
                    reducedEffects
                        ? AnyShapeStyle(Color.appTextPrimary)
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.appTextPrimary, Color.appAccent.opacity(0.94)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .fixedSize(horizontal: false, vertical: true)

            Text(bodyText)
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero, elevatedShadow: reducedEffects == false)
    }

    private var iconForStep: String {
        switch step {
        case 1: return "hand.tap.fill"
        case 2: return "star.fill"
        default: return "map.fill"
        }
    }
}

struct OnboardingFlowView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects
    @State private var pageIndex = 0
    @State private var appeared = false

    private let headlines = ["Cast with intent", "Earn brilliance", "Enter the arena"]
    private let bodies = [
        "Tap elemental orbs and weave combos — patience beats frantic taps.",
        "Clear encounters to collect stars, unlock deeper lanes, and chase the Boss Gauntlet.",
        "Your dashboard awaits: momentum widgets, practice mode, and three elemental journeys."
    ]
    private let illustrations: [OnboardingIllustrationKind] = [.spells, .stars, .journey]

    var body: some View {
        ZStack {
            LayeredBackgroundView()
            PlayAnimatedBackdropView()

            VStack(spacing: 22) {
                onboardingHeader

                TabView(selection: $pageIndex) {
                    ForEach(0 ..< headlines.count, id: \.self) { index in
                        VStack(spacing: 18) {
                            OnboardingIllustrationStage(kind: illustrations[index], animate: $appeared)

                            OnboardingCopyCard(
                                step: index + 1,
                                totalSteps: headlines.count,
                                headline: headlines[index],
                                bodyText: bodies[index]
                            )

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .tag(index)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.32), value: pageIndex)

                pageDots

                Button(action: advance) {
                    Text(pageIndex == headlines.count - 1 ? "Enter Questoria" : "Continue")
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .buttonStyle(PrimaryProminentButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            appeared = true
        }
        .onChange(of: pageIndex) { _ in
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                appeared = true
            }
        }
    }

    private var onboardingHeader: some View {
        VStack(spacing: 8) {
            Text("QUESTORIA")
                .font(.caption.weight(.heavy))
                .tracking(2.2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Welcome")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(
                    reducedEffects
                        ? AnyShapeStyle(Color.appTextPrimary)
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.appTextPrimary, Color.appTextSecondary.opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text("Three beats before your first trial.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var pageDots: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< headlines.count, id: \.self) { dot in
                Capsule()
                    .fill(
                        dot == pageIndex
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.appPrimary.opacity(0.98), Color.appAccent.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(Color.appSurface.opacity(0.72))
                    )
                    .frame(width: dot == pageIndex ? 32 : 10, height: 10)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: dot == pageIndex
                                        ? [Color.white.opacity(0.35), Color.clear]
                                        : [Color.appAccent.opacity(0.38), Color.appPrimary.opacity(0.14)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: reducedEffects || dot != pageIndex ? .clear : Color.appPrimary.opacity(0.35),
                        radius: reducedEffects ? 0 : 8,
                        x: 0,
                        y: reducedEffects ? 0 : 4
                    )
                    .animation(.spring(response: 0.42, dampingFraction: 0.78), value: pageIndex)
                    .accessibilityLabel("Page \(dot + 1) of \(headlines.count)")
                    .accessibilityAddTraits(dot == pageIndex ? [.isSelected] : [])
            }
        }
    }

    private func advance() {
        FeedbackEffects.buttonTap()
        if pageIndex < headlines.count - 1 {
            withAnimation(.easeInOut(duration: 0.32)) {
                pageIndex += 1
            }
        } else {
            FeedbackEffects.majorAction()
            progress.completeOnboarding()
        }
    }
}
