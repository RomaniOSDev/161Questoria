import SwiftUI

// MARK: - Metrics

enum QuestoriaMetrics {
    static let cornerHero: CGFloat = 26
    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 18
    static let cornerSmall: CGFloat = 14
    static let iconOrb: CGFloat = 52
    static let levelBadge: CGFloat = 46
}

// MARK: - Glass card

private struct QuestoriaGlassCardModifier: ViewModifier {
    @Environment(\.questoriaReducedVisualEffects) private var reduced
    @Environment(\.questoriaHighContrastUI) private var highContrast

    var cornerRadius: CGFloat
    var elevatedShadow: Bool

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurface.opacity(0.995),
                                    Color.appSurface.opacity(0.82),
                                    Color.appSurface.opacity(0.68)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if reduced == false && highContrast == false {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.clear,
                                        Color.black.opacity(0.068)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blendMode(.overlay)
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(highContrast ? 0.7 : 0.42),
                                    Color.appPrimary.opacity(highContrast ? 0.5 : 0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: highContrast ? 2 : 1
                        )
                }
            }
            .shadow(
                color: (!reduced && elevatedShadow) ? Color.black.opacity(0.24) : .clear,
                radius: (!reduced && elevatedShadow) ? 20 : 0,
                x: 0,
                y: (!reduced && elevatedShadow) ? 11 : 0
            )
    }
}

extension View {
    func questoriaGlassCard(cornerRadius: CGFloat = QuestoriaMetrics.cornerLarge, elevatedShadow: Bool = true) -> some View {
        modifier(QuestoriaGlassCardModifier(cornerRadius: cornerRadius, elevatedShadow: elevatedShadow))
    }
}

// MARK: - Section chrome

struct QuestoriaSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1.4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuestoriaHeroIntro: View {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(
                    reducedEffects
                        ? AnyShapeStyle(Color.appTextPrimary)
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.appTextPrimary, Color.appAccent.opacity(0.92)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Icon orb

struct QuestoriaSymbolOrb: View {
    let systemName: String
    var accent: Color = Color.appPrimary

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.55), accent.opacity(0.08)],
                        center: .center,
                        startRadius: 4,
                        endRadius: 28
                    )
                )
            Circle()
                .strokeBorder(accent.opacity(0.45), lineWidth: 1)

            Image(systemName: systemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: QuestoriaMetrics.iconOrb, height: QuestoriaMetrics.iconOrb)
    }
}

// MARK: - Large navigation tile (Play hub)

struct QuestoriaNavHeroTile<Leading: View>: View {
    let title: String
    let subtitle: String
    var footnote: String?
    @ViewBuilder var leading: () -> Leading

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            leading()
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let footnote {
                    Text(footnote)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appAccent.opacity(0.9))
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.appAccent.opacity(0.95), Color.appSurface.opacity(0.35))
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero)
    }
}

// MARK: - Activity / boss glyphs (shared)

struct QuestoriaActivityGlyph: View {
    let activity: ActivityIdentifier

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            switch activity {
            case .elementalConvergence:
                let orb = Path(ellipseIn: CGRect(x: center.x - 18, y: center.y - 18, width: 36, height: 36))
                context.fill(orb, with: .color(Color.red.opacity(0.85)))
                let orb2 = Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 28, width: 26, height: 26))
                context.fill(orb2, with: .color(Color.blue.opacity(0.85)))
            case .elementalCascade:
                var zig = Path()
                zig.move(to: CGPoint(x: center.x - 22, y: center.y + 18))
                zig.addLine(to: CGPoint(x: center.x - 8, y: center.y - 6))
                zig.addLine(to: CGPoint(x: center.x + 10, y: center.y + 10))
                zig.addLine(to: CGPoint(x: center.x + 22, y: center.y - 18))
                context.stroke(zig, with: .color(Color.appAccent.opacity(0.95)), lineWidth: 4)
            case .arcaneRhythm:
                var diamond = Path()
                diamond.move(to: CGPoint(x: center.x, y: center.y - 20))
                diamond.addLine(to: CGPoint(x: center.x + 16, y: center.y))
                diamond.addLine(to: CGPoint(x: center.x, y: center.y + 20))
                diamond.addLine(to: CGPoint(x: center.x - 16, y: center.y))
                diamond.closeSubpath()
                context.stroke(diamond, with: .color(Color.appPrimary.opacity(0.95)), lineWidth: 3)
            case .bossGauntlet:
                let crest = Path(ellipseIn: CGRect(x: center.x - 20, y: center.y - 12, width: 40, height: 28))
                context.fill(crest, with: .color(Color.appAccent.opacity(0.88)))
                context.stroke(crest, with: .color(Color.appPrimary.opacity(0.9)), lineWidth: 2)
            }
        }
        .frame(width: QuestoriaMetrics.iconOrb - 2, height: QuestoriaMetrics.iconOrb - 2)
        .background(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerSmall, style: .continuous)
                .fill(Color.appSurface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerSmall, style: .continuous)
                .stroke(Color.appAccent.opacity(0.28), lineWidth: 1)
        )
    }
}

