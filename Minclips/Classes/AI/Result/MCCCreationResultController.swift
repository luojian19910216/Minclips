import UIKit
import Common
import Combine
import Data
import FDFullscreenPopGesture
import SnapKit

public final class MCCCreationResultController: MCCViewController<MCCCreationResultView, MCCEmptyViewModel> {

    public let mccr_pageTitle: String

    public let mccr_workRef: String

    public private(set) var mccr_kind: MCCCreationResultKind

    public let mccr_seedRun: MCSRunItem?

    /// Retire success: called with trimmed **`workRef`** before pop; list removes the row.
    public var mccr_onRunRetired: ((String) -> Void)?

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

    public init(navigationTitle: String, kind: MCCCreationResultKind, workRef: String? = nil, seedRun: MCSRunItem? = nil) {
        self.mccr_pageTitle = navigationTitle
        self.mccr_workRef = workRef ?? navigationTitle
        self.mccr_kind = kind
        self.mccr_seedRun = seedRun
        super.init()
        hidesBottomBarWhenPushed = true
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        
        self.navigationItem.title = mccr_pageTitle
        self.navigationItem.rightBarButtonItem = mccr_barCircleItem(imageName: "ic_cm_run_delete", action: #selector(mccr_onDelete))
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "121212")
        contentView.backgroundColor = view.backgroundColor
        if let run = mccr_seedRun, run.contentKind.isToVideo {
            contentView.mccr_setVideoArtifactPixelDimensions(from: run)
        }
        contentView.mccr_apply(kind: mccr_kind)
        if let run = mccr_seedRun {
            contentView.mccr_bindPosterFrom(run: run)
            if run.runState == .failed {
                contentView.mccr_applyFailureSubtitle(from: run)
            }
        }
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mccr_maybeFetchRunDetail()
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

    private func mccr_barCircleItem(imageName: String, action: Selector) -> UIBarButtonItem {
        let b = UIButton(type: .custom)
        b.backgroundColor = .clear
        b.adjustsImageWhenHighlighted = false
        let img = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
        b.setImage(img, for: .normal)
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
                        guard let self else { return }
                        let ref = self.mccr_workRef.trimmingCharacters(in: .whitespacesAndNewlines)
                        if ref.isEmpty == false {
                            self.mccr_onRunRetired?(ref)
                        }
                        self.navigationController?.popViewController(animated: true)
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

    private func mccr_maybeFetchRunDetail() {
        let ref = mccr_workRef.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ref.isEmpty == false else { return }

        let needsDetail: Bool = {
            if let seed = mccr_seedRun {
                return seed.runState == .generating
            }
            return true
        }()
        guard needsDetail else { return }

        var request = MCSRunInfoRequest()
        request.workRef = ref
        MCCRunAPIManager.shared.detail(with: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] run in
                    self?.mccr_applyFetchedRun(run)
                }
            )
            .store(in: &cancellables)
    }

    private func mccr_applyFetchedRun(_ run: MCSRunItem) {
        let nextKind = run.mcc_creationResultPresentationKind()
        mccr_kind = nextKind
        let title = run.mcc_workNavigationTitlePreferringHumanReadable()
        mccr_navTitleLabel.text = title
        mccr_navTitleLabel.sizeToFit()
        if run.contentKind.isToVideo {
            contentView.mccr_setVideoArtifactPixelDimensions(from: run)
        }
        contentView.mccr_apply(kind: nextKind)
        contentView.mccr_bindPosterFrom(run: run)
        if run.runState == .failed {
            contentView.mccr_applyFailureSubtitle(from: run)
        }
    }

}

extension MCSRunItem {

    /// Mirrors project list title; used after detail fetch when only `workRef` was known.
    func mcc_workNavigationTitlePreferringHumanReadable() -> String {
        let raw = showTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty == false { return raw }
        let tmpl = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        if tmpl.isEmpty == false { return tmpl }
        let id = runId.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? "Project" : id
    }

    /// Mirrors project list → result kind mapping (list has full model; push/detail fetch supplies the rest).
    func mcc_creationResultPresentationKind() -> MCCCreationResultKind {
        switch runState {
        case .failed:
            return failureCode == .auditFail ? .restricted : .failed
        case .generating:
            if contentKind.isToVideo {
                let sec = tenSecondMode != 0 ? 10 : 5
                return .successVideo(totalDuration: TimeInterval(sec))
            }
            return .successImage
        case .success:
            if contentKind.isToVideo {
                let s = max(mcc_primaryOutputArtifactDurationSeconds(), 1)
                return .successVideo(totalDuration: TimeInterval(s))
            }
            return .successImage
        }
    }
}
