import UIKit
import Common
import SnapKit

public final class MCCFeedGeneratingView: MCCBaseView {

    public let mcvw_closeButton: MCCNavCapsuleButton = {
        let b = MCCNavCapsuleButton(type: .custom)
        b.mcvw_apply(
            icon: UIImage(named: "ic_cm_close")?.withRenderingMode(.alwaysTemplate),
            title: nil,
            titleColor: .white
        )
        b.mcvw_useStandaloneCapsule()
        b.tintColor = .white
        return b
    }()

    public let mcvw_previewBox = UIView()
    public let mcvw_previewImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()
    public let mcvw_previewBlurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.isUserInteractionEnabled = false
        return v
    }()
    public let mcvw_percentLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        return l
    }()
    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .center
        return l
    }()
    public let mcvw_subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.white.withAlphaComponent(0.4)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    public let mcvw_exploreButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = .white.withAlphaComponent(0.12)
        b.layer.cornerRadius = 24
        b.clipsToBounds = true
        return b
    }()
    public let mcvw_projectsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hex: "0077FF")!
        b.layer.cornerRadius = 24
        b.clipsToBounds = true
        return b
    }()
    public let mcvw_buttonRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    public override func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "18181C")!
        addSubview(mcvw_closeButton)
        mcvw_closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.size.equalTo(44)
        }
        addSubview(mcvw_previewBox)
        mcvw_previewBox.snp.makeConstraints { make in
            make.top.equalTo(mcvw_closeButton.snp.bottom).offset(80)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 120, height: 160))
        }
        mcvw_previewBox.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        mcvw_previewBox.layer.cornerRadius = 8
        mcvw_previewBox.clipsToBounds = true
        mcvw_previewBox.addSubview(mcvw_previewImageView)
        mcvw_previewImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_previewBox.addSubview(mcvw_previewBlurView)
        mcvw_previewBlurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_previewBox.addSubview(mcvw_percentLabel)
        mcvw_percentLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        mcvw_percentLabel.layer.shadowColor = UIColor.black.cgColor
        mcvw_percentLabel.layer.shadowOpacity = 0.45
        mcvw_percentLabel.layer.shadowRadius = 4
        mcvw_percentLabel.layer.shadowOffset = .zero
        addSubview(mcvw_titleLabel)
        mcvw_titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mcvw_previewBox.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        addSubview(mcvw_subtitleLabel)
        mcvw_subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(mcvw_titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        addSubview(mcvw_buttonRow)
        mcvw_buttonRow.addArrangedSubview(mcvw_exploreButton)
        mcvw_buttonRow.addArrangedSubview(mcvw_projectsButton)
        mcvw_buttonRow.snp.makeConstraints { make in
            make.top.equalTo(mcvw_subtitleLabel.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        mcvw_exploreButton.snp.makeConstraints { $0.height.equalTo(48) }
        mcvw_projectsButton.snp.makeConstraints { $0.height.equalTo(48) }
    }
}
