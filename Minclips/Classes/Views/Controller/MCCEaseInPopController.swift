import UIKit
import Common
import SnapKit

public class MCCEaseInPopController: MCCPopController<MCCEaseInPopView, MCCEmptyViewModel> {

    public override func mcvc_init() {
        super.mcvc_init()

        self.animationStyle = .easeInEaseOut
        self.dimmingInsets = .init(top: MCCScreenSize.navigationBarHeight, left: 0, bottom: MCCScreenSize.tabBarHeight, right: 0)
    }

}

public class MCCEaseInPopView: MCCBasePopView {

    public override func mcvw_setupUI() {
        super.mcvw_setupUI()

        self.cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.equalTo(300)
        }
    }

}
