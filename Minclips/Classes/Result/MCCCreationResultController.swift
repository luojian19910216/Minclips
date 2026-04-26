import UIKit
import Common
import FDFullscreenPopGesture
import SnapKit

/// 生成结果 / 错误态（纯 UI，业务与接口后续再接）
public final class MCCCreationResultController: MCCViewController<MCCCreationResultView, MCCEmptyViewModel> {

    public let mccr_pageTitle: String
    public let mccr_kind: MCCCreationResultKind

    public init(navigationTitle: String, kind: MCCCreationResultKind) {
        self.mccr_pageTitle = navigationTitle
        self.mccr_kind = kind
        super.init()
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
    }
    
    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "121212")
        contentView.backgroundColor = view.backgroundColor
        contentView.mccr_apply(kind: mccr_kind)
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        contentView.mccr_actionButton.addTarget(self, action: #selector(mccr_onPrimaryAction), for: .touchUpInside)
    }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        nav.navigationBar.mc_barStyle = .transparentLight
        nav.navigationBar.mc_shadowHidden = true
        let item = navigationItem
        item.title = nil
        item.largeTitleDisplayMode = .never
        nav.navigationBar.prefersLargeTitles = false
        let t = UILabel()
        t.text = mccr_pageTitle
        t.textColor = .white
        t.font = .systemFont(ofSize: 17, weight: .semibold)
        t.sizeToFit()
        item.titleView = t
        item.leftBarButtonItem = mccr_barCircleItem(systemName: "chevron.left", action: #selector(mccr_onBack))
        item.rightBarButtonItem = mccr_barCircleItem(systemName: "trash", action: #selector(mccr_onDelete))
    }

    private func mccr_barCircleItem(systemName: String, action: Selector) -> UIBarButtonItem {
        let b = UIButton(type: .custom)
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        b.backgroundColor = UIColor(white: 0, alpha: 0.35)
        let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        b.setImage(UIImage(systemName: systemName, withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        b.snp.makeConstraints { $0.size.equalTo(36) }
        b.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: b)
    }

    @objc
    private func mccr_onBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func mccr_onDelete() {
    }

    @objc
    private func mccr_onPrimaryAction() {
    }
}
