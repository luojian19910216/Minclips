import UIKit
import Common
import SnapKit

fileprivate enum MCCProStyle {
    static let cardBg = UIColor.white.withAlphaComponent(0.06)
    static let accent = UIColor(hex: "0077FF")!
    static let muted = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
}

fileprivate enum MPEMetric {
    static let listCellHeight: CGFloat = 68
    static let listLineSpacing: CGFloat = 16
    static let listHorizontal: CGFloat = 12
    static var mcvw_heroImageAspect: CGFloat {
        guard let i = UIImage(named: "ic_bg_pro"), i.size.width > 0 else { return 0.5 }
        return i.size.height / i.size.width
    }
}

public final class MCCProView: MCCBaseView {

    public static var mcvw_listCellHeight: CGFloat { MPEMetric.listCellHeight }
    public static var mcvw_listLineSpacing: CGFloat { MPEMetric.listLineSpacing }
    public static var mcvw_listHorizontal: CGFloat { MPEMetric.listHorizontal }
    public static let mcvw_listRowCount: Int = 3
    public static var mcvw_listFixedFrameHeight: CGFloat {
        CGFloat(mcvw_listRowCount) * MPEMetric.listCellHeight
            + CGFloat(max(0, mcvw_listRowCount - 1)) * MPEMetric.listLineSpacing
    }

