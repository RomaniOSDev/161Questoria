import SwiftUI

struct BossGauntletContainerView: View {
    @State private var sessionKey = UUID()

    var body: some View {
        ElementalConvergenceSessionView(
            difficulty: .hard,
            level: QuestoriaGame.maxLevelIndex,
            activityIdentifier: .bossGauntlet,
            isPractice: false,
            isBossFight: true,
            onFlowCommand: { command in
                switch command {
                case .retry:
                    sessionKey = UUID()
                case .next, .exitToLevels:
                    break
                }
            }
        )
        .id(sessionKey)
    }
}
