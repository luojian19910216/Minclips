import UIKit
import Common
import FDFullscreenPopGesture
import Data

public final class MCCOneClickController: MCCViewController<MCCOneClickView, MCCEmptyViewModel> {

    public var mcvc_toolboxItem: MCSCfToolboxItem?

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "0F0F12")!
        contentView.backgroundColor = view.backgroundColor
    }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        let t = mcvc_toolboxItem?.code.trimmingCharacters(in: .whitespacesAndNewlines)
        navigationItem.title = (t?.isEmpty == false) ? t : nil
    }

}
