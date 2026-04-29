import UIKit
import Common
import SnapKit

public final class MCCDeleteConfirmPopView: MCCBasePopView {

    public let mccd_messageLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        return l
    }()

    private static func mccd_messageAttributedText() -> NSAttributedString {
        let raw = "Deleting it will make it unrecoverable. Are you sure to delete it?"
        let ps = NSMutableParagraphStyle()
        ps.alignment = .natural
        ps.lineSpacing = 4
        return NSAttributedString(
            string: raw,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.white,
                .paragraphStyle: ps
            ]
        )
    }

    public let mccd_deleteButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Delete", for: .normal)
        b.setTitleColor(UIColor(hex: "F54545"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        b.layer.cornerCurve = .continuous
        b.clipsToBounds = true
        return b
    }()

    public override func mcvw_setupUI() {
        super.mcvw_setupUI()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        cardView.backgroundColor = UIColor(white: 0.14, alpha: 0.96)

        cardView.addSubview(mccd_messageLabel)
        cardView.addSubview(mccd_deleteButton)
        mccd_messageLabel.attributedText = Self.mccd_messageAttributedText()

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.width.equalTo(240)
        }
        mccd_messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().offset(-28)
        }
        mccd_deleteButton.snp.makeConstraints { make in
            make.top.equalTo(mccd_messageLabel.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let h = mccd_deleteButton.bounds.height
        guard h > 1 else { return }
        mccd_deleteButton.layer.cornerRadius = h * 0.5
    }

}

public final class MCCDeleteConfirmPopController: MCCPopController<MCCDeleteConfirmPopView, MCCEmptyViewModel> {

    public var onConfirmDelete: (() -> Void)?

    public override func mcvc_init() {
        super.mcvc_init()
        animationStyle = .easeInEaseOut
        dimmingInsets = .init(top: MCCScreenSize.navigationBarHeight, left: 0, bottom: 0, right: 0)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    public override func mcvc_bind() {
        super.mcvc_bind()
        contentView.mccd_deleteButton.addTarget(self, action: #selector(mccd_onDeleteTapped), for: .touchUpInside)
    }

    @objc
    private func mccd_onDeleteTapped() {
        contentView.mccd_deleteButton.isEnabled = false
        onConfirmDelete?()
    }

    public func mccd_setDeleteEnabled(_ enabled: Bool) {
        contentView.mccd_deleteButton.isEnabled = enabled
    }

}
