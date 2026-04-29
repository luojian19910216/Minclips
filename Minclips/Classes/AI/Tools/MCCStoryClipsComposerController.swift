import UIKit
import Common
public final class MCCStoryClipsComposerController: MCCViewController<MCCStoryClipsComposerView, MCCEmptyViewModel> {

    public override init() {
        super.init()
        hidesBottomBarWhenPushed = true
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        nav.navigationBar.mc_barStyle = .transparentLight
        nav.navigationBar.mc_shadowHidden = true
        navigationItem.title = nil
        let title = UILabel()
        title.text = "Create Story Clips"
        title.textColor = .white
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        title.sizeToFit()
        navigationItem.titleView = title
        navigationItem.leftBarButtonItem = mcvc_circleBackItem()
        navigationItem.rightBarButtonItem = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_cm_credits")?.withRenderingMode(.alwaysOriginal),
            title: "+ 9999"
        )
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let v = contentView
        view.backgroundColor = UIColor(hex: "0F0F12")
        let p = NSMutableParagraphStyle()
        p.lineSpacing = 2
        v.mcvw_promptTextView.attributedText = NSAttributedString(
            string: "Describe your desired shot.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.white.withAlphaComponent(0.35),
                .paragraphStyle: p
            ]
        )
        v.mcvw_continueButton.setTitle("Continue + 250", for: .normal)
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
