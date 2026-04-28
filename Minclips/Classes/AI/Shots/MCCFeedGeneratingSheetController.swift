import UIKit
import Common
import SnapKit
import PanModal
import SDWebImage

public final class MCCFeedGeneratingView: MCCBaseView {

    public let mcvw_closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.tintColor = UIColor.white.withAlphaComponent(0.85)
        return b
    }()

    public let mcvw_previewBox = UIView()
    public let mcvw_previewImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()
    public let mcvw_percentLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        return l
    }()
    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .center
        return l
    }()
    public let mcvw_subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.white.withAlphaComponent(0.56)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    public let mcvw_exploreButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(white: 0.2, alpha: 1)
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        return b
    }()
    public let mcvw_projectsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hex: "0077FF")!
        b.layer.cornerRadius = 12
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
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        addSubview(mcvw_closeButton)
        mcvw_closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(40)
        }
        addSubview(mcvw_previewBox)
        mcvw_previewBox.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(48)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 160, height: 160))
        }
        mcvw_previewBox.layer.cornerRadius = 12
        mcvw_previewBox.clipsToBounds = true
        mcvw_previewBox.addSubview(mcvw_previewImageView)
        mcvw_previewImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_previewBox.addSubview(mcvw_percentLabel)
        mcvw_percentLabel.snp.makeConstraints { $0.center.equalToSuperview() }
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
            make.top.equalTo(mcvw_subtitleLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-24)
        }
        mcvw_exploreButton.snp.makeConstraints { $0.height.equalTo(50) }
        mcvw_projectsButton.snp.makeConstraints { $0.height.equalTo(50) }
    }
}

public final class MCCFeedGeneratingSheetController: MCCSheetController<MCCFeedGeneratingView, MCCEmptyViewModel> {

    public var mcvc_dismiss: (() -> Void)?

    public override var longFormHeight: PanModalHeight { .contentHeight(400) }
    public override var showDragIndicator: Bool { true }
    public override var cornerRadius: CGFloat { 16 }

    public override func mcvc_setupLocalization() {
        super.mcvc_setupLocalization()
        view.backgroundColor = contentView.backgroundColor
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        let v = contentView
        v.mcvw_closeButton.addTarget(self, action: #selector(mcvc_tapClose), for: .touchUpInside)
        v.mcvw_exploreButton.addTarget(self, action: #selector(mcvc_tapExplore), for: .touchUpInside)
        v.mcvw_projectsButton.addTarget(self, action: #selector(mcvc_tapProjects), for: .touchUpInside)
    }

    public func mcvc_applyCopy(
        closeAccessibilityLabel: String? = nil,
        percent: String,
        title: String,
        subtitle: String,
        explore: String,
        projects: String
    ) {
        let v = contentView
        v.mcvw_closeButton.accessibilityLabel = closeAccessibilityLabel
        v.mcvw_percentLabel.text = percent
        v.mcvw_titleLabel.text = title
        v.mcvw_subtitleLabel.text = subtitle
        v.mcvw_exploreButton.setTitle(explore, for: .normal)
        v.mcvw_projectsButton.setTitle(projects, for: .normal)
    }

    public func mcvc_setPosterFromURLString(_ urlString: String) {
        let v = contentView.mcvw_previewImageView
        if let u = URL(string: urlString), !urlString.isEmpty {
            v.sd_setImage(with: u, placeholderImage: nil, options: [])
        } else {
            v.sd_cancelCurrentImageLoad()
            v.image = nil
        }
    }

    @objc
    private func mcvc_tapClose() {
        dismiss(animated: true) { [weak self] in self?.mcvc_dismiss?() }
    }

    @objc
    private func mcvc_tapExplore() {
        dismiss(animated: true) { [weak self] in self?.mcvc_dismiss?() }
    }

    @objc
    private func mcvc_tapProjects() {
        dismiss(animated: true) { [weak self] in self?.mcvc_dismiss?() }
    }
}
