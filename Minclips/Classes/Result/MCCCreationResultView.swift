import UIKit
import Common
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
        v.layer.cornerRadius = 12
        return v
    }()

    private let mccr_imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let mccr_blurView: UIVisualEffectView = {
        let e = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        return e
    }()

    private let mccr_iconBase = UIView()

    private let mccr_filmImageView = UIImageView()

    private let mccr_badgeImageView = UIImageView()

    private let mccr_statusStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 8
        return s
    }()

    public let mccr_titleLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 19, weight: .bold)
        l.numberOfLines = 0
        return l
    }()

    public let mccr_subtitleLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.6)
        l.numberOfLines = 0
        l.setContentHuggingPriority(.required, for: .vertical)
        return l
    }()

    public let mccr_actionButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setContentHuggingPriority(.required, for: .vertical)
        return b
    }()

    private let mccr_actionIconContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.layer.cornerRadius = 36
        v.clipsToBounds = true
        v.backgroundColor = UIColor(white: 0, alpha: 0.35)
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 1, alpha: 0.35).cgColor
        return v
    }()

    private let mccr_actionIconView = UIImageView()

    private let mccr_actionAvatarView: UIImageView = {
        let iv = UIImageView()
        iv.isHidden = true
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.tintColor = .white
        return iv
    }()

    private let mccr_actionTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.isUserInteractionEnabled = false
        return l
    }()

    private var mccr_didConfigureFilm: Bool = false

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

        configureFilmIcon()
        mccr_iconBase.snp.makeConstraints { $0.size.equalTo(56) }

        mccr_statusStack.addArrangedSubview(mccr_iconBase)
        mccr_statusStack.setCustomSpacing(12, after: mccr_iconBase)
        mccr_statusStack.addArrangedSubview(mccr_titleLabel)
        mccr_statusStack.addArrangedSubview(mccr_subtitleLabel)
        mccr_subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        addSubview(mccr_actionButton)
        mccr_actionButton.addSubview(mccr_actionIconContainer)
        mccr_actionIconContainer.addSubview(mccr_actionIconView)
        mccr_actionIconContainer.addSubview(mccr_actionAvatarView)
        mccr_actionButton.addSubview(mccr_actionTitleLabel)

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

        mccr_mediaContainer.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(mccr_mediaContainer.snp.width).multipliedBy(4.0 / 3.0)
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

        mccr_actionButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(mccr_mediaContainer.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-28)
        }

        mccr_actionIconContainer.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(72)
        }
        mccr_actionIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }
        mccr_actionAvatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }
        mccr_actionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(mccr_actionIconContainer.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }

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

    private func configureFilmIcon() {
        guard !mccr_didConfigureFilm else { return }
        mccr_didConfigureFilm = true
        let c = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        mccr_filmImageView.image = UIImage(systemName: "film", withConfiguration: c)
        mccr_filmImageView.tintColor = .white
        mccr_filmImageView.contentMode = .scaleAspectFit
        mccr_iconBase.addSubview(mccr_filmImageView)
        mccr_filmImageView.snp.makeConstraints { $0.center.equalToSuperview() }
        mccr_iconBase.addSubview(mccr_badgeImageView)
        mccr_badgeImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(4)
            make.centerY.equalToSuperview().offset(-4)
            make.size.equalTo(24)
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
        mccr_actionButton.isHidden = false
        mccr_blurView.isHidden = false
        mccr_statusStack.isHidden = false
        mccr_iconBase.isHidden = false
        mccr_mediaContainer.layer.cornerRadius = 12
        mccr_mediaContainer.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(mccr_mediaContainer.snp.width).multipliedBy(4.0 / 3.0)
        }
        mccr_actionButton.snp.remakeConstraints { make in
            make.top.greaterThanOrEqualTo(mccr_mediaContainer.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-28)
        }
        setPlaceholderImage()
    }

    private func mccr_applySuccessChrome(isVideo: Bool, duration: TimeInterval) {
        mccr_isVideoMode = isVideo
        mccr_videoDuration = duration
        mccr_successPill.isHidden = false
        mccr_videoChrome.isHidden = !isVideo
        mccr_actionButton.isHidden = true
        mccr_blurView.isHidden = true
        mccr_statusStack.isHidden = true
        mccr_iconBase.isHidden = true
        mccr_mediaContainer.layer.cornerRadius = 0
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
        let badgeSmall = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        mccr_badgeImageView.isHidden = false
        mccr_badgeImageView.image = UIImage(systemName: "xmark.circle.fill", withConfiguration: badgeSmall)
        mccr_badgeImageView.tintColor = .systemRed
        mccr_titleLabel.text = "Failed"
        mccr_titleLabel.textColor = .systemRed
        mccr_subtitleLabel.text = "Your credits have been restored"
        mccr_subtitleLabel.isHidden = false
        applyFailedAction()
    }

    private func mccr_applyRestrictedContent() {
        setPlaceholderImage()
        let badgeSmall = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        mccr_badgeImageView.isHidden = false
        mccr_badgeImageView.image = UIImage(
            systemName: "exclamationmark.triangle.fill",
            withConfiguration: badgeSmall
        )
        mccr_badgeImageView.tintColor = .systemOrange
        mccr_titleLabel.text = "Restricted"
        mccr_titleLabel.textColor = .systemOrange
        let first = "There are copyright risks associated with your character"

        let second = "Your credits have been restored"

        let full = first + "\n" + second

        let a = NSMutableAttributedString(string: full, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor(white: 1, alpha: 0.6)
        ])
        mccr_subtitleLabel.attributedText = a
        mccr_subtitleLabel.isHidden = false
        applyRestrictedAction()
    }

    private func applyFailedAction() {
        let ic = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        mccr_actionIconView.isHidden = false
        mccr_actionAvatarView.isHidden = true
        mccr_actionIconView.image = UIImage(systemName: "sparkles", withConfiguration: ic)
        mccr_actionIconView.tintColor = .white
        mccr_actionTitleLabel.text = "Retry"
    }

    private func applyRestrictedAction() {
        mccr_actionIconView.isHidden = true
        mccr_actionAvatarView.isHidden = false
        if mccr_actionAvatarView.image == nil {
            let ac = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            mccr_actionAvatarView.image = UIImage(
                systemName: "person.crop.circle.fill",
                withConfiguration: ac
            )
        }
        mccr_actionTitleLabel.text = "Edit"
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
