import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var progress: ProgressStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            LayeredBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    QuestoriaSectionHeader(
                        title: "Hall of deeds",
                        subtitle: "Unlock crests by reaching mastery milestones."
                    )

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AchievementDefinition.allCases) { achievement in
                            let unlocked = achievement.isUnlocked(progress: progress)
                            QuestoriaAchievementCell(achievement: achievement, unlocked: unlocked)
                                .animation(.spring(response: 0.45, dampingFraction: 0.72), value: unlocked)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .padding(.bottom, 96)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Achievements")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.headline)
            }
        }
    }
}
