import UIKit
import SnapKit
import Common

public final class MCCCreatePromptFlowView: MCCBaseView {

    public let mcvw_heroImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = UIColor(hex: "2E2620")
        return v
    }()

    public let mcvw_cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "232328")
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_addThumbButton: UIButton = {
        let b = UIButton(type: .system)
        b.layer.cornerRadius = 8
        b.clipsToBounds = true
        b.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        return b
    }()

    public let mcvw_textView: UITextView = {
        let v = UITextView()
        v.backgroundColor = .clear
        v.font = .systemFont(ofSize: 16, weight: .regular)
        v.textColor = .white.withAlphaComponent(0.88)
        v.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 8, right: 0)
        v.textContainer.lineFragmentPadding = 0
        return v
    }()

    public let mcvw_lightBulbFooter: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "lightbulb"), for: .normal)
        b.tintColor = .white.withAlphaComponent(0.55)
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        return b
    }()

    public let mcvw_trashFooter: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "trash"), for: .normal)
        b.tintColor = .white.withAlphaComponent(0.55)
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        return b
    }()

    private let mcvw_shotSettingsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.distribution = .fillEqually
        return s
    }()

    public let mcvw_continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.layer.cornerRadius = 26
        b.clipsToBounds = true
        b.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(UIColor.white.withAlphaComponent(0.65), for: .normal)
        return b
    }()

    public let mcvw_resolutionChip = UIButton(type: .system)
    public let mcvw_durationChip = UIButton(type: .system)
    public let mcvw_audioChip = UIButton(type: .system)

    private var mcvw_cardTopHeroConstraint: Constraint?
    private var mcvw_cardTopKeyboardConstraint: Constraint?

    public override func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "0F0F12")

        addSubview(mcvw_heroImageView)
        mcvw_heroImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.42)
        }

        addSubview(mcvw_cardContainer)
        mcvw_cardContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            mcvw_cardTopHeroConstraint = make.top.equalTo(mcvw_heroImageView.snp.centerY).offset(20).constraint
        }
        mcvw_cardContainer.snp.prepareConstraints { make in
            mcvw_cardTopKeyboardConstraint = make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(20).constraint
        }

        mcvw_cardContainer.addSubview(mcvw_addThumbButton)
        mcvw_cardContainer.addSubview(mcvw_textView)

        let footerStack = UIStackView(arrangedSubviews: [mcvw_lightBulbFooter, UIView(), mcvw_trashFooter])
        footerStack.axis = .horizontal
        mcvw_cardContainer.addSubview(footerStack)

        mcvw_addThumbButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.size.equalTo(40)
        }
        mcvw_textView.snp.makeConstraints { make in
            make.top.equalTo(mcvw_addThumbButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(96)
        }
        footerStack.snp.makeConstraints { make in
            make.top.equalTo(mcvw_textView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(36)
        }

        addSubview(mcvw_shotSettingsStack)
        [mcvw_resolutionChip, mcvw_durationChip, mcvw_audioChip].forEach(Self.mcvw_styleShotChip)
        [mcvw_resolutionChip, mcvw_durationChip, mcvw_audioChip].forEach(mcvw_shotSettingsStack.addArrangedSubview)
        mcvw_resolutionChip.setTitle("720P", for: .normal)
        mcvw_durationChip.setTitle("5s", for: .normal)
        mcvw_audioChip.setTitle("Original", for: .normal)
        let chipCfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        mcvw_resolutionChip.setImage(UIImage(systemName: "rectangle.on.rectangle", withConfiguration: chipCfg), for: .normal)
        mcvw_durationChip.setImage(UIImage(systemName: "clock", withConfiguration: chipCfg), for: .normal)
        mcvw_audioChip.setImage(UIImage(systemName: "waveform", withConfiguration: chipCfg), for: .normal)

        mcvw_shotSettingsStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(mcvw_cardContainer)
            make.top.equalTo(mcvw_cardContainer.snp.bottom).offset(12)
            make.height.equalTo(40)
        }

        addSubview(mcvw_continueButton)
        mcvw_continueButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(52)
            make.bottom.equalTo(keyboardLayoutGuide.snp.top).offset(-12)
        }
    }

    public func mcvw_setShotSettingsVisible(_ show: Bool) {
        mcvw_shotSettingsStack.isHidden = !show
        mcvw_trashFooter.isHidden = !show
    }

    public func mcvw_setKeyboardActive(_ active: Bool, animated: Bool) {
        if active {
            mcvw_cardTopHeroConstraint?.deactivate()
            mcvw_cardTopKeyboardConstraint?.activate()
        } else {
            mcvw_cardTopKeyboardConstraint?.deactivate()
            mcvw_cardTopHeroConstraint?.activate()
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
                self.layoutIfNeeded()
            }
        } else {
            setNeedsLayout()
        }
    }

    private static func mcvw_styleShotChip(_ b: UIButton) {
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        b.tintColor = .white.withAlphaComponent(0.9)
        b.backgroundColor = UIColor(hex: "2C2C33")
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
    }
}
