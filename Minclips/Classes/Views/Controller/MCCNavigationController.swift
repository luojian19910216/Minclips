import UIKit

open class MCCNavigationController: UINavigationController {

    open override var shouldAutorotate: Bool {
        return self.topViewController?.shouldAutorotate ?? false
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.topViewController?.supportedInterfaceOrientations ?? .portrait
    }

    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }

    open override var childForStatusBarHidden: UIViewController? {
        return self.topViewController
    }

    open override var childForStatusBarStyle: UIViewController? {
        return self.topViewController
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }

}

extension MCCNavigationController: UINavigationControllerDelegate {

    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            if (toVC as? MCPNavigationControllerTransactionDelegate)?.transactionStyle == .bottom {
                let animator = MCCBottomAnimator()
                animator.isPresenting = true
                return animator
            }

        case .pop:
            if (fromVC as? MCPNavigationControllerTransactionDelegate)?.transactionStyle == .bottom {
                let animator = MCCBottomAnimator()
                animator.isPresenting = false
                return animator
            }
        default: break
        }
        return nil
    }

}

public final class MCCBottomAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    public var isPresenting: Bool = true

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        let duration = transitionDuration(using: transitionContext)
        if isPresenting {
            guard let toVC = transitionContext.viewController(forKey: .to) else { return }
            container.addSubview(toVC.view)

            let finalFrame = transitionContext.finalFrame(for: toVC)
            toVC.view.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.height)

            UIView.animate(withDuration: duration) {
                toVC.view.frame = finalFrame
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            guard
                let fromVC = transitionContext.viewController(forKey: .from),

                let toVC = transitionContext.viewController(forKey: .to)
            else { return }
            container.insertSubview(toVC.view, belowSubview: fromVC.view)

            let initialFrame = fromVC.view.frame

            UIView.animate(withDuration: duration) {
                fromVC.view.frame = initialFrame.offsetBy(dx: 0, dy: initialFrame.height)
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }

}
