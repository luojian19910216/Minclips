import UIKit
import SnapKit
import Common

public final class MCCShotsStockPickerCell: MCCBaseCollectionViewCell {

    public static let mcvw_reuseId = "MCCShotsStockPickerCell"

    private let mcvw_gradientLayer = CAGradientLayer()

    private let mcvw_fillView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "48485A")
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let mcvw_ownPromptLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 3
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        l.text = "Use my own\nprompt"
        return l
    }()

    private let mcvw_timeLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        l.textColor = UIColor.white.withAlphaComponent(0.95)
        return l
    }()

    private let mcvw_checkHost = UIView()

    private let mcvw_checkIcon = UIImageView()

    override public func mcvw_setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        mcvw_gradientLayer.colors = [
            UIColor(hex: "2B5AFF")!.cgColor,
            UIColor(hex: "6B4AFF")!.cgColor
        ]
        contentView.layer.insertSublayer(mcvw_gradientLayer, at: 0)

        contentView.addSubview(mcvw_fillView)
        contentView.addSubview(mcvw_ownPromptLabel)
        contentView.addSubview(mcvw_timeLabel)
        contentView.addSubview(mcvw_checkHost)
        mcvw_checkHost.addSubview(mcvw_checkIcon)

        mcvw_gradientLayer.opacity = 0
        mcvw_ownPromptLabel.alpha = 0

        mcvw_checkHost.layer.borderWidth = 2
        mcvw_checkHost.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        mcvw_checkHost.layer.cornerRadius = 12
        mcvw_checkIcon.contentMode = .scaleAspectFit

        mcvw_fillView.snp.makeConstraints { $0.edges.equalToSuperview() }

        mcvw_ownPromptLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(4)
        }
        mcvw_timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
        }
        mcvw_checkHost.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.size.equalTo(24)
        }
        mcvw_checkIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let r = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        mcvw_gradientLayer.frame = r
        mcvw_gradientLayer.cornerRadius = 12
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        mcvw_gradientLayer.opacity = 0
        mcvw_ownPromptLabel.alpha = 0
    }

    public func mcvw_configureOwnPrompt() {
        mcvw_gradientLayer.opacity = 1
        mcvw_ownPromptLabel.alpha = 1
        mcvw_timeLabel.text = ""
        mcvw_applyBadge(selected: false)
    }

    public func mcvw_configureThumbnail(timeText: String) {
        mcvw_gradientLayer.opacity = 0
        mcvw_ownPromptLabel.alpha = 0
        mcvw_timeLabel.text = timeText
        mcvw_applyBadge(selected: false)
    }

    public func mcvw_applyBadge(selected: Bool) {
        if selected {
            mcvw_checkHost.layer.borderWidth = 0
            mcvw_checkHost.backgroundColor = UIColor(hex: "2979FF")
            mcvw_checkIcon.image = UIImage(systemName: "checkmark")
            mcvw_checkIcon.tintColor = .white
        } else {
            mcvw_checkHost.layer.borderWidth = 2
            mcvw_checkHost.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
            mcvw_checkHost.backgroundColor = .clear
            mcvw_checkIcon.image = UIImage(systemName: "circle.fill")
            mcvw_checkIcon.tintColor = .clear
        }
    }
}
