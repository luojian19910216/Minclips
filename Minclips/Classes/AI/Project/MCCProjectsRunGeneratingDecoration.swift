import UIKit

enum MCCGenerationProgressSimulation {

    static func percent(elapsedSinceStart: TimeInterval) -> Int {
        let elapsed = max(0, elapsedSinceStart)
        if elapsed <= 15 {
            return min(30, Int((elapsed / 15 * 30).rounded(.towardZero)))
        }
        if elapsed <= 90 {
            let t = elapsed - 15
            return min(
                85,
                max(31, Int((31 + t / 75 * (85 - 31)).rounded(.towardZero))))
        }
        if elapsed <= 120 {
            let t = elapsed - 90
            return min(
                99,
                max(86, Int((86 + t / 30 * (99 - 86)).rounded(.towardZero))))
        }
        return 99
    }
}

final class MCCRunGeneratingShimmerView: UIView {

    private let shimmerLayer = CAGradientLayer()

    private var mcvw_animating = false

    private var mcvw_lastLayoutSize = CGSize(width: -1, height: -1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
        layer.addSublayer(shimmerLayer)
        shimmerLayer.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.11).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        shimmerLayer.locations = [0.28, 0.5, 0.72]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.opacity = 0.52
        shimmerLayer.drawsAsynchronously = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height
        guard w > 2, h > 2 else { return }
        let size = CGSize(width: w, height: h)
        guard size != mcvw_lastLayoutSize else { return }
        mcvw_lastLayoutSize = size

        let stripeW = max(w, h) * 2.05
        let stripeH = max(w, h) * 2.05
        shimmerLayer.bounds = CGRect(x: 0, y: 0, width: stripeW * 0.5, height: stripeH)
        shimmerLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        shimmerLayer.position = CGPoint(x: -stripeW * 0.3, y: h * 0.5)
        shimmerLayer.transform = CATransform3DIdentity
        if mcvw_animating {
            mcvw_restartSweepAnimation()
        }
    }

    func mcvw_startAnimating() {
        mcvw_animating = true
        mcvw_restartSweepAnimation()
    }

    func mcvw_stopAnimating() {
        mcvw_animating = false
        shimmerLayer.removeAnimation(forKey: "mcvw_shimmerSweep")
        shimmerLayer.opacity = 0.52
        mcvw_lastLayoutSize = CGSize(width: -1, height: -1)
    }

    private func mcvw_restartSweepAnimation() {
        shimmerLayer.removeAnimation(forKey: "mcvw_shimmerSweep")
        let w = bounds.width
        guard w > 2 else { return }

        let startPx = shimmerLayer.position.x
        let band = max(shimmerLayer.bounds.width, shimmerLayer.bounds.height)
        let travel = w + band * 3.25
        let endPx = startPx + travel

        let sweep = CABasicAnimation(keyPath: "position.x")
        sweep.fromValue = startPx
        sweep.toValue = endPx
        sweep.duration = 4.8
        sweep.repeatCount = .infinity
        sweep.autoreverses = false
        sweep.timingFunction = CAMediaTimingFunction(name: .linear)
        sweep.isRemovedOnCompletion = false
        sweep.fillMode = .forwards
        shimmerLayer.add(sweep, forKey: "mcvw_shimmerSweep")
    }
}
