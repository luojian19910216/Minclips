import UIKit
import Common
import Combine
import FDFullscreenPopGesture

public enum MCETransactionStyle {
    case normal
    case bottom
}

public protocol MCPNavigationControllerTransactionDelegate {
    var transactionStyle: MCETransactionStyle {get}
}

public protocol MCPViewControllerInitProtocol {
    
    func mcvc_init()

    func mcvc_configureNav()

    func mcvc_setupLocalization()

    func mcvc_bind()

    func mcvc_loadData()

}

open class MCCViewControllerCore: UIViewController, MCPViewControllerInitProtocol, MCPNavigationControllerTransactionDelegate {

    private var notificationCancellables = Set<AnyCancellable>()

    open override var shouldAutorotate: Bool {
        return false
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    open override var prefersStatusBarHidden: Bool {
        return false
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    open var transactionStyle: MCETransactionStyle {
        return .normal
    }

    open override var fd_interactivePopDisabled: Bool {
        get { transactionStyle != .normal }
        set {}
    }

    required
    public init?(coder: NSCoder) { fatalError() }

    public init() {
        super.init(nibName: nil, bundle: nil)

        self.mcvc_init()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(hex: "0F0F12")

        self.mcvc_setupLocalization()
        self.mcvc_bind()
        self.mcvc_loadData()

        self.registerNotifications()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.fd_prefersNavigationBarHidden {
            self.mcvc_configureNav()
        }

        self.setNeedsStatusBarAppearanceUpdate()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard navigationController?.topViewController != self else { return }
        var current: UIViewController? = presentedViewController
        while let vc = current {
            if vc is MCPPopupPresentable {
                vc.dismiss(animated: false)
                return
            }
            current = vc.presentedViewController
        }
    }

    open override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if let vc = self.presentedViewController {
            if !vc.isKind(of: viewControllerToPresent.classForCoder) {
                vc.dismiss(animated: true) {
                    super.present(viewControllerToPresent, animated: flag, completion: completion)
                }
            }
            return
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    deinit {
        print("Controller deinit（\(self.classForCoder), title: \(self.title ?? "")）")
    }

    open func mcvc_init() {}

    @objc dynamic
    open func mcvc_configureNav() {}

    open func mcvc_needLeftBarButtonItem() -> Bool {
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }

    @objc
    open func mcvc_leftBarButtonItemAction() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    open func mcvc_rightBarButtonItemAction() {}

    open func mcvc_setupLocalization() {}

    open func mcvc_bind() {}

    open func mcvc_loadData() {}

    private func registerNotifications() {
        NotificationCenter.default.publisher(for: .languageUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.mcvc_setupLocalization()
                self.mcvc_configureNav()
            }
            .store(in: &notificationCancellables)
    }

}

open class MCCViewController<View: MCCBaseView, ViewModel: MCCBaseViewModel>: MCCViewControllerCore {

    public var cancellables = Set<AnyCancellable>()

    public lazy var viewModel: ViewModel = {
        let item: ViewModel = .init()
        return item
    }()

    public var contentView: View {
        return self.view as! View
    }

    public override func loadView() {
        self.view = View()
    }

}

public enum MCCRootTabNavChrome {

    public static func leftTitleBarButtonItem(title: String, ) -> UIBarButtonItem {
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = .systemFont(ofSize: 32, weight: .semibold)
        label.sizeToFit()
        let item = UIBarButtonItem(customView: label)
        if #available(iOS 26.0, *) {
            item.hidesSharedBackground = true
        }
        return item
    }

    public static func proBarButtonItem(
        target: Any,
        action: Selector,
        titleColor: UIColor = .white
    ) -> UIBarButtonItem {
        let b: UIButton = .init()
        b.frame = .init(x: 0, y: 0, width: 76, height: 44)
        b.setImage(UIImage(named: "ic_nav_pro"), for: .normal)
        b.setTitle("PRO", for: .normal)
        b.setTitleColor(titleColor, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        b.contentEdgeInsets = .init(top: 0, left: 12, bottom: 0, right: 17)
        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        b.layer.cornerRadius = 22
        b.clipsToBounds = true
        b.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: b)
    }

    public static func settingsBarButtonItem(target: Any, action: Selector) -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage(named: "ic_nav_setting")?.withRenderingMode(.alwaysTemplate), style: .plain, target: target, action: action)
    }

    /// Feed 详情：导航栏积分胶囊 —— `ic_cm_credits` + 数值（排版与 `proBarButtonItem` 同套路）。
    public static func feedCreditsBarButtonItem(amount: String, target: Any? = nil, action: Selector? = nil) -> UIBarButtonItem {
        let b = UIButton(type: .custom)
        b.frame = CGRect(x: 0, y: 0, width: 76, height: 44)
        b.setImage(UIImage(named: "ic_cm_credits")?.withRenderingMode(.alwaysOriginal), for: .normal)
        b.setTitle(amount, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 17)
        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        b.layer.cornerRadius = 22
        b.clipsToBounds = true
        b.adjustsImageWhenHighlighted = false
        if let target, let action {
            b.addTarget(target, action: action, for: .touchUpInside)
        }
        return UIBarButtonItem(customView: b)
    }

    /// Feed 详情：导航栏举报 —— `ic_nav_report`，原图着色（不参与导航栏 tint 模板）。
    public static func feedReportBarButtonItem(target: Any, action: Selector) -> UIBarButtonItem {
        UIBarButtonItem(
            image: UIImage(named: "ic_nav_report")?.withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: target,
            action: action
        )
    }

}
