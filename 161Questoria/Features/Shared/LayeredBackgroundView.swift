import SwiftUI

struct LayeredBackgroundView: View {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appBackground,
                    Color.appSurface.opacity(0.55),
                    Color.appBackground.opacity(0.96),
                    Color.appPrimary.opacity(0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if reducedEffects == false {
                RadialGradient(
                    colors: [Color.appPrimary.opacity(0.22), Color.clear],
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 340
                )
                RadialGradient(
                    colors: [Color.appAccent.opacity(0.18), Color.clear],
                    center: UnitPoint(x: 0.08, y: 0.92),
                    startRadius: 30,
                    endRadius: 380
                )
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.11)],
                    startPoint: UnitPoint(x: 0.5, y: 0.42),
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                Canvas { context, size in
                    let spacing: CGFloat = 56
                    for row in stride(from: 0 as CGFloat, to: size.height + spacing, by: spacing) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: row))
                        path.addLine(to: CGPoint(x: size.width, y: row + spacing * 0.35))
                        context.stroke(
                            path,
                            with: .color(Color.appAccent.opacity(0.045)),
                            lineWidth: 1
                        )
                    }
                    for col in stride(from: 0 as CGFloat, to: size.width + spacing, by: spacing) {
                        var path = Path()
                        path.move(to: CGPoint(x: col, y: 0))
                        path.addLine(to: CGPoint(x: col + spacing * 0.2, y: size.height))
                        context.stroke(
                            path,
                            with: .color(Color.appPrimary.opacity(0.045)),
                            lineWidth: 1
                        )
                    }
                }
                .drawingGroup(opaque: false)
            }
        }
        .ignoresSafeArea()
    }
}

struct PrimaryProminentButtonStyle: ButtonStyle {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.headline)
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(buttonFill(isPressed: pressed))
            }
            .shadow(
                color: reducedEffects ? .clear : Color.appPrimary.opacity(pressed ? 0.22 : 0.38),
                radius: reducedEffects ? 0 : 14,
                x: 0,
                y: reducedEffects ? 0 : 8
            )
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: pressed)
    }

    private func buttonFill(isPressed: Bool) -> LinearGradient {
        if reducedEffects {
            return LinearGradient(
                colors: [
                    Color.appPrimary.opacity(isPressed ? 0.78 : 1),
                    Color.appPrimary.opacity(isPressed ? 0.72 : 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color.appPrimary.opacity(isPressed ? 0.82 : 1),
                Color.appAccent.opacity(isPressed ? 0.68 : 0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct SecondaryOutlineButtonStyle: ButtonStyle {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.headline)
            .foregroundStyle(Color.appTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurface.opacity(pressed ? 0.92 : 0.72),
                                    Color.appSurface.opacity(pressed ? 0.78 : 0.52)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(reducedEffects ? 0.48 : 0.72),
                                    Color.appPrimary.opacity(reducedEffects ? 0.22 : 0.38)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: reducedEffects ? 1 : 1.5
                        )
                }
            }
            .shadow(
                color: reducedEffects ? .clear : Color.black.opacity(pressed ? 0.06 : 0.14),
                radius: reducedEffects ? 0 : 10,
                x: 0,
                y: reducedEffects ? 0 : 6
            )
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: pressed)
    }
}

struct RedFlashOverlay: View {
    @Binding var isVisible: Bool

    var body: some View {
        GeometryReader { proxy in
            Color.red.opacity(isVisible ? 0.45 : 0)
                .ignoresSafeArea()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}

struct ScrollScreenContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
        }
    }
}
