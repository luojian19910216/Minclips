import UIKit
import Common
import SnapKit

public final class MCCDeleteConfirmPopView: MCCBasePopView {

    public let mccd_messageLabel: UILabel = {
        let l = UILabel()
        l.text = "Deleting it will make it unrecoverable. Are you sure to delete it?"
        l.textColor = UIColor(white: 1, alpha: 0.92)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.numberOfLines = 0
        return l
    }()

    public let mccd_deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Delete", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor.systemRed
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        return b
    }()

    public override func mcvw_setupUI() {
        super.mcvw_setupUI()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        cardView.backgroundColor = UIColor(white: 0.14, alpha: 0.96)

        cardView.addSubview(mccd_messageLabel)
        cardView.addSubview(mccd_deleteButton)

        cardView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.width.greaterThanOrEqualTo(240)
            make.width.lessThanOrEqualTo(280)
        }
        mccd_messageLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        mccd_deleteButton.snp.makeConstraints { make in
            make.top.equalTo(mccd_messageLabel.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }

}

public final class MCCDeleteConfirmPopController: MCCPopController<MCCDeleteConfirmPopView, MCCEmptyViewModel> {

    public var onConfirmDelete: (() -> Void)?

    public override func mcvc_init() {
        super.mcvc_init()
        animationStyle = .easeInEaseOut
        dimmingInsets = .init(
            top: MCCScreenSize.navigationBarHeight,
            left: 0,
            bottom: MCCScreenSize.tabBarHeight,
            right: 0
        )
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