struct QuestoriaBossGlyph: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let crown = Path { path in
                path.move(to: CGPoint(x: center.x - 22, y: center.y + 14))
                path.addLine(to: CGPoint(x: center.x - 18, y: center.y - 14))
                path.addLine(to: CGPoint(x: center.x - 6, y: center.y + 4))
                path.addLine(to: CGPoint(x: center.x, y: center.y - 18))
                path.addLine(to: CGPoint(x: center.x + 6, y: center.y + 4))
                path.addLine(to: CGPoint(x: center.x + 18, y: center.y - 14))
                path.addLine(to: CGPoint(x: center.x + 22, y: center.y + 14))
                path.closeSubpath()
            }
            context.fill(crown, with: .color(Color.appAccent.opacity(0.92)))
            context.stroke(crown, with: .color(Color.appPrimary.opacity(0.85)), lineWidth: 2)
        }
        .frame(width: QuestoriaMetrics.iconOrb - 2, height: QuestoriaMetrics.iconOrb - 2)
        .background(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerSmall, style: .continuous)
                .fill(Color.appSurface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerSmall, style: .continuous)
                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Momentum card

struct QuestoriaMomentumBoard: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                QuestoriaSectionHeader(title: "Momentum", subtitle: "Weekly bloom · daily streak")
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color.appAccent.opacity(0.85))
            }

            HStack(spacing: 12) {
                streakChip
                Spacer(minLength: 8)
                weekGauge
            }

            ProgressView(
                value: Double(min(progress.weeklyStarsEarned, QuestoriaGame.weeklyStarGoal)),
                total: Double(QuestoriaGame.weeklyStarGoal)
            )
            .tint(Color.appPrimary)

            Text("Today: \(progress.dailyStarsEarned) / \(QuestoriaGame.dailyStarGoal) new stars toward your daily bloom.")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero)
    }

    private var streakChip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Streak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange.opacity(0.95))
                Text("\(progress.streakCount)")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.appAccent)
                Text("days")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerMedium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.72),
                            Color.appSurface.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerMedium, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.32), Color.appAccent.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var weekGauge: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("Week stars")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text("\(progress.weeklyStarsEarned) / \(QuestoriaGame.weeklyStarGoal)")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Color.appPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerMedium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.72),
                            Color.appSurface.opacity(0.38)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerMedium, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.28), Color.appPrimary.opacity(0.1)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Boss tiles

struct QuestoriaBossUnlockedTile: View {
    let defeated: Bool

    var body: some View {
        QuestoriaNavHeroTile(
            title: ActivityIdentifier.bossGauntlet.title,
            subtitle: defeated ? "Trial conquered — defend your legend anytime." : ActivityIdentifier.bossGauntlet.subtitle,
            footnote: defeated ? "Tap to replay" : "Hard convergence duel"
        ) {
            QuestoriaBossGlyph()
        }
        .overlay(alignment: .topTrailing) {
            if defeated {
                Image(systemName: "crown.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .padding(10)
            }
        }
    }
}

struct QuestoriaBossLockedTile: View {
    let requiredStars: Int
    let currentStars: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                QuestoriaSymbolOrb(systemName: "lock.fill", accent: Color.appTextSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Boss Gauntlet")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Peak endurance encounter")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appAccent.opacity(0.85))
                }
                Spacer()
            }

            Text("Earn \(requiredStars) lifetime stars to unlock an endurance convergence duel.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: Double(min(currentStars, requiredStars)), total: Double(requiredStars))
                .tint(Color.appAccent)

            Text("\(currentStars) / \(requiredStars) stars")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.appAccent)
                .fontWeight(.semibold)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero, elevatedShadow: false)
        .opacity(0.92)
    }
}

