import SwiftUI

enum QuestoriaMainTab: Hashable {
    case home
    case play
    case achievements
    case settings
}

struct MainTabShellView: View {
    @State private var tab: QuestoriaMainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    NavigationStack {
                        HomeView(selectedTab: $tab)
                    }
                case .play:
                    NavigationStack {
                        PlayTabView()
                    }
                case .achievements:
                    NavigationStack {
                        AchievementsView()
                    }
                case .settings:
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 78)

            CustomTabBar(selection: $tab)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct CustomTabBar: View {
    @Binding var selection: QuestoriaMainTab
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    var body: some View {
        QuestoriaFloatingTabChrome {
            HStack(spacing: 6) {
                tabButton(.home, title: "Home", systemImage: "house.fill")
                tabButton(.play, title: "Play", systemImage: "gamecontroller.fill")
                tabButton(.achievements, title: "Awards", systemImage: "medal.fill")
                tabButton(.settings, title: "Settings", systemImage: "gearshape.fill")
            }
        }
    }

    private func tabButton(_ target: QuestoriaMainTab, title: String, systemImage: String) -> some View {
        let isSelected = selection == target
        return Button(action: {
            FeedbackEffects.buttonTap()
            selection = target
        }) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(isSelected ? Color.appBackground : Color.appTextSecondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent.opacity(0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: reducedEffects ? .clear : Color.appPrimary.opacity(0.38),
                            radius: 14,
                            y: 8
                        )
                }
            }
            .scaleEffect(isSelected ? 1 : 0.94)
            .animation(.spring(response: 0.42, dampingFraction: 0.74), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
