import Combine
import SwiftUI

private enum AccessibilityKeys {
    static let prefix = "questoria.accessibility."
    static let soundEnabled = prefix + "soundEnabled"
    static let hapticsEnabled = prefix + "hapticsEnabled"
    static let reducedVisualEffects = prefix + "reducedVisualEffects"
    static let highContrastUI = prefix + "highContrastUI"
    static let largerDynamicType = prefix + "largerDynamicType"
}

final class AccessibilityPreferencesStore: ObservableObject {
    static let shared = AccessibilityPreferencesStore()

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: AccessibilityKeys.soundEnabled) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: AccessibilityKeys.hapticsEnabled) }
    }

    @Published var reducedVisualEffects: Bool {
        didSet { defaults.set(reducedVisualEffects, forKey: AccessibilityKeys.reducedVisualEffects) }
    }

    @Published var highContrastUI: Bool {
        didSet { defaults.set(highContrastUI, forKey: AccessibilityKeys.highContrastUI) }
    }

    @Published var largerDynamicType: Bool {
        didSet { defaults.set(largerDynamicType, forKey: AccessibilityKeys.largerDynamicType) }
    }

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: AccessibilityKeys.soundEnabled) == nil {
            defaults.set(true, forKey: AccessibilityKeys.soundEnabled)
        }
        if defaults.object(forKey: AccessibilityKeys.hapticsEnabled) == nil {
            defaults.set(true, forKey: AccessibilityKeys.hapticsEnabled)
        }
        soundEnabled = defaults.bool(forKey: AccessibilityKeys.soundEnabled)
        hapticsEnabled = defaults.bool(forKey: AccessibilityKeys.hapticsEnabled)
        reducedVisualEffects = defaults.bool(forKey: AccessibilityKeys.reducedVisualEffects)
        highContrastUI = defaults.bool(forKey: AccessibilityKeys.highContrastUI)
        largerDynamicType = defaults.bool(forKey: AccessibilityKeys.largerDynamicType)
    }

    var preferredDynamicTypeSize: DynamicTypeSize {
        largerDynamicType ? .accessibility2 : .large
    }
}

private struct QuestoriaReducedVisualEffectsKey: EnvironmentKey {
    static let defaultValue = false
}

private struct QuestoriaHighContrastUIKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var questoriaReducedVisualEffects: Bool {
        get { self[QuestoriaReducedVisualEffectsKey.self] }
        set { self[QuestoriaReducedVisualEffectsKey.self] = newValue }
    }

    var questoriaHighContrastUI: Bool {
        get { self[QuestoriaHighContrastUIKey.self] }
        set { self[QuestoriaHighContrastUIKey.self] = newValue }
    }
}
