import UIKit
import Common

public final class MCCFeedResolutionPopController: MCCPopController<MCCFeedOptionPopView, MCCEmptyViewModel> {

    public var mcvc_currentIndex: Int = 0
    public var mcvc_onSelectIndex: ((Int) -> Void)?

    public override func mcvc_init() {
        super.mcvc_init()
        animationStyle = .easeInEaseOut
        dimmingInsets = .zero
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.mcvw_applyCardCornerRadius()
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        contentView.mcvw_titleLabel.text = "Resolution"
        let entries: [(title: String, isPro: Bool)] = [
            (title: "480P", isPro: false),
            (title: "720P", isPro: true),
            (title: "1080P", isPro: true)
        ]
        for (idx, e) in entries.enumerated() {
            let pill = MCCFeedOptionPillControl()
            pill.tag = idx
            pill.mcvw_titleLabel.text = e.title
            pill.mcvw_proChip.isHidden = !e.isPro
            pill.mcvw_setSelectedHighlighted(idx == mcvc_currentIndex)
            pill.addTarget(self, action: #selector(mcvc_pillTapped(_:)), for: .touchUpInside)
            contentView.mcvw_optionStack.addArrangedSubview(pill)
        }
    }
    
    @objc
    private func mcvc_pillTapped(_ s: UIControl) {
        mcvc_onSelectIndex?(s.tag)
        dismiss(animated: true)
    }
}
