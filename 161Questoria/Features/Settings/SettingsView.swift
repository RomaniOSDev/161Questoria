import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @ObservedObject private var accessibility = AccessibilityPreferencesStore.shared
    @State private var showResetConfirm = false

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }

    var body: some View {
        ZStack {
            LayeredBackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    QuestoriaSectionHeader(title: "Command deck", subtitle: "Progress, chronicle, and comfort tweaks.")

                    QuestoriaSettingsStatBoard(
                        activitiesPlayed: progress.totalActivitiesPlayed,
                        starsEarned: progress.totalStarsEarned,
                        playTimeDescription: formattedDuration(seconds: progress.totalPlayTimeSeconds)
                    )

                    QuestoriaGoalsSummaryBoard(
                        weekly: progress.weeklyStarsEarned,
                        weeklyGoal: QuestoriaGame.weeklyStarGoal,
                        daily: progress.dailyStarsEarned,
                        dailyGoal: QuestoriaGame.dailyStarGoal
                    )

                    QuestoriaSectionHeader(title: "Data trails")

                    NavigationLink {
                        AttemptHistoryView()
                    } label: {
                        QuestoriaSettingsNavRow(title: "Attempt History", systemImage: "clock.arrow.circlepath")
                    }
                    .buttonStyle(.plain)

                    QuestoriaSectionHeader(title: "Comfort")

                    QuestoriaAccessibilityBoard {
                        Toggle("Sound effects", isOn: $accessibility.soundEnabled)
                            .tint(Color.appPrimary)
                        Toggle("Haptics", isOn: $accessibility.hapticsEnabled)
                            .tint(Color.appPrimary)
                        Toggle("Reduce motion & decorative visuals", isOn: $accessibility.reducedVisualEffects)
                            .tint(Color.appPrimary)
                        Toggle("Higher contrast outlines", isOn: $accessibility.highContrastUI)
                            .tint(Color.appPrimary)
                        Toggle("Larger text (extra step)", isOn: $accessibility.largerDynamicType)
                            .tint(Color.appPrimary)
                    }

                    QuestoriaSectionHeader(title: "Legal & ratings")

                    Button(action: rateApp) {
                        QuestoriaSettingsNavRow(title: "Rate Us", systemImage: "star.circle.fill")
                    }
                    .buttonStyle(.plain)

                    Button(action: { openExternalLink(.privacyPolicy) }) {
                        QuestoriaSettingsNavRow(title: "Privacy Policy", systemImage: "doc.text.fill")
                    }
                    .buttonStyle(.plain)

                    Button(action: { openExternalLink(.termsOfUse) }) {
                        QuestoriaSettingsNavRow(title: "Terms of Use", systemImage: "scroll.fill")
                    }
                    .buttonStyle(.plain)

                    QuestoriaSectionHeader(title: "Support")

                    Button(action: openSupportMail) {
                        QuestoriaSettingsNavRow(title: "Support", systemImage: "envelope.fill")
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive, action: {
                        FeedbackEffects.buttonTap()
                        showResetConfirm = true
                    }) {
                        QuestoriaDestructiveActionTile(title: "Reset All Progress")
                    }
                    .buttonStyle(.plain)

                    Text(versionText)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .padding(.bottom, 96)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.headline)
            }
        }
        .alert("Reset All Progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                FeedbackEffects.majorAction()
                progress.resetAllProgress()
            }
        } message: {
            Text("This clears saved progress on this device.")
        }
    }

    private func formattedDuration(seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func openExternalLink(_ link: QuestoriaExternalLink) {
        FeedbackEffects.buttonTap()
        if let url = link.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func rateApp() {
        FeedbackEffects.buttonTap()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func openSupportMail() {
        FeedbackEffects.buttonTap()
        guard let url = URL(string: "mailto:support@example.com") else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
