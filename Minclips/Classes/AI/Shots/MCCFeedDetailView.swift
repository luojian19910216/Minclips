import UIKit
import Common
import SnapKit
import SDWebImage

private final class MCCBottomBlackFadeGradientView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        let g = layer as! CAGradientLayer
        g.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor
        ]
        g.locations = [0, 1]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class MCCFeedDetailCharacterAvatarSlotView: UIView {

    public let mcvw_imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_removeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        b.tintColor = UIColor(white: 0.08, alpha: 0.92)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        b.layer.cornerRadius = 9
        b.clipsToBounds = true
        b.adjustsImageWhenHighlighted = false
        return b
    }()

    private let mcvw_placeholderView = UIImageView()

    private let mcvw_outerDiameter: CGFloat
    private let mcvw_innerImageDiameter: CGFloat

    public override func layoutSubviews() {
        super.layoutSubviews()
        let oh = bounds.width > 1 ? bounds.width * 0.5 : 0
        layer.cornerRadius = oh
        mcvw_imageView.layer.cornerRadius = mcvw_innerImageDiameter * 0.5
        layer.cornerCurve = .continuous
    }

    public init(outerDiameter: CGFloat, innerImageDiameter: CGFloat) {
        mcvw_outerDiameter = outerDiameter
        mcvw_innerImageDiameter = innerImageDiameter
        super.init(frame: .zero)
        mcvw_setup()
    }

    public convenience init(avatarDiameter: CGFloat) {
        self.init(outerDiameter: avatarDiameter, innerImageDiameter: avatarDiameter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func mcvw_setup() {
        clipsToBounds = true

        let ph = UIImage(systemName: "person.fill")?.withRenderingMode(.alwaysTemplate)
        mcvw_placeholderView.image = ph
        mcvw_placeholderView.tintColor = UIColor.white.withAlphaComponent(0.35)

        addSubview(mcvw_imageView)
        addSubview(mcvw_placeholderView)
        addSubview(mcvw_removeButton)

        mcvw_imageView.layer.masksToBounds = true
        mcvw_imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(mcvw_innerImageDiameter)
        }
        let phWide = mcvw_innerImageDiameter * 0.38
        mcvw_placeholderView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(phWide)
            make.height.equalTo(mcvw_placeholderView.snp.width).multipliedBy(1)
        }

        snp.makeConstraints { make in
            make.width.height.equalTo(mcvw_outerDiameter)
        }
        mcvw_removeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(3)
            make.trailing.equalToSuperview().offset(-3)
            make.size.equalTo(18)
        }

        clipsToBounds = true
    }

    public func mcvw_apply(image: UIImage?) {
        mcvw_imageView.image = image
        // Keep image view visible when empty so the 56×56 white @ 6% circular fill renders.
        mcvw_placeholderView.isHidden = (image != nil)
        mcvw_removeButton.isHidden = (image == nil)

        backgroundColor = .clear
        if image != nil {
            mcvw_imageView.backgroundColor = .clear
            layer.borderWidth = 0
            layer.borderColor = nil
        } else {
            mcvw_imageView.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        }
    }

    public func mcvw_setActiveEmptyRing(_ active: Bool) {
        guard mcvw_imageView.image == nil else {
            layer.borderWidth = 0
            layer.borderColor = nil
            return
        }
        layer.borderWidth = active ? 1 : 0
        layer.borderColor = active ? UIColor(hex: "0077FF")!.cgColor : nil
    }
}

public final class MCCFeedDetailView: MCCBaseView {

