import UIKit
import Common
import Combine
import FDFullscreenPopGesture
import Data
import SDWebImage
import PhotosUI
import Photos
import AVFoundation
import KTVHTTPCache

public final class MCCFeedDetailController: MCCViewController<MCCFeedDetailView, MCCEmptyViewModel> {

    public var mcvc_feedItem: MCSFeedItem!
    public var mcvc_webpHandoff: MCCWebpPlaybackHandoff?
    private var mcvc_feedProfileCancellable: AnyCancellable?
    private var mcvc_integralCancellable: AnyCancellable?
    private var mcvc_mp4Player: AVPlayer?
    private var mcvc_mp4PeriodicObserver: Any?
    private var mcvc_mp4EndObserver: NSObjectProtocol?
    private var mcvc_resolutionIndex: Int = 0
    private var mcvc_durationIsTen: Bool = false
    private var mcvc_modeIndex: Int = 0

    private var mcvc_characterCircleImages: [UIImage?] = [nil]

    private var mcvc_navCreditsBarButton: UIButton?

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
        hidesBottomBarWhenPushed = true
    }

    deinit {
        mcvc_feedProfileCancellable?.cancel()
        mcvc_integralCancellable?.cancel()
        mcvc_removeMp4ObserversAndPlayer()
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
        navigationItem.leftBarButtonItems = nil
        navigationItem.leftBarButtonItem = back

        let creditsBar = MCCRootTabNavChrome.feedCreditsBarButtonItem(
            amount: mcvc_navCreditsDisplayText(),
            target: self,
            action: #selector(mcvc_navCreditsTapped)
        )
        mcvc_navCreditsBarButton = creditsBar.customView as? UIButton

        let betweenCreditsAndReport = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        betweenCreditsAndReport.width = 8
        navigationItem.rightBarButtonItems = [
            MCCRootTabNavChrome.feedReportBarButtonItem(target: self, action: #selector(mcvc_reportTapped)),
            betweenCreditsAndReport,
            creditsBar
        ]
        navigationItem.title = nil
    }

    @objc
    private func mcvc_detailBackTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func mcvc_navCreditsTapped() {
        let vc = MCCProController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func mcvc_navCreditsDisplayText() -> String {
        let n = max(0, MCCAccountService.shared.currentUser.value?.pointsBalance ?? 0)
        return NumberFormatter.localizedString(from: NSNumber(value: n), number: .decimal)
    }

    private func mcvc_refreshNavCreditsDisplay() {
        mcvc_navCreditsBarButton?.setTitle(mcvc_navCreditsDisplayText(), for: .normal)
    }

    /// 进入详情拉取 `integralStatement`，更新本地 `MCSUser.pointsBalance`（`MCCAccountService` 落库 + 广播，导航栏积分自动刷新）。
    private func mcvc_refreshIntegralStatement() {
        guard MCCAccountService.shared.currentUser.value != nil else { return }
        mcvc_integralCancellable?.cancel()
        mcvc_integralCancellable = MCCUmAPIManager.shared.integralStatement()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { balance in
                    MCCAccountService.shared.update {
                        $0.pointsBalance = max(0, balance)
                    }
                }
            )
    }

    @objc
    private func mcvc_reportTapped() {
    }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = UIColor(hex: "000000")
        contentView.backgroundColor = view.backgroundColor
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        MCCAccountService.shared.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.mcvc_refreshNavCreditsDisplay()
            }
            .store(in: &cancellables)

        mcvc_applyCharacterRecentVisibility()
        let v = contentView
        v.mcvw_resolutionPill.addTarget(self, action: #selector(mcvc_resolutionTapped), for: .touchUpInside)
        v.mcvw_durationPill.addTarget(self, action: #selector(mcvc_durationTapped), for: .touchUpInside)
        v.mcvw_modePill.addTarget(self, action: #selector(mcvc_modeTapped), for: .touchUpInside)
        v.mcvw_continueButton.addTarget(self, action: #selector(mcvc_continueTapped), for: .touchUpInside)
        v.mcvw_playPauseButton.addTarget(self, action: #selector(mcvc_playPauseTapped), for: .touchUpInside)
        v.mcvw_muteButton.addTarget(self, action: #selector(mcvc_muteTapped), for: .touchUpInside)
        v.mcvw_favoriteButton.addTarget(self, action: #selector(mcvc_favoriteTapped), for: .touchUpInside)
        v.mcvw_characterAlbumButton.addTarget(self, action: #selector(mcvc_characterAlbumTapped), for: .touchUpInside)
        mcvc_bindCharacterCircleRemoveButtons()
        mcvc_refreshContinueButtonState()
    }

    private func mcvc_bindCharacterCircleRemoveButtons() {
        for (ix, slot) in contentView.mcvw_characterCircleSlots.enumerated() {
            slot.mcvw_removeButton.tag = ix
            slot.mcvw_removeButton.removeTarget(nil, action: nil, for: .allEvents)
            slot.mcvw_removeButton.addTarget(self, action: #selector(mcvc_characterCircleRemoveTapped(_:)), for: .touchUpInside)
        }
    }

    private func mcvc_applyPresetGallerySlotsFromFeedItem() {
        let pg = mcvc_feedItem?.presetGallery ?? []
        let n = max(1, pg.count)
        contentView.mcvw_reloadPresetGallerySlotUI(slotCount: n, entries: pg)
        mcvc_resizeCharacterSlotImages(count: n)
        mcvc_bindCharacterCircleRemoveButtons()
    }

    private func mcvc_resizeCharacterSlotImages(count: Int) {
        let n = max(1, count)
        guard mcvc_characterCircleImages.count != n else { return }
        if mcvc_characterCircleImages.count < n {
            mcvc_characterCircleImages += Array(repeating: nil, count: n - mcvc_characterCircleImages.count)
        } else {
            mcvc_characterCircleImages = Array(mcvc_characterCircleImages.prefix(n))
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mcvc_refreshIntegralStatement()
        mcvc_applyCharacterRecentVisibility()
        let rawId = mcvc_feedItem?.itemId ?? ""
        let trimmed = rawId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isMovingToParent else { return }

        mcvc_resolutionIndex = 0
        mcvc_durationIsTen = false
        mcvc_modeIndex = 0

        let needsHud = !mcvc_hasLocalPreviewMedia()
        if needsHud {
            MCCToastManager.showHUD(in: view)
        }
        mcvc_tryApplyOptimisticDetailFromCache()
        mcvc_requestItemProfile(hudWasShown: needsHud, templateRef: trimmed)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            mcvc_mp4Player?.pause()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mcvc_hydrateRecentCharacterPhotoIfNeeded()
        mcvc_syncCharacterCirclesAppearance()
    }

    private func mcvc_applyStaticCopy() {
        mcvc_applyCharacterRecentVisibility()
        let v = contentView
        mcvc_refreshNavCreditsDisplay()
        v.mcvw_characterTitleLabel.text = "Character"
        let likes = max(0, mcvc_feedItem?.likesCount ?? 0)
        v.mcvw_favoriteCountLabel.text = NumberFormatter.localizedString(from: NSNumber(value: likes), number: .decimal)
        mcvc_applyPresetGallerySlotsFromFeedItem()
        mcvc_syncCharacterCirclesAppearance()
    }

    private func mcvc_characterSlotsFullyFilled() -> Bool {
        !mcvc_characterCircleImages.isEmpty && !mcvc_characterCircleImages.contains(where: { $0 == nil })
    }

    private func mcvc_refreshContinueButtonState() {
        let v = contentView
        let cost = mcvc_feedItem?.pointCost ?? 50
        let filled = mcvc_characterSlotsFullyFilled()
        let enTitle = mcvc_continueButtonAttributedTitle(pointCost: cost, muted: false)
        let disTitle = mcvc_continueButtonAttributedTitle(pointCost: cost, muted: true)
        v.mcvw_continueButton.setAttributedTitle(enTitle, for: .normal)
        v.mcvw_continueButton.setAttributedTitle(disTitle, for: .disabled)
        v.mcvw_continueButton.isEnabled = filled
        v.mcvw_continueButton.backgroundColor = filled ? UIColor(hex: "0077FF")! : UIColor.white.withAlphaComponent(0.06)
    }

    private func mcvc_continueButtonAttributedTitle(pointCost: Int, muted: Bool) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let color = muted ? UIColor.white.withAlphaComponent(0.24) : UIColor.white
        let out = NSMutableAttributedString()
        out.append(NSAttributedString(string: "Continue", attributes: [
            .font: font,
            .foregroundColor: color
        ]))
        out.append(NSAttributedString(string: " ", attributes: [
            .font: font,
            .foregroundColor: color
        ]))
        if let base = UIImage(named: "ic_cm_credits") {
            let att = NSTextAttachment()
            if muted {
                att.image = mcvc_imageWithAlpha(base, alpha: 0.24)
            } else {
                att.image = base.withRenderingMode(.alwaysOriginal)
            }
            let h: CGFloat = 18
            let scale = max(h / base.size.height, 0.001)
            let w = base.size.width * scale
            att.bounds = CGRect(x: 0, y: (font.capHeight - h) / 2 - font.descender / 3, width: w, height: h)
            out.append(NSAttributedString(attachment: att))
        }
        out.append(NSAttributedString(string: " ", attributes: [
            .font: font,
            .foregroundColor: color
        ]))
        out.append(NSAttributedString(string: "\(pointCost)", attributes: [
            .font: font,
            .foregroundColor: color
        ]))
        return out
    }

    private func mcvc_imageWithAlpha(_ image: UIImage, alpha: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        let r = UIGraphicsImageRenderer(size: image.size, format: format)
        return r.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size), blendMode: .normal, alpha: alpha)
        }
    }

    /// 远程 MP4：`AVURLAsset` + `PreferPreciseDuration=false` + 缓冲策略边下边播；经 `KTVHTTPCache` 代理 URL 走时移缓存。
    /// （仍依赖 CDN 支持 `Accept-Ranges`/`206` 与 moov 前置等。）
    private func mcvc_remoteMp4StreamingPlayer(url: URL) -> AVPlayer {
        /// `bindToLocalhost: false` 与官方 README 一致，便于 AirPlay / 非同设备输出；仅本地预览时也可为 `true`。
        let playURL = KTVHTTPCache.proxyURL(withOriginalURL: url, bindToLocalhost: false) as URL
        let assetOpts: [String: Any] = [
            AVURLAssetPreferPreciseDurationAndTimingKey: false,
        ]
        let asset = AVURLAsset(url: playURL, options: assetOpts)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 4
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        player.isMuted = true
        player.actionAtItemEnd = .pause
        return player
    }

    private func mcvc_applyDetailMedia(item: MCSFeedItem, webpHandoff: MCCWebpPlaybackHandoff?, thumbnailPixelSize: CGSize) {
        let v = contentView
        v.mcvw_applyMediaHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
        mcvc_removeMp4ObserversAndPlayer()

        let ctx: [SDWebImageContextOption: Any] = [
            .imageThumbnailPixelSize: NSValue(cgSize: thumbnailPixelSize),
            .imagePreserveAspectRatio: true
        ]
        let asset = item.videoAsset
        let posterRaw = asset.posterImageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if let u = URL(string: posterRaw), !posterRaw.isEmpty {
            v.mcvw_posterImageView.sd_setImage(with: u, placeholderImage: nil, options: [], context: ctx)
        } else {
            v.mcvw_posterImageView.sd_cancelCurrentImageLoad()
            v.mcvw_posterImageView.image = nil
        }

        let mp4Raw = asset.videoMp4Url.trimmingCharacters(in: .whitespacesAndNewlines)
        if mcvc_stringHasHttpHttpsURL(mp4Raw), let mp4URL = URL(string: mp4Raw) {
            v.mcvw_webpImageView.sd_cancelCurrentImageLoad()
            v.mcvw_webpImageView.autoPlayAnimatedImage = false
            v.mcvw_webpImageView.stopAnimating()
            v.mcvw_webpImageView.image = nil
            v.mcvw_webpImageView.isHidden = true

            let player = mcvc_remoteMp4StreamingPlayer(url: mp4URL)
            mcvc_mp4Player = player

            v.mcvw_bindMp4Playback(player: player, surfaceVisible: true)
            v.mcvw_progressView.progress = 0
            mcvc_addMp4ProgressObserver(for: player)
            mcvc_addMp4LoopObserver(for: player)
            player.play()
            return
        }

        v.mcvw_bindMp4Playback(player: nil, surfaceVisible: false)
        v.mcvw_progressView.progress = 0.3

        if let h = webpHandoff {
            v.mcvw_webpImageView.sd_cancelCurrentImageLoad()
            v.mcvw_webpImageView.autoPlayAnimatedImage = false
            v.mcvw_webpImageView.isHidden = false
            v.mcvw_webpImageView.image = h.image
            v.mcvw_webpImageView.player?.seekToFrame(at: h.frameIndex, loopCount: h.loopCount)
            v.mcvw_webpImageView.autoPlayAnimatedImage = true
            v.mcvw_webpImageView.startAnimating()
            return
        }
        let webpTrim = asset.webpImageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if let u = URL(string: webpTrim), !webpTrim.isEmpty {
            v.mcvw_webpImageView.autoPlayAnimatedImage = true
            v.mcvw_webpImageView.isHidden = false
            v.mcvw_webpImageView.sd_setImage(with: u, placeholderImage: nil, options: [], completed: { [weak self] _, _, _, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.contentView.mcvw_webpImageView.startAnimating()
                }
            })
            return
        }
        v.mcvw_webpImageView.sd_cancelCurrentImageLoad()
        v.mcvw_webpImageView.image = nil
        v.mcvw_webpImageView.isHidden = true
    }

    private func mcvc_stringHasHttpHttpsURL(_ raw: String) -> Bool {
        guard !raw.isEmpty, let u = URL(string: raw), let scheme = u.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private func mcvc_removeMp4ObserversAndPlayer() {
        if let o = mcvc_mp4PeriodicObserver, let player = mcvc_mp4Player {
            player.removeTimeObserver(o)
        }
        mcvc_mp4PeriodicObserver = nil
        if let o = mcvc_mp4EndObserver {
            NotificationCenter.default.removeObserver(o)
            mcvc_mp4EndObserver = nil
        }
        mcvc_mp4Player?.pause()
        mcvc_mp4Player = nil
        contentView.mcvw_bindMp4Playback(player: nil, surfaceVisible: false)
    }

    private func mcvc_addMp4ProgressObserver(for player: AVPlayer) {
        let interval = CMTime(seconds: 0.12, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        mcvc_mp4PeriodicObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let item = player.currentItem else { return }
            let duration = item.duration
            guard duration.isNumeric, duration.seconds > 0 else { return }
            self.contentView.mcvw_progressView.progress = Float(time.seconds / duration.seconds)
        }
    }

    private func mcvc_addMp4LoopObserver(for player: AVPlayer) {
        mcvc_mp4EndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let ended = note.object as? AVPlayerItem,
                  let current = self.mcvc_mp4Player?.currentItem,
                  ended === current else { return }
            self.mcvc_mp4Player?.seek(to: .zero)
            self.mcvc_mp4Player?.play()
        }
    }

    @objc
    private func mcvc_playPauseTapped() {
        if let player = mcvc_mp4Player {
            if player.timeControlStatus == .playing {
                player.pause()
            } else {
                player.play()
            }
            return
        }
        let w = contentView.mcvw_webpImageView
        guard !w.isHidden, w.image != nil else { return }
        if w.isAnimating {
            w.stopAnimating()
        } else {
            w.startAnimating()
        }
    }

    @objc
    private func mcvc_muteTapped() {
        if let player = mcvc_mp4Player {
            player.isMuted.toggle()
        }
    }

    @objc
    private func mcvc_favoriteTapped() {
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
        guard mcvc_characterSlotsFullyFilled() else { return }
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
        present(g, animated: true)
    }

    @objc
    private func mcvc_characterCircleRemoveTapped(_ sender: UIButton) {
        let i = sender.tag
        guard (0 ..< mcvc_characterCircleImages.count).contains(i) else { return }
        mcvc_characterCircleImages[i] = nil
        mcvc_syncCharacterCirclesAppearance()
    }

    private func mcvc_syncCharacterCirclesAppearance() {
        let v = contentView
        for i in mcvc_characterCircleImages.indices {
            v.mcvw_characterCircleSlots[i].mcvw_apply(image: mcvc_characterCircleImages[i])
        }
        let nextEmpty = mcvc_characterCircleImages.indices.first { mcvc_characterCircleImages[$0] == nil }
        v.mcvw_applyCharacterCircleFocus(nextEmptySlotIndex: nextEmpty)
        mcvc_refreshContinueButtonState()
    }

    private func mcvc_offerPickedCharacterImageToSlots(_ img: UIImage) {
        if let ix = mcvc_characterCircleImages.indices.first(where: { mcvc_characterCircleImages[$0] == nil }) {
            mcvc_characterCircleImages[ix] = img
            mcvc_syncCharacterCirclesAppearance()
            return
        }
    }

    @objc
    private func mcvc_characterAlbumTapped() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func mcvc_applyCharacterRecentVisibility() {
        let visible = !MCCRecentPickedPhotoStore.localIdentifiers.isEmpty
        contentView.mcvw_configureCharacterRecentTileVisible(visible)
    }

    private func mcvc_hydrateRecentCharacterPhotoIfNeeded() {
        guard !contentView.mcvw_characterRecentTile.isHidden else { return }
        let v = contentView.mcvw_characterRecentImageView
        guard v.image == nil, let id = MCCRecentPickedPhotoStore.localIdentifiers.first else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = assets.firstObject else { return }
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .opportunistic
        let scale = UIScreen.main.scale
        let side: CGFloat = 128
        let px = CGSize(width: side * scale, height: side * scale)
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: px,
            contentMode: .aspectFill,
            options: opts
        ) { [weak self] img, _ in
            DispatchQueue.main.async {
                guard let self, self.contentView.mcvw_characterRecentImageView.image == nil else { return }
                self.contentView.mcvw_characterRecentImageView.image = img
                self.mcvc_syncCharacterCirclesAppearance()
            }
        }
    }
}

extension MCCFeedDetailController: PHPickerViewControllerDelegate {

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let r = results.first else { return }
        if let id = r.assetIdentifier {
            MCCRecentPickedPhotoStore.record(localIdentifier: id)
        }
        mcvc_applyCharacterRecentVisibility()
        let prov = r.itemProvider
        guard prov.canLoadObject(ofClass: UIImage.self) else { return }
        _ = prov.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            let img = object as? UIImage
            DispatchQueue.main.async {
                guard let self, let img else { return }
                self.contentView.mcvw_characterRecentImageView.image = img
                self.mcvc_offerPickedCharacterImageToSlots(img)
            }
        }
    }
}

