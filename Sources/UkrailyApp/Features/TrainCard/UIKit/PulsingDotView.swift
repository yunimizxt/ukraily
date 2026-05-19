import UIKit
import SwiftUI

// UIKit CAReplicatorLayer pulse — sustained animation across SwiftUI state changes
final class PulsingDotUIView: UIView {

    private let dotLayer = CALayer()
    private let replicatorLayer = CAReplicatorLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let size: CGFloat = 10
        dotLayer.bounds = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        dotLayer.cornerRadius = size / 2
        dotLayer.backgroundColor = UIColor.systemGreen.cgColor
        dotLayer.position = CGPoint(x: size / 2, y: size / 2)

        replicatorLayer.addSublayer(dotLayer)
        replicatorLayer.instanceCount = 3
        replicatorLayer.instanceDelay = 0.4
        layer.addSublayer(replicatorLayer)

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 2.5
        pulse.duration = 1.2
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1.0
        fade.toValue = 0.0
        fade.duration = 1.2
        fade.repeatCount = .infinity
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

        dotLayer.add(pulse, forKey: "pulse")
        dotLayer.add(fade, forKey: "fade")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        replicatorLayer.frame = bounds
        dotLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

// SwiftUI wrapper
struct PulsingDotView: UIViewRepresentable {
    func makeUIView(context: Context) -> PulsingDotUIView { PulsingDotUIView() }
    func updateUIView(_ uiView: PulsingDotUIView, context: Context) {}
}
