import UIKit
import Common
import SnapKit

public final class MCCFeedOptionPopView: MCCBasePopView {

    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(white: 1, alpha: 0.48)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        return l
    }()

    public let mcvw_optionStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        s.alignment = .fill
        return s
    }()

    public static let mcvw_cardCornerRadius: CGFloat = 12

    public override func mcvw_setupUI() {
        super.mcvw_setupUI()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cardView.backgroundColor = UIColor(white: 1, alpha: 0.06)
        cardView.addSubview(mcvw_titleLabel)
        cardView.addSubview(mcvw_optionStack)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        mcvw_titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        mcvw_optionStack.snp.makeConstraints { make in
            make.top.equalTo(mcvw_titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    public func mcvw_applyCardCornerRadius() {
        let mask = CAShapeLayer()
        mask.frame = cardView.bounds
        mask.path = UIBezierPath(
            roundedRect: cardView.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(
                width: Self.mcvw_cardCornerRadius,
                height: Self.mcvw_cardCornerRadius
            )
        ).cgPath
        cardView.layer.mask = mask
    }
}

public final class MCCFeedOptionPillControl: UIControl {

    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 14, weight: .regular)
        return l
    }()

    public let mcvw_proChip: UIView = {
        let w = UIView()
        w.backgroundColor = UIColor(hex: "FFC629")!.withAlphaComponent(0.12)
        w.layer.cornerRadius = 9
        w.clipsToBounds = true
        w.isHidden = true
        let l = UILabel()
        l.text = "PRO"
        l.textColor = UIColor(hex: "FFC629")
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        w.addSubview(l)
        l.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(5)
        }
        w.snp.makeConstraints { $0.height.equalTo(18) }
        return w
    }()

    private let mcvw_contentStack: UIStackView = {
        let h = UIStackView()
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        h.isUserInteractionEnabled = false
        return h
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = UIColor(white: 1, alpha: 0.06)
        mcvw_contentStack.addArrangedSubview(mcvw_titleLabel)
        mcvw_contentStack.addArrangedSubview(UIView())
        mcvw_contentStack.addArrangedSubview(mcvw_proChip)
        addSubview(mcvw_contentStack)
        mcvw_contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    public func mcvw_setSelectedHighlighted(_ on: Bool) {
        if on {
            backgroundColor = UIColor(hex: "0077FF")!.withAlphaComponent(0.12)
            layer.borderColor = UIColor(hex: "0077FF")!.withAlphaComponent(0.4).cgColor
            layer.borderWidth = 1
        } else {
            backgroundColor = UIColor(white: 1, alpha: 0.06)
            layer.borderColor = nil
            layer.borderWidth = 0
        }
    }
}
