import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data
import SDWebImage

public final class MCCFeedDetailController: MCCViewController<MCCFeedDetailView, MCCEmptyViewModel> {

    public var mcvc_feedItem: MCSFeedItem!
    public var mcvc_webpHandoff: MCCWebpPlaybackHandoff?
    private var mcvc_didApplyDetailMedia = false
    private var mcvc_resolutionIndex: Int = 1
    private var mcvc_durationIsTen: Bool = false
    private var mcvc_modeIndex: Int = 0

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
        let shots = MCCRootTabNavChrome.leftTitleBarButtonItem(title: "Shots")
        navigationItem.leftBarButtonItems = [back, gap, shots]
        navigationItem.rightBarButtonItem = MCCRootTabNavChrome.proBarButtonItem(
            target: self,
            action: #selector(mcvc_onProTapped),
            titleColor: .white
        )
        navigationItem.title = nil
    }

    @objc
    private func mcvc_detailBackTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func mcvc_onProTapped() {
        let vc = MCCProController()
        navigationController?.pushViewController(vc, animated: true)
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "000000")
        contentView.backgroundColor = view.backgroundColor
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let v = contentView
        v.mcvw_resolutionPill.addTarget(self, action: #selector(mcvc_resolutionTapped), for: .touchUpInside)
        v.mcvw_durationPill.addTarget(self, action: #selector(mcvc_durationTapped), for: .touchUpInside)
        v.mcvw_modePill.addTarget(self, action: #selector(mcvc_modeTapped), for: .touchUpInside)
        v.mcvw_continueButton.addTarget(self, action: #selector(mcvc_continueTapped), for: .touchUpInside)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !mcvc_didApplyDetailMedia, let item = mcvc_feedItem else { return }
        mcvc_didApplyDetailMedia = true
        mcvc_durationIsTen = item.tenSecondMode
        mcvc_resolutionIndex = 1
        mcvc_modeIndex = 0
        let w = max(1, view.bounds.width)
        let inset: CGFloat = 16
        let colW = max(1, w - inset * 2)
        let thumbPx = MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: colW)
        mcvc_applyDetailMedia(item: item, webpHandoff: mcvc_webpHandoff, thumbnailPixelSize: thumbPx)
        mcvc_applyStaticCopy()
        mcvc_syncBottomBar()
    }

    private func mcvc_applyStaticCopy() {
        let v = contentView
        v.mcvw_creditsLabel.text = "+ 9999"
        v.mcvw_progressView.progress = 0.3
        v.mcvw_characterTitleLabel.text = "Character"
        v.mcvw_resolutionTitleLabel.text = "Resolution"
        v.mcvw_durationTitleLabel.text = "Duration"
        v.mcvw_modeTitleLabel.text = "Mode"
        v.mcvw_continueButton.setTitle("Continue + 50", for: .normal)
    }

    private func mcvc_applyDetailMedia(item: MCSFeedItem, webpHandoff: MCCWebpPlaybackHandoff?, thumbnailPixelSize: CGSize) {
        let v = contentView
        v.mcvw_applyMediaHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
        let ctx: [SDWebImageContextOption: Any] = [
            .imageThumbnailPixelSize: NSValue(cgSize: thumbnailPixelSize),
            .imagePreserveAspectRatio: true
        ]
        let asset = item.videoAsset
        if let u = URL(string: asset.posterImageUrl), !asset.posterImageUrl.isEmpty {
            v.mcvw_posterImageView.sd_setImage(with: u, placeholderImage: nil, options: [], context: ctx)
        } else {
            v.mcvw_posterImageView.sd_cancelCurrentImageLoad()
            v.mcvw_posterImageView.image = nil
        }
        if let h = webpHandoff {
            v.mcvw_webpImageView.sd_cancelCurrentImageLoad()
            v.mcvw_webpImageView.autoPlayAnimatedImage = false
            v.mcvw_webpImageView.isHidden = false
            v.mcvw_webpImageView.image = h.image
            v.mcvw_webpImageView.player?.seekToFrame(at: h.frameIndex, loopCount: h.loopCount)
            v.mcvw_webpImageView.autoPlayAnimatedImage = true
            v.mcvw_webpImageView.startAnimating()
        } else if let u = URL(string: asset.webpImageUrl), !asset.webpImageUrl.isEmpty {
            v.mcvw_webpImageView.autoPlayAnimatedImage = true
            v.mcvw_webpImageView.isHidden = false
            v.mcvw_webpImageView.sd_setImage(with: u, placeholderImage: nil, options: [], completed: { [weak self] _, _, _, _ in
                self?.contentView.mcvw_webpImageView.startAnimating()
            })
        } else {
            v.mcvw_webpImageView.sd_cancelCurrentImageLoad()
            v.mcvw_webpImageView.image = nil
            v.mcvw_webpImageView.isHidden = true
        }
    }

    private func mcvc_syncBottomBar() {
        let v = contentView
        let r = ["480P", "720P", "1080P"]
        v.mcvw_resolutionValueLabel.text = r[min(mcvc_resolutionIndex, r.count - 1)]
        v.mcvw_durationValueLabel.text = mcvc_durationIsTen ? "10s" : "5s"
        let m = ["Original", "Generated"]
        v.mcvw_modeValueLabel.text = m[min(mcvc_modeIndex, m.count - 1)]
    }

    @objc
    private func mcvc_resolutionTapped() {
        mcvc_presentResolutionPop()
    }

    @objc
    private func mcvc_durationTapped() {
        mcvc_presentDurationPop()
    }

    @objc
    private func mcvc_modeTapped() {
        mcvc_presentModePop()
    }

    @objc
    private func mcvc_continueTapped() {
        mcvc_presentGenerating()
    }

    private func mcvc_presentResolutionPop() {
        let p = MCCFeedOptionPopController()
        p.loadViewIfNeeded()
        p.mcvc_applyRows([
            MCCFeedOptionRow(title: "480P", isPro: false, isSelected: mcvc_resolutionIndex == 0),
            MCCFeedOptionRow(title: "720P", isPro: false, isSelected: mcvc_resolutionIndex == 1),
            MCCFeedOptionRow(title: "1080P", isPro: true, isSelected: mcvc_resolutionIndex == 2)
        ]) { [weak self] i in
            self?.mcvc_resolutionIndex = i
            self?.mcvc_syncBottomBar()
        }
        present(p, animated: true)
    }

    private func mcvc_presentDurationPop() {
        let p = MCCFeedOptionPopController()
        p.loadViewIfNeeded()
        p.mcvc_applyRows([
            MCCFeedOptionRow(title: "5s", isPro: false, isSelected: !mcvc_durationIsTen),
            MCCFeedOptionRow(title: "10s", isPro: true, isSelected: mcvc_durationIsTen)
        ]) { [weak self] i in
            self?.mcvc_durationIsTen = (i == 1)
            self?.mcvc_syncBottomBar()
        }
        present(p, animated: true)
    }

    private func mcvc_presentModePop() {
        let p = MCCFeedOptionPopController()
        p.loadViewIfNeeded()
        p.mcvc_applyRows([
            MCCFeedOptionRow(title: "Original", isPro: false, isSelected: mcvc_modeIndex == 0),
            MCCFeedOptionRow(title: "Generated", isPro: true, isSelected: mcvc_modeIndex == 1)
        ]) { [weak self] i in
            self?.mcvc_modeIndex = i
            self?.mcvc_syncBottomBar()
        }
        present(p, animated: true)
    }

    private func mcvc_presentGenerating() {
        let g = MCCFeedGeneratingSheetController()
        g.mcvc_applyCopy(
            closeAccessibilityLabel: "Close",
            percent: "30%",
            title: "Generating",
            subtitle: "Please check in Projects later.",
            explore: "Explore",
            projects: "Projects"
        )
        if let poster = mcvc_feedItem?.videoAsset.posterImageUrl {
            g.mcvc_setPosterFromURLString(poster)
        }
        present(g, animated: true)
    }
}
