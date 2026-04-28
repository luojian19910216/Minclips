import UIKit
import Common
import SnapKit

public enum MCEFeedOptionPopAnchorAlignment {
    case leading
    case center
    case trailing
}

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
    private let mcvw_glassBlurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemChromeMaterialDark)
        return UIVisualEffectView(effect: effect)
    }()
    private let mcvw_glassTintView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.10)
        return v
    }()
    private let mcvw_glassHighlightView = MCCGlassHighlightView()
    private let mcvw_glassBorderView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        v.layer.borderWidth = 0.8
        v.isUserInteractionEnabled = false
        return v
    }()

    public override func mcvw_setupUI() {
        super.mcvw_setupUI()
        dimmingView.backgroundColor = UIColor.clear
        cardView.backgroundColor = .clear
        cardView.addSubview(mcvw_glassBlurView)
        cardView.addSubview(mcvw_glassTintView)
        cardView.addSubview(mcvw_glassHighlightView)
        cardView.addSubview(mcvw_glassBorderView)
        cardView.addSubview(mcvw_titleLabel)
        cardView.addSubview(mcvw_optionStack)
        mcvw_glassBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mcvw_glassTintView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mcvw_glassHighlightView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(64)
        }
        mcvw_glassBorderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

    public func mcvw_applyAnchorFrame(_ frame: CGRect, alignment: MCEFeedOptionPopAnchorAlignment) {
        let cardWidth = mcvw_computeCardWidth()
        cardView.snp.remakeConstraints { make in
            make.bottom.equalTo(self.snp.top).offset(frame.minY - 8)
            make.width.equalTo(cardWidth)
            switch alignment {
            case .leading:
                make.leading.equalTo(self.snp.leading).offset(frame.minX)
            case .center:
                make.centerX.equalTo(self.snp.leading).offset(frame.midX)
            case .trailing:
                make.trailing.equalTo(self.snp.leading).offset(frame.maxX)
            }
        }
    }

    private func mcvw_computeCardWidth() -> CGFloat {
        let outerInset: CGFloat = 16
        let pillHorizontalInset: CGFloat = 16
        let titleToChipGap: CGFloat = 8
        var maxPillContent: CGFloat = 0
        for sub in mcvw_optionStack.arrangedSubviews {
            guard let pill = sub as? MCCFeedOptionPillControl else { continue }
            let titleWidth = pill.mcvw_titleLabel.intrinsicContentSize.width
            var rowWidth = pillHorizontalInset + titleWidth + pillHorizontalInset
            if !pill.mcvw_proChip.isHidden {
                let chipLabelWidth = pill.mcvw_proChip.subviews
                    .compactMap { $0 as? UILabel }
                    .first?.intrinsicContentSize.width ?? 0
                rowWidth += titleToChipGap + chipLabelWidth + 10
            }
            maxPillContent = max(maxPillContent, rowWidth)
        }
        let titleRowWidth = mcvw_titleLabel.intrinsicContentSize.width
        let inner = max(maxPillContent, titleRowWidth)
        return ceil(inner + outerInset * 2)
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
        mcvw_glassBorderView.layer.cornerRadius = Self.mcvw_cardCornerRadius
    }
}

private final class MCCGlassHighlightView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        let g = layer as! CAGradientLayer
        g.colors = [
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.white.withAlphaComponent(0.06).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        g.locations = [0, 0.45, 1]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
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

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = UIColor(white: 1, alpha: 0.06)
        addSubview(mcvw_titleLabel)
        addSubview(mcvw_proChip)
        mcvw_titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        mcvw_proChip.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(mcvw_titleLabel.snp.trailing).offset(8)
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
