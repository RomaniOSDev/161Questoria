import SwiftUI

struct ActivityDestinationView: View {
    let activity: ActivityIdentifier
    let difficulty: GameDifficulty
    let level: Int
    let isPractice: Bool

    var body: some View {
        Group {
            switch activity {
            case .elementalConvergence:
                ElementalConvergenceContainerView(difficulty: difficulty, level: level, isPractice: isPractice)
            case .elementalCascade:
                ElementalCascadeContainerView(difficulty: difficulty, level: level, isPractice: isPractice)
            case .arcaneRhythm:
                ArcaneRhythmContainerView(difficulty: difficulty, level: level, isPractice: isPractice)
            case .bossGauntlet:
                BossGauntletContainerView()
            }
        }
    }
}

struct ActivityLevelsView: View {
    let activity: ActivityIdentifier

    @EnvironmentObject private var progress: ProgressStore
    @State private var difficulty: GameDifficulty = .easy
    @State private var practiceMode = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            LayeredBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    QuestoriaSectionHeader(title: activity.title, subtitle: activity.subtitle)

                    QuestoriaPracticeModeBanner(isOn: $practiceMode)

                    QuestoriaDifficultyChrome {
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(GameDifficulty.allCases) { diff in
                                Text(diff.displayTitle).tag(diff)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(0 ..< QuestoriaGame.levelCountPerActivity, id: \.self) { index in
                            let unlocked = progress.isLevelUnlocked(activity: activity, difficulty: difficulty, level: index)

                            NavigationLink {
                                ActivityDestinationView(
                                    activity: activity,
                                    difficulty: difficulty,
                                    level: index,
                                    isPractice: practiceMode
                                )
                            } label: {
                                QuestoriaLevelGridCell(
                                    displayNumber: index + 1,
                                    stars: progress.stars(for: activity, difficulty: difficulty, level: index),
                                    locked: unlocked == false
                                )
                            }
                            .disabled(unlocked == false)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(activity.title)
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.headline)
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}
