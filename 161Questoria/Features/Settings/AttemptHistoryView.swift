import SwiftUI

struct AttemptHistoryView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ZStack {
            LayeredBackgroundView()

            ScrollView {
                VStack(spacing: 18) {
                    QuestoriaSectionHeader(
                        title: "Chronicle",
                        subtitle: "Latest encounters stored locally on this device."
                    )

                    if progress.attemptLogs.isEmpty {
                        VStack(spacing: 16) {
                            QuestoriaSymbolOrb(systemName: "clock.arrow.circlepath", accent: Color.appAccent)
                                .scaleEffect(1.15)
                            Text("No attempts yet")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.appTextPrimary)
                            Text("Complete encounters to populate your timeline.")
                                .font(.subheadline)
                                .foregroundStyle(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(28)
                        .frame(maxWidth: .infinity)
                        .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerHero)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(progress.attemptLogs) { log in
                                QuestoriaChronicleCard(log: log)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .padding(.bottom, 96)
            }
        }
        .navigationTitle("Attempt history")
        .navigationBarTitleDisplayMode(.inline)
    }
}
