import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data

public final class MCCFeedDetailController: MCCViewController<MCCFeedDetailView, MCCEmptyViewModel> {

    public var mcvc_feedItem: MCSFeedItem!

    public var mcvc_webpHandoff: MCCWebpPlaybackHandoff?

    private var mcvc_didApplyDetailMedia = false

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
        hidesBottomBarWhenPushed = true
    }

    public override func mcvc_needLeftBarButtonItem() -> Bool {
        false
    }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
        guard navigationController != nil else { return }
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        let back = UIBarButtonItem(
            image: UIImage(named: "ic_nav_back")?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(mcvc_detailBackTapped)
        )
        back.tintColor = .white
        let gap = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        gap.width = 8
        let shorts = MCCRootTabNavChrome.leftTitleBarButtonItem(title: "Shorts")
        navigationItem.leftBarButtonItems = [back, gap, shorts]
        navigationItem.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
        navigationItem.title = nil
    }

    @objc private func mcvc_detailBackTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func mcvc_onProTapped() {
        let vc = MCCProController()
        navigationController?.pushViewController(vc, animated: true)
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
        let inset: CGFloat = 16
        let colW = max(1, w - inset * 2)
        let thumbPx = MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: colW)
        contentView.mcvw_configure(feedItem: item, webpHandoff: mcvc_webpHandoff, thumbnailPixelSize: thumbPx)
    }

}

