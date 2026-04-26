import UIKit
import Common
import Combine
import Data
import FDFullscreenPopGesture
import SnapKit

public final class MCCCreationResultController: MCCViewController<MCCCreationResultView, MCCEmptyViewModel> {

    public let mccr_pageTitle: String

    public let mccr_workRef: String

    public let mccr_kind: MCCCreationResultKind

    private lazy var mccr_navTitleLabel: UILabel = {
        let t = UILabel()
        t.textColor = .white
        t.font = .systemFont(ofSize: 17, weight: .semibold)
        t.textAlignment = .center
        t.numberOfLines = 1
        t.adjustsFontSizeToFitWidth = true
        t.minimumScaleFactor = 0.75
        return t
    }()

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public init(navigationTitle: String, kind: MCCCreationResultKind, workRef: String? = nil) {
        self.mccr_pageTitle = navigationTitle
        self.mccr_workRef = workRef ?? navigationTitle
        self.mccr_kind = kind
        super.init()
        hidesBottomBarWhenPushed = true
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
    }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        nav.navigationBar.mc_barStyle = .transparentLight
        nav.navigationBar.mc_shadowHidden = true
        let item = navigationItem
        item.title = nil
        item.largeTitleDisplayMode = .never
        nav.navigationBar.prefersLargeTitles = false
        mccr_navTitleLabel.text = mccr_pageTitle
        mccr_navTitleLabel.sizeToFit()
        item.titleView = mccr_navTitleLabel
        item.leftBarButtonItem = mccr_barCircleItem(systemName: "chevron.left", action: #selector(mccr_onBack))
        item.rightBarButtonItem = mccr_barCircleItem(systemName: "trash", action: #selector(mccr_onDelete))
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
        contentView.mccr_onSuccessToolbar = { [weak self] action in
            self?.mccr_handleSuccessToolbar(action)
        }
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
        mccr_presentDeleteConfirm()
    }

    private func mccr_presentDeleteConfirm() {
        let pop = MCCDeleteConfirmPopController()
        pop.onConfirmDelete = { [weak self, weak pop] in
            self?.mccr_retireCurrentRun(pop: pop)
        }
        present(pop, animated: true)
    }

    private func mccr_retireCurrentRun(pop: MCCDeleteConfirmPopController?) {
        let ref = mccr_workRef.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ref.isEmpty else {
            pop?.mccd_setDeleteEnabled(true)
            return
        }

        var request = MCSRunDeleteRequest()
        request.workRef = ref
        MCCRunAPIManager.shared.retire(with: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak pop] completion in
                    if case .failure = completion {
                        pop?.mccd_setDeleteEnabled(true)
                    }
                },
                receiveValue: { [weak self, weak pop] _ in
                    pop?.dismiss(animated: true) {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            )
            .store(in: &cancellables)
    }

    @objc
    private func mccr_onPrimaryAction() {
    }

    private func mccr_handleSuccessToolbar(_ action: MCCCreationSuccessToolbarAction) {
        switch action {
        case .retry: break

        case .edit: break

        case .save: break
        }
    }

}
