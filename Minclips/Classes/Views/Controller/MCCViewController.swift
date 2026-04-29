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

