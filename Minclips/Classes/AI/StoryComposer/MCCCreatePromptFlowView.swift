import UIKit
import SnapKit
import Common

public final class MCCCreatePromptFlowView: MCCBaseView {

    public let mcvw_heroImageView = UIImageView()

    public let mcvw_cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "232328")
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_textView = UITextView()

    private let mcvw_thumbRowScroll = UIScrollView()
    private let mcvw_addThumbButton = UIButton(type: .system)

    public let mcvw_lightBulbFooter = UIButton(type: .system)
    public let mcvw_trashFooter = UIButton(type: .system)

    private let mcvw_shotSettingsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.distribution = .fillEqually
        return s
    }()

    public let mcvw_continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.layer.cornerRadius = 26
        b.clipsToBounds = true
        b.backgroundColor = UIColor(hex: "39393F")
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(UIColor.white.withAlphaComponent(0.65), for: .normal)
        return b
    }()

    public let mcvw_resolutionChip = UIButton(type: .system)
    public let mcvw_durationChip = UIButton(type: .system)
    public let mcvw_audioChip = UIButton(type: .system)

    override public func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "0F0F12")

        let heroWrap = UIView()
        mcvw_heroImageView.contentMode = .scaleAspectFill
        mcvw_heroImageView.clipsToBounds = true
        mcvw_heroImageView.layer.cornerRadius = 16
        mcvw_heroImageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        mcvw_heroImageView.backgroundColor = UIColor(hex: "2E2620")

        heroWrap.addSubview(mcvw_heroImageView)
        addSubview(heroWrap)
        addSubview(mcvw_cardContainer)
        addSubview(mcvw_shotSettingsStack)
        addSubview(mcvw_continueButton)

        let thumbLead = UIButton(type: .system)
        thumbLead.layer.cornerRadius = 18
        thumbLead.layer.borderWidth = 1
        thumbLead.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        thumbLead.backgroundColor = UIColor(hex: "383840")
        thumbLead.setTitle("✕", for: .normal)
        thumbLead.setTitleColor(.white.withAlphaComponent(0.95), for: .normal)

        mcvw_addThumbButton.layer.cornerRadius = 16
        mcvw_addThumbButton.layer.borderWidth = 1
        mcvw_addThumbButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        mcvw_addThumbButton.setTitle("+", for: .normal)
        mcvw_addThumbButton.setTitleColor(.white.withAlphaComponent(0.85), for: .normal)

        mcvw_thumbRowScroll.showsHorizontalScrollIndicator = false
        mcvw_thumbRowScroll.addSubview(thumbLead)
        mcvw_thumbRowScroll.addSubview(mcvw_addThumbButton)
        thumbLead.frame = CGRect(x: 8, y: 2, width: 40, height: 40)
        mcvw_addThumbButton.frame = CGRect(x: 56, y: 2, width: 40, height: 40)
        mcvw_thumbRowScroll.contentSize = CGSize(width: 120, height: 44)

        mcvw_textView.backgroundColor = .clear
        mcvw_textView.font = .systemFont(ofSize: 16, weight: .regular)
        mcvw_textView.textColor = .white.withAlphaComponent(0.88)
        mcvw_textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 8, right: 0)

        mcvw_lightBulbFooter.setImage(UIImage(systemName: "lightbulb"), for: .normal)
        mcvw_lightBulbFooter.tintColor = .white.withAlphaComponent(0.55)
        mcvw_lightBulbFooter.backgroundColor = .clear
        mcvw_trashFooter.setImage(UIImage(systemName: "trash"), for: .normal)
        mcvw_trashFooter.tintColor = .white.withAlphaComponent(0.55)
        mcvw_trashFooter.backgroundColor = .clear

        let footerStack = UIStackView(arrangedSubviews: [mcvw_lightBulbFooter, UIView(), mcvw_trashFooter])
        footerStack.axis = .horizontal
        footerStack.isLayoutMarginsRelativeArrangement = true

        mcvw_cardContainer.addSubview(mcvw_thumbRowScroll)
        mcvw_cardContainer.addSubview(mcvw_textView)
        mcvw_cardContainer.addSubview(footerStack)

        [mcvw_resolutionChip, mcvw_durationChip, mcvw_audioChip].forEach(Self.mcvw_styleShotChip)
        [mcvw_resolutionChip, mcvw_durationChip, mcvw_audioChip].forEach(mcvw_shotSettingsStack.addArrangedSubview)

        mcvw_resolutionChip.setTitle("720P", for: .normal)
        mcvw_durationChip.setTitle("5s", for: .normal)
        mcvw_audioChip.setTitle("Original", for: .normal)

        heroWrap.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.42)
        }
        mcvw_heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        mcvw_cardContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(heroWrap.snp.centerY).offset(12)
        }

        mcvw_thumbRowScroll.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(44)
        }
        mcvw_textView.snp.makeConstraints { make in
            make.top.equalTo(mcvw_thumbRowScroll.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(100)
        }
        footerStack.snp.makeConstraints { make in
            make.top.equalTo(mcvw_textView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        mcvw_shotSettingsStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(mcvw_continueButton.snp.top).offset(-16)
        }

        mcvw_continueButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.height.equalTo(52)
        }
    }

    public func mcvw_setShotSettingsVisible(_ show: Bool) {
        mcvw_shotSettingsStack.isHidden = !show
    }

    private static func mcvw_styleShotChip(_ b: UIButton) {
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        b.backgroundColor = UIColor(hex: "2C2C33")
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    }
}
