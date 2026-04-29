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
import PanModal

public final class MCCFeedDetailController: MCCViewController<MCCFeedDetailView, MCCEmptyViewModel> {

    public var mcvc_feedItem: MCSFeedItem!
    public var mcvc_webpHandoff: MCCWebpPlaybackHandoff?
    private var mcvc_feedProfileCancellable: AnyCancellable?
    private var mcvc_integralCancellable: AnyCancellable?
    private var mcvc_favoriteCancellable: AnyCancellable?
    private var mcvc_composeSeedCancellable: AnyCancellable?
    private var mcvc_mp4Player: AVPlayer?
    private var mcvc_mp4PeriodicObserver: Any?
    private var mcvc_mp4EndObserver: NSObjectProtocol?
    /// 避免 `setImage` 与播控状态瞬变导致循环衔接处图标闪动。
    private var mcvc_lastTransportPlayIconName: String?
    private var mcvc_lastTransportMuteIconName: String?
    /// WebP _transport_icon：不依賴 `SDAnimatedImageView.isAnimating`（部分環境下讀取會崩）。
    private var mcvc_webpTransportAnimating = false
    private var mcvc_resolutionIndex: Int = 0
    private var mcvc_durationIsTen: Bool = false
    private var mcvc_modeIndex: Int = 0

    private var mcvc_characterCircleImages: [UIImage?] = [nil]
    private var mcvc_characterRemoteImageURLs: [String?] = [nil]

    /// 当前选中的上传槽（蓝框）；默认 0，点击图片框或头像圈可切换。
    private var mcvc_activeCharacterSlotIndex: Int = 0
    private var mcvc_characterSelectionTapGestures: [UITapGestureRecognizer] = []

    private var mcvc_navCreditsBarItem: UIBarButtonItem?

    /// 已展示在 Recent 磁贴上的 `localIdentifier`，避免重复向 Photos 拉取。
    private var mcvc_recentTileSyncedAssetId: String?

    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public override func mcvc_init() {
        fd_prefersNavigationBarHidden = false
        hidesBottomBarWhenPushed = true
    }

    deinit {
        mcvc_removeCharacterSelectionGestures()
        mcvc_feedProfileCancellable?.cancel()
        mcvc_integralCancellable?.cancel()
        mcvc_favoriteCancellable?.cancel()
        mcvc_composeSeedCancellable?.cancel()
        mcvc_removeMp4ObserversAndPlayer()
    }

