import UIKit
import Common
import PanModal
import SDWebImage
import Combine
import CombineCocoa

public final class MCCFeedGeneratingSheetController: MCCSheetController<MCCFeedGeneratingView, MCCEmptyViewModel> {

    public var mcvc_dismiss: (() -> Void)?

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

    public func mcvc_setPosterFromURLString(_ urlString: String) {
        let v = contentView.mcvw_previewImageView
        if let u = URL(string: urlString), !urlString.isEmpty {
            v.sd_setImage(with: u, placeholderImage: nil, options: [])
        } else {
            v.sd_cancelCurrentImageLoad()
            v.image = nil
        }
    }

    private func mcvc_dismissAndPopRootSwitchTab(selectedIndex: Int) {
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
