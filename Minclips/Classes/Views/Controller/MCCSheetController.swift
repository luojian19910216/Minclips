import UIKit
import Common
import PanModal

open class MCCSheetController<View: MCCBaseView, ViewModel: MCCBaseViewModel>: MCCViewController<View, ViewModel>, MCPPopupPresentable, PanModalPresentable {

    open override func mcvc_init() {
        modalPresentationStyle = .custom
        transitioningDelegate = PanModalPresentationDelegate.default
    }

    open var panScrollable: UIScrollView? { nil }

    open var topOffset: CGFloat { MCCScreenSize.topSafeHeight}

    open var shortFormHeight: PanModalHeight { longFormHeight }

    open var longFormHeight: PanModalHeight { .contentHeight(300) }

    open var cornerRadius: CGFloat { 16 }

    open var showDragIndicator: Bool { true }

    open var isHapticFeedbackEnabled: Bool { false }

    open var allowsExtendedPanScrolling: Bool { false }

}
