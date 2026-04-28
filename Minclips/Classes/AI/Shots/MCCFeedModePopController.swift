import UIKit
import Common

public final class MCCFeedModePopController: MCCPopController<MCCFeedOptionPopView, MCCEmptyViewModel> {

    public var mcvc_currentIndex: Int = 0
    public var mcvc_onSelectIndex: ((Int) -> Void)?
    public var mcvc_anchorFrame: CGRect = .zero
    public var mcvc_anchorAlignment: MCEFeedOptionPopAnchorAlignment = .trailing

    public override func mcvc_init() {
        super.mcvc_init()

        self.animationStyle = .easeInEaseOut
        self.dimmingInsets = .init(top: MCCScreenSize.navigationBarHeight, left: 0, bottom: 0, right: 0)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.mcvw_applyCardCornerRadius()
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        contentView.mcvw_titleLabel.text = "Resolution"
        let entries: [(title: String, isPro: Bool)] = [
            (title: "Original", isPro: false),
            (title: "Generated", isPro: true)
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
        contentView.mcvw_applyAnchorFrame(mcvc_anchorFrame, alignment: mcvc_anchorAlignment)
    }

    @objc
    private func mcvc_pillTapped(_ s: UIControl) {
        mcvc_onSelectIndex?(s.tag)
        dismiss(animated: true)
    }
}
