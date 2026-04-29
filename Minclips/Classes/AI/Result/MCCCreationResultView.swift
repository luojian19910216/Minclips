import UIKit
import Common
import Data
import SDWebImage
import SnapKit
import AVFoundation
import KTVHTTPCache

public enum MCCCreationResultKind {
    case failed
    case restricted
    case successImage
    case successVideo(totalDuration: TimeInterval)

}

public enum MCCCreationSuccessToolbarAction: Int {
    case retry = 0
    case edit = 1
    case save = 2

}

/// Failed/restricted detail preview insets & plate fill (white @ 6% alpha, square corners).
private enum MCCCreationResultPreviewMetrics {
    static let horizontalInset: CGFloat = 28
    static let topInset: CGFloat = 12

    /// Primary bottom bar (**`mccr_actionGlassBar`**, **`mccr_successPill`**) trailing edge inset from bottom **safe area** (**16**).
    static let toolbarBottomInsetFromSafeArea: CGFloat = 16

    /// Gap above the bottom bar (**32**): tools↔pill on video, poster↔bar on failure / success‑image.
    static let previewContentAboveButtonBarGap: CGFloat = 32

    /// Bottom toolbar strip (**failed / restricted** primary & **success** Retry·Edit·Save): **上图下文** capsule, **66** pt.
    static let successToolbarBarHeight: CGFloat = 66

    /// Top/bottom **layoutMargins** on primary & success bottom stacks (fits **上图下文** inside **`successToolbarBarHeight`**).
    static let toolbarBarStackVerticalMargins: CGFloat = 9

    /// Poster / plate bottom inset when bottom strip is visible (**16 + strip + 32**).
    static let previewPlateBottomInsetFromSafeArea: CGFloat =
        toolbarBottomInsetFromSafeArea + successToolbarBarHeight + previewContentAboveButtonBarGap

    /// Same as **`previewPlateBottomInsetFromSafeArea`** (success-image path命名保留).
    static let previewPlateBottomInsetWhenSuccessToolbar: CGFloat = previewPlateBottomInsetFromSafeArea

    static let previewPlateBackgroundAlpha: CGFloat = 0.06

    /// Gap between failure/restrict icon and status title (Failed / Restricted).
    static let failureIconToTitleVerticalSpacing: CGFloat = 20

    /// Title → subtitle, and paragraph gaps inside the subtitle (reason vs credits note).
    static let failureDetailVerticalSpacing: CGFloat = 8

    /// Bottom primary row: **`primaryActionIconSize`** (**failed** Retry = **`ic_cm_retry`** only; **restricted** Edit = circular **source thumbnail**).
    static let primaryActionIconSize: CGFloat = 28

    /// Thumbnail ↔ caption: **12** reg caption sits **6** pt below the icon (**failed/restricted** bar & success toolbar columns).
    static let primaryActionIconToTitleSpacing: CGFloat = 6

    /// White hairline stroke on the circular **source thumbnail** (failed Retry & restricted Edit).
    static let primaryActionSourceBorderWidth: CGFloat = 0.5

    /// White stroke on **`success`** toolbar **Edit** thumbnail only (**1** pt; Retry/Save icons have no chrome).
    static let successToolbarEditThumbBorderWidth: CGFloat = 1

    /// Left/right **layoutMargins** inside **`mccr_successStack`** / **`mccr_actionPrimaryStack`** (**28**).
    static let primaryActionBarInteriorHorizontalPadding: CGFloat = 28

    /// Gap between Retry / Edit / Save columns (**32** pt).
    static let successToolbarInterButtonSpacing: CGFloat = 32

    /// Legacy: stack vertical padding unused; strip height uses **`successToolbarBarHeight`**.
    static let primaryActionBarContentVerticalPadding: CGFloat = 0

    /// Success video: playback band top inset from **safe area top**.
    static let videoPlaybackTopInsetFromSafeArea: CGFloat = 12

    /// Breathing room between **`mccr_mediaContainer`** bottom and **`mccr_videoChrome`** top.
    static let videoChromeTopGapBelowPlaybackBand: CGFloat = 8

    /// Timeline + scrubber strip (**`mccr_videoChrome`**) intrinsic height (**178** pt); below **`mccr_successPill`** (**`previewContentAboveButtonBarGap`** + **`successToolbarBarHeight`**).
    static let videoToolsZoneHeight: CGFloat = 178

    /// Vertical gap (**32**) between **`mccr_videoChrome`** bottom and **`mccr_successPill`** top.
    static let videoChromeSpacingToSuccessPill: CGFloat =
        previewContentAboveButtonBarGap

    /// Same as **`videoToolsZoneHeight`** (**178** = tool row **44** + gap **10** + frame strip **124**，与 **`MCCFeedDetailView`** transport 对齐).
    static let videoChromeInteriorHeight: CGFloat = videoToolsZoneHeight

    /// Top tool row: time / play–pause / mute hits **44**（与 Feed 详情视频控制条一致）.
    static let videoTimelineControlRowHeight: CGFloat = 44

    static let videoTimelineControlToStripGap: CGFloat = 10

    /// Frame strip height derived from **`videoChromeInteriorHeight`** − tool row − gap.
    static let videoFrameStripHeight: CGFloat =
        videoChromeInteriorHeight - videoTimelineControlRowHeight - videoTimelineControlToStripGap
}

private enum MCCCreationFailureSubtitleStyle {
    /// `UILabel.textAlignment` is ignored for `attributedText`; alignment must live in `NSParagraphStyle`.
    private static func typographyBase(paragraphSpacingAfter: CGFloat? = nil) -> [NSAttributedString.Key: Any] {
        let ps = NSMutableParagraphStyle()
        ps.alignment = .center
        if let spacing = paragraphSpacingAfter {
            ps.paragraphSpacing = spacing
        }
        return [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.48),
            .paragraphStyle: ps,
        ]
    }

    static func attributed(_ plain: String) -> NSAttributedString {
        attributedParagraphsSeparatedByDoubleNewline(plain)
    }

    /// Splits by `\n\n`; matches stack spacing (`failureDetailVerticalSpacing`) between paragraphs (reason vs credits lines).
    private static func attributedParagraphsSeparatedByDoubleNewline(_ plain: String) -> NSAttributedString {
        let parts = plain.components(separatedBy: "\n\n").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard !parts.isEmpty else {
            return NSAttributedString(string: "")
        }
        if parts.count == 1 {
            return NSAttributedString(string: parts[0], attributes: typographyBase())
        }
        let gap = MCCCreationResultPreviewMetrics.failureDetailVerticalSpacing
        let out = NSMutableAttributedString()
        for (i, part) in parts.enumerated() {
            if i > 0 {
                out.append(NSAttributedString(string: "\n"))
            }
            let attrs = typographyBase(paragraphSpacingAfter: i < parts.count - 1 ? gap : nil)
            out.append(NSAttributedString(string: part, attributes: attrs))
        }
        return out
    }
}

