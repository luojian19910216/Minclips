import UIKit
import Common
import SnapKit

fileprivate enum MCCProStyle {
    static let cardBg = UIColor(hex: "1C1C1E")!
    static let accent = UIColor(hex: "00AAFF")!
    static let muted = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
    static let buttonCorner: CGFloat = 12
}

fileprivate enum MPEMetric {
    static let listCellHeight: CGFloat = 76
    static let listLineSpacing: CGFloat = 10
    static let listHorizontal: CGFloat = 20
    static let headerHeroRatio: CGFloat = 0.38
}

public final class MCCProView: MCCBaseView {

    public static var mcvw_listCellHeight: CGFloat { MPEMetric.listCellHeight }
    public static var mcvw_listLineSpacing: CGFloat { MPEMetric.listLineSpacing }
    public static var mcvw_listHorizontal: CGFloat { MPEMetric.listHorizontal }

    public let mcvw_scrollView: UIScrollView = {
        let s = UIScrollView()
        s.alwaysBounceVertical = false
        s.bounces = false
        s.showsVerticalScrollIndicator = true
        s.backgroundColor = .black
        s.contentInsetAdjustmentBehavior = .always
        return s
    }()

    public let mcvw_heroImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = UIColor(white: 0.12, alpha: 1)
        return v
    }()

    public let mcvw_headlineLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 22, weight: .heavy)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    public let mcvw_subheadlineLabel: UILabel = {
        let l = UILabel()
        l.textColor = MCCProStyle.muted
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    public let mcvw_collectionView: UICollectionView = {
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .vertical
        flow.minimumLineSpacing = MPEMetric.listLineSpacing
        flow.sectionInset = UIEdgeInsets(
            top: 0,
            left: MPEMetric.listHorizontal,
            bottom: 0,
            right: MPEMetric.listHorizontal
        )
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flow)
        cv.backgroundColor = .black
        cv.isScrollEnabled = false
        cv.alwaysBounceVertical = false
        cv.bounces = false
        cv.showsVerticalScrollIndicator = true
        cv.register(MCCProPlanCell.self, forCellWithReuseIdentifier: MCCProPlanCell.mcvw_id)
        return cv
    }()

    public let mcvw_ctaButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = MCCProStyle.accent
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.layer.cornerRadius = MCCProStyle.buttonCorner
        b.clipsToBounds = true
        return b
    }()

    public let mcvw_renewalHintLabel: UILabel = {
        let l = UILabel()
        l.textColor = MCCProStyle.muted
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    public let mcvw_restoreButton = UIButton(type: .system)
    public let mcvw_termsButton = UIButton(type: .system)
    public let mcvw_policyButton = UIButton(type: .system)

    private let mcvw_heroContainer = UIView()
    private let mcvw_heroGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.cgColor,
        ]
        g.locations = [0.5, 1]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        return g
    }()

    private let mcvw_listContainer = UIView()
    private let mcvw_contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 0
        return s
    }()
    private let mcvw_legalRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .fill
        s.spacing = 6
        return s
    }()

    public override func mcvw_setupUI() {
        backgroundColor = .black

        [mcvw_restoreButton, mcvw_termsButton, mcvw_policyButton].forEach { b in
            b.setTitleColor(MCCProStyle.muted, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
        }

        addSubview(mcvw_scrollView)
        mcvw_scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mcvw_scrollView.addSubview(mcvw_contentStack)
        mcvw_contentStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(mcvw_scrollView.contentLayoutGuide)
            make.leading.trailing.equalTo(mcvw_scrollView.frameLayoutGuide)
        }

        mcvw_heroContainer.addSubview(mcvw_heroImageView)
        mcvw_heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_heroContainer.layer.addSublayer(mcvw_heroGradient)
        mcvw_contentStack.addArrangedSubview(mcvw_heroContainer)
        mcvw_heroContainer.snp.makeConstraints { make in
            make.height.equalTo(mcvw_heroContainer.snp.width).multipliedBy(MPEMetric.headerHeroRatio)
        }

        let textBlock = UIStackView(arrangedSubviews: [mcvw_headlineLabel, mcvw_subheadlineLabel])
        textBlock.axis = .vertical
        textBlock.spacing = 8
        textBlock.isLayoutMarginsRelativeArrangement = true
        textBlock.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
        mcvw_contentStack.addArrangedSubview(textBlock)

        mcvw_contentStack.addArrangedSubview(mcvw_listContainer)
        mcvw_listContainer.addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
        }

        mcvw_contentStack.setCustomSpacing(20, after: mcvw_listContainer)

        let ctaPad = UIStackView(arrangedSubviews: [mcvw_ctaButton])
        ctaPad.isLayoutMarginsRelativeArrangement = true
        ctaPad.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        mcvw_ctaButton.snp.makeConstraints { $0.height.equalTo(52) }
        mcvw_contentStack.addArrangedSubview(ctaPad)

        mcvw_legalRow.addArrangedSubview(mcvw_restoreButton)
        mcvw_legalRow.addArrangedSubview(mccpr_dot())
        mcvw_legalRow.addArrangedSubview(mcvw_termsButton)
        mcvw_legalRow.addArrangedSubview(mccpr_dot())
        mcvw_legalRow.addArrangedSubview(mcvw_policyButton)
        let legalHost = UIView()
        legalHost.addSubview(mcvw_legalRow)
        mcvw_legalRow.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        let footStack = UIStackView(arrangedSubviews: [mcvw_renewalHintLabel, legalHost])
        footStack.axis = .vertical
        footStack.spacing = 12
        footStack.isLayoutMarginsRelativeArrangement = true
        footStack.layoutMargins = UIEdgeInsets(top: 12, left: 20, bottom: 20, right: 20)
        mcvw_contentStack.addArrangedSubview(footStack)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        mcvw_heroGradient.frame = mcvw_heroContainer.bounds
    }

    public func mcvw_setListFrameHeight(_ height: CGFloat) {
        mcvw_collectionView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func mccpr_dot() -> UILabel {
        let l = UILabel()
        l.text = "·"
        l.textColor = MCCProStyle.muted
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textAlignment = .center
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }

}

