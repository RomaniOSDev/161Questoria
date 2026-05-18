import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects
    @Binding var selectedTab: QuestoriaMainTab

    var body: some View {
        ZStack {
            LayeredBackgroundView()
            PlayAnimatedBackdropView()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard

                    statsStrip

                    QuestoriaMomentumBoard()

                    ribbonAccent

                    QuestoriaSectionHeader(title: "Pick a lane", subtitle: "Illustrated shortcuts · full hub lives under Play")

                    activityCarousel

                    ribbonAccent

                    bossSection

                    shortcutsRow
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .padding(.bottom, 96)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.headline)
            }
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            Image("HomeHeroBanner")
                .resizable()
                .scaledToFill()
                .frame(height: 210)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [
                    Color.appBackground.opacity(0.05),
                    Color.appBackground.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(greetingLine)
                    .font(.caption.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(Color.appAccent.opacity(0.92))

                Text("Questoria waits.")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Align elements, steady your rhythm, and chase another crown of stars.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    heroBadge(icon: "star.fill", tint: Color.yellow.opacity(0.95), text: "\(progress.totalStarsEarned) stars")
                    heroBadge(icon: "flame.fill", tint: Color.orange.opacity(0.95), text: "\(progress.streakCount)d streak")
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerHero, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: reducedEffects ? .clear : Color.black.opacity(0.22),
            radius: reducedEffects ? 0 : 18,
            x: 0,
            y: reducedEffects ? 0 : 12
        )
    }

    private var statsStrip: some View {
        HStack(spacing: 10) {
            HomeStatCapsule(
                title: "Lifetime",
                value: "\(progress.totalStarsEarned)",
                caption: "stars",
                systemImage: "sparkles",
                tint: Color.appPrimary
            )
            HomeStatCapsule(
                title: "Runs",
                value: "\(progress.totalActivitiesPlayed)",
                caption: "sessions",
                systemImage: "gamecontroller.fill",
                tint: Color.appAccent
            )
            HomeStatCapsule(
                title: "Focus",
                value: formatPlayTime(progress.totalPlayTimeSeconds),
                caption: "logged",
                systemImage: "hourglass",
                tint: Color.appPrimary.opacity(0.85)
            )
        }
    }

    private var ribbonAccent: some View {
        Image("HomeWidgetRibbon")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .opacity(0.92)
    }

    private var activityCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(ActivityIdentifier.standardActivities, id: \.self) { activity in
                    NavigationLink {
                        ActivityLevelsView(activity: activity)
                    } label: {
                        HomeActivityShortcutCard(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var bossSection: some View {
        Group {
            if progress.isBossGauntletUnlocked {
                NavigationLink {
                    BossGauntletContainerView()
                } label: {
                    QuestoriaBossUnlockedTile(defeated: progress.bossGauntletDefeated)
                }
                .buttonStyle(.plain)
            } else {
                QuestoriaBossLockedTile(
                    requiredStars: QuestoriaGame.bossUnlockTotalStars,
                    currentStars: progress.totalStarsEarned
                )
            }
        }
    }

    private var shortcutsRow: some View {
        VStack(spacing: 12) {
            Button {
                FeedbackEffects.buttonTap()
                selectedTab = .play
            } label: {
                HomeShortcutRow(
                    title: "Full Play hub",
                    subtitle: "Momentum tips & detailed lanes",
                    systemImage: "square.grid.2x2.fill",
                    palette: [Color.appPrimary.opacity(0.95), Color.appAccent.opacity(0.85)]
                )
            }
            .buttonStyle(.plain)

            Button {
                FeedbackEffects.buttonTap()
                selectedTab = .achievements
            } label: {
                HomeShortcutRow(
                    title: "Achievements",
                    subtitle: "Badges, milestones, history",
                    systemImage: "medal.fill",
                    palette: [Color.appAccent.opacity(0.92), Color.appPrimary.opacity(0.65)]
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "GOOD MORNING"
        case 12 ..< 17: return "GOOD AFTERNOON"
        default: return "GOOD EVENING"
        }
    }

    private func heroBadge(icon: String, tint: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.appSurface.opacity(0.72))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.appAccent.opacity(0.22), lineWidth: 1)
        )
    }

    private func formatPlayTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return seconds > 0 ? "<1m" : "—"
    }
}

// MARK: - Widget tiles

private struct HomeStatCapsule: View {
    let title: String
    let value: String
    let caption: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint.opacity(0.92))

            Text(title.uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(0.9)
                .foregroundStyle(Color.appTextSecondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.heavy)
                .foregroundStyle(Color.appTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium, elevatedShadow: false)
    }
}

private struct HomeActivityShortcutCard: View {
    let activity: ActivityIdentifier

    private var gradientPair: [Color] {
        switch activity {
        case .elementalConvergence:
            return [Color.red.opacity(0.55), Color.blue.opacity(0.55)]
        case .elementalCascade:
            return [Color.teal.opacity(0.58), Color.green.opacity(0.52)]
        case .arcaneRhythm:
            return [Color.indigo.opacity(0.62), Color.orange.opacity(0.48)]
        case .bossGauntlet:
            return [Color.appPrimary.opacity(0.62), Color.appAccent.opacity(0.52)]
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerLarge, style: .continuous)
                .fill(
                    LinearGradient(colors: gradientPair, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .opacity(0.35)

            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerLarge, style: .continuous)
                .fill(Color.appSurface.opacity(0.25))

            VStack(spacing: 12) {
                QuestoriaActivityGlyph(activity: activity)
                    .frame(width: QuestoriaMetrics.iconOrb + 8, height: QuestoriaMetrics.iconOrb + 8)

                VStack(spacing: 4) {
                    Text(activity.title)
                        .font(.footnote.weight(.heavy))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text("\(QuestoriaGame.levelCountPerActivity) stages")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appAccent.opacity(0.92))
                }
            }
            .padding(14)
        }
        .frame(width: 148, height: 158)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerLarge, elevatedShadow: false)
        .overlay(
            RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct HomeShortcutRow: View {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    let title: String
    let subtitle: String
    let systemImage: String
    let palette: [Color]

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: QuestoriaMetrics.cornerMedium, style: .continuous)
                    .fill(
                        LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .shadow(
                        color: reducedEffects ? .clear : Color.black.opacity(0.22),
                        radius: reducedEffects ? 0 : 6,
                        x: 0,
                        y: reducedEffects ? 0 : 3
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.appAccent.opacity(0.95), Color.appSurface.opacity(0.35))
        }
        .padding(18)
        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero)
    }
}

struct QuestoriaLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.8)
                    .padding(.top, 30)
            }
        }
    }
}
