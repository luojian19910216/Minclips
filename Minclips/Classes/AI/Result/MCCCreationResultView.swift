import UIKit
import Common
import Data
import SDWebImage
import SnapKit

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
    static let gapImageToPrimaryButton: CGFloat = 32

    static let previewPlateBackgroundAlpha: CGFloat = 0.06

    /// Gap between failure/restrict icon and status title (Failed / Restricted).
    static let failureIconToTitleVerticalSpacing: CGFloat = 20

    /// Title → subtitle, and paragraph gaps inside the subtitle (reason vs credits note).
    static let failureDetailVerticalSpacing: CGFloat = 8

    /// Bottom primary: circular **source thumbnail** (`sourceImageUrl` + fallbacks) + title (failed & restricted share this row).
    static let primaryActionIconSize: CGFloat = 28

    /// White hairline stroke on the circular **source thumbnail** (failed Retry & restricted Edit).
    static let primaryActionSourceBorderWidth: CGFloat = 0.5

    /// Glass bar inset from safe area bottom; horizontal inset matches page gutter (`horizontalInset`).
    static let primaryActionBarBottomInset: CGFloat = 8

    /// Padding inside chip (icon↔rounded edge left/right).
    static let primaryActionBarInteriorHorizontalPadding: CGFloat = 20

    /// Icon+title stack inset top/bottom inside the glass chip.
    static let primaryActionBarContentVerticalPadding: CGFloat = 8

    static let primaryActionBarCornerRadius: CGFloat = 24
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

