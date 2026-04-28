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

    public override func mcvc_loadData() {
        super.mcvc_loadData()
        let rows = [
            MCCFeedOptionRow(title: "5s", isPro: false, isSelected: !mcvc_currentIsTen),
            MCCFeedOptionRow(title: "10s", isPro: true, isSelected: mcvc_currentIsTen)
        ]
        contentView.mcvw_setRows(rows) { [weak self] i in
            guard let self else { return }
            self.mcvc_onSelectIsTen?(i == 1)
            self.dismiss(animated: true)
        }
    }
}
