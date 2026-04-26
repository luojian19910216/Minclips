import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCFeedDetailController: MCCViewController<MCCFeedDetailView, MCCEmptyViewModel> {

    public var mcvc_feedItem: MCSFeedItem!

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
        hidesBottomBarWhenPushed = true
    }

    public override func mcvc_configureNav() {
        guard let nav = navigationController else { return }
        nav.navigationBar.mc_shadowHidden = true
        nav.navigationBar.mc_barStyle = .transparentLight
        let item = navigationItem
        item.largeTitleDisplayMode = .never
        nav.navigationBar.prefersLargeTitles = false
        let t = (mcvc_feedItem?.itemId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        item.title = t.isEmpty ? "Detail" : t
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "000000")
        contentView.backgroundColor = view.backgroundColor
    }

}
