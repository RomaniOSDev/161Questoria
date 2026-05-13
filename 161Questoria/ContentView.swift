//
//  ContentView.swift
//  161Questoria
//
//  Created by Roman on 5/13/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var progress = ProgressStore()
    @ObservedObject private var accessibility = AccessibilityPreferencesStore.shared

    var body: some View {
        Group {
            if progress.hasSeenOnboarding {
                MainTabShellView()
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(progress)
        .environmentObject(accessibility)
        .environment(\.dynamicTypeSize, accessibility.preferredDynamicTypeSize)
        .environment(\.questoriaReducedVisualEffects, accessibility.reducedVisualEffects)
        .environment(\.questoriaHighContrastUI, accessibility.highContrastUI)
    }
}

#Preview {
    ContentView()
}
