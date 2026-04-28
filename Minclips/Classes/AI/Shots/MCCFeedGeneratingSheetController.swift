import UIKit
import Common
import PanModal
import SDWebImage

public final class MCCFeedGeneratingSheetController: MCCSheetController<MCCFeedGeneratingView, MCCEmptyViewModel> {

    public var mcvc_dismiss: (() -> Void)?

    public override var longFormHeight: PanModalHeight { .maxHeight }
    public override var showDragIndicator: Bool { false }
    public override var cornerRadius: CGFloat { 24 }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        let v = contentView
        v.mcvw_closeButton.accessibilityLabel = "Close"
        v.mcvw_percentLabel.text = "0%"
        v.mcvw_titleLabel.text = "Generating"
        v.mcvw_subtitleLabel.text = "Please check in Projects later."
        v.mcvw_exploreButton.setTitle("Explore", for: .normal)
        v.mcvw_projectsButton.setTitle("Projects", for: .normal)
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        
        let v = contentView
        v.mcvw_closeButton.addTarget(self, action: #selector(mcvc_tapClose), for: .touchUpInside)
        v.mcvw_exploreButton.addTarget(self, action: #selector(mcvc_tapExplore), for: .touchUpInside)
        v.mcvw_projectsButton.addTarget(self, action: #selector(mcvc_tapProjects), for: .touchUpInside)
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

    @objc
    private func mcvc_tapClose() {
        dismiss(animated: true) { [weak self] in self?.mcvc_dismiss?() }
    }

    @objc
    private func mcvc_tapExplore() {
        dismiss(animated: true) { [weak self] in self?.mcvc_dismiss?() }
    }

    @objc
    private func mcvc_tapProjects() {
        dismiss(animated: true) { [weak self] in self?.mcvc_dismiss?() }
    }
}