private extension MCCFeedDetailController {

    func mcvc_effectiveDetailColumnWidth() -> CGFloat {
        let w = view.bounds.width
        if w > 1 {
            return w
        }
        if let ww = view.window?.bounds.width, ww > 1 {
            return ww
        }
        return max(1, UIScreen.main.bounds.width)
    }

    func mcvc_hasLocalPreviewMedia() -> Bool {
        guard let item = mcvc_feedItem else { return false }
        if mcvc_webpHandoff != nil {
            return true
        }
        let a = item.videoAsset
        if mcvc_stringHasHttpHttpsURL(a.videoMp4Url.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return true
        }
        return !a.posterImageUrl.isEmpty || !a.webpImageUrl.isEmpty
    }

    func mcvc_tryApplyOptimisticDetailFromCache() {
        guard mcvc_hasLocalPreviewMedia(), let item = mcvc_feedItem else { return }
        let colW = max(1, mcvc_effectiveDetailColumnWidth())
        let thumbPx = MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: colW)
        mcvc_applyDetailMedia(item: item, webpHandoff: mcvc_webpHandoff, thumbnailPixelSize: thumbPx)
        mcvc_applyStaticCopy()
        mcvc_syncBottomBar()
    }

    func mcvc_requestItemProfile(hudWasShown: Bool, templateRef: String) {
        mcvc_feedProfileCancellable?.cancel()
        var rq = MCSFeedDetailRequest()
        rq.templateRef = templateRef
        mcvc_feedProfileCancellable = MCCFeedAPIManager.shared.itemProfile(with: rq)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                if hudWasShown {
                    MCCToastManager.hide()
                }
                if case let .failure(err) = completion {
                    if !self.mcvc_hasLocalPreviewMedia() {
                        MCCToastManager.showToast(err.localizedDescription, in: self.view)
                    }
                }
            }, receiveValue: { [weak self] item in
                guard let self else { return }
                self.mcvc_feedItem = item
                self.mcvc_webpHandoff = nil
                let colW = max(1, self.mcvc_effectiveDetailColumnWidth())
                let thumbPx = MCCShotsListItemMetrics.feedImageThumbnailPixelSize(columnWidthPoints: colW)
                self.mcvc_applyDetailMedia(item: item, webpHandoff: nil, thumbnailPixelSize: thumbPx)
                self.mcvc_applyStaticCopy()
                self.mcvc_syncBottomBar()
            })
    }
}