public final class MCCProPlanCell: MCCBaseCollectionViewCell {

    public static let mcvw_id = "MCCProPlanCell"

    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.numberOfLines = 1
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()
    public let mcvw_popularPill: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.backgroundColor = MCCProStyle.accent
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.isHidden = true
        return l
    }()
    public let mcvw_priceLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textAlignment = .right
        return l
    }()
    public let mcvw_periodLabel: UILabel = {
        let l = UILabel()
        l.textColor = MCCProStyle.muted
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textAlignment = .right
        return l
    }()
    public let mcvw_saveBadge: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.backgroundColor = MCCProStyle.accent
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.isHidden = true
        return l
    }()

    private let mcvw_rightColumn: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .trailing
        s.spacing = 2
        return s
    }()
    private let mcvw_titleRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 6
        return s
    }()
    private let mcvw_border = UIView()

    public override func mcvw_setupUI() {
        contentView.clipsToBounds = false
        mcvw_border.clipsToBounds = true
        mcvw_border.backgroundColor = MCCProStyle.cardBg
        mcvw_rightColumn.addArrangedSubview(mcvw_priceLabel)
        mcvw_rightColumn.addArrangedSubview(mcvw_periodLabel)
        mcvw_titleRow.addArrangedSubview(mcvw_titleLabel)
        mcvw_titleRow.addArrangedSubview(mcvw_popularPill)

        contentView.addSubview(mcvw_border)
        mcvw_border.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_border.layer.cornerRadius = 12
        mcvw_border.addSubview(mcvw_titleRow)
        mcvw_border.addSubview(mcvw_rightColumn)
        mcvw_titleRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(mcvw_rightColumn.snp.leading).offset(-8)
        }
        mcvw_rightColumn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        mcvw_border.addSubview(mcvw_saveBadge)
        mcvw_saveBadge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-4)
            make.trailing.equalToSuperview().offset(4)
        }
    }

    public func mcvw_setSelection(_ isSelected: Bool) {
        mcvw_border.layer.borderWidth = isSelected ? 2 : 0
        mcvw_border.layer.borderColor = isSelected ? MCCProStyle.accent.cgColor : nil
    }

}
