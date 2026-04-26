import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCFeedDetailController: MCCViewController<MCCFeedDetailView, MCCEmptyViewModel> {

    public var mcvc_feedItem: MCSFeedItem!

    /// 从列表 cell 带入的 WebP 播放进度；`nil` 时详情内按 URL 重新拉取。
    public var mcvc_webpHandoff: MCCWebpPlaybackHandoff?

    private var mcvc_didApplyDetailMedia = false

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

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !mcvc_didApplyDetailMedia, let item = mcvc_feedItem else { return }
        mcvc_didApplyDetailMedia = true
        let w = max(1, view.bounds.width)
        let thumbPx = MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: w)
        contentView.mcvw_configure(feedItem: item, webpHandoff: mcvc_webpHandoff, thumbnailPixelSize: thumbPx)
    }

}