// MARK: - Activity levels

struct QuestoriaPracticeModeBanner: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .top, spacing: 14) {
                QuestoriaSymbolOrb(systemName: "wand.and.stars", accent: Color.appAccent)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Practice mode")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("No stars, unlocks, play stats, or goals — unlimited rehearsal.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Color.appPrimary)
        .padding(16)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium, elevatedShadow: false)
    }
}

struct QuestoriaDifficultyChrome<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            QuestoriaSectionHeader(title: "Difficulty", subtitle: "Tunes creature pressure & pacing")
            content
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerSmall + 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurface.opacity(0.62),
                                    Color.appSurface.opacity(0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerSmall + 4, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.14)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

struct QuestoriaLevelGridCell: View {
    let displayNumber: Int
    let stars: Int
    let locked: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Group {
                    if locked {
                        Circle()
                            .fill(Color.appSurface.opacity(0.45))
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appPrimary.opacity(1),
                                        Color.appAccent.opacity(0.72),
                                        Color.appPrimary.opacity(0.88)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .frame(width: QuestoriaMetrics.levelBadge, height: QuestoriaMetrics.levelBadge)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: locked
                                    ? [Color.white.opacity(0.06), Color.white.opacity(0.03)]
                                    : [Color.white.opacity(0.55), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: locked ? 1 : 2
                        )
                }

                if locked == false {
                    Text("\(displayNumber)")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.appBackground)
                }

                if locked {
                    Circle()
                        .fill(Color.black.opacity(0.42))
                        .frame(width: QuestoriaMetrics.levelBadge, height: QuestoriaMetrics.levelBadge)

                    Image(systemName: "lock.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                }
            }

            HStack(spacing: 3) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(index < stars ? Color.appPrimary : Color.appTextSecondary.opacity(0.32))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 124)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium, elevatedShadow: false)
        .opacity(locked ? 0.62 : 1)
    }
}

// MARK: - Settings rows

struct QuestoriaSettingsNavRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            QuestoriaSymbolOrb(systemName: systemImage, accent: Color.appPrimary)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appAccent.opacity(0.85))
        }
        .padding(16)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium, elevatedShadow: false)
    }
}

struct QuestoriaSettingsStatBoard: View {
    let activitiesPlayed: Int
    let starsEarned: Int
    let playTimeDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuestoriaSectionHeader(title: "Statistics", subtitle: "Lifetime totals on this device")

            VStack(spacing: 0) {
                QuestoriaStatRow(title: "Activities played", value: "\(activitiesPlayed)", icon: "gamecontroller.fill")
                Divider().opacity(0.35)
                QuestoriaStatRow(title: "Stars earned", value: "\(starsEarned)", icon: "star.fill")
                Divider().opacity(0.35)
                QuestoriaStatRow(title: "Play time", value: playTimeDescription, icon: "clock.fill")
            }
        }
        .padding(18)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero)
    }
}

private struct QuestoriaStatRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appAccent.opacity(0.85))
                .frame(width: 26)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Color.appPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }
}

struct QuestoriaGoalsSummaryBoard: View {
    let weekly: Int
    let weeklyGoal: Int
    let daily: Int
    let dailyGoal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuestoriaSectionHeader(title: "Goals", subtitle: "Star deltas toward weekly & daily blooms")

            ProgressView(value: Double(min(weekly, weeklyGoal)), total: Double(weeklyGoal))
                .tint(Color.appPrimary)
                .frame(maxWidth: .infinity)

            Text("Week: \(weekly) / \(weeklyGoal) · Today: \(daily) / \(dailyGoal)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero)
    }
}

struct QuestoriaAccessibilityBoard<Content: View>: View {
    @ViewBuilder let toggles: Content

