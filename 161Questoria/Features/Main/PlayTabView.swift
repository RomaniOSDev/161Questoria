import SwiftUI

struct PlayTabView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ZStack {
            LayeredBackgroundView()
            PlayAnimatedBackdropView()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    QuestoriaHeroIntro(
                        title: "Sharpen focus, weave elements, chase brilliance.",
                        subtitle: "Every encounter rewards patience and precise gestures."
                    )

                    QuestoriaMomentumBoard()

                    bossSection

                    QuestoriaSectionHeader(title: "Activities", subtitle: "Ten stages each · three elemental lanes")

                    VStack(spacing: 16) {
                        ForEach(ActivityIdentifier.standardActivities, id: \.self) { activity in
                            NavigationLink {
                                ActivityLevelsView(activity: activity)
                            } label: {
                                QuestoriaNavHeroTile(
                                    title: activity.title,
                                    subtitle: activity.subtitle,
                                    footnote: "\(QuestoriaGame.levelCountPerActivity) stages"
                                ) {
                                    QuestoriaActivityGlyph(activity: activity)
                                        .frame(width: QuestoriaMetrics.iconOrb, height: QuestoriaMetrics.iconOrb)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 22)
                .padding(.bottom, 96)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Play")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.headline)
            }
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
}