    public let mcvw_mediaContainer = UIView()
    public let mcvw_videoOverlay = UIView()
    public let mcvw_creditsLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        return l
    }()
    public let mcvw_reportButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "flag.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.tintColor = UIColor.white.withAlphaComponent(0.9)
        return b
    }()
    public let mcvw_videoTransportBar = UIView()
    public let mcvw_playPauseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(named: "ic_cm_play_off")?.withRenderingMode(.alwaysOriginal), for: .normal)
        b.adjustsImageWhenHighlighted = false
        return b
    }()
    public let mcvw_muteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(named: "ic_cm_volume_on")?.withRenderingMode(.alwaysOriginal), for: .normal)
        b.adjustsImageWhenHighlighted = false
        return b
    }()
    public let mcvw_favoriteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(named: "ic_cm_dislike")?.withRenderingMode(.alwaysOriginal), for: .normal)
        b.adjustsImageWhenHighlighted = false
        return b
    }()
    public let mcvw_favoriteCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.72)
        l.textAlignment = .center
        return l
    }()
    public let mcvw_progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .bar)
        p.progressTintColor = UIColor(hex: "0077FF")!
        p.trackTintColor = UIColor.white.withAlphaComponent(0.24)
        p.layer.cornerRadius = 1
        p.clipsToBounds = true
        return p
    }()

    public let mcvw_posterImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_webpImageView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_settingsRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.distribution = .fillEqually
        s.alignment = .fill
        return s
    }()

    public let mcvw_resolutionValueLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "FFFFFF")!
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .natural
        return l
    }()
    public let mcvw_durationValueLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "FFFFFF")!
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .natural
        return l
    }()
    public let mcvw_modeValueLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "FFFFFF")!
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .natural
        return l
    }()
    public let mcvw_continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hex: "0077FF")!
        b.layer.cornerRadius = 24
        b.layer.cornerCurve = .continuous
        b.clipsToBounds = true
        return b
    }()

    public let mcvw_resolutionPill = UIControl()
    public let mcvw_durationPill = UIControl()
    public let mcvw_modePill = UIControl()

    public let mcvw_characterSection = UIStackView()
    public let mcvw_characterTitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "FFFFFF")!
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        return l
    }()

    public let mcvw_characterCirclesStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 4
        s.alignment = .center
        s.distribution = .fill
        return s
    }()

    public let mcvw_characterCircleSlots: [MCCFeedDetailCharacterAvatarSlotView] = [
        MCCFeedDetailCharacterAvatarSlotView(outerDiameter: 64, innerImageDiameter: 56),
        MCCFeedDetailCharacterAvatarSlotView(outerDiameter: 64, innerImageDiameter: 56)
    ]

    private let mcvw_characterSlotsScrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        s.alwaysBounceHorizontal = true
        s.alwaysBounceVertical = false
        return s
    }()
    public let mcvw_characterSlotsStack = UIStackView()

    public let mcvw_characterAlbumButton: UIButton = {
        let b = UIButton(type: .system)
        return b
    }()

    public let mcvw_characterRecentTile = UIView()

    public let mcvw_characterRecentImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        return v
    }()

    public let mcvw_characterRecentLabel: UILabel = {
        let l = UILabel()
        l.text = "Recent"
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.72)
        l.textAlignment = .center
        return l
    }()

    public let mcvw_characterPlaceholderViews: [UIView] = MCCFeedDetailView.mcvw_makePlaceholderBoxes(count: 5)

    public override func mcvw_setupUI() {
        backgroundColor = .clear
        mcvw_mediaContainer.layer.cornerRadius = 0
        mcvw_mediaContainer.clipsToBounds = true
        mcvw_mediaContainer.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        mcvw_mediaContainer.addSubview(mcvw_posterImageView)
        mcvw_mediaContainer.addSubview(mcvw_webpImageView)
        mcvw_posterImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_webpImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_mediaContainer.addSubview(mcvw_videoOverlay)
        mcvw_videoOverlay.isUserInteractionEnabled = true
        mcvw_videoOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_videoOverlay.addSubview(mcvw_creditsLabel)
        mcvw_creditsLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(10)
        }
        mcvw_videoOverlay.addSubview(mcvw_reportButton)
        mcvw_reportButton.snp.makeConstraints { make in
            make.trailing.equalTo(mcvw_creditsLabel.snp.leading).offset(-12)
            make.centerY.equalTo(mcvw_creditsLabel)
            make.size.equalTo(28)
        }
        mcvw_videoTransportBar.isUserInteractionEnabled = true
        mcvw_videoOverlay.addSubview(mcvw_videoTransportBar)
        mcvw_videoOverlay.addSubview(mcvw_muteButton)
        mcvw_videoOverlay.addSubview(mcvw_favoriteCountLabel)
        mcvw_videoOverlay.addSubview(mcvw_favoriteButton)
        mcvw_videoTransportBar.addSubview(mcvw_playPauseButton)
        mcvw_videoTransportBar.addSubview(mcvw_progressView)
        mcvw_videoTransportBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(36)
        }
        mcvw_muteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(mcvw_videoTransportBar)
            make.size.equalTo(20)
        }
        mcvw_favoriteCountLabel.snp.makeConstraints { make in
            make.centerX.equalTo(mcvw_muteButton)
            make.bottom.equalTo(mcvw_videoTransportBar.snp.top).offset(-24)
        }
        mcvw_favoriteButton.snp.makeConstraints { make in
            make.centerX.equalTo(mcvw_muteButton)
            make.bottom.equalTo(mcvw_favoriteCountLabel.snp.top).offset(-4)
            make.size.equalTo(20)
        }
        mcvw_playPauseButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        mcvw_progressView.snp.makeConstraints { make in
            make.leading.equalTo(mcvw_playPauseButton.snp.trailing).offset(8)
            make.trailing.equalTo(mcvw_muteButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(2)
        }
        addSubview(mcvw_mediaContainer)
        mcvw_styleRoundPill(mcvw_resolutionPill, iconNamed: "ic_cm_hd", textLabel: mcvw_resolutionValueLabel)
        mcvw_styleRoundPill(mcvw_durationPill, iconNamed: "ic_cm_duration", textLabel: mcvw_durationValueLabel)
        mcvw_styleRoundPill(mcvw_modePill, iconNamed: "ic_cm_audio", textLabel: mcvw_modeValueLabel)

        for slot in mcvw_characterCircleSlots {
            mcvw_characterCirclesStack.addArrangedSubview(slot)
        }

        let album = mcvw_characterAlbumButton
        album.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        album.layer.cornerRadius = 10
        album.clipsToBounds = true
        album.layer.borderWidth = 1
        album.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor
        album.setTitle(nil, for: .normal)
        album.setImage(UIImage(named: "ic_cm_add")?.withRenderingMode(.alwaysOriginal), for: .normal)
        album.adjustsImageWhenHighlighted = false

        mcvw_characterRecentTile.layer.cornerRadius = 10
        mcvw_characterRecentTile.layer.masksToBounds = true
        mcvw_characterRecentTile.clipsToBounds = true
        mcvw_characterRecentTile.layer.borderWidth = 1
        mcvw_characterRecentTile.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor

        let recentFade = MCCBottomBlackFadeGradientView(frame: .zero)

        mcvw_characterRecentTile.addSubview(mcvw_characterRecentImageView)
        mcvw_characterRecentTile.addSubview(recentFade)
        mcvw_characterRecentTile.addSubview(mcvw_characterRecentLabel)

        mcvw_characterRecentImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        recentFade.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(32)
        }
        mcvw_characterRecentLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().offset(-8)
        }

        mcvw_characterSlotsStack.axis = .horizontal
        mcvw_characterSlotsStack.spacing = 12
        mcvw_characterSlotsStack.alignment = .center
        mcvw_characterSlotsStack.distribution = .fill

        let tileWidth: CGFloat = 72
        let tileHeight: CGFloat = 96

        mcvw_applyGalleryTileIntrinsicSize(album, width: tileWidth, height: tileHeight)
        mcvw_applyGalleryTileIntrinsicSize(mcvw_characterRecentTile, width: tileWidth, height: tileHeight)

        mcvw_characterSlotsStack.addArrangedSubview(album)
        mcvw_characterSlotsStack.addArrangedSubview(mcvw_characterRecentTile)

        var placeTag = 0
        for p in mcvw_characterPlaceholderViews {
            mcvw_applyGalleryTileIntrinsicSize(p, width: tileWidth, height: tileHeight)
            p.layer.cornerRadius = 10
            p.clipsToBounds = true
            p.layer.borderWidth = 1
            p.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor
            p.backgroundColor = UIColor.white.withAlphaComponent(0.06)
            p.tag = placeTag
            placeTag += 1
            mcvw_characterSlotsStack.addArrangedSubview(p)
        }
        mcvw_characterSlotsScrollView.addSubview(mcvw_characterSlotsStack)
        mcvw_characterSlotsStack.snp.makeConstraints { make in
            make.leading.equalTo(mcvw_characterSlotsScrollView.contentLayoutGuide.snp.leading).offset(12)
            make.trailing.equalTo(mcvw_characterSlotsScrollView.contentLayoutGuide.snp.trailing).offset(-12)
            make.top.bottom.equalTo(mcvw_characterSlotsScrollView.contentLayoutGuide)
            make.height.equalTo(tileHeight)
        }

        mcvw_characterSection.axis = .vertical
        mcvw_characterSection.spacing = 14
        mcvw_characterSection.alignment = .fill

        let titleInsetWrap = UIView()
        titleInsetWrap.addSubview(mcvw_characterTitleLabel)
        mcvw_characterTitleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        let circlesInsetWrap = UIView()
        circlesInsetWrap.addSubview(mcvw_characterCirclesStack)
        mcvw_characterCirclesStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        mcvw_characterSection.addArrangedSubview(titleInsetWrap)
        mcvw_characterSection.addArrangedSubview(circlesInsetWrap)
        mcvw_characterSection.addArrangedSubview(mcvw_characterSlotsScrollView)
        mcvw_characterSection.setCustomSpacing(24, after: circlesInsetWrap)

        mcvw_characterSlotsScrollView.snp.makeConstraints { $0.height.equalTo(tileHeight) }
        addSubview(mcvw_characterSection)

        mcvw_settingsRow.addArrangedSubview(mcvw_resolutionPill)
        mcvw_settingsRow.addArrangedSubview(mcvw_durationPill)
        mcvw_settingsRow.addArrangedSubview(mcvw_modePill)
        addSubview(mcvw_settingsRow)
        addSubview(mcvw_continueButton)
        mcvw_continueButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.height.equalTo(48)
        }
        mcvw_settingsRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mcvw_continueButton.snp.top).offset(-16)
            make.height.equalTo(44)
        }
        mcvw_applyMediaHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
    }

    private func mcvw_styleRoundPill(
        _ pill: UIControl,
        iconNamed: String,
        textLabel: UILabel
    ) {
        pill.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        pill.layer.cornerRadius = 22
        pill.layer.cornerCurve = .continuous
        pill.clipsToBounds = true

        textLabel.numberOfLines = 1
        textLabel.lineBreakMode = .byTruncatingTail

        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(named: iconNamed)?.withRenderingMode(.alwaysOriginal)

        pill.addSubview(iconView)
        pill.addSubview(textLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }
    }

    private func mcvw_applyGalleryTileIntrinsicSize(_ v: UIView, width: CGFloat, height: CGFloat) {
        v.snp.makeConstraints { make in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
    }

    public func mcvw_applyCharacterCircleFocus(nextEmptySlotIndex: Int?) {
        for (i, slot) in mcvw_characterCircleSlots.enumerated() {
            slot.mcvw_setActiveEmptyRing(nextEmptySlotIndex == i)
        }
    }

    public func mcvw_applyMediaHeightPerWidth(_ ratio: CGFloat) {
        mcvw_mediaContainer.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mcvw_characterSection.snp.top).offset(-16)
            make.height.equalTo(mcvw_mediaContainer.snp.width).multipliedBy(ratio)
        }
        mcvw_characterSection.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mcvw_settingsRow.snp.top).offset(-20)
        }
    }

    private static func mcvw_makePlaceholderBoxes(count: Int) -> [UIView] {
        (0..<count).map { _ in
            let v = UIView()
            v.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            v.layer.cornerRadius = 13
            v.clipsToBounds = true
            v.isUserInteractionEnabled = false
            return v
        }
    }

}
