import UIKit
import Common
import SnapKit

public class MCCTopPopController: MCCPopController<MCCTopPopView, MCCEmptyViewModel> {

    public override func mcvc_init() {
        super.mcvc_init()

        self.animationStyle = .topPopUp
        self.dimmingInsets = .init(top: MCCScreenSize.navigationBarHeight, left: 0, bottom: MCCScreenSize.tabBarHeight, right: 0)
    }

}

public class MCCTopPopView: MCCBasePopView {

    public override func mcvw_setupUI() {
        super.mcvw_setupUI()

        self.cardView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
    }

}
