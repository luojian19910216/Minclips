import UIKit
import Common

public final class MCCFeedModePopController: MCCPopController<MCCFeedOptionPopView, MCCEmptyViewModel> {

    public var mcvc_currentIndex: Int = 0
    public var mcvc_onSelectIndex: ((Int) -> Void)?

    public override func mcvc_init() {
        super.mcvc_init()
        animationStyle = .easeInEaseOut
        dimmingInsets = .zero
    }

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        let rows = [
            MCCFeedOptionRow(title: "Original", isPro: false, isSelected: mcvc_currentIndex == 0),
            MCCFeedOptionRow(title: "Generated", isPro: true, isSelected: mcvc_currentIndex == 1)
        ]
        contentView.mcvw_setRows(rows) { [weak self] i in
            guard let self else { return }
            self.mcvc_onSelectIndex?(i)
            self.dismiss(animated: true)
        }
    }
}
