import UIKit
import Common
import PanModal
import SDWebImage
import Combine
import CombineCocoa

public final class MCCFeedGeneratingSheetController: MCCSheetController<MCCFeedGeneratingView, MCCEmptyViewModel> {

    public var mcvc_dismiss: (() -> Void)?

    public func mcvc_markGenerationSucceeded() {
        mcvc_resultReceived = true
        mcvc_stopProgressTicker()
        contentView.mcvw_percentLabel.text = "100%"
    }

    private var mcvc_resultReceived = false
    private var mcvc_simulationStart: Date?
    private var mcvc_progressTicker: AnyCancellable?

    public override var longFormHeight: PanModalHeight { .maxHeight }
    public override var showDragIndicator: Bool { false }
    public override var cornerRadius: CGFloat { 24 }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let v = contentView
        v.mcvw_percentLabel.text = "0%"
        v.mcvw_titleLabel.text = "Generating"
        v.mcvw_subtitleLabel.text = "Please check in Projects later."
        v.mcvw_exploreButton.setTitle("Explore", for: .normal)
        v.mcvw_projectsButton.setTitle("Projects", for: .normal)
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let v = contentView
        v.mcvw_closeButton.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true) {
                    self.mcvc_dismiss?()
                }
            }
            .store(in: &cancellables)
        v.mcvw_exploreButton.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] in
                self?.mcvc_dismissAndPopRootSwitchTab(selectedIndex: 0)
            }
            .store(in: &cancellables)
        v.mcvw_projectsButton.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] in
                self?.mcvc_dismissAndPopRootSwitchTab(selectedIndex: 2)
            }
            .store(in: &cancellables)
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        mcvc_startProgressSimulation()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            mcvc_stopProgressTicker()
        }
    }

    public func mcvc_setPosterFromURLString(_ urlString: String) {
        let v = contentView.mcvw_previewImageView
        if let u = URL(string: urlString), !urlString.isEmpty {
            v.sd_setImage(with: u, placeholderImage: nil, options: [])
        } else {
            v.sd_cancelCurrentImageLoad()
            v.image = nil
        }
    }

    private func mcvc_startProgressSimulation() {
        guard mcvc_progressTicker == nil else { return }
        mcvc_resultReceived = false
        mcvc_simulationStart = Date()
        mcvc_progressTicker = Timer.publish(every: 0.08, on: RunLoop.main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.mcvc_applySimulatedProgress()
            }
    }

    private func mcvc_stopProgressTicker() {
        mcvc_progressTicker?.cancel()
        mcvc_progressTicker = nil
    }

    private func mcvc_applySimulatedProgress() {
        guard !mcvc_resultReceived else {
            mcvc_stopProgressTicker()
            return
        }
        guard let start = mcvc_simulationStart else {
            mcvc_simulationStart = Date()
            return
        }
        let elapsed = Date().timeIntervalSince(start)
        let display = Self.mcvc_simulatedPercent(atElapsed: elapsed)
        contentView.mcvw_percentLabel.text = "\(display)%"
        if elapsed >= 120 && display == 99 {
            mcvc_stopProgressTicker()
        }
    }

    private static func mcvc_simulatedPercent(atElapsed elapsed: TimeInterval) -> Int {
        if elapsed <= 15 {
            return min(30, Int((elapsed / 15 * 30).rounded(.towardZero)))
        }
        if elapsed <= 90 {
            let t = elapsed - 15
            return min(
                85,
                max(31, Int((31 + t / 75 * (85 - 31)).rounded(.towardZero))))
        }
        if elapsed <= 120 {
            let t = elapsed - 90
            return min(
                99,
                max(86, Int((86 + t / 30 * (99 - 86)).rounded(.towardZero))))
        }
        return 99
    }

    private func mcvc_dismissAndPopRootSwitchTab(selectedIndex: Int) {
        mcvc_stopProgressTicker()
        guard let presenter = presentingViewController else {
            dismiss(animated: true)
            return
        }
        let nav = (presenter as? UINavigationController) ?? presenter.navigationController
        let tabBar =
            presenter.tabBarController as? MCCTabBarController
            ?? nav?.viewControllers.compactMap({ $0 as? MCCTabBarController }).first
        dismiss(animated: true) {
            nav?.popToRootViewController(animated: true)
            tabBar?.selectedIndex = selectedIndex
        }
    }
}
