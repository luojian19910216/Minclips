import UIKit
import SnapKit
import SkeletonView

private enum MCCProSkeletonAppearance {
    static let gradient = SkeletonGradient(
        baseColor: UIColor(white: 0.22, alpha: 1),
        secondaryColor: UIColor(white: 0.40, alpha: 1)
    )
}

/// 自底向上：`list` → `text` + 顶 `flex`；底上留白给真实主 CTA 尺寸（主按钮骨架在 `MCCProView` 里贴真按钮，避免透明蒙层透出蓝底、SkeletonView 在嵌套里不画渐变）。
public final class MCCProSkeletonOverlay: UIView {

    private enum Metric {
        /// 20 + 28 + 8 + 16，与内层 `textBlock` 边距 + 两线一致
        static let textBlockHeight: CGFloat = 72
        static let sectionGap: CGFloat = 32
        static let ctaHeight: CGFloat = 48
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isSkeletonable = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        mcvw_build()
    }

    required init?(coder: NSCoder) { fatalError() }

    public func mcvw_showProSkeleton() {
        mcvw_recursiveHideSkeleton(in: self)
        isHidden = false
        isUserInteractionEnabled = true
        layoutIfNeeded()
        mcvw_recursiveShowSkeleton(in: self, gradient: MCCProSkeletonAppearance.gradient)
    }

    public func mcvw_hideProSkeleton() {
        guard !isHidden else { return }
        mcvw_recursiveHideSkeleton(in: self)
        isHidden = true
        isUserInteractionEnabled = false
    }

    private func mcvw_recursiveShowSkeleton(in view: UIView, gradient: SkeletonGradient) {
        if view.isSkeletonable {
            view.showAnimatedGradientSkeleton(usingGradient: gradient)
        }
        for sub in view.subviews {
            mcvw_recursiveShowSkeleton(in: sub, gradient: gradient)
        }
    }

    private func mcvw_recursiveHideSkeleton(in view: UIView) {
        view.hideSkeleton()
        for sub in view.subviews {
            mcvw_recursiveHideSkeleton(in: sub)
        }
    }

    private func mcvw_build() {
        let topSpacer = UIView()
        topSpacer.backgroundColor = .clear
        topSpacer.isUserInteractionEnabled = false

        let textBlock = UIStackView()
        textBlock.axis = .vertical
        textBlock.spacing = 8
        textBlock.isLayoutMarginsRelativeArrangement = true
        textBlock.layoutMargins = UIEdgeInsets(top: 20, left: 32, bottom: 0, right: 32)
        textBlock.addArrangedSubview(mcvw_skeletonLine(height: 28, widthRatio: 0.7))
        textBlock.addArrangedSubview(mcvw_skeletonLine(height: 16, widthRatio: 0.85))

        let listHost = UIView()
        let listStack = UIStackView()
        listStack.axis = .vertical
        listStack.spacing = MCCProView.mcvw_listLineSpacing
        listStack.alignment = .fill
        listHost.addSubview(listStack)
        listStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(MCCProView.mcvw_listHorizontal)
        }
        for _ in 0..<MCCProView.mcvw_listRowCount {
            listStack.addArrangedSubview(mcvw_planRowSkeleton())
        }

        [topSpacer, textBlock, listHost].forEach { addSubview($0) }

        let listToBottom = Metric.ctaHeight + Metric.sectionGap
        listHost.snp.makeConstraints { make in
            make.height.equalTo(MCCProView.mcvw_listFixedFrameHeight)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(listToBottom)
        }
        textBlock.snp.makeConstraints { make in
            make.height.equalTo(Metric.textBlockHeight)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(listHost.snp.top).offset(-Metric.sectionGap)
        }
        topSpacer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(textBlock.snp.top)
        }
    }

    private func mcvw_skeletonLine(height: CGFloat, widthRatio: CGFloat) -> UIView {
        let host = UIView()
        let line = UIView()
        line.isSkeletonable = true
        line.clipsToBounds = true
        line.skeletonCornerRadius = Float(height * 0.5)
        host.addSubview(line)
        line.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(widthRatio)
            make.height.equalTo(height)
        }
        return host
    }

    private func mcvw_planRowSkeleton() -> UIView {
        let row = UIView()
        row.snp.makeConstraints { $0.height.equalTo(MCCProView.mcvw_listCellHeight) }
        let card = UIView()
        card.clipsToBounds = true
        card.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        card.layer.cornerRadius = 12
        row.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        let leftBar = UIView()
        leftBar.isSkeletonable = true
        leftBar.clipsToBounds = true
        leftBar.backgroundColor = UIColor(white: 0.2, alpha: 0.35)
        leftBar.skeletonCornerRadius = Float(8)
        let priceBar = UIView()
        priceBar.isSkeletonable = true
        priceBar.clipsToBounds = true
        priceBar.backgroundColor = UIColor(white: 0.2, alpha: 0.35)
        priceBar.skeletonCornerRadius = Float(6)
        let periodBar = UIView()
        periodBar.isSkeletonable = true
        periodBar.clipsToBounds = true
        periodBar.backgroundColor = UIColor(white: 0.2, alpha: 0.35)
        periodBar.skeletonCornerRadius = Float(6)

        let rightStack = UIStackView(arrangedSubviews: [priceBar, periodBar])
        rightStack.axis = .horizontal
        rightStack.alignment = .center
        rightStack.spacing = 4

        card.addSubview(leftBar)
        card.addSubview(rightStack)
        leftBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(16)
            make.width.equalToSuperview().multipliedBy(0.38)
        }
        priceBar.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.width.equalTo(56)
        }
        periodBar.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.width.equalTo(36)
        }
        rightStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(leftBar.snp.trailing).offset(8)
        }
        return row
    }

}