    public override func mcvc_configureNav() {
        super.mcvc_configureNav()
 
        let creditsBar = MCCRootTabNavChrome.capsuleBarButtonItem(
            icon: UIImage(named: "ic_cm_credits")?.withRenderingMode(.alwaysOriginal),
            title: mcvc_navCreditsDisplayText(),
            target: self,
            action: #selector(mcvc_navCreditsTapped)
        )
        mcvc_navCreditsBarItem = creditsBar

        let betweenCreditsAndReport = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        betweenCreditsAndReport.width = 8
        
        navigationItem.rightBarButtonItems = [
            MCCRootTabNavChrome.capsuleBarButtonItem(
                icon: UIImage(named: "ic_nav_report")?.withRenderingMode(.alwaysOriginal),
                target: self,
                action: #selector(mcvc_reportTapped)
            ),
            betweenCreditsAndReport,
            creditsBar
        ]
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
        let t = mcvc_navCreditsDisplayText()
        MCCRootTabNavChrome.updateCapsuleBarButtonItem(mcvc_navCreditsBarItem, title: t)
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
        let recentTap = UITapGestureRecognizer(target: self, action: #selector(mcvc_characterRecentTapped))
        v.mcvw_characterRecentTile.addGestureRecognizer(recentTap)
        mcvc_bindCharacterCircleRemoveButtons()
        mcvc_refreshContinueButtonState()
        mcvc_bindCharacterSlotSelectionGestures()
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
        mcvc_removeCharacterSelectionGestures()
        contentView.mcvw_reloadPresetGallerySlotUI(slotCount: n, entries: pg)
        mcvc_resizeCharacterSlotImages(count: n)
        mcvc_bindCharacterCircleRemoveButtons()
        mcvc_bindCharacterSlotSelectionGestures()
    }

    private func mcvc_resizeCharacterSlotImages(count: Int) {
        let n = max(1, count)
        guard mcvc_characterCircleImages.count != n else {
            mcvc_activeCharacterSlotIndex = mcvc_clampCharacterSlotIndex(mcvc_activeCharacterSlotIndex)
            return
        }
        if mcvc_characterCircleImages.count < n {
            let addCount = n - mcvc_characterCircleImages.count
            mcvc_characterCircleImages += Array(repeating: nil, count: addCount)
            mcvc_characterRemoteImageURLs += Array(repeating: nil, count: addCount)
        } else {
            mcvc_characterCircleImages = Array(mcvc_characterCircleImages.prefix(n))
            mcvc_characterRemoteImageURLs = Array(mcvc_characterRemoteImageURLs.prefix(n))
        }
        mcvc_activeCharacterSlotIndex = mcvc_clampCharacterSlotIndex(mcvc_activeCharacterSlotIndex)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mcvc_refreshIntegralStatement()
        mcvc_refreshRecentTileThumbnailFromStoreIfNeeded()
        let rawId = mcvc_feedItem?.itemId ?? ""
        let trimmed = rawId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isMovingToParent else { return }

        mcvc_resolutionIndex = 0
        mcvc_durationIsTen = false
        mcvc_modeIndex = 0
        mcvc_activeCharacterSlotIndex = 0

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
        mcvc_refreshRecentTileThumbnailFromStoreIfNeeded()
        mcvc_syncCharacterCirclesAppearance()
    }

    private func mcvc_applyStaticCopy() {
        mcvc_refreshRecentTileThumbnailFromStoreIfNeeded()
        let v = contentView
        mcvc_refreshNavCreditsDisplay()
        v.mcvw_characterTitleLabel.text = "Character"
        mcvc_refreshFavoriteChrome()
        mcvc_applyPresetGallerySlotsFromFeedItem()
        mcvc_syncCharacterCirclesAppearance()
    }

    private func mcvc_characterSlotsFullyFilled() -> Bool {
        guard !mcvc_characterCircleImages.isEmpty else { return false }
        let n = mcvc_characterCircleImages.count
        guard mcvc_characterRemoteImageURLs.count == n else { return false }
        for i in mcvc_characterCircleImages.indices {
            let hasPic = mcvc_characterCircleImages[i] != nil
            let url = mcvc_characterRemoteImageURLs[i]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let hasRemote = !url.isEmpty
            if !hasPic && !hasRemote { return false }
        }
        return true
    }

    public func mcvc_applyRemoteCharacterImageURLs(_ urls: [String]) {
        guard !urls.isEmpty else { return }
        guard mcvc_characterCircleImages.count == mcvc_characterRemoteImageURLs.count else { return }
        let n = min(mcvc_characterCircleImages.count, urls.count)
        for i in 0 ..< n {
            let raw = urls[i].trimmingCharacters(in: .whitespacesAndNewlines)
            mcvc_characterCircleImages[i] = nil
            mcvc_characterRemoteImageURLs[i] = raw.isEmpty ? nil : raw
        }
        mcvc_syncCharacterCirclesAppearance()
        mcvc_refreshContinueButtonState()
    }

    /// 480P → `lowPointsCost`，720P → `pointCost`，1080P → `hiDefPoints`；若某档为 0 则退回 `pointCost`。图生视频且选 10s 时再加 `tenSecPoints`。
    private func mcvc_effectiveContinuePointCost() -> Int {
        guard let item = mcvc_feedItem else { return 50 }
        let tier = min(max(mcvc_resolutionIndex, 0), 2)
        let base: Int
        switch tier {
        case 0:
            let v = item.lowPointsCost
            base = v > 0 ? v : item.pointCost
        case 1:
            base = item.pointCost
        case 2:
            let v = item.hiDefPoints
            base = v > 0 ? v : item.pointCost
        default:
            base = item.pointCost
        }
        let videoExtra = item.contentKind.isToVideo && mcvc_durationIsTen ? item.tenSecPoints : 0
        return base + videoExtra
    }

    private func mcvc_refreshContinueButtonState() {
        let v = contentView
        let cost = mcvc_effectiveContinuePointCost()
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
        /// 默认 `.pause` 会在每圈结尾先进入暂停，图标会闪成「未播放」；手动 loop 用 `.none`。
        player.actionAtItemEnd = .none
        return player
    }

    private func mcvc_applyDetailMedia(item: MCSFeedItem, webpHandoff: MCCWebpPlaybackHandoff?, thumbnailPixelSize: CGSize) {
        mcvc_webpTransportAnimating = false
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
            mcvc_refreshTransportControlIcons()
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
            mcvc_webpTransportAnimating = true
            mcvc_refreshTransportControlIcons()
            return
        }
        let webpTrim = asset.webpImageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if let u = URL(string: webpTrim), !webpTrim.isEmpty {
            v.mcvw_webpImageView.autoPlayAnimatedImage = true
            v.mcvw_webpImageView.isHidden = false
            v.mcvw_webpImageView.sd_setImage(with: u, placeholderImage: nil, options: [], completed: { [weak self] _, _, _, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.mcvc_webpTransportAnimating = true
                    self.contentView.mcvw_webpImageView.startAnimating()
                    self.mcvc_refreshTransportControlIcons()
                }
            })
            return
        }
        v.mcvw_webpImageView.sd_cancelCurrentImageLoad()
        v.mcvw_webpImageView.image = nil
        v.mcvw_webpImageView.isHidden = true
        mcvc_refreshTransportControlIcons()
    }

    /// 播放中 `ic_cm_play_on` / 未播放 `ic_cm_play_off`；静音 `ic_cm_volume_off` / 出声 `ic_cm_volume_on`。WebP 无音轨：仅更新播放图标，音量示意用 `volume_on`。
    /// 不做 `[weak self]` 派发：在 deinit / 已离场后再形成 weak reference 会 ObjC runtime abort。改为「同步执行 + 严格守卫」。
    private func mcvc_refreshTransportControlIcons() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [view = self.view] in
                _ = view
                /// 离开主线程的路径里不再回调自身，避免对 deallocating 的 controller 形成 weak ref；视图最近的状态由下一次 viewWillAppear / 触发点重刷。
            }
            return
        }
        guard isViewLoaded, view.window != nil else { return }
        let v = contentView

        if let p = mcvc_mp4Player {
            let playing = mcvc_mp4TransportShowsPlaying(p)
            mcvc_setPlayIconIfNeeded(playing ? "ic_cm_play_on" : "ic_cm_play_off", on: v)
            mcvc_setVolumeIconIfNeeded(p.isMuted ? "ic_cm_volume_off" : "ic_cm_volume_on", on: v)
            return
        }

        let w = v.mcvw_webpImageView
        if !w.isHidden, w.image != nil {
            mcvc_setPlayIconIfNeeded(w.isAnimating ? "ic_cm_play_on" : "ic_cm_play_off", on: v)
        } else {
            mcvc_setPlayIconIfNeeded("ic_cm_play_off", on: v)
        }
        mcvc_setVolumeIconIfNeeded("ic_cm_volume_on", on: v)
    }

    private func mcvc_setPlayIconIfNeeded(_ name: String, on v: MCCFeedDetailView) {
        if name == mcvc_lastTransportPlayIconName { return }
        mcvc_lastTransportPlayIconName = name
        v.mcvw_playPauseButton.setImage(UIImage(named: name)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    private func mcvc_setVolumeIconIfNeeded(_ name: String, on v: MCCFeedDetailView) {
        if name == mcvc_lastTransportMuteIconName { return }
        mcvc_lastTransportMuteIconName = name
        v.mcvw_muteButton.setImage(UIImage(named: name)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    /// 与「仅看 `timeControlStatus == .playing`」相比，把 seek/重开缓冲等短暂态仍视为在播，避免图标来回切。
    private func mcvc_mp4TransportShowsPlaying(_ p: AVPlayer) -> Bool {
        switch p.timeControlStatus {
        case .paused:
            return false
        case .playing:
            return true
        case .waitingToPlayAtSpecifiedRate:
            return true
        @unknown default:
            return p.rate > 0.01
        }
    }

    private func mcvc_stringHasHttpHttpsURL(_ raw: String) -> Bool {
        guard !raw.isEmpty, let u = URL(string: raw), let scheme = u.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    /// `deinit` 期间访问 `contentView`/`self.view` 会触发 lazy load 与 KVO 重入，故在此函数内不假定视图存活；视图相关 reset 由调用方（仍在 view 生命周期内）通过 `isViewLoaded` 包裹。
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
        mcvc_lastTransportPlayIconName = nil
        mcvc_lastTransportMuteIconName = nil
        // 在 view.window != nil 时才刷新 UI；deinit / pop 后跳过，避免对 deallocating self 形成 [weak self]（会触发 ObjC runtime abort：Cannot form weak reference to instance ... in the process of deallocation）。
        if isViewLoaded, view.window != nil {
            contentView.mcvw_bindMp4Playback(player: nil, surfaceVisible: false)
            mcvc_refreshTransportControlIcons()
        }
    }

    private func mcvc_addMp4ProgressObserver(for player: AVPlayer) {
        let interval = CMTime(seconds: 0.12, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        mcvc_mp4PeriodicObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            /// 勿在此反复 `setImage`：会打断 `UIButton` 触摸（暂停后点静音尤明显）；进度与播控图标无关。
            guard let item = player.currentItem else { return }
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
            mcvc_refreshTransportControlIcons()
            return
        }
        let w = contentView.mcvw_webpImageView
        guard !w.isHidden, w.image != nil else { return }
        if w.isAnimating {
            w.stopAnimating()
        } else {
            w.startAnimating()
        }
        mcvc_refreshTransportControlIcons()
    }

    @objc
    private func mcvc_muteTapped() {
        if let player = mcvc_mp4Player {
            player.isMuted.toggle()
            mcvc_refreshTransportControlIcons()
        }
    }

    private func mcvc_refreshFavoriteChrome() {
        let v = contentView
        let liked = mcvc_feedItem?.likedByUser ?? false
        let iconName = liked ? "ic_cm_like" : "ic_cm_dislike"
        v.mcvw_favoriteButton.setImage(UIImage(named: iconName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        let likes = max(0, mcvc_feedItem?.likesCount ?? 0)
        v.mcvw_favoriteCountLabel.text = NumberFormatter.localizedString(from: NSNumber(value: likes), number: .decimal)
    }

    @objc
    private func mcvc_favoriteTapped() {
        guard let item = mcvc_feedItem else { return }
        let ref = item.itemId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ref.isEmpty else { return }

        mcvc_favoriteCancellable?.cancel()

        let wasLiked = item.likedByUser
        var rq = MCSFeedDetailRequest()
        rq.templateRef = ref

        let pipeline: AnyPublisher<MCSEmpty, MCENetworkError> =
            wasLiked ? MCCFeedAPIManager.shared.favorCancel(with: rq) : MCCFeedAPIManager.shared.favorApply(with: rq)

        contentView.mcvw_favoriteButton.isUserInteractionEnabled = false
        mcvc_favoriteCancellable = pipeline
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.contentView.mcvw_favoriteButton.isUserInteractionEnabled = true
                if case let .failure(err) = completion {
                    MCCToastManager.showToast(err.localizedDescription, in: self.view)
                }
            }, receiveValue: { [weak self] _ in
                guard let self else { return }
                var next = item
                if wasLiked {
                    next.likedByUser = false
                    next.likesCount = max(0, next.likesCount - 1)
                } else {
                    next.likedByUser = true
                    next.likesCount = next.likesCount + 1
                }
                self.mcvc_feedItem = next
                self.mcvc_refreshFavoriteChrome()
            })
    }

    private func mcvc_syncBottomBar() {
        let v = contentView
        let showVideoSettings = mcvc_feedItem?.contentKind.isToVideo ?? true
        v.mcvw_configureDurationAndMusicPillsVisible(showVideoSettings)
        let r = ["480P", "720P", "1080P"]
        v.mcvw_resolutionValueLabel.text = r[min(mcvc_resolutionIndex, r.count - 1)]
        v.mcvw_durationValueLabel.text = mcvc_durationIsTen ? "10s" : "5s"
        let m = ["Original", "Generated"]
        v.mcvw_modeValueLabel.text = m[min(mcvc_modeIndex, m.count - 1)]
        mcvc_refreshContinueButtonState()
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
        guard let item = mcvc_feedItem else { return }
        let templateRef = item.itemId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !templateRef.isEmpty else { return }
        MCCToastManager.showHUD(in: self.view)
        mcvc_runComposeSeedPipeline(
            images: mcvc_characterCircleImages,
            existingRemoteURLs: mcvc_characterRemoteImageURLs,
            templateRef: templateRef
        )
    }

    private func mcvc_runComposeSeedPipeline(images: [UIImage?], existingRemoteURLs: [String?], templateRef: String) {
        guard images.count == existingRemoteURLs.count, !images.isEmpty else {
            MCCToastManager.hide()
            return
        }
        let firstUIImage = images.first.flatMap { $0 }
        let tf = existingRemoteURLs.first.flatMap { $0 }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let firstPreviewURL: String?
        if firstUIImage == nil, !tf.isEmpty {
            firstPreviewURL = tf
        } else {
            firstPreviewURL = nil
        }
        
        let qualityRaw = mcvc_resolutionIndex
        let durationRaw = mcvc_durationIsTen ? 10 : 5
        mcvc_composeSeedCancellable?.cancel()
        mcvc_composeSeedCancellable = MCCOSSImageUploader.shared
            .mcvc_resolveImageListURLs(images: images, existingRemoteURLs: existingRemoteURLs)
            .handleEvents(receiveOutput: { [weak self] keys in
                guard let self else { return }
                for i in keys.indices where i < self.mcvc_characterRemoteImageURLs.count {
                    self.mcvc_characterRemoteImageURLs[i] = keys[i]
                }
            })
            .flatMap { keys -> AnyPublisher<MCSRunItem, MCCOSSImageUploadError> in
                var rq = MCSComposeSeedRequest()
                rq.templateRef = templateRef
                rq.imageList = keys
                rq.outputQuality = String(qualityRaw)
                rq.clipDuration = String(durationRaw)
                return MCCRunAPIManager.shared
                    .composeSeed(with: rq)
                    .mapError { MCCOSSImageUploadError.backend($0) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                if case let .failure(err) = completion {
                    MCCToastManager.hide()
                    let message = self.mcvc_messageForComposeSeedFailure(err)
                    MCCToastManager.showToast(message, in: self.view)
                }
            }, receiveValue: { [weak self] runItem in
                MCCToastManager.hide()
                let sheet = MCCFeedGeneratingSheetController()
                sheet.mcvc_configure(
                    userPreview: firstUIImage,
                    userPreviewFallbackURLString: firstPreviewURL,
                    seedRunItem: runItem
                )
                self?.present(sheet, animated: true)
            })
    }

    private func mcvc_messageForComposeSeedFailure(_ err: MCCOSSImageUploadError) -> String {
        switch err {
        case .missingImageData:
            return "Image is empty."
        case .missingObjectKey:
            return "Upload session expired."
        case .ossPutFailed(let underlying):
            return underlying.localizedDescription
        case .backend(let net):
            return net.localizedDescription
        }
    }

    private func mcvc_presentResolutionPop() {
        let pill = contentView.mcvw_resolutionPill
        let p = MCCFeedResolutionPopController()
        p.mcvc_currentIndex = mcvc_resolutionIndex
        p.mcvc_anchorFrame = mcvc_anchorFrameInPopWindow(of: pill)
        p.mcvc_anchorAlignment = .leading
        p.mcvc_onSelectIndex = { [weak self] i in
            self?.mcvc_resolutionIndex = i
            self?.mcvc_syncBottomBar()
        }
        present(p, animated: true)
    }

    private func mcvc_presentDurationPop() {
        let pill = contentView.mcvw_durationPill
        let p = MCCFeedDurationPopController()
        p.mcvc_currentIsTen = mcvc_durationIsTen
        p.mcvc_anchorFrame = mcvc_anchorFrameInPopWindow(of: pill)
        p.mcvc_anchorAlignment = .center
        p.mcvc_onSelectIsTen = { [weak self] isTen in
            self?.mcvc_durationIsTen = isTen
            self?.mcvc_syncBottomBar()
        }
        present(p, animated: true)
    }

    private func mcvc_presentModePop() {
        let pill = contentView.mcvw_modePill
        let p = MCCFeedModePopController()
        p.mcvc_currentIndex = mcvc_modeIndex
        p.mcvc_anchorFrame = mcvc_anchorFrameInPopWindow(of: pill)
        p.mcvc_anchorAlignment = .trailing
        p.mcvc_onSelectIndex = { [weak self] i in
            self?.mcvc_modeIndex = i
            self?.mcvc_syncBottomBar()
        }
        present(p, animated: true)
    }

    /// `MCCPopController` 把弹窗 view 限定在 `dimmingInsets` 内（顶部 nav、底部 tabBar），
    /// 这里把 trigger pill 的 frame 转成弹窗 view 自己的坐标系。
    private func mcvc_anchorFrameInPopWindow(of pill: UIView) -> CGRect {
        let windowFrame = pill.convert(pill.bounds, to: nil)
        let topInset = MCCScreenSize.navigationBarHeight
        return windowFrame.offsetBy(dx: 0, dy: -topInset)
    }

    @objc
    private func mcvc_characterCircleRemoveTapped(_ sender: UIButton) {
        let i = sender.tag
        guard (0 ..< mcvc_characterCircleImages.count).contains(i) else { return }
        mcvc_characterCircleImages[i] = nil
        mcvc_characterRemoteImageURLs[i] = nil
        mcvc_activeCharacterSlotIndex = i
        mcvc_syncCharacterCirclesAppearance()
    }

    private func mcvc_syncCharacterCirclesAppearance() {
        guard !contentView.mcvw_characterCircleSlots.isEmpty,
              mcvc_characterCircleImages.count == contentView.mcvw_characterCircleSlots.count else { return }
        mcvc_activeCharacterSlotIndex = mcvc_clampCharacterSlotIndex(mcvc_activeCharacterSlotIndex)
        let v = contentView
        for i in mcvc_characterCircleImages.indices {
            v.mcvw_characterCircleSlots[i].mcvw_apply(
                image: mcvc_characterCircleImages[i],
                remotePreviewURL: mcvc_characterRemoteImageURLs[i]
            )
        }
        v.mcvw_applyCharacterSlotsSelection(activeSlotIndex: mcvc_activeCharacterSlotIndex)
        mcvc_refreshContinueButtonState()
    }

    private func mcvc_offerPickedCharacterImageToSlots(_ img: UIImage) {
        guard !mcvc_characterCircleImages.isEmpty else { return }
        let target = mcvc_clampCharacterSlotIndex(mcvc_activeCharacterSlotIndex)
        mcvc_characterCircleImages[target] = img
        mcvc_characterRemoteImageURLs[target] = nil
        mcvc_advanceActiveSlotAfterFill(filledAt: target)
        mcvc_syncCharacterCirclesAppearance()
    }

    private func mcvc_advanceActiveSlotAfterFill(filledAt index: Int) {
        guard !mcvc_characterCircleImages.isEmpty else { return }
        let n = mcvc_characterCircleImages.count
        guard mcvc_characterCircleImages.contains(where: { $0 == nil }) else { return }
        if index + 1 < n, let j = (index + 1 ..< n).first(where: { mcvc_characterCircleImages[$0] == nil }) {
            mcvc_activeCharacterSlotIndex = j
            return
        }
        if let j = mcvc_characterCircleImages.indices.first(where: { mcvc_characterCircleImages[$0] == nil }) {
            mcvc_activeCharacterSlotIndex = j
        }
    }

    private func mcvc_clampCharacterSlotIndex(_ i: Int) -> Int {
        let n = max(1, mcvc_characterCircleImages.count)
        return min(max(i, 0), n - 1)
    }

    private func mcvc_removeCharacterSelectionGestures() {
        for g in mcvc_characterSelectionTapGestures {
            g.view?.removeGestureRecognizer(g)
        }
        mcvc_characterSelectionTapGestures.removeAll()
    }

    private func mcvc_bindCharacterSlotSelectionGestures() {
        mcvc_removeCharacterSelectionGestures()
        guard !contentView.mcvw_characterCircleSlots.isEmpty else { return }

        func add(on view: UIView, index: Int) {
            view.tag = index
            view.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(mcvc_characterSlotTapSelect(_:)))
            view.addGestureRecognizer(tap)
            mcvc_characterSelectionTapGestures.append(tap)
        }

        for (ix, slot) in contentView.mcvw_characterCircleSlots.enumerated() {
            add(on: slot, index: ix)
        }
    }

    @objc
    private func mcvc_characterSlotTapSelect(_ g: UITapGestureRecognizer) {
        guard let v = g.view else { return }
        let ix = v.tag
        guard (0 ..< mcvc_characterCircleImages.count).contains(ix) else { return }
        mcvc_activeCharacterSlotIndex = ix
        mcvc_syncCharacterCirclesAppearance()
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
        let ok = MCCRecentPickedPhotoStore.hasValidRecentPickForTile()
        contentView.mcvw_configureCharacterRecentTileVisible(ok)
        if !ok {
            mcvc_recentTileSyncedAssetId = nil
            contentView.mcvw_characterRecentImageView.image = nil
        }
    }

    /// 从全局 `UserDefaults` 快照拉一张磁贴预览；别处（含引导）选过的图会一直占最近一条。
    private func mcvc_refreshRecentTileThumbnailFromStoreIfNeeded() {
        mcvc_applyCharacterRecentVisibility()
        guard !contentView.mcvw_characterRecentTile.isHidden else { return }
        guard let id = MCCRecentPickedPhotoStore.localIdentifiers.first else { return }
        if id == MCCRecentPickedPhotoStore.photoLibraryFallbackPlaceholderId {
            if id == mcvc_recentTileSyncedAssetId,
               contentView.mcvw_characterRecentImageView.image != nil {
                return
            }
            guard let url = MCCRecentPickedPhotoStore.fallbackJPEGFileURLIfPresent(),
                  let img = UIImage(contentsOfFile: url.path) else { return }
            mcvc_recentTileSyncedAssetId = id
            contentView.mcvw_characterRecentImageView.image = img
            return
        }
        if id == mcvc_recentTileSyncedAssetId,
           contentView.mcvw_characterRecentImageView.image != nil {
            return
        }
        let side = UIScreen.main.scale * 168
        mcvc_requestRecentUIImage(localIdentifier: id, targetPixelSide: side) { [weak self] img in
            DispatchQueue.main.async {
                guard let self else { return }
                guard MCCRecentPickedPhotoStore.localIdentifiers.first == id else { return }
                self.mcvc_recentTileSyncedAssetId = id
                self.contentView.mcvw_characterRecentImageView.image = img
            }
        }
    }

    /// 相册 `PHAsset`；若资源已删除则返回 nil。
    private func mcvc_requestRecentUIImage(localIdentifier id: String, targetPixelSide: CGFloat, completion: @escaping (UIImage?) -> Void) {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [trimmed], options: nil)
        guard let asset = assets.firstObject else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = targetPixelSide > 540 ? .highQualityFormat : .opportunistic
        let px = CGSize(width: targetPixelSide, height: targetPixelSide)
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: px,
            contentMode: .aspectFill,
            options: opts
        ) { img, _ in
            DispatchQueue.main.async {
                completion(img)
            }
        }
    }

    @objc
    private func mcvc_characterRecentTapped() {
        guard let id = MCCRecentPickedPhotoStore.localIdentifiers.first else { return }
        if id == MCCRecentPickedPhotoStore.photoLibraryFallbackPlaceholderId {
            guard let url = MCCRecentPickedPhotoStore.fallbackJPEGFileURLIfPresent(),
                  let img = UIImage(contentsOfFile: url.path) else { return }
            mcvc_offerPickedCharacterImageToSlots(img)
            return
        }
        let longest = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        mcvc_requestRecentUIImage(localIdentifier: id, targetPixelSide: UIScreen.main.scale * longest) { [weak self] img in
            guard let self, let img else { return }
            self.mcvc_offerPickedCharacterImageToSlots(img)
        }
    }
}

extension MCCFeedDetailController: PHPickerViewControllerDelegate {

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let r = results.first else { return }
        if let id = r.assetIdentifier {
            MCCRecentPickedPhotoStore.record(localIdentifier: id)
            mcvc_recentTileSyncedAssetId = id
        }
        mcvc_applyCharacterRecentVisibility()
        let prov = r.itemProvider
        guard prov.canLoadObject(ofClass: UIImage.self) else { return }
        _ = prov.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            let img = object as? UIImage
            DispatchQueue.main.async {
                guard let self, let img else { return }
                if r.assetIdentifier == nil {
                    if let data = img.jpegData(compressionQuality: 0.92) ?? img.pngData() {
                        let ok = MCCRecentPickedPhotoStore.recordFallbackJPEGData(data)
                        if ok {
                            self.mcvc_recentTileSyncedAssetId = MCCRecentPickedPhotoStore.photoLibraryFallbackPlaceholderId
                        }
                        self.mcvc_applyCharacterRecentVisibility()
                    }
                }
                self.contentView.mcvw_characterRecentImageView.image = img
                self.mcvc_offerPickedCharacterImageToSlots(img)
                self.mcvc_applyCharacterRecentVisibility()
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