public final class MCCCreationResultView: MCCBaseView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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
        return b
    }()

    /// Chrome for bottom Retry/Edit (`systemChromeMaterialDark`).
    private let mccr_actionGlassBar: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
        v.layer.cornerCurve = .continuous
        v.layer.cornerRadius = MCCCreationResultPreviewMetrics.primaryActionBarCornerRadius
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        v.isHidden = true
        return v
    }()

    private let mccr_actionPrimaryStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 4
        s.isUserInteractionEnabled = false
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

    private let mccr_actionTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .white
        l.textAlignment = .center
        l.isUserInteractionEnabled = false
        return l
    }()

    /// Invalidates stale `sd_setImage` completions when rebound or leaving failed detail.
    private var mccr_posterLoadGeneration: UInt = 0

    private var mccr_actionThumbLoadGeneration: UInt = 0

    private let mccr_successPill: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        return v
    }()

    private let mccr_successStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .equalSpacing
        s.isLayoutMarginsRelativeArrangement = true
        s.layoutMargins = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        return s
    }()

    public private(set) var mccr_successActionButtons: [UIButton] = []

    private let mccr_videoChrome = UIView()

    private let mccr_timeLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(white: 1, alpha: 0.85)
        return l
    }()

    private let mccr_playButton: UIButton = {
        let b = UIButton(type: .system)

        let c = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        b.setImage(UIImage(systemName: "play.fill", withConfiguration: c), for: .normal)
        b.tintColor = .white
        return b
    }()

    private let mccr_volumeButton: UIButton = {
        let b = UIButton(type: .system)

        let c = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: "speaker.wave.2.fill", withConfiguration: c), for: .normal)
        b.tintColor = .white
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

    private var mccr_isPlaying: Bool = false

    public var mccr_onSuccessToolbar: ((MCCCreationSuccessToolbarAction) -> Void)?

    public override func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "121212")

        addSubview(mccr_mediaContainer)
        mccr_mediaContainer.addSubview(mccr_imageView)
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

        mccr_actionGlassBar.contentView.addSubview(mccr_actionPrimaryStack)
        mccr_actionGlassBar.contentView.addSubview(mccr_actionButton)

        addSubview(mccr_videoChrome)
        mccr_videoChrome.isHidden = true
        let ctrlRow = UIStackView(arrangedSubviews: [mccr_timeLabel, UIView(), mccr_playButton, UIView(), mccr_volumeButton])
        ctrlRow.axis = .horizontal
        ctrlRow.alignment = .center
        mccr_videoChrome.addSubview(ctrlRow)
        mccr_videoChrome.addSubview(mccr_frameCollection)
        mccr_videoChrome.addSubview(mccr_playheadView)

        addSubview(mccr_successPill)
        mccr_successPill.contentView.addSubview(mccr_successStack)
        mccr_successPill.isHidden = true
        mccr_buildSuccessToolbar()

        let hInset = MCCCreationResultPreviewMetrics.primaryActionBarInteriorHorizontalPadding
        let vInset = MCCCreationResultPreviewMetrics.primaryActionBarContentVerticalPadding

        mccr_actionPrimaryStack.snp.makeConstraints { $0.center.equalToSuperview() }

        mccr_actionGlassBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.primaryActionBarBottomInset)
            make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
            make.width.equalTo(mccr_actionPrimaryStack.snp.width).offset(hInset * 2)
            make.height.equalTo(mccr_actionPrimaryStack.snp.height).offset(vInset * 2)
        }

        mccr_actionButton.snp.makeConstraints { $0.edges.equalToSuperview() }

        mccr_mediaContainer.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(MCCCreationResultPreviewMetrics.topInset)
            make.leading.trailing.equalToSuperview().inset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.bottom.equalTo(mccr_actionGlassBar.snp.top)
                .offset(-MCCCreationResultPreviewMetrics.gapImageToPrimaryButton)
        }

        mccr_imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mccr_blurView.snp.makeConstraints { $0.edges.equalToSuperview() }

        mccr_statusStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
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
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
        mccr_successStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(72)
        }

        mccr_videoChrome.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mccr_successPill.snp.top).offset(-12)
        }
        ctrlRow.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(32)
        }
        mccr_frameCollection.snp.makeConstraints { make in
            make.top.equalTo(ctrlRow.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
            make.bottom.equalToSuperview()
        }
        mccr_playheadView.snp.makeConstraints { make in
            make.width.equalTo(2)
            make.top.bottom.equalTo(mccr_frameCollection)
            make.centerX.equalTo(mccr_frameCollection)
        }

        mccr_playButton.addTarget(self, action: #selector(mccr_togglePlay), for: .touchUpInside)
    }

    private func mccr_buildSuccessToolbar() {
        mccr_successStack.arrangedSubviews.forEach {
            mccr_successStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        mccr_successActionButtons.removeAll()
        mccr_editThumbHost = nil
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)

        let specs: [(String, String, MCCCreationSuccessToolbarAction, Bool)] = [
            ("sparkles", "Retry", .retry, false),
            ("", "Edit", .edit, true),
            ("arrow.down.circle.fill", "Save", .save, false)
        ]
        for (sym, title, action, useEditThumb) in specs {
            let col = UIStackView()
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 6
            let circle = UIView()
            circle.backgroundColor = UIColor(white: 0, alpha: 0.35)
            circle.layer.cornerRadius = 22
            circle.snp.makeConstraints { $0.size.equalTo(44) }
            if useEditThumb {
                let thumb = UIImageView()
                thumb.contentMode = .scaleAspectFill
                thumb.clipsToBounds = true
                thumb.layer.cornerRadius = 12
                circle.addSubview(thumb)
                thumb.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }
                mccr_editThumbHost = thumb
            } else {
                let iv = UIImageView(image: UIImage(systemName: sym, withConfiguration: cfg))
                iv.tintColor = .white
                iv.contentMode = .scaleAspectFit
                circle.addSubview(iv)
                iv.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.size.equalTo(24)
                }
            }

            let lab = UILabel()
            lab.text = title
            lab.font = .systemFont(ofSize: 11, weight: .medium)
            lab.textColor = .white
            col.addArrangedSubview(circle)
            col.addArrangedSubview(lab)
            let btn = UIButton(type: .custom)
            btn.tag = action.rawValue
            btn.addTarget(self, action: #selector(mccr_successToolbarTap(_:)), for: .touchUpInside)
            let wrap = UIView()
            wrap.addSubview(col)
            col.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
                make.centerY.equalToSuperview()
            }
            wrap.addSubview(btn)
            btn.snp.makeConstraints { $0.edges.equalToSuperview() }
            mccr_successStack.addArrangedSubview(wrap)
            mccr_successActionButtons.append(btn)
        }
        mccr_successStack.spacing = 16
    }

    private var mccr_editThumbHost: UIImageView?

    @objc
    private func mccr_successToolbarTap(_ sender: UIButton) {
        guard let a = MCCCreationSuccessToolbarAction(rawValue: sender.tag) else { return }
        mccr_onSuccessToolbar?(a)
    }

    @objc
    private func mccr_togglePlay() {
        mccr_isPlaying.toggle()
        let c = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)

        let name = mccr_isPlaying ? "pause.fill" : "play.fill"
        mccr_playButton.setImage(UIImage(systemName: name, withConfiguration: c), for: .normal)
    }

    private func setPlaceholderImage() {
        if mccr_imageView.image != nil { return }
        mccr_imageView.image = Self.mccr_placeholderGradient()
    }

    public func mccr_setPreviewImage(_ image: UIImage?) {
        mccr_imageView.image = image ?? Self.mccr_placeholderGradient()
        mccr_editThumbHost?.image = mccr_imageView.image
    }

    private func mccr_cancelPosterLoad() {
        mccr_posterLoadGeneration &+= 1
        mccr_imageView.sd_cancelCurrentImageLoad()
        mccr_actionThumbLoadGeneration &+= 1
        mccr_actionAvatarView.sd_cancelCurrentImageLoad()
    }

    /// Same **`sourceImageUrl`/poster URL + blur** policy as works-list cells (`mcvw_bindThumbnail`).
    public func mccr_bindPosterFrom(run: MCSRunItem) {
        guard run.runState == .failed else { return }
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
        mccr_imageView.sd_setImage(with: remoteURL, placeholderImage: Self.mccr_placeholderGradient(), options: [.retryFailed]) {
            [weak self] _, _, _, _ in
            guard let self else { return }
            guard self.mccr_posterLoadGeneration == token else { return }
            self.mccr_editThumbHost?.image = self.mccr_imageView.image
        }
        mccr_bindPrimaryActionThumbnailIfNeeded(from: run)
    }

    private func mccr_bindPrimaryActionThumbnailIfNeeded(from run: MCSRunItem) {
        guard run.runState == .failed else { return }

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
        mccr_isVideoMode = false
        mccr_successPill.isHidden = true
        mccr_videoChrome.isHidden = true
        mccr_actionGlassBar.isHidden = false
        mccr_actionButton.isHidden = false
        mccr_blurView.isHidden = false
        mccr_statusStack.isHidden = false
        mccr_mediaContainer.layer.cornerRadius = 0
        mccr_mediaContainer.backgroundColor = UIColor(white: 1, alpha: MCCCreationResultPreviewMetrics.previewPlateBackgroundAlpha)
        mccr_actionGlassBar.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-MCCCreationResultPreviewMetrics.primaryActionBarBottomInset)
            make.leading.greaterThanOrEqualToSuperview().offset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().offset(-MCCCreationResultPreviewMetrics.horizontalInset)
            make.width.equalTo(mccr_actionPrimaryStack.snp.width).offset(
                MCCCreationResultPreviewMetrics.primaryActionBarInteriorHorizontalPadding * 2
            )
            make.height.equalTo(mccr_actionPrimaryStack.snp.height).offset(
                MCCCreationResultPreviewMetrics.primaryActionBarContentVerticalPadding * 2
            )
        }
        mccr_mediaContainer.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(MCCCreationResultPreviewMetrics.topInset)
            make.leading.trailing.equalToSuperview().inset(MCCCreationResultPreviewMetrics.horizontalInset)
            make.bottom.equalTo(mccr_actionGlassBar.snp.top)
                .offset(-MCCCreationResultPreviewMetrics.gapImageToPrimaryButton)
        }
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
        mccr_mediaContainer.backgroundColor = .clear
        mccr_mediaContainer.snp.remakeConstraints { make in
            if isVideo {
                make.top.equalTo(safeAreaLayoutGuide.snp.top)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(mccr_videoChrome.snp.top)
            } else {
                make.top.equalTo(safeAreaLayoutGuide.snp.top)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
        if !isVideo {
            mccr_successPill.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
                make.leading.greaterThanOrEqualToSuperview().offset(24)
                make.trailing.lessThanOrEqualToSuperview().offset(-24)
            }
        } else {
            mccr_videoChrome.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(mccr_successPill.snp.top).offset(-12)
            }
            mccr_successPill.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
                make.leading.greaterThanOrEqualToSuperview().offset(24)
                make.trailing.lessThanOrEqualToSuperview().offset(-24)
            }
            mccr_timeLabel.text = "00:00 / " + mccr_formatClock(duration)
            mccr_frameImages = Self.mccr_stripImages(count: 18, duration: duration)
            mccr_frameCollection.reloadData()
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

    /// Bottom row shared by **failed** (Retry) and **restricted** (Edit): circular `sourceImageUrl`, 0.5pt white stroke.
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

    private func applyFailedAction() {
        mccr_configurePrimaryActionSourceThumbnail(title: "Retry")
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
        CGSize(width: 48, height: 56)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }

}
