import UIKit
import Common
import SnapKit

public enum MCCCreationResultKind {
    /// 生成失败
    case failed
    /// 审核 / 内容拒绝（如版权风险）
    case restricted
}

public final class MCCCreationResultView: MCCBaseView {

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
    }

    private func setPlaceholderImage() {
        if mccr_imageView.image != nil { return }
        let w: CGFloat = 3
        let h: CGFloat = 4
        let r = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let im = r.image { ctx in
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
        mccr_imageView.image = im
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
        setPlaceholderImage()
        let badgeSmall = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        switch kind {
        case .failed:
            mccr_badgeImageView.isHidden = false
            mccr_badgeImageView.image = UIImage(systemName: "xmark.circle.fill", withConfiguration: badgeSmall)
            mccr_badgeImageView.tintColor = .systemRed
            mccr_titleLabel.text = "Failed"
            mccr_titleLabel.textColor = .systemRed
            mccr_subtitleLabel.text = "Your credits have been restored"
            mccr_subtitleLabel.isHidden = false
            applyFailedAction()
        case .restricted:
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

}
