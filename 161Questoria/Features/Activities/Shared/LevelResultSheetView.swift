import SwiftUI

struct LevelResultSheetView: View {
    let payload: ActivitySessionResultPayload
    let onNext: () -> Void
    let onRetry: () -> Void
    let onLevels: () -> Void

    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    @State private var revealStars = 0
    @State private var bannerOffset: CGFloat = -320
    @State private var defeatFlashOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            LayeredBackgroundView()

            ScrollView {
                VStack(spacing: 22) {
                    outcomeMedallion

                    Text(payload.outcome == .victory ? "Victory" : "Game Over")
                        .font(.system(.largeTitle, design: .rounded)).bold()
                        .foregroundStyle(Color.appTextPrimary)

                    if payload.isPractice {
                        Text("Practice — stars, unlocks, and statistics were not saved.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                    }

                    starRow

                    VStack(spacing: 10) {
                        Text(payload.headlineTitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                        Text(payload.headlineValue)
                            .font(.system(.title, design: .rounded)).bold()
                            .foregroundStyle(Color.appAccent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium)

                    if payload.outcome == .defeat {
                        Button(action: {
                            FeedbackEffects.buttonTap()
                            onRetry()
                        }) {
                            Text("Try Again")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(PrimaryProminentButtonStyle())
                    }

                    VStack(spacing: 12) {
                        if payload.outcome == .victory, payload.showsNextLevel {
                            Button(action: {
                                FeedbackEffects.buttonTap()
                                onNext()
                            }) {
                                Text("Next Level")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .buttonStyle(PrimaryProminentButtonStyle())
                        }

                        Button(action: {
                            FeedbackEffects.buttonTap()
                            onRetry()
                        }) {
                            Text("Retry")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(SecondaryOutlineButtonStyle())

                        Button(action: {
                            FeedbackEffects.buttonTap()
                            onLevels()
                        }) {
                            Text("Back to Levels")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(SecondaryOutlineButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 26)
            }

            if payload.outcome == .victory, payload.newlyUnlockedAchievements.isEmpty == false {
                achievementBanner(first: payload.newlyUnlockedAchievements[0])
                    .offset(y: bannerOffset)
            }

            Color.red.opacity(defeatFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear(perform: handleAppear)
    }

    private var outcomeMedallion: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: payload.outcome == .victory
                            ? [Color.appPrimary.opacity(0.95), Color.appAccent.opacity(0.78)]
                            : [Color.appTextSecondary.opacity(0.65), Color.appSurface.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 92, height: 92)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                }

            Image(systemName: payload.outcome == .victory ? "sparkles" : "xmark.octagon.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Color.appBackground)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(
            color: reducedEffects ? .clear : Color.appAccent.opacity(payload.outcome == .victory ? 0.42 : 0.08),
            radius: reducedEffects ? 0 : 20,
            x: 0,
            y: reducedEffects ? 0 : 12
        )
    }

    @ViewBuilder
    private var starRow: some View {
        HStack(spacing: 16) {
            ForEach(0 ..< 3, id: \.self) { index in
                Image(systemName: index < revealStars ? "star.fill" : "star")
                    .foregroundStyle(index < revealStars ? Color.appPrimary : Color.appTextSecondary.opacity(0.35))
                    .font(.system(size: 34))
                    .shadow(
                        color: reducedEffects || index >= revealStars
                            ? .clear
                            : Color.appAccent.opacity(0.55),
                        radius: reducedEffects ? 0 : 12,
                        x: 0,
                        y: reducedEffects ? 0 : 4
                    )
                    .scaleEffect(index < revealStars ? 1 : 0.65)
                    .animation(.spring(response: 0.45, dampingFraction: 0.72).delay(Double(index) * 0.15), value: revealStars)
            }
        }
        .padding(.vertical, 6)
    }

    private func achievementBanner(first: AchievementDefinition) -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.appPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    Text(first.title)
                        .font(.subheadline)
                        .foregroundStyle(Color.appAccent)
                }
                Spacer()
            }
            .padding()
            .questoriaGlassCard(cornerRadius: QuestoriaMetrics.cornerMedium)
            .padding(.horizontal, 16)
            Spacer()
        }
        .padding(.top, 12)
    }

    private func handleAppear() {
        if payload.outcome == .victory {
            if payload.isPractice == false {
                FeedbackEffects.successNotify()
                FeedbackEffects.playSuccessSound()
            }
            animateStars(count: payload.earnedStars)
            if payload.newlyUnlockedAchievements.isEmpty == false {
                bannerOffset = -320
                withAnimation(.easeInOut(duration: 2)) {
                    bannerOffset = 18
                }
            }
        } else {
            FeedbackEffects.failureNotify()
            FeedbackEffects.playFailSound()
            revealStars = 0
            defeatFlashOpacity = 0
            withAnimation(.easeInOut(duration: 0.15)) {
                defeatFlashOpacity = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    defeatFlashOpacity = 0
                }
            }
        }
    }

    private func animateStars(count: Int) {
        revealStars = 0
        guard payload.outcome == .victory else { return }
        let capped = min(max(count, 0), 3)
        for index in 1 ... capped {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index - 1) * 0.18) {
                if payload.isPractice == false {
                    FeedbackEffects.starEarned()
                }
                revealStars = index
            }
        }
    }
}
