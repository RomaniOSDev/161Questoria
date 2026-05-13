import SwiftUI

/// Lightweight ambient motion: low particle count, no blur, modest refresh rate — keeps scrolling smooth.
struct PlayAnimatedBackdropView: View {
    @Environment(\.questoriaReducedVisualEffects) private var reducedEffects

    var body: some View {
        Group {
            if reducedEffects {
                Color.clear
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let particleCount = 18
                        for index in 0 ..< particleCount {
                            let x = CGFloat(index) / CGFloat(particleCount) * size.width
                            let wave = sin(time * 1.15 + Double(index) * 0.42) * 16
                            let y = size.height * 0.34 + wave
                            let rect = CGRect(x: x, y: y, width: 5, height: 5)
                            let opacity = 0.07 + CGFloat(sin(time * 0.9 + Double(index))) * 0.035
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(Color.appAccent.opacity(Double(opacity)))
                            )
                        }

                        for ring in 0 ..< 3 {
                            let radius = CGFloat(56 + ring * 52) + CGFloat(sin(time * 0.95 + Double(ring))) * 8
                            let center = CGPoint(x: size.width * 0.26 + CGFloat(ring * 16), y: size.height * 0.17)
                            let circle = Path(ellipseIn: CGRect(x: center.x - radius / 2, y: center.y - radius / 2, width: radius, height: radius))
                            context.stroke(circle, with: .color(Color.appPrimary.opacity(0.065)), lineWidth: 1.5)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
        }
    }
}