private final class MCCFrameStripCell: UICollectionViewCell {

    static let reuseId = "MCCFrameStripCell"

    let mcc_thumbView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    let mcc_plusLabel: UILabel = {
        let l = UILabel()
        l.text = "+"
        l.font = .systemFont(ofSize: 22, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 4
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 1, alpha: 0.12)
        contentView.addSubview(mcc_thumbView)
        contentView.addSubview(mcc_plusLabel)
        mcc_thumbView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcc_plusLabel.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func mcc_configure(image: UIImage?, isAddSlot: Bool) {
        mcc_plusLabel.isHidden = !isAddSlot
        mcc_thumbView.isHidden = isAddSlot
        mcc_thumbView.image = image
    }

}

private final class MCCCreationResultMp4SurfaceView: UIView {

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var mccr_playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        mccr_playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class MCCCreationResultView: MCCBaseView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /// Aligned with **`MCCFeedDetailView`** video transport: **44** pt hit, **12** pt image inset (`ic_cm_play_*` / `ic_cm_volume_*`).
    private enum MCCCreationResultTransport {
        static let controlHitSide: CGFloat = 44
        static let controlImageInset: CGFloat = 12
    }

    private let mccr_mediaContainer: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 0
        v.backgroundColor = UIColor(white: 1, alpha: MCCCreationResultPreviewMetrics.previewPlateBackgroundAlpha)
        return v
    }()

