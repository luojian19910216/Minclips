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

    @objc
    open func mcvc_onProTapped() {}

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

    public static let rootTabLeftTitleSize: CGFloat = 28

    public static let proBarButtonImageSide: CGFloat = 22

    public static func leftTitleBarButtonItem(
        title: String,
        textColor: UIColor = .white
    ) -> UIBarButtonItem {
        let label = UILabel()
        label.text = title
        label.textColor = textColor
        label.font = .systemFont(ofSize: rootTabLeftTitleSize, weight: .semibold)
        label.sizeToFit()
        return UIBarButtonItem(customView: label)
    }

    public static func proBarButtonItem(
        target: Any,
        action: Selector,
        titleColor: UIColor = .white
    ) -> UIBarButtonItem {
        let b = UIButton(type: .custom)
        b.accessibilityLabel = "PRO"
        b.addTarget(target, action: action, for: .touchUpInside)
        let icon = mcv_scaledProImageOriginal()
        if let icon = icon {
            b.setImage(icon, for: .normal)
        }
        b.setTitle("PRO", for: .normal)
        b.setTitleColor(titleColor, for: .normal)
        let proFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        b.titleLabel?.font = proFont
        b.titleLabel?.lineBreakMode = .byClipping
        b.imageView?.contentMode = .scaleAspectFit
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.sizeToFit()
        b.translatesAutoresizingMaskIntoConstraints = false
        let textW = ("PRO" as NSString).size(withAttributes: [.font: proFont]).width

        let minW: CGFloat
        if icon != nil {
            minW = proBarButtonImageSide + 4 + ceil(textW) + 2
        } else {
            minW = ceil(textW) + 8
        }
        b.widthAnchor.constraint(greaterThanOrEqualToConstant: minW).isActive = true
        return UIBarButtonItem(customView: b)
    }

    private static func mcv_scaledProImageOriginal() -> UIImage? {
        guard let im = UIImage(named: "ic_nav_pro") else { return nil }
        let s = proBarButtonImageSide

        let r = UIGraphicsImageRenderer(size: CGSize(width: s, height: s))

        let drawn = r.image { _ in
            im.draw(in: CGRect(x: 0, y: 0, width: s, height: s))
        }
        return drawn.withRenderingMode(.alwaysOriginal)
    }

    public static func settingsBarButtonItem(target: Any, action: Selector) -> UIBarButtonItem {
        if let img = UIImage(named: "ic_nav_setting")?.withRenderingMode(.alwaysTemplate) {
            return UIBarButtonItem(image: img, style: .plain, target: target, action: action)
        }

        let sym = UIImage(systemName: "gearshape")
        return UIBarButtonItem(
            image: sym,
            style: .plain,
            target: target,
            action: action
        )
    }

}
