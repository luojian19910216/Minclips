import UIKit
import Common

public final class MCCFeedDurationPopController: MCCPopController<MCCFeedOptionPopView, MCCEmptyViewModel> {

    public var mcvc_currentIsTen: Bool = false
    public var mcvc_onSelectIsTen: ((Bool) -> Void)?

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
        contentView.mcvw_titleLabel.text = "Duration"
        let entries: [(title: String, isPro: Bool, isSelected: Bool)] = [
            (title: "5s", isPro: false, isSelected: !mcvc_currentIsTen),
            (title: "10s", isPro: true, isSelected: mcvc_currentIsTen)
        ]
        for (idx, e) in entries.enumerated() {
            let pill = MCCFeedOptionPillControl()
            pill.tag = idx
            pill.mcvw_titleLabel.text = e.title
            pill.mcvw_proChip.isHidden = !e.isPro
            pill.mcvw_setSelectedHighlighted(e.isSelected)
            pill.addTarget(self, action: #selector(mcvc_pillTapped(_:)), for: .touchUpInside)
            contentView.mcvw_optionStack.addArrangedSubview(pill)
        }
    }

    @objc
    private func mcvc_pillTapped(_ s: UIControl) {
        mcvc_onSelectIsTen?(s.tag == 1)
        dismiss(animated: true)
    }
}
