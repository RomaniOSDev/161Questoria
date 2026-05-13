import AudioToolbox
import UIKit

enum FeedbackEffects {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notifier = UINotificationFeedbackGenerator()

    private static var prefs: AccessibilityPreferencesStore { AccessibilityPreferencesStore.shared }

    static func buttonTap() {
        guard prefs.hapticsEnabled else { return }
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    static func majorAction() {
        guard prefs.hapticsEnabled else { return }
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    static func eventTap() {
        guard prefs.hapticsEnabled else { return }
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    static func starEarned() {
        guard prefs.hapticsEnabled else { return }
        notifier.prepare()
        notifier.notificationOccurred(.success)
    }

    static func successNotify() {
        guard prefs.hapticsEnabled else { return }
        notifier.prepare()
        notifier.notificationOccurred(.success)
    }

    static func failureNotify() {
        guard prefs.hapticsEnabled else { return }
        notifier.prepare()
        notifier.notificationOccurred(.error)
    }

    static func playSuccessSound() {
        guard prefs.soundEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    static func playFailSound() {
        guard prefs.soundEnabled else { return }
        AudioServicesPlaySystemSound(1521)
    }
}
