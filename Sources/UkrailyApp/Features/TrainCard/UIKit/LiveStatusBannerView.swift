import UIKit
import SwiftUI

final class LiveStatusBannerUIView: UIView {

    private let label = UILabel()
    private var isVisible = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
        layer.cornerRadius = 10
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -60)
    }

    func show(message: String, autoDismissAfter delay: TimeInterval = 3.5) {
        label.text = message
        UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.7) {
            self.alpha = 1
            self.transform = .identity
        }.startAnimation()

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.hide()
        }
    }

    func hide() {
        UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -60)
        }.startAnimation()
    }
}

struct LiveStatusBanner: UIViewRepresentable {

    @Binding var message: String?

    func makeUIView(context: Context) -> LiveStatusBannerUIView {
        LiveStatusBannerUIView()
    }

    func updateUIView(_ uiView: LiveStatusBannerUIView, context: Context) {
        if let msg = message {
            uiView.show(message: msg)
        }
    }
}
