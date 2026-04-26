import UIKit
import Common
import Combine
import FDFullscreenPopGesture

public final class MCCSettingsController: MCCViewController<MCCSettingsView, MCCEmptyViewModel> {

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
    }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        nav.navigationBar.mc_shadowHidden = true
        nav.navigationBar.mc_barStyle = .transparentLight
        let item = navigationItem
        item.largeTitleDisplayMode = .never
        nav.navigationBar.prefersLargeTitles = false
        item.title = "Settings"
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "000000")
        contentView.backgroundColor = view.backgroundColor
    }

}
