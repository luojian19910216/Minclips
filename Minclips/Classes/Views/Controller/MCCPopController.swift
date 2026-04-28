import UIKit

public protocol MCPPopupPresentable: UIViewController {}

public enum MCEPopAnimationStyle {
    case topPopUp
    case easeInEaseOut
    case scaleInEaseOut
}

open class MCCPopController<View: MCCBasePopView, ViewModel: MCCBaseViewModel>: MCCViewController<View, ViewModel>, MCPPopupPresentable, UIViewControllerTransitioningDelegate {

    open var animationStyle: MCEPopAnimationStyle = .easeInEaseOut

    open var dimmingInsets: UIEdgeInsets = .zero

    open override func mcvc_init() {
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.view.frame = .init(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.size.width,
            height: UIScreen.main.bounds.size.height - dimmingInsets.top - dimmingInsets.bottom
        )

        self.contentView.dimmingView.frame = view.bounds

        let corners: UIRectCorner
        switch animationStyle {
        case .easeInEaseOut, .scaleInEaseOut: corners = .allCorners

        case .topPopUp: corners = [.bottomLeft, .bottomRight]
        }

        let mask = CAShapeLayer()
        mask.frame = contentView.cardView.bounds
        mask.path = UIBezierPath(
            roundedRect: contentView.cardView.bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: 16, height: 16)
        ).cgPath
        contentView.cardView.layer.mask = mask
    }

    open override func mcvc_bind() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hide))
        contentView.dimmingView.addGestureRecognizer(tap)
    }

    @objc
    open func hide() {
        dismiss(animated: true)
    }

    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        MCCInsetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            insets: dimmingInsets
        )
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        MCCPopAnimator(isPresenting: true, animationStyle: self.animationStyle)
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        MCCPopAnimator(isPresenting: false, animationStyle: self.animationStyle)
    }

}

public final class MCCPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    public let isPresenting: Bool

    public let animationStyle: MCEPopAnimationStyle

    public init(isPresenting: Bool, animationStyle: MCEPopAnimationStyle) {
        self.isPresenting = isPresenting
        self.animationStyle = animationStyle
    }

    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        animationStyle == .scaleInEaseOut ? 0.4 : 0.2
    }

    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        if isPresenting {
            guard
                let toVC = transitionContext.viewController(forKey: .to),

                let popView = toVC.view as? MCCBasePopView else
            {return}
            transitionContext.containerView.addSubview(toVC.view)
            toVC.view.frame = transitionContext.containerView.bounds
            toVC.view.layoutIfNeeded()
            inAnimation(popView: popView, duration: duration)
        } else {
            guard
                let fromVC = transitionContext.viewController(forKey: .from),

                let popView = fromVC.view as? MCCBasePopView
            else {return}
            outAnimation(popView: popView, duration: duration)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            transitionContext.completeTransition(true)
        }
    }

    private func inAnimation(popView: MCCBasePopView, duration: TimeInterval) {
        let card = popView.cardView

        let dimming = popView.dimmingView
        dimming.layer.add(opacityAnimation(from: 0, to: 1, duration: duration, removeOnCompletion: true), forKey: nil)
        switch animationStyle {
        case .topPopUp:
            card.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
            card.transform = CGAffineTransform(translationX: 0, y: -card.bounds.height * 0.5)
            card.layer.add(keyframeAnimation(keyPath: "bounds.size.height", values: [0, card.frame.height], duration: duration, removeOnCompletion: true), forKey: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                card.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                card.transform = .identity
            }

        case .easeInEaseOut:
            card.layer.add(opacityAnimation(from: 0, to: 1, duration: duration, removeOnCompletion: true), forKey: nil)
        case .scaleInEaseOut:
            card.layer.add(keyframeAnimation(keyPath: "transform.scale", values: [0, 1.05, 0.95, 1], duration: duration, removeOnCompletion: true), forKey: nil)
        }
    }

    private func outAnimation(popView: MCCBasePopView, duration: TimeInterval) {
        let card = popView.cardView

        let dimming = popView.dimmingView
        dimming.layer.add(opacityAnimation(from: 1, to: 0, duration: duration, removeOnCompletion: false), forKey: nil)
        switch animationStyle {
        case .topPopUp:
            card.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
            card.transform = CGAffineTransform(translationX: 0, y: -card.bounds.height * 0.5)
            card.layer.add(keyframeAnimation(keyPath: "bounds.size.height", values: [card.frame.height, 0], duration: duration, removeOnCompletion: false), forKey: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                card.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                card.transform = .identity
            }

        case .easeInEaseOut, .scaleInEaseOut:
            card.layer.add(opacityAnimation(from: 1, to: 0, duration: duration, removeOnCompletion: false), forKey: nil)
        }
    }

    private func opacityAnimation(from: CGFloat, to: CGFloat, duration: TimeInterval, removeOnCompletion: Bool) -> CAKeyframeAnimation {
        keyframeAnimation(keyPath: "opacity", values: [from, to], duration: duration, removeOnCompletion: removeOnCompletion)
    }

    private func keyframeAnimation(keyPath: String, values: [Any], duration: TimeInterval, removeOnCompletion: Bool) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation()
        animation.keyPath = keyPath
        animation.values = values
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = removeOnCompletion
        return animation
    }

}

public final class MCCInsetPresentationController: UIPresentationController {

    private let insets: UIEdgeInsets

    public init(presentedViewController: UIViewController, presenting: UIViewController?, insets: UIEdgeInsets) {
        self.insets = insets
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let parent = containerView?.superview else {return}
        containerView?.backgroundColor = .clear
        containerView?.frame = CGRect(
            x: insets.left,
            y: insets.top,
            width: parent.bounds.width - insets.left - insets.right,
            height: parent.bounds.height - insets.top - insets.bottom
        )
    }

}
