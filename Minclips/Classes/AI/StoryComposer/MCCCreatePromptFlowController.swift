import UIKit
import Common
public enum MCCCreatePromptFlowKind {
    case character
    case shot
}

public final class MCCCreatePromptFlowController: MCCViewController<MCCCreatePromptFlowView, MCCEmptyViewModel> {

    public var mcvc_promptKind: MCCCreatePromptFlowKind = .character

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public init(kind: MCCCreatePromptFlowKind) {
        mcvc_promptKind = kind
        super.init()
        hidesBottomBarWhenPushed = true
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        nav.navigationBar.mc_barStyle = .transparentLight
        nav.navigationBar.mc_shadowHidden = true
        navigationItem.title = nil
        let title = UILabel()
        switch mcvc_promptKind {
        case .character:
            title.text = "Create Character"
        case .shot:
            title.text = "Create Shot"
        }
        title.textColor = .white
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        title.sizeToFit()
        navigationItem.titleView = title
        navigationItem.leftBarButtonItem = mcvc_circleBackItem()
        navigationItem.rightBarButtonItem = MCCRootTabNavChrome.feedCreditsBarButtonItem(amount: "+ 9999", target: nil, action: nil)
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let v = contentView
        view.backgroundColor = UIColor(hex: "0F0F12")

        let ph: String
        let cta: String
        switch mcvc_promptKind {
        case .character:
            ph = "Describe what character you want"
            cta = "Continue + 250"
            v.mcvw_trashFooter.isHidden = true
        case .shot:
            ph = "Describe what shot you want"
            cta = "Continue + 250"
            v.mcvw_trashFooter.isHidden = false
        }
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

    private func mcvc_circleBackItem() -> UIBarButtonItem {
        let b = UIButton(type: .custom)
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        b.backgroundColor = UIColor(white: 0, alpha: 0.35)
        let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        b.addTarget(self, action: #selector(mcvc_back), for: .touchUpInside)
        b.bounds = CGRect(x: 0, y: 0, width: 36, height: 36)
        return UIBarButtonItem(customView: b)
    }

    @objc
    private func mcvc_back() {
        navigationController?.popViewController(animated: true)
    }
}