    private let mccr_imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .clear
        iv.isOpaque = false
        return iv
    }()

    /// Same blur as works-list thumbnails (`MCCProjectsListPageView.mcvw_blurOverlay` — `.dark`).
    private let mccr_blurView: UIVisualEffectView = {
        let e = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        e.isUserInteractionEnabled = false
        return e
    }()

    /// Detail badges: `ic_cm_failed_detail` / `ic_cm_restricted_detail` (works list keeps `ic_cm_*` without `_detail`).
    private let mccr_failureStatusIconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.setContentCompressionResistancePriority(.required, for: .vertical)
        return v
    }()

    private let mccr_statusStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = MCCCreationResultPreviewMetrics.failureDetailVerticalSpacing
        return s
    }()

    public let mccr_titleLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        return l
    }()

    public let mccr_subtitleLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.48)
        l.numberOfLines = 0
        l.setContentHuggingPriority(.required, for: .vertical)
        return l
    }()

    public let mccr_actionButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setContentHuggingPriority(.required, for: .vertical)
        b.backgroundColor = .clear
        b.isOpaque = false
        return b
    }()

    /// Bottom **Retry / Edit** strip：与成功条一致 **白 6%**，**上图下文**胶囊。
    private let mccr_actionGlassBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        v.isHidden = true
        return v
    }()

    private let mccr_actionPrimaryStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = MCCCreationResultPreviewMetrics.primaryActionIconToTitleSpacing
        s.isUserInteractionEnabled = false
        s.isLayoutMarginsRelativeArrangement = true
        s.layoutMargins = UIEdgeInsets(
            top: MCCCreationResultPreviewMetrics.toolbarBarStackVerticalMargins,
            left: MCCCreationResultPreviewMetrics.primaryActionBarInteriorHorizontalPadding,
            bottom: MCCCreationResultPreviewMetrics.toolbarBarStackVerticalMargins,
            right: MCCCreationResultPreviewMetrics.primaryActionBarInteriorHorizontalPadding
        )
        return s
    }()

    private let mccr_actionIconContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.clipsToBounds = true
        v.backgroundColor = .clear
        return v
    }()

    private let mccr_actionIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let mccr_actionAvatarView: UIImageView = {
        let iv = UIImageView()
        iv.isHidden = true
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    /// Primary Retry/Edit caption: **12 regular**, **white**.
    private let mccr_actionTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 1
        l.isUserInteractionEnabled = false
        return l
    }()

    /// Invalidates stale `sd_setImage` completions when rebound or leaving failed detail.
    private var mccr_posterLoadGeneration: UInt = 0

    private var mccr_actionThumbLoadGeneration: UInt = 0

    private let mccr_successPill: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        return v
    }()

    private let mccr_successStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .fillEqually
        s.spacing = MCCCreationResultPreviewMetrics.successToolbarInterButtonSpacing
        s.isLayoutMarginsRelativeArrangement = true
        s.layoutMargins = UIEdgeInsets(
            top: MCCCreationResultPreviewMetrics.toolbarBarStackVerticalMargins,
            left: MCCCreationResultPreviewMetrics.primaryActionBarInteriorHorizontalPadding,
            bottom: MCCCreationResultPreviewMetrics.toolbarBarStackVerticalMargins,
            right: MCCCreationResultPreviewMetrics.primaryActionBarInteriorHorizontalPadding
        )
        return s
    }()

    public private(set) var mccr_successActionButtons: [UIButton] = []

    private let mccr_videoChrome = UIView()

    /// Top band of **`mccr_videoChrome`**: left time, centered play/pause, right mute (**`videoTimelineControlRowHeight`**).
    private let mccr_videoToolTopRow = UIView()

    private let mccr_timeLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return l
    }()

    private let mccr_playButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "ic_cm_play_off")?.withRenderingMode(.alwaysOriginal), for: .normal)
        b.adjustsImageWhenHighlighted = false
        return b
    }()

    private let mccr_volumeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "ic_cm_volume_off")?.withRenderingMode(.alwaysOriginal), for: .normal)
        b.adjustsImageWhenHighlighted = false
        return b
    }()

    private lazy var mccr_frameCollection: UICollectionView = {
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .horizontal
        flow.minimumInteritemSpacing = 4
        flow.minimumLineSpacing = 4
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flow)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.dataSource = self
        cv.delegate = self
        cv.register(MCCFrameStripCell.self, forCellWithReuseIdentifier: MCCFrameStripCell.reuseId)
        return cv
    }()

    private let mccr_playheadView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    private var mccr_frameImages: [UIImage] = []

    private var mccr_videoDuration: TimeInterval = 15

    private var mccr_isVideoMode: Bool = false

    /// First `outputArtifacts` **`width`**×**`height`** (fallback 16∶9); drives aspect-fit rect for `mccr_mediaContainer` in video result mode.
    private var mccr_videoArtifactPixelSize: CGSize = CGSize(width: 16, height: 9)

    private var mccr_isPlaying: Bool = false

    private let mccr_mp4SurfaceView = MCCCreationResultMp4SurfaceView()

    private var mccr_resultPlayer: AVPlayer?

    private var mccr_resultVideoPeriodicObserver: Any?

    private var mccr_resultVideoEndObserver: NSObjectProtocol?

    /// Same pattern as **`MCCFeedDetailController`**: avoid redundant `setImage` (touches / performance).
    private var mccr_lastTransportPlayIconName: String?

    private var mccr_lastTransportMuteIconName: String?

    public var mccr_onSuccessToolbar: ((MCCCreationSuccessToolbarAction) -> Void)?

    /// Initial layout mirrors `mccr_applyErrorChrome` preview + bottom primary row (blur pill + Retry/Edit).
    private func mccr_installPrimaryActionChromeLayout() {
        mccr_actionPrimaryStack.snp.makeConstraints { $0.center.equalToSuperview() }

        mccr_actionGlassBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.toolbarBottomInsetFromSafeArea)
            make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
            make.width.equalTo(mccr_actionPrimaryStack.snp.width)
            make.height.equalTo(MCCCreationResultPreviewMetrics.successToolbarBarHeight)
        }

        mccr_actionButton.snp.makeConstraints { $0.edges.equalToSuperview() }

        mccr_mediaContainer.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(MCCCreationResultPreviewMetrics.topInset)
            make.leading.trailing.equalToSuperview().inset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.previewPlateBottomInsetFromSafeArea)
        }
    }

    public override func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "121212")

        addSubview(mccr_mediaContainer)
        mccr_mediaContainer.addSubview(mccr_imageView)
        mccr_mediaContainer.addSubview(mccr_mp4SurfaceView)
        mccr_mediaContainer.addSubview(mccr_blurView)
        mccr_mediaContainer.addSubview(mccr_statusStack)
        
        mccr_statusStack.addArrangedSubview(mccr_failureStatusIconView)
        mccr_statusStack.addArrangedSubview(mccr_titleLabel)
        mccr_statusStack.addArrangedSubview(mccr_subtitleLabel)
        mccr_statusStack.setCustomSpacing(
            MCCCreationResultPreviewMetrics.failureIconToTitleVerticalSpacing,
            after: mccr_failureStatusIconView
        )
        mccr_subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        addSubview(mccr_actionGlassBar)
        mccr_actionPrimaryStack.addArrangedSubview(mccr_actionIconContainer)
        mccr_actionPrimaryStack.addArrangedSubview(mccr_actionTitleLabel)

        mccr_actionIconContainer.addSubview(mccr_actionIconView)
        mccr_actionIconContainer.addSubview(mccr_actionAvatarView)

        // Tap fills the strip; icons + caption sit in the stack (上图下文).
        mccr_actionGlassBar.addSubview(mccr_actionButton)
        mccr_actionGlassBar.addSubview(mccr_actionPrimaryStack)

        mccr_installPrimaryActionChromeLayout()

        addSubview(mccr_videoChrome)
        mccr_videoChrome.isHidden = true
        mccr_videoChrome.addSubview(mccr_videoToolTopRow)
        mccr_videoToolTopRow.addSubview(mccr_timeLabel)
        mccr_videoToolTopRow.addSubview(mccr_playButton)
        mccr_videoToolTopRow.addSubview(mccr_volumeButton)
        mccr_videoChrome.addSubview(mccr_frameCollection)
        mccr_videoChrome.addSubview(mccr_playheadView)

        addSubview(mccr_successPill)
        mccr_successPill.addSubview(mccr_successStack)
        mccr_successPill.isHidden = true
        mccr_buildSuccessToolbar()

        mccr_imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mccr_mp4SurfaceView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mccr_mp4SurfaceView.isHidden = true
        mccr_blurView.snp.makeConstraints { $0.edges.equalToSuperview() }

        mccr_statusStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
        }
        layoutIfNeeded()
        setPlaceholderImage()

        let iconSZ = MCCCreationResultPreviewMetrics.primaryActionIconSize
        mccr_actionIconContainer.snp.makeConstraints { make in
            make.size.equalTo(iconSZ)
        }
        mccr_actionIconView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mccr_actionAvatarView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mccr_successPill.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.toolbarBottomInsetFromSafeArea)
            make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
            make.height.equalTo(MCCCreationResultPreviewMetrics.successToolbarBarHeight)
        }
        mccr_successStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        mccr_videoChrome.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mccr_successPill.snp.top)
                .offset(-MCCCreationResultPreviewMetrics.videoChromeSpacingToSuccessPill)
            make.height.equalTo(MCCCreationResultPreviewMetrics.videoChromeInteriorHeight)
        }
        mccr_videoToolTopRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(MCCCreationResultPreviewMetrics.videoTimelineControlRowHeight)
        }
        mccr_timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(mccr_playButton.snp.leading).offset(-8)
        }
        mccr_playButton.snp.makeConstraints { make in
            make.centerX.equalTo(mccr_videoChrome.snp.centerX)
            make.centerY.equalToSuperview()
            make.size.equalTo(MCCCreationResultTransport.controlHitSide)
        }
        mccr_volumeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(MCCCreationResultTransport.controlHitSide)
            make.leading.greaterThanOrEqualTo(mccr_playButton.snp.trailing).offset(8)
        }
        mccr_frameCollection.snp.makeConstraints { make in
            make.top.equalTo(mccr_videoToolTopRow.snp.bottom).offset(MCCCreationResultPreviewMetrics.videoTimelineControlToStripGap)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(MCCCreationResultPreviewMetrics.videoFrameStripHeight)
            make.bottom.equalToSuperview()
        }
        mccr_playheadView.snp.makeConstraints { make in
            make.width.equalTo(2)
            make.top.bottom.equalTo(mccr_frameCollection)
            make.centerX.equalTo(mccr_frameCollection)
        }

        let inset = MCCCreationResultTransport.controlImageInset
        let pad = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        mccr_playButton.contentEdgeInsets = pad
        mccr_volumeButton.contentEdgeInsets = pad

        mccr_playButton.addTarget(self, action: #selector(mccr_togglePlay), for: .touchUpInside)
        mccr_volumeButton.addTarget(self, action: #selector(mccr_toggleResultVideoMute), for: .touchUpInside)
    }

    /// Sets `outputArtifacts.first` pixel sizing for playback aspect layout (typically before `mccr_apply(kind:)` when kind is `.successVideo`).
    public func mccr_setVideoArtifactPixelDimensions(from run: MCSRunItem) {
        let s = run.mcc_primaryOutputArtifactPixelDimensions()
        mccr_setVideoArtifactPixelDimensions(width: s.width, height: s.height)
    }

    public func mccr_setVideoArtifactPixelDimensions(width: CGFloat, height: CGFloat) {
        mccr_videoArtifactPixelSize = CGSize(width: max(1, width), height: max(1, height))
        if mccr_isVideoMode {
            setNeedsLayout()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        mccr_syncPrimaryActionGlassCorner()
        mccr_syncSuccessToolbarCorner()
        mccr_relayoutVideoPlaybackAreaIfNeeded()
    }

    /// Video result: bottom‑up stack from **`toolbarBottomInsetFromSafeArea`** (pill) through chrome; aspect‑fit **`mccr_mediaContainer`** in the band capped at **`mediaBottomMaxY`**, with **`videoChromeTopGapBelowPlaybackBand`** between rect bottom and chrome **top**.
    private func mccr_relayoutVideoPlaybackAreaIfNeeded() {
        guard mccr_isVideoMode else { return }
        guard bounds.width > 8, bounds.height > 8 else { return }

        let m = MCCCreationResultPreviewMetrics.self
        let bandTopY = safeAreaInsets.top + m.videoPlaybackTopInsetFromSafeArea
        let contentSafeBottomY = bounds.height - safeAreaInsets.bottom
        let pillBottomY = contentSafeBottomY - m.toolbarBottomInsetFromSafeArea
        let barH = m.successToolbarBarHeight
        let vcH = m.videoChromeInteriorHeight
        let pillTopY = pillBottomY - barH
        let chromeTopY = pillTopY - m.videoChromeSpacingToSuccessPill - vcH
        let mediaBottomMaxY = chromeTopY - m.videoChromeTopGapBelowPlaybackBand
        guard mediaBottomMaxY > bandTopY + 44 else { return }

        let maxW = bounds.width
        let maxH = mediaBottomMaxY - bandTopY
        let vw = mccr_videoArtifactPixelSize.width
        let vh = mccr_videoArtifactPixelSize.height
        let scale = min(maxW / vw, maxH / vh)
        let w = vw * scale
        let h = vh * scale
        let x = (bounds.width - w) * 0.5
        let y = bandTopY + (maxH - h) * 0.5

        mccr_successPill.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-m.toolbarBottomInsetFromSafeArea)
            make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
            make.height.equalTo(barH)
        }

        mccr_mediaContainer.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(x)
            make.top.equalToSuperview().offset(y)
            make.width.equalTo(w)
            make.height.equalTo(h)
        }

        mccr_videoChrome.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(chromeTopY)
            make.height.equalTo(vcH)
        }
    }

    private func mccr_syncSuccessToolbarCorner() {
        guard mccr_successPill.isHidden == false else { return }
        let b = mccr_successPill.bounds
        guard b.width > 1, b.height > 1 else { return }
        mccr_successPill.layer.cornerRadius = b.height * 0.5
    }

    /// Failed / restricted bottom strip：**白 6%** 胶囊，`cornerRadius = height/2`。
    private func mccr_syncPrimaryActionGlassCorner() {
        guard mccr_actionGlassBar.isHidden == false else { return }
        let b = mccr_actionGlassBar.bounds
        guard b.width > 1, b.height > 1 else { return }
        let r = b.height * 0.5
        let v = mccr_actionGlassBar
        v.layer.cornerRadius = r
        v.layer.cornerCurve = .continuous
        v.layer.masksToBounds = true
    }

    private func mccr_buildSuccessToolbar() {
        mccr_successStack.arrangedSubviews.forEach {
            mccr_successStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        mccr_successActionButtons.removeAll()
        mccr_editThumbHost = nil

        let specs: [(String, MCCCreationSuccessToolbarAction, Bool)] = [
            ("Retry", .retry, false),
            ("Edit", .edit, true),
            ("Save", .save, false)
        ]
        for (title, action, useEditThumb) in specs {
            let iconSZ = MCCCreationResultPreviewMetrics.primaryActionIconSize
            let circle = UIView()
            circle.snp.makeConstraints { $0.size.equalTo(iconSZ) }
            if useEditThumb {
                circle.backgroundColor = .clear
                circle.layer.cornerRadius = iconSZ * 0.5
                circle.layer.cornerCurve = .continuous
                circle.layer.borderWidth = MCCCreationResultPreviewMetrics.successToolbarEditThumbBorderWidth
                circle.layer.borderColor = UIColor.white.cgColor
                circle.clipsToBounds = true
                let thumb = UIImageView()
                thumb.contentMode = .scaleAspectFill
                thumb.clipsToBounds = true
                thumb.layer.cornerRadius = 10
                circle.addSubview(thumb)
                thumb.snp.makeConstraints { $0.edges.equalToSuperview().inset(3) }
                mccr_editThumbHost = thumb
            } else {
                circle.backgroundColor = .clear
                let iv = UIImageView()
                switch action {
                case .retry:
                    iv.image = UIImage(named: "ic_cm_retry")?.withRenderingMode(.alwaysOriginal)
                case .save:
                    iv.image = UIImage(named: "ic_cm_download")?.withRenderingMode(.alwaysOriginal)
                case .edit:
                    break
                }
                iv.contentMode = .scaleAspectFit
                circle.addSubview(iv)
                iv.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.size.equalTo(iconSZ)
                }
            }

            let caption = UILabel()
            caption.text = title
            caption.font = .systemFont(ofSize: 12, weight: .regular)
            caption.textColor = .white
            caption.textAlignment = .center
            caption.numberOfLines = 1

            let col = UIStackView(arrangedSubviews: [circle, caption])
            col.axis = .vertical
            col.alignment = .center
            col.spacing = MCCCreationResultPreviewMetrics.primaryActionIconToTitleSpacing

            let btn = UIButton(type: .custom)
            btn.tag = action.rawValue
            btn.accessibilityLabel = title
            btn.addTarget(self, action: #selector(mccr_successToolbarTap(_:)), for: .touchUpInside)

            let wrap = UIView()
            wrap.addSubview(col)
            wrap.addSubview(btn)
            col.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview()
                make.trailing.lessThanOrEqualToSuperview()
            }
            btn.snp.makeConstraints { $0.edges.equalToSuperview() }
            mccr_successStack.addArrangedSubview(wrap)
            mccr_successActionButtons.append(btn)
        }
    }

    private var mccr_editThumbHost: UIImageView?

    @objc
    private func mccr_successToolbarTap(_ sender: UIButton) {
        guard let a = MCCCreationSuccessToolbarAction(rawValue: sender.tag) else { return }
        mccr_onSuccessToolbar?(a)
    }

    @objc
    private func mccr_togglePlay() {
        if let player = mccr_resultPlayer {
            switch player.timeControlStatus {
            case .playing:
                player.pause()
            default:
                player.play()
            }
            mccr_refreshResultTransportIcons()
            return
        }

        mccr_isPlaying.toggle()
        let name = mccr_isPlaying ? "ic_cm_play_on" : "ic_cm_play_off"
        mccr_setPlayIconIfNeeded(name)
        mccr_setVolumeIconIfNeeded("ic_cm_volume_on")
    }

    @objc
    private func mccr_toggleResultVideoMute() {
        guard let p = mccr_resultPlayer else { return }
        p.isMuted.toggle()
        mccr_refreshResultTransportIcons()
    }

    /// Playback / mute icons: **`ic_cm_play_*`**, **`ic_cm_volume_*`** (same filenames as **`MCCFeedDetailController`**).
    private func mccr_refreshResultTransportIcons() {
        guard let p = mccr_resultPlayer else { return }

        let playing = mccr_resultTransportShowsPlaying(p)
        mccr_setPlayIconIfNeeded(playing ? "ic_cm_play_on" : "ic_cm_play_off")
        mccr_setVolumeIconIfNeeded(p.isMuted ? "ic_cm_volume_off" : "ic_cm_volume_on")
    }

    private func mccr_setPlayIconIfNeeded(_ name: String) {
        if name == mccr_lastTransportPlayIconName { return }
        mccr_lastTransportPlayIconName = name
        mccr_playButton.setImage(UIImage(named: name)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    private func mccr_setVolumeIconIfNeeded(_ name: String) {
        if name == mccr_lastTransportMuteIconName { return }
        mccr_lastTransportMuteIconName = name
        mccr_volumeButton.setImage(UIImage(named: name)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    /// Same spirit as **`MCCFeedDetailController.mcvc_mp4TransportShowsPlaying`** (`seek`/buffer spikes stay “playing”).
    private func mccr_resultTransportShowsPlaying(_ p: AVPlayer) -> Bool {
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

    /// When the success toolbar is visible and we are not in video result mode, show a **clear** placeholder so
    /// `mccr_mediaContainer`’s plate (white @ 6 %) is visible; otherwise use the blue shimmer used on failed/restricted rows.
    private var mccr_successToolbarShowsPlateBehindImage: Bool {
        mccr_successPill.isHidden == false && mccr_isVideoMode == false
    }

    private func mccr_placeholderImageForMedia() -> UIImage {
        mccr_successToolbarShowsPlateBehindImage ? Self.mccr_placeholderClearForPlate : Self.mccr_placeholderGradient()
    }

    private static let mccr_placeholderClearForPlate: UIImage = {
        let sz = CGSize(width: 1, height: 1)
        let f = UIGraphicsImageRendererFormat()
        f.opaque = false
        f.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: sz, format: f).image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: sz))
        }
    }()

    private func setPlaceholderImage() {
        if mccr_imageView.image != nil { return }
        mccr_imageView.image = mccr_placeholderImageForMedia()
    }

    public func mccr_setPreviewImage(_ image: UIImage?) {
        mccr_imageView.image = image ?? mccr_placeholderImageForMedia()
        mccr_editThumbHost?.image = mccr_imageView.image
    }

    private func mccr_cancelPosterLoad() {
        mccr_removeResultVideoPlayback()
        mccr_posterLoadGeneration &+= 1
        mccr_imageView.sd_cancelCurrentImageLoad()
        mccr_actionThumbLoadGeneration &+= 1
        mccr_actionAvatarView.sd_cancelCurrentImageLoad()
    }

    private func mccr_removeResultVideoPlayback() {
        if let o = mccr_resultVideoPeriodicObserver, let player = mccr_resultPlayer {
            player.removeTimeObserver(o)
        }
        mccr_resultVideoPeriodicObserver = nil
        if let o = mccr_resultVideoEndObserver {
            NotificationCenter.default.removeObserver(o)
            mccr_resultVideoEndObserver = nil
        }
        mccr_resultPlayer?.pause()
        mccr_resultPlayer = nil
        mccr_mp4SurfaceView.mccr_playerLayer.player = nil
        mccr_mp4SurfaceView.isHidden = true
        mccr_lastTransportPlayIconName = nil
        mccr_lastTransportMuteIconName = nil
    }

    /// Current time (**white**) / total (**white @ 40%**) — **`12pt` `regular`**; total来自 **`run.mcc_primaryOutputArtifactDurationSeconds()`** 与播放器进度。
    private func mccr_applyResultTimeLabelAttributed(current playhead: TimeInterval, total artifactSeconds: TimeInterval) {
        let font = UIFont.systemFont(ofSize: 12, weight: .regular)
        let tot = max(0, artifactSeconds)
        var cur = max(0, playhead)
        if tot > 0 {
            cur = min(cur, tot)
        }
        let curS = mccr_formatClock(cur)
        let totS = mccr_formatClock(tot > 0 ? tot : 0)
        let m = NSMutableAttributedString()
        m.append(NSAttributedString(string: curS, attributes: [
            .font: font,
            .foregroundColor: UIColor.white
        ]))
        m.append(NSAttributedString(string: " / ", attributes: [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ]))
        m.append(NSAttributedString(string: totS, attributes: [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ]))
        mccr_timeLabel.attributedText = m
    }

    private func mccr_addResultVideoPeriodicObserver(for player: AVPlayer) {
        if let o = mccr_resultVideoPeriodicObserver {
            player.removeTimeObserver(o)
        }
        mccr_resultVideoPeriodicObserver = nil

        let interval = CMTime(seconds: 0.12, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        mccr_resultVideoPeriodicObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            [weak self] _ in
            guard let self else { return }
            guard let player = self.mccr_resultPlayer else { return }
            /// 只做时间文案：**勿**在每拍 `setImage`（与 Feed 一致，避免打断触摸）。
            let sec = CMTimeGetSeconds(player.currentTime())
            let cur = sec.isFinite ? sec : 0
            self.mccr_applyResultTimeLabelAttributed(current: cur, total: self.mccr_videoDuration)
        }
    }

    private func mccr_remoteResultMp4Player(url: URL) -> AVPlayer {
        let playURL = KTVHTTPCache.proxyURL(withOriginalURL: url, bindToLocalhost: false) as URL
        let assetOpts: [String: Any] = [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ]
        let asset = AVURLAsset(url: playURL, options: assetOpts)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 4
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        player.isMuted = true
        player.actionAtItemEnd = .none
        return player
    }

    private func mccr_attachResultVideoEndLoop(for player: AVPlayer) {
        if let o = mccr_resultVideoEndObserver {
            NotificationCenter.default.removeObserver(o)
            mccr_resultVideoEndObserver = nil
        }
        mccr_resultVideoEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.mccr_resultPlayer?.seek(to: .zero)
            self.mccr_resultPlayer?.play()
        }
    }

    private func mccr_urlLooksPlayableHttps(_ raw: String) -> Bool {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.isEmpty == false, let u = URL(string: t), let scheme = u.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private func mccr_bindSuccessVideoPosterAndPlayer(from run: MCSRunItem) {
        mccr_cancelPosterLoad()
        let token = mccr_posterLoadGeneration

        let thumbRaw = run.outputCoverThumbUrl.mcc_normalizedRemoteURL()
        if thumbRaw.isEmpty == false, let thumbURL = URL(string: thumbRaw) {
            mccr_blurView.isHidden = true
            mccr_imageView.image = nil
            mccr_imageView.sd_setImage(with: thumbURL, placeholderImage: mccr_placeholderImageForMedia(), options: [.retryFailed]) {
                [weak self] _, _, _, _ in
                guard let self else { return }
                guard self.mccr_posterLoadGeneration == token else { return }
                self.mccr_editThumbHost?.image = self.mccr_imageView.image
            }
        } else {
            mccr_blurView.isHidden = true
            mccr_imageView.image = nil
            setPlaceholderImage()
        }

        let durSec = run.mcc_primaryOutputArtifactDurationSeconds()
        if durSec > 0 {
            mccr_videoDuration = TimeInterval(durSec)
            mccr_frameImages = Self.mccr_stripImages(count: 18, duration: mccr_videoDuration)
            mccr_frameCollection.reloadData()
        }
        mccr_applyResultTimeLabelAttributed(current: 0, total: mccr_videoDuration)

        let mp4Raw = run.mcc_resultSuccessVideoMp4URLString().trimmingCharacters(in: .whitespacesAndNewlines)
        guard mccr_urlLooksPlayableHttps(mp4Raw), let mp4URL = URL(string: mp4Raw) else {
            return
        }

        let player = mccr_remoteResultMp4Player(url: mp4URL)
        mccr_lastTransportPlayIconName = nil
        mccr_lastTransportMuteIconName = nil
        mccr_resultPlayer = player
        mccr_mp4SurfaceView.mccr_playerLayer.player = player
        mccr_mp4SurfaceView.isHidden = false
        mccr_mediaContainer.bringSubviewToFront(mccr_mp4SurfaceView)
        mccr_attachResultVideoEndLoop(for: player)
        mccr_addResultVideoPeriodicObserver(for: player)
        player.play()
        mccr_isPlaying = true
        mccr_refreshResultTransportIcons()
    }

    /// Failed: **`sourceImageUrl`/poster** + blur policy like works-list. Success image: **`outputArtifacts.first.url`** (see `mcc_resultSuccessImageURLString()`). Success video: cover **`outputCoverThumbUrl`**, playback **`mcc_resultSuccessVideoMp4URLString()`** (first artifact).
    public func mccr_bindPosterFrom(run: MCSRunItem) {
        switch run.runState {
        case .failed:
            mccr_posterLoadGeneration &+= 1
            let token = mccr_posterLoadGeneration
            mccr_imageView.sd_cancelCurrentImageLoad()

            let pick = run.mcc_worksListThumbnail()
            let raw = pick.urlString.mcc_normalizedRemoteURL()
            guard raw.isEmpty == false, let remoteURL = URL(string: raw) else {
                mccr_blurView.isHidden = true
                mccr_imageView.image = nil
                setPlaceholderImage()
                mccr_bindPrimaryActionThumbnailIfNeeded(from: run)
                return
            }

            mccr_blurView.isHidden = !pick.blurOverlay
            mccr_imageView.image = nil
            mccr_imageView.sd_setImage(with: remoteURL, placeholderImage: mccr_placeholderImageForMedia(), options: [.retryFailed]) {
                [weak self] _, _, _, _ in
                guard let self else { return }
                guard self.mccr_posterLoadGeneration == token else { return }
                self.mccr_editThumbHost?.image = self.mccr_imageView.image
            }
            mccr_bindPrimaryActionThumbnailIfNeeded(from: run)

        case .success:
            if run.contentKind.isToVideo {
                mccr_bindSuccessVideoPosterAndPlayer(from: run)
                return
            }
            mccr_posterLoadGeneration &+= 1
            let token = mccr_posterLoadGeneration
            mccr_imageView.sd_cancelCurrentImageLoad()

            let raw = run.mcc_resultSuccessImageURLString().mcc_normalizedRemoteURL()
            guard raw.isEmpty == false, let remoteURL = URL(string: raw) else {
                mccr_blurView.isHidden = true
                mccr_imageView.image = nil
                setPlaceholderImage()
                return
            }

            mccr_blurView.isHidden = true
            mccr_imageView.image = nil
            mccr_imageView.sd_setImage(with: remoteURL, placeholderImage: mccr_placeholderImageForMedia(), options: [.retryFailed]) {
                [weak self] _, _, _, _ in
                guard let self else { return }
                guard self.mccr_posterLoadGeneration == token else { return }
                self.mccr_editThumbHost?.image = self.mccr_imageView.image
            }

        default:
            break
        }
    }

    private func mccr_clearPrimaryActionThumbnail() {
        mccr_actionThumbLoadGeneration &+= 1
        mccr_actionAvatarView.sd_cancelCurrentImageLoad()
        mccr_actionAvatarView.image = nil
    }

    private func mccr_bindPrimaryActionThumbnailIfNeeded(from run: MCSRunItem) {
        guard run.runState == .failed else { return }
        /// User image only for **restricted** (`auditFail` → Edit); plain **failed** Retry uses **`ic_cm_retry`**.
        guard run.failureCode == .auditFail else {
            mccr_clearPrimaryActionThumbnail()
            return
        }

        mccr_actionThumbLoadGeneration &+= 1
        let token = mccr_actionThumbLoadGeneration
        mccr_actionAvatarView.sd_cancelCurrentImageLoad()

        let raw = Self.mccr_actionButtonSourceURLString(from: run)
        guard raw.isEmpty == false, let remoteURL = URL(string: raw) else {
            mccr_actionAvatarView.image = nil
            return
        }

        mccr_actionAvatarView.sd_setImage(
            with: remoteURL,
            placeholderImage: Self.mccr_placeholderGradient(),
            options: [.retryFailed]
        ) { [weak self] _, _, _, _ in
            guard let self else { return }
            guard self.mccr_actionThumbLoadGeneration == token else { return }
        }
    }

    private static func mccr_actionButtonSourceURLString(from run: MCSRunItem) -> String {
        let direct = run.sourceImageUrl.mcc_normalizedRemoteURL()
        if direct.isEmpty == false { return direct }
        let bundle0 = run.inputBundle.sourceImage0.mcc_normalizedRemoteURL()
        if bundle0.isEmpty == false { return bundle0 }
        return run.mcc_firstPosterImageURLString().mcc_normalizedRemoteURL()
    }

    /// Refreshes server `failureReason` when present (`.fail`), then shared credit line — 14pt regular, white 48% opacity.
    public func mccr_applyFailureSubtitle(from run: MCSRunItem) {
        guard run.runState == .failed else { return }

        let credits = "Your credits have been restored"

        switch run.failureCode {
        case .fail:
            let detail = run.failureReason.trimmingCharacters(in: .whitespacesAndNewlines)
            let body: String
            if detail.isEmpty {
                body = credits
            } else {
                body = detail + "\n\n" + credits
            }
            mccr_subtitleLabel.attributedText = MCCCreationFailureSubtitleStyle.attributed(body)
        case .auditFail:
            let first = "There are copyright risks associated with your character"
            mccr_subtitleLabel.attributedText = MCCCreationFailureSubtitleStyle.attributed(first + "\n\n" + credits)
        }

        mccr_subtitleLabel.isHidden = false
    }
    static func mccr_placeholderGradient() -> UIImage {
        let w: CGFloat = 3

        let h: CGFloat = 4

        let r = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        return r.image { ctx in
            let c1 = UIColor(red: 0.12, green: 0.18, blue: 0.35, alpha: 1).cgColor

            let c2 = UIColor(red: 0.05, green: 0.06, blue: 0.12, alpha: 1).cgColor

            let arr = [c1, c2] as CFArray

            let locs: [CGFloat] = [0, 1]
            if let g = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: arr,
                locations: locs
            ) {
                ctx.cgContext.drawLinearGradient(
                    g,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: w, y: h),
                    options: []
                )
            }
        }
    }

    public func mccr_apply(kind: MCCCreationResultKind) {

        switch kind {
        case .failed:
            mccr_applyErrorChrome()
            mccr_applyFailedContent()
        case .restricted:
            mccr_applyErrorChrome()
            mccr_applyRestrictedContent()
        case .successImage:
            mccr_applySuccessChrome(isVideo: false, duration: 0)
        case .successVideo(let duration):
            mccr_applySuccessChrome(isVideo: true, duration: duration)
        }
    }

    private func mccr_applyErrorChrome() {
        mccr_removeResultVideoPlayback()
        mccr_isVideoMode = false
        mccr_successPill.isHidden = true
        mccr_videoChrome.isHidden = true
        mccr_actionGlassBar.isHidden = false
        // Match success-strip columns: thumbnail **above**, caption below (never left–right inline).
        mccr_actionPrimaryStack.axis = .vertical
        mccr_actionPrimaryStack.alignment = .center
        mccr_actionPrimaryStack.spacing = MCCCreationResultPreviewMetrics.primaryActionIconToTitleSpacing
        mccr_actionButton.isHidden = false
        mccr_blurView.isHidden = false
        mccr_statusStack.isHidden = false
        mccr_mediaContainer.layer.cornerRadius = 0
        mccr_mediaContainer.backgroundColor = UIColor(white: 1, alpha: MCCCreationResultPreviewMetrics.previewPlateBackgroundAlpha)
        mccr_actionGlassBar.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.toolbarBottomInsetFromSafeArea)
            make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
            make.width.equalTo(mccr_actionPrimaryStack.snp.width)
            make.height.equalTo(MCCCreationResultPreviewMetrics.successToolbarBarHeight)
        }
        mccr_mediaContainer.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(MCCCreationResultPreviewMetrics.topInset)
            make.leading.trailing.equalToSuperview().inset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.previewPlateBottomInsetFromSafeArea)
        }
        mccr_actionGlassBar.bringSubviewToFront(mccr_actionPrimaryStack)
        mccr_actionGlassBar.bringSubviewToFront(mccr_actionButton)
        setPlaceholderImage()
    }

    private func mccr_applySuccessChrome(isVideo: Bool, duration: TimeInterval) {
        mccr_cancelPosterLoad()
        mccr_isVideoMode = isVideo
        mccr_videoDuration = duration
        mccr_successPill.isHidden = false
        mccr_videoChrome.isHidden = !isVideo
        mccr_actionGlassBar.isHidden = true
        mccr_actionButton.isHidden = true
        mccr_blurView.isHidden = true
        mccr_statusStack.isHidden = true
        mccr_mediaContainer.layer.cornerRadius = 0
        if isVideo {
            mccr_mediaContainer.backgroundColor = .clear
        } else {
            mccr_mediaContainer.backgroundColor =
                UIColor(white: 1, alpha: MCCCreationResultPreviewMetrics.previewPlateBackgroundAlpha)
        }
        if !isVideo {
            mccr_mediaContainer.snp.remakeConstraints { make in
                make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(MCCCreationResultPreviewMetrics.topInset)
                make.leading.trailing.equalToSuperview().inset(MCCCreationResultPreviewMetrics.horizontalInset)
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                    .offset(-MCCCreationResultPreviewMetrics.previewPlateBottomInsetWhenSuccessToolbar)
            }
        }
        if isVideo {
            mccr_successPill.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.toolbarBottomInsetFromSafeArea)
                make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
                make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
                make.height.equalTo(MCCCreationResultPreviewMetrics.successToolbarBarHeight)
            }
            mccr_applyResultTimeLabelAttributed(current: 0, total: duration)
            mccr_frameImages = Self.mccr_stripImages(count: 18, duration: duration)
            mccr_frameCollection.reloadData()
            setNeedsLayout()
        }
        setPlaceholderImage()
        mccr_editThumbHost?.image = mccr_imageView.image
        bringSubviewToFront(mccr_successPill)
    }

    private func mccr_formatClock(_ t: TimeInterval) -> String {
        let s = max(0, Int((t + 0.5).rounded(.down)))

        let m = s / 60

        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    private static func mccr_stripImages(count: Int, duration: TimeInterval) -> [UIImage] {
        (0..<count).map { i in
            let t = CGFloat(i) / CGFloat(max(1, count - 1))

            let hue = CGFloat(i) / CGFloat(count) * 0.12 + 0.55

            let sat: CGFloat = 0.35

            let bri: CGFloat = 0.35 + t * 0.25

            let c = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: 1)

            let r = UIGraphicsImageRenderer(size: CGSize(width: 48, height: 64))
            return r.image { ctx in
                c.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 48, height: 64))
                let a = NSMutableAttributedString(
                    string: String(format: "%.1fs", duration * Double(t)),
                    attributes: [
                        .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.85)
                    ]
                )
                let sz = a.size()
                a.draw(at: CGPoint(x: (48 - sz.width) / 2, y: (64 - sz.height) / 2))
            }
        }
    }

    private func mccr_applyFailedContent() {
        setPlaceholderImage()
        mccr_failureStatusIconView.image = UIImage(named: "ic_cm_failed_detail")?.withRenderingMode(.alwaysOriginal)
        mccr_titleLabel.text = "Failed"
        mccr_titleLabel.textColor = UIColor(hex: "F54545")
        let credits = "Your credits have been restored"
        mccr_subtitleLabel.attributedText = MCCCreationFailureSubtitleStyle.attributed(credits)
        mccr_subtitleLabel.isHidden = false
        applyFailedAction()
    }

    private func mccr_applyRestrictedContent() {
        setPlaceholderImage()
        mccr_failureStatusIconView.image = UIImage(named: "ic_cm_restricted_detail")?.withRenderingMode(.alwaysOriginal)
        mccr_titleLabel.text = "Restricted"
        mccr_titleLabel.textColor = UIColor(hex: "FFC629")
        let first = "There are copyright risks associated with your character"
        let second = "Your credits have been restored"
        mccr_subtitleLabel.attributedText = MCCCreationFailureSubtitleStyle.attributed(first + "\n\n" + second)
        mccr_subtitleLabel.isHidden = false
        applyRestrictedAction()
    }

    /// Bottom row — **failed** (`Retry`): **`ic_cm_retry`** only, no user image. **Restricted** (`Edit`): circular `sourceImageUrl`, hairline stroke (**`primaryActionSourceBorderWidth`**).
    private func mccr_configurePrimaryActionSourceThumbnail(title: String) {
        let sz = MCCCreationResultPreviewMetrics.primaryActionIconSize
        mccr_actionIconContainer.layer.cornerRadius = sz * 0.5
        mccr_actionIconContainer.layer.borderWidth = MCCCreationResultPreviewMetrics.primaryActionSourceBorderWidth
        mccr_actionIconContainer.layer.borderColor = UIColor.white.cgColor

        mccr_actionIconView.isHidden = true
        mccr_actionIconView.image = nil
        mccr_actionAvatarView.isHidden = false
        mccr_actionAvatarView.layer.cornerRadius = sz * 0.5

        mccr_actionTitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        mccr_actionTitleLabel.textColor = .white
        mccr_actionTitleLabel.text = title
    }

    /// Failed Retry: **`ic_cm_retry`** only (**`mccr_buildSuccessToolbar`** matches), no thumbnail / gray chip.
    private func mccr_configurePrimaryActionRetrySymbol() {
        mccr_actionIconContainer.layer.cornerRadius = 0
        mccr_actionIconContainer.layer.borderWidth = 0
        mccr_actionIconContainer.layer.borderColor = nil

        mccr_clearPrimaryActionThumbnail()
        mccr_actionAvatarView.isHidden = true

        mccr_actionIconView.isHidden = false
        mccr_actionIconView.image = UIImage(named: "ic_cm_retry")?.withRenderingMode(.alwaysOriginal)
        mccr_actionIconView.contentMode = .scaleAspectFit

        mccr_actionTitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        mccr_actionTitleLabel.textColor = .white
        mccr_actionTitleLabel.text = "Retry"
    }

    private func applyFailedAction() {
        mccr_configurePrimaryActionRetrySymbol()
    }

    private func applyRestrictedAction() {
        mccr_configurePrimaryActionSourceThumbnail(title: "Edit")
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mccr_frameImages.count + 1
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MCCFrameStripCell.reuseId,
            for: indexPath
        ) as! MCCFrameStripCell
        if indexPath.item < mccr_frameImages.count {
            cell.mcc_configure(image: mccr_frameImages[indexPath.item], isAddSlot: false)
        } else {
            cell.mcc_configure(image: nil, isAddSlot: true)
        }
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 48, height: MCCCreationResultPreviewMetrics.videoFrameStripHeight)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }

}
