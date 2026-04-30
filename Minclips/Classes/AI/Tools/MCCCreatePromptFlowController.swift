import UIKit
import Common
import Combine
import Data

public enum MCCCreatePromptFlowKind {
    case character
    case shot
}

public final class MCCCreatePromptFlowController: MCCViewController<MCCCreatePromptFlowView, MCCEmptyViewModel> {

    public var mcvc_promptKind: MCCCreatePromptFlowKind = .character

    private var mcvc_navCreditsBarItem: UIBarButtonItem?

    private var mcvc_integralCancellable: AnyCancellable?

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public init(kind: MCCCreatePromptFlowKind) {
        mcvc_promptKind = kind
        super.init()
        hidesBottomBarWhenPushed = true
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()

        navigationItem.title = nil
        guard let backItem = navigationItem.leftBarButtonItem else {
            mcvc_fallbackNavWithoutBalance()
            return
        }

        let titleLbl = UILabel()
        switch mcvc_promptKind {
        case .character:
            titleLbl.text = "Create Character"
        case .shot:
            titleLbl.text = "Create Shot"
        }
        titleLbl.textColor = .white
        titleLbl.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLbl.textAlignment = .center
        titleLbl.numberOfLines = 1
        titleLbl.adjustsFontSizeToFitWidth = true
        titleLbl.minimumScaleFactor = 0.85
        titleLbl.sizeToFit()

        let creditsBar = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_cm_credits")?.withRenderingMode(.alwaysOriginal),
            title: mcvc_navCreditsDisplayText(),
            target: self,
            action: #selector(mcvc_navCreditsTapped)
        )
        mcvc_navCreditsBarItem = creditsBar
        creditsBar.customView?.layoutIfNeeded()

        let backW = Self.mcvc_navBarButtonIntrinsicWidth(backItem)
        let creditsW = Self.mcvc_navBarButtonIntrinsicWidth(creditsBar)

        navigationItem.titleView = titleLbl

        let delta = creditsW - backW
        if delta > 0.5 {
            navigationItem.leftBarButtonItems = [backItem, Self.mcvc_navBarFlexibleSpacerItem(width: delta)]
            navigationItem.rightBarButtonItems = [creditsBar]
        } else if delta < -0.5 {
            navigationItem.leftBarButtonItems = [backItem]
            navigationItem.rightBarButtonItems = [creditsBar, Self.mcvc_navBarFlexibleSpacerItem(width: -delta)]
        } else {
            navigationItem.leftBarButtonItems = [backItem]
            navigationItem.rightBarButtonItems = [creditsBar]
        }
    }

    private func mcvc_fallbackNavWithoutBalance() {
        navigationItem.title = nil
        let titleLbl = UILabel()
        switch mcvc_promptKind {
        case .character:
            titleLbl.text = "Create Character"
        case .shot:
            titleLbl.text = "Create Shot"
        }
        titleLbl.textColor = .white
        titleLbl.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLbl.textAlignment = .center
        titleLbl.sizeToFit()

        let creditsBar = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_cm_credits")?.withRenderingMode(.alwaysOriginal),
            title: mcvc_navCreditsDisplayText(),
            target: self,
            action: #selector(mcvc_navCreditsTapped)
        )
        mcvc_navCreditsBarItem = creditsBar
        navigationItem.titleView = titleLbl
        navigationItem.rightBarButtonItem = creditsBar
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let v = contentView
        view.backgroundColor = UIColor(hex: "0F0F12")

        let ph: String
        let cta: String
        let heroAsset: String
        switch mcvc_promptKind {
        case .character:
            ph = "Describe what character you want"
            cta = "Continue + 250"
            heroAsset = "ic_bg_toImage"
            v.mcvw_trashFooter.isHidden = true
        case .shot:
            ph = "Describe what shot you want"
            cta = "Continue + 250"
            heroAsset = "ic_bg_toVideo"
            v.mcvw_trashFooter.isHidden = false
        }
        v.mcvw_setHeroImage(UIImage(named: heroAsset))
        v.mcvw_setShotSettingsVisible(mcvc_promptKind == .shot)
        let p = NSMutableParagraphStyle()
        p.lineSpacing = 2
        v.mcvw_textView.attributedText = NSAttributedString(
            string: ph,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.white.withAlphaComponent(0.35),
                .paragraphStyle: p
            ]
        )
        v.mcvw_continueButton.setTitle(cta, for: .normal)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mcvc_refreshIntegralStatement()
    }

    public override func mcvc_bind() {
        super.mcvc_bind()

        MCCAccountService.shared.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.mcvc_refreshNavCreditsDisplay()
            }
            .store(in: &cancellables)

        mcvc_observeKeyboardNotifications()
        mcvc_installDismissTap()
    }

    @objc
    private func mcvc_navCreditsTapped() {
        let vc = MCCProController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func mcvc_navCreditsDisplayText() -> String {
        let n = max(0, MCCAccountService.shared.currentUser.value?.pointsBalance ?? 0)
        return NumberFormatter.localizedString(from: NSNumber(value: n), number: .decimal)
    }

    private func mcvc_refreshNavCreditsDisplay() {
        let t = mcvc_navCreditsDisplayText()
        MCCRootTabNavChrome.updateCapsuleBarButtonItem(mcvc_navCreditsBarItem, title: t)
    }

    private func mcvc_refreshIntegralStatement() {
        guard MCCAccountService.shared.currentUser.value != nil else { return }
        mcvc_integralCancellable?.cancel()
        mcvc_integralCancellable = MCCUmAPIManager.shared.integralStatement()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { balance in
                    MCCAccountService.shared.update {
                        $0.pointsBalance = max(0, balance)
                    }
                }
            )
    }

}

extension MCCCreatePromptFlowController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touched = touch.view else { return true }
        if touched.isDescendant(of: contentView.mcvw_textView) { return false }
        return true
    }
}

private extension MCCCreatePromptFlowController {

    static func mcvc_navBarButtonIntrinsicWidth(_ item: UIBarButtonItem) -> CGFloat {
        if let v = item.customView {
            v.setNeedsLayout()
            v.layoutIfNeeded()
            var w = v.bounds.width
            if w <= 0.5 {
                v.sizeToFit()
                w = v.bounds.width
            }
            if w <= 0.5 {
                let fit = v.systemLayoutSizeFitting(
                    CGSize(width: UIView.layoutFittingCompressedSize.width, height: 44),
                    withHorizontalFittingPriority: .fittingSizeLevel,
                    verticalFittingPriority: .required
                )
                w = fit.width
            }
            if w > 0.5 { return w }
        }
        return 44
    }

    static func mcvc_navBarFlexibleSpacerItem(width: CGFloat) -> UIBarButtonItem {
        let w = max(0, width)
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: w),
            v.heightAnchor.constraint(equalToConstant: 44)
        ])
        return UIBarButtonItem(customView: v)
    }

    func mcvc_observeKeyboardNotifications() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.contentView.mcvw_setKeyboardActive(true, animated: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.contentView.mcvw_setKeyboardActive(false, animated: true)
            }
            .store(in: &cancellables)
    }

    func mcvc_installDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(mcvc_dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    @objc
    func mcvc_dismissKeyboard() {
        view.endEditing(true)
    }
}