    public let mcvw_heroImageView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(named: "ic_bg_pro")
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = .clear
        return v
    }()

    public let mcvw_headlineLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 24, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    public let mcvw_subheadlineLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white.withAlphaComponent(0.4)
        l.font = .systemFont(ofSize: 16, weight: .regular)
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
        cv.clipsToBounds = false
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
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.clipsToBounds = true
        return b
    }()

    public let mcvw_renewalHintLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    public let mcvw_restoreButton = UIButton(type: .system)
    public let mcvw_termsButton = UIButton(type: .system)
    public let mcvw_policyButton = UIButton(type: .system)

    private let mcvw_heroContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.clipsToBounds = true
        return v
    }()

    private let mcvw_listContainer = UIView()
    /// 顶部可伸缩空白，多出的垂直空间出现在标题上方（列表与 CTA 之间固定 32，不由本视图撑开）。
    private let mcvw_topSpacer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.setContentHuggingPriority(.defaultLow, for: .vertical)
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return v
    }()
    private let mcvw_contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 0
        s.distribution = .fill
        return s
    }()
    private let mcvw_legalRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .fill
        s.spacing = 12
        return s
    }()

    private let mcvw_skeletonOverlay = MCCProSkeletonOverlay()
    /// 加载中隐藏真按钮、只显示同框占位 + CA 微光，比 SkeletonView 叠在蓝按钮上稳得多。
    private let mcvw_ctaLoadingPill = MCCProCTALoadingPill()

    public override func mcvw_setupUI() {
        backgroundColor = .black

        let legalMuted = UIColor.white.withAlphaComponent(0.72)
        let legalEdge = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        [mcvw_restoreButton, mcvw_termsButton, mcvw_policyButton].forEach { b in
            b.setTitleColor(legalMuted, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
            b.contentEdgeInsets = legalEdge
        }

        addSubview(mcvw_heroContainer)
        mcvw_heroContainer.addSubview(mcvw_heroImageView)
        mcvw_heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_heroContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(mcvw_heroContainer.snp.width).multipliedBy(MPEMetric.mcvw_heroImageAspect)
        }

        addSubview(mcvw_contentStack)
        mcvw_contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }

        mcvw_contentStack.addArrangedSubview(mcvw_topSpacer)

        let textBlock = UIStackView(arrangedSubviews: [mcvw_headlineLabel, mcvw_subheadlineLabel])
        textBlock.axis = .vertical
        textBlock.spacing = 8
        textBlock.isLayoutMarginsRelativeArrangement = true
        textBlock.layoutMargins = UIEdgeInsets(top: 20, left: 32, bottom: 0, right: 32)
        mcvw_contentStack.addArrangedSubview(textBlock)

        mcvw_contentStack.addArrangedSubview(mcvw_listContainer)
        mcvw_listContainer.clipsToBounds = false
        mcvw_listContainer.addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(MCCProView.mcvw_listFixedFrameHeight)
        }

        mcvw_contentStack.setCustomSpacing(32, after: textBlock)
        mcvw_contentStack.setCustomSpacing(32, after: mcvw_listContainer)

        let ctaRow = UIView()
        ctaRow.addSubview(mcvw_ctaButton)
        ctaRow.addSubview(mcvw_ctaLoadingPill)
        mcvw_ctaButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        mcvw_ctaLoadingPill.snp.makeConstraints { $0.edges.equalTo(mcvw_ctaButton) }
        let ctaPad = UIStackView(arrangedSubviews: [ctaRow])
        ctaPad.isLayoutMarginsRelativeArrangement = true
        ctaPad.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
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
        footStack.spacing = 0
        footStack.isLayoutMarginsRelativeArrangement = true
        footStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        mcvw_contentStack.addArrangedSubview(footStack)
        mcvw_contentStack.setCustomSpacing(16, after: ctaPad)

        addSubview(mcvw_skeletonOverlay)
        mcvw_skeletonOverlay.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mcvw_ctaButton.snp.bottom)
        }
        mcvw_skeletonOverlay.isHidden = true
    }

    public func mcvw_setProSkeletonVisible(_ visible: Bool) {
        if visible {
            mcvw_skeletonOverlay.mcvw_showProSkeleton()
            mcvw_ctaButton.isHidden = true
            mcvw_ctaLoadingPill.isHidden = false
            mcvw_ctaLoadingPill.superview?.bringSubviewToFront(mcvw_ctaLoadingPill)
            bringSubviewToFront(mcvw_skeletonOverlay)
            layoutIfNeeded()
            mcvw_ctaLoadingPill.mcvw_startShimmer()
        } else {
            mcvw_ctaLoadingPill.mcvw_stopShimmer()
            mcvw_ctaLoadingPill.isHidden = true
            mcvw_ctaButton.isHidden = false
            mcvw_skeletonOverlay.mcvw_hideProSkeleton()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let ctaH = mcvw_ctaButton.bounds.height
        if ctaH > 0 { mcvw_ctaButton.layer.cornerRadius = ctaH * 0.5 }
        if !mcvw_skeletonOverlay.isHidden {
            bringSubviewToFront(mcvw_skeletonOverlay)
            mcvw_ctaLoadingPill.superview?.bringSubviewToFront(mcvw_ctaLoadingPill)
        }
    }

    private func mccpr_dot() -> UILabel {
        let l = UILabel()
        l.text = "·"
        l.textColor = .white.withAlphaComponent(0.72)
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textAlignment = .center
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }

}

/// 主 CTA 占位：不依赖 SkeletonView，避免与主按钮/蒙层叠图异常。
fileprivate final class MCCProCTALoadingPill: UIView {

    private let band = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        isUserInteractionEnabled = true
        backgroundColor = UIColor(white: 0.22, alpha: 1)
        clipsToBounds = true
        layer.addSublayer(band)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        let w = bounds.width
        layer.cornerRadius = h > 0 ? h * 0.5 : 0
        let bw = max(w * 0.38, 28)
        band.cornerRadius = h * 0.5
        band.backgroundColor = UIColor.white.withAlphaComponent(0.16).cgColor
        band.frame = CGRect(x: -bw, y: 0, width: bw, height: max(h, 1))
    }

    func mcvw_startShimmer() {
        mcvw_stopShimmer()
        let w = bounds.width
        let h = bounds.height
        guard w > 0.5, h > 0.5, !isHidden else { return }
        let a = CABasicAnimation(keyPath: "transform.translation.x")
        a.fromValue = 0
        a.toValue = w + w * 0.55
        a.duration = 1.2
        a.repeatCount = .infinity
        a.isRemovedOnCompletion = false
        band.add(a, forKey: "mcvw_shim")
    }

    func mcvw_stopShimmer() {
        band.removeAllAnimations()
    }
}