    init(@ViewBuilder toggles: () -> Content) {
        self.toggles = toggles()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuestoriaSectionHeader(title: "Accessibility", subtitle: "Sensory & readability")

            VStack(alignment: .leading, spacing: 16) {
                toggles
            }

            Text("Large text applies Questoria screens using an extra Dynamic Type step.")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero)
    }
}

struct QuestoriaDestructiveActionTile: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.red.opacity(0.92))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium, elevatedShadow: false)
            .overlay(
                RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerMedium, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
            )
    }
}

// MARK: - Achievements

struct QuestoriaAchievementCell: View {
    let achievement: AchievementDefinition
    let unlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                QuestoriaAchievementBadgeArt(unlocked: unlocked)
                    .frame(height: 108)

                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(unlocked ? Color.appPrimary : Color.appTextSecondary.opacity(0.8))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appSurface.opacity(0.94),
                                        Color.appSurface.opacity(0.72)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.appAccent.opacity(unlocked ? 0.35 : 0.18), lineWidth: 1)
                    )
                    .padding(8)
            }

            Text(achievement.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            Text(achievement.detail)
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero, elevatedShadow: false)
        .overlay {
            if unlocked {
                RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.55), Color.appAccent.opacity(0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        }
        .scaleEffect(unlocked ? 1 : 0.97)
    }
}

private struct QuestoriaAchievementBadgeArt: View {
    let unlocked: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2 + 4)
            let shield = Path(roundedRect: CGRect(x: center.x - 54, y: center.y - 54, width: 108, height: 112), cornerRadius: 28)
            context.fill(shield, with: .color(Color.appSurface.opacity(unlocked ? 1 : 0.55)))
            context.stroke(shield, with: .color(Color.appAccent.opacity(unlocked ? 0.95 : 0.28)), lineWidth: unlocked ? 3 : 2)

            let inner = Path(ellipseIn: CGRect(x: center.x - 22, y: center.y - 26, width: 44, height: 44))
            context.fill(inner, with: .color(Color.appPrimary.opacity(unlocked ? 0.95 : 0.28)))

            let ribbon = Path(ellipseIn: CGRect(x: center.x - 36, y: center.y + 22, width: 72, height: 24))
            context.fill(ribbon, with: .color(Color.appAccent.opacity(unlocked ? 0.85 : 0.22)))
        }
    }
}

// MARK: - Chronicle (attempt history)

struct QuestoriaChronicleCard: View {
    let log: SessionAttemptLog

    private var activityTitle: String {
        ActivityIdentifier(rawValue: log.activityRaw)?.title ?? log.activityRaw
    }

    private var difficultyTitle: String {
        GameDifficulty(rawValue: log.difficultyRaw)?.displayTitle ?? log.difficultyRaw
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activityTitle)
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("\(difficultyTitle) · Stage \(log.level + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
                QuestoriaOutcomePill(victory: log.outcome == .victory)
            }

            HStack(spacing: 10) {
                Text(log.practice ? "Practice" : "Ranked")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(log.practice ? Color.appTextSecondary.opacity(0.65) : Color.appAccent.opacity(0.92))
                    )

                if log.stars > 0 {
                    Label("\(log.stars)", systemImage: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                }

                Spacer()

                Text(log.endedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium, elevatedShadow: false)
    }
}

private struct QuestoriaOutcomePill: View {
    let victory: Bool

    var body: some View {
        Text(victory ? "Victory" : "Defeat")
            .font(.caption.weight(.heavy))
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                if victory {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.98), Color.appAccent.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    Capsule()
                        .fill(Color.appTextSecondary.opacity(0.55))
                }
            }
    }
}

// MARK: - Tab bar chrome

struct QuestoriaFloatingTabChrome<Content: View>: View {
    @Environment(\.questoriaReducedVisualEffects) private var reduced
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurface.opacity(0.94),
                                    Color.appSurface.opacity(0.78),
                                    Color.appPrimary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(reduced ? 0 : 0.14),
                                    Color.appAccent.opacity(0.42),
                                    Color.appPrimary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .shadow(color: Color.black.opacity(reduced ? 0.1 : 0.26), radius: reduced ? 14 : 22, y: 12)
    }
}
