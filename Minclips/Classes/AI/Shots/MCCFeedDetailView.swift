import UIKit
import Common
import SnapKit
import SDWebImage

public final class MCCFeedDetailView: MCCBaseView {

    public let mcvw_scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = true
        s.alwaysBounceVertical = true
        s.contentInsetAdjustmentBehavior = .always
        s.backgroundColor = .clear
        return s
    }()

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
    public let mcvw_progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .bar)
        p.progressTintColor = UIColor(hex: "00AAFF")!
        p.trackTintColor = UIColor.white.withAlphaComponent(0.25)
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

    public let mcvw_characterTitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        return l
    }()
    public let mcvw_avatarRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        return s
    }()
    public let mcvw_characterGrid: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 8
        s.distribution = .fillEqually
        return s
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
        l.textColor = .white
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textAlignment = .center
        return l
    }()
    public let mcvw_durationValueLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textAlignment = .center
        return l
    }()
    public let mcvw_modeValueLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textAlignment = .center
        return l
    }()
    public let mcvw_continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.backgroundColor = UIColor(hex: "0077FF")!
        b.layer.cornerRadius = 14
        b.clipsToBounds = true
        return b
    }()

    public let mcvw_resolutionPill = UIControl()
    public let mcvw_durationPill = UIControl()
    public let mcvw_modePill = UIControl()
    public let mcvw_resolutionTitleLabel = MCCFeedDetailView.mcvw_makePillCaptionLabel()
    public let mcvw_durationTitleLabel = MCCFeedDetailView.mcvw_makePillCaptionLabel()
    public let mcvw_modeTitleLabel = MCCFeedDetailView.mcvw_makePillCaptionLabel()

    public override func mcvw_setupUI() {
        backgroundColor = .clear
        addSubview(mcvw_scrollView)
        mcvw_scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 20
        content.alignment = .fill
        mcvw_scrollView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalTo(mcvw_scrollView.contentLayoutGuide)
            make.width.equalTo(mcvw_scrollView.frameLayoutGuide)
        }
        mcvw_mediaContainer.layer.cornerRadius = 12
        mcvw_mediaContainer.clipsToBounds = true
        mcvw_mediaContainer.backgroundColor = UIColor.white.withAlphaComponent(0.06)
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
        mcvw_videoOverlay.addSubview(mcvw_progressView)
        mcvw_progressView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(10)
            make.height.equalTo(3)
        }
        content.addArrangedSubview(mcvw_mediaContainer)
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        mcvw_applyMediaHeightPerWidth(MCCShotsListItemMetrics.imageHeightPerWidth)
        let charBlock = mcvw_makeCharacterBlock()
        content.addArrangedSubview(charBlock)
        mcvw_stylePill(mcvw_resolutionPill, titleLabel: mcvw_resolutionTitleLabel, value: mcvw_resolutionValueLabel)
        mcvw_stylePill(mcvw_durationPill, titleLabel: mcvw_durationTitleLabel, value: mcvw_durationValueLabel)
        mcvw_stylePill(mcvw_modePill, titleLabel: mcvw_modeTitleLabel, value: mcvw_modeValueLabel)
        mcvw_settingsRow.addArrangedSubview(mcvw_resolutionPill)
        mcvw_settingsRow.addArrangedSubview(mcvw_durationPill)
        mcvw_settingsRow.addArrangedSubview(mcvw_modePill)
        mcvw_settingsRow.snp.makeConstraints { $0.height.equalTo(64) }
        content.addArrangedSubview(mcvw_settingsRow)
        content.addArrangedSubview(mcvw_continueButton)
        mcvw_continueButton.snp.makeConstraints { $0.height.equalTo(54) }
    }

    private static func mcvw_makePillCaptionLabel() -> UILabel {
        let t = UILabel()
        t.textColor = UIColor.white.withAlphaComponent(0.55)
        t.font = .systemFont(ofSize: 12, weight: .regular)
        t.textAlignment = .center
        return t
    }

    private func mcvw_stylePill(_ c: UIControl, titleLabel: UILabel, value: UILabel) {
        c.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
        c.layer.cornerRadius = 10
        c.clipsToBounds = true
        c.addSubview(titleLabel)
        c.addSubview(value)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        value.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    private func mcvw_makeCharacterBlock() -> UIView {
        let w = UIView()
        w.addSubview(mcvw_characterTitleLabel)
        mcvw_characterTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        w.addSubview(mcvw_avatarRow)
        mcvw_avatarRow.snp.makeConstraints { make in
            make.top.equalTo(mcvw_characterTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        for _ in 0..<3 {
            mcvw_avatarRow.addArrangedSubview(mcvw_avatarCircle())
        }
        w.addSubview(mcvw_characterGrid)
        mcvw_characterGrid.snp.makeConstraints { make in
            make.top.equalTo(mcvw_avatarRow.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        let r1 = mcvw_gridRow()
        let r2 = mcvw_gridRow()
        mcvw_characterGrid.addArrangedSubview(r1)
        mcvw_characterGrid.addArrangedSubview(r2)
        mcvw_characterGrid.snp.makeConstraints { $0.height.equalTo(2 * 56 + 8) }
        return w
    }

    private func mcvw_avatarCircle() -> UIView {
        let o = UIView()
        o.layer.cornerRadius = 20
        o.clipsToBounds = true
        o.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        o.snp.makeConstraints { $0.size.equalTo(40) }
        return o
    }

    private func mcvw_gridRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.distribution = .fillEqually
        s.addArrangedSubview(mcvw_cell())
        s.addArrangedSubview(mcvw_cell())
        return s
    }

    private func mcvw_cell() -> UIView {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        v.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        return v
    }

    public func mcvw_applyMediaHeightPerWidth(_ ratio: CGFloat) {
        mcvw_mediaContainer.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(mcvw_mediaContainer.snp.width).multipliedBy(ratio)
        }
    }
}
