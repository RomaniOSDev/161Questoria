import SwiftUI

struct GeometryScaler {
    let size: CGSize
    private let reference = CGSize(width: 400, height: 680)

    func point(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(
            x: x * size.width / reference.width,
            y: y * size.height / reference.height
        )
    }
}