public final class MCCProPlanCell: MCCBaseCollectionViewCell {

    public static let mcvw_id = "MCCProPlanCell"

    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.numberOfLines = 1
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()
    public let mcvw_popularPill: UIButton = {
        let b = UIButton(type: .custom)
        b.isUserInteractionEnabled = false
        if let raw = UIImage(named: "ic_gc_popular")?.withRenderingMode(.alwaysOriginal) {
            let aw = raw.size.width
            let ah = raw.size.height
            let capL: CGFloat = aw > 24 ? 12 : max(1, aw / 3)
            let capR: CGFloat = aw > 24 ? 12 : max(1, aw / 3)
            let capT: CGFloat = ah > 16 ? 8 : max(1, ah / 3)
            let capB: CGFloat = ah > 16 ? 8 : max(1, ah / 3)
            let capped = raw.resizableImage(
                withCapInsets: UIEdgeInsets(top: capT, left: capL, bottom: capB, right: capR),
                resizingMode: .stretch
            )
            b.setBackgroundImage(capped, for: .normal)
        }
        b.setTitleColor(MCCProStyle.accent, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        b.titleLabel?.textAlignment = .center
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 7)
        b.isHidden = true
        return b
    }()
    /// 右侧价（粗体，与周期拆成两个 label，避免整行一条富文本）。
    public let mcvw_rightPriceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .white
        l.textAlignment = .right
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    public let mcvw_rightPeriodLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .white
        l.textAlignment = .right
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    private let mcvw_rightTextStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 0
        return s
    }()
    public let mcvw_saveBadge: UIButton = {
        let b = UIButton(type: .custom)
        b.isUserInteractionEnabled = false
        b.backgroundColor = MCCProStyle.accent
        b.setTitleColor(.white, for: .normal)
        b.setTitleColor(.white, for: .highlighted)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        b.titleLabel?.textAlignment = .center
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        b.isHidden = true
        return b
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
        clipsToBounds = false
        contentView.clipsToBounds = false
        mcvw_border.clipsToBounds = true
        mcvw_border.backgroundColor = MCCProStyle.cardBg
        mcvw_titleRow.addArrangedSubview(mcvw_titleLabel)
        mcvw_titleRow.addArrangedSubview(mcvw_popularPill)

        contentView.addSubview(mcvw_border)
        mcvw_border.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_border.layer.cornerRadius = 12
        mcvw_rightTextStack.addArrangedSubview(mcvw_rightPriceLabel)
        mcvw_rightTextStack.addArrangedSubview(mcvw_rightPeriodLabel)
        mcvw_border.addSubview(mcvw_titleRow)
        mcvw_border.addSubview(mcvw_rightTextStack)
        mcvw_titleRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(mcvw_rightTextStack.snp.leading).offset(-8)
        }
        mcvw_rightTextStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        mcvw_popularPill.snp.makeConstraints { $0.height.equalTo(20) }
        contentView.addSubview(mcvw_saveBadge)
        mcvw_saveBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalTo(mcvw_border.snp.top)
            make.height.equalTo(24)
        }
        contentView.bringSubviewToFront(mcvw_saveBadge)
    }

    public func mcvw_setSelection(_ isSelected: Bool) {
        mcvw_border.layer.borderWidth = 2
        mcvw_border.layer.borderColor = isSelected
            ? MCCProStyle.accent.cgColor
            : MCCProStyle.cardBg.cgColor
    }

    /// 右侧两段文案：`leading` 价、`trailing` 周期（如 `"/week"`），可空。
    public func mcvw_setRightLine(leading: String, trailing: String) {
        mcvw_rightPriceLabel.text = leading.isEmpty ? nil : leading
        mcvw_rightPeriodLabel.text = trailing.isEmpty ? nil : trailing
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_rightPriceLabel.text = nil
        mcvw_rightPeriodLabel.text = nil
    }

}
