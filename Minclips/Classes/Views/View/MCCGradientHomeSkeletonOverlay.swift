import UIKit
import SnapKit
import SkeletonView

private enum MCCHomeSkeletonAppearance {
    static let gradient = SkeletonGradient(
        baseColor: UIColor(white: 0.22, alpha: 1),
        secondaryColor: UIColor(white: 0.40, alpha: 1)
    )
}

public final class MCCGradientHomeSkeletonOverlay: UIView {

    public enum MCCStyle {
        case tagsAndDoubleColumn
        case singleColumnList
        /// Shorts 子列表：仅双列宫格（无顶部分类条）
        case doubleColumnGrid
        /// Projects 子列表：三列宫格
        case tripleColumnGrid
    }

    private let mcvw_stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 12
        s.isSkeletonable = true
        return s
    }()

    public init(style: MCCStyle) {
        super.init(frame: .zero)
        isSkeletonable = true
        backgroundColor = .clear
        addSubview(mcvw_stack)
        let topInset: CGFloat
        switch style {
        case .tagsAndDoubleColumn, .singleColumnList:
            topInset = 8
        case .doubleColumnGrid, .tripleColumnGrid:
            topInset = 0
        }
        mcvw_stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topInset)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        mcvw_build(style: style)
    }

    required init?(coder: NSCoder) { fatalError() }

    public func mcvw_showHomeSkeleton() {
        hideSkeleton()
        isHidden = false
        layoutIfNeeded()
        showAnimatedGradientSkeleton(usingGradient: MCCHomeSkeletonAppearance.gradient)
    }

    public func mcvw_hideHomeSkeleton() {
        hideSkeleton()
        isHidden = true
    }

    private func mcvw_build(style: MCCStyle) {
        switch style {
        case .tagsAndDoubleColumn:
            let tag = UIView()
            mcvw_skeletonize(tag, radius: 8, height: 32)
            mcvw_stack.addArrangedSubview(tag)
            for _ in 0..<Self.mcvw_rowCountTagsAndDoubleGrid {
                mcvw_stack.addArrangedSubview(mcvw_makeDoubleColumnRow(thumbHeight: Self.mcvw_doubleColumnThumbHeight))
            }
        case .singleColumnList:
            for _ in 0..<Self.mcvw_rowCountSingleColumn {
                let row = UIView()
                mcvw_skeletonize(row, radius: 6, height: Self.mcvw_singleColumnRowHeight)
                mcvw_stack.addArrangedSubview(row)
            }
        case .doubleColumnGrid:
            for _ in 0..<Self.mcvw_rowCountDoubleGrid {
                mcvw_stack.addArrangedSubview(mcvw_makeDoubleColumnRow(thumbHeight: Self.mcvw_doubleColumnThumbHeight))
            }
        case .tripleColumnGrid:
            for _ in 0..<Self.mcvw_rowCountTripleGrid {
                mcvw_stack.addArrangedSubview(mcvw_makeTripleColumnRow(blockHeight: Self.mcvw_tripleColumnBlockHeight))
            }
        }
    }

    /// 行数按常见一屏高度估算（含 `spacing`），偏大一号避免露底
    private static let mcvw_rowCountTagsAndDoubleGrid = 8

    private static let mcvw_rowCountSingleColumn = 16

    private static let mcvw_rowCountDoubleGrid = 8

    private static let mcvw_rowCountTripleGrid = 10

    private static let mcvw_doubleColumnThumbHeight: CGFloat = 128

    private static let mcvw_singleColumnRowHeight: CGFloat = 56

    private static let mcvw_tripleColumnBlockHeight: CGFloat = 122

    private func mcvw_skeletonize(_ v: UIView, radius: CGFloat, height: CGFloat) {
        v.isSkeletonable = true
        v.skeletonCornerRadius = Float(radius)
        v.clipsToBounds = true
        v.snp.makeConstraints { $0.height.equalTo(height) }
    }

    private func mcvw_makeDoubleColumnRow(thumbHeight: CGFloat) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        row.isSkeletonable = true
        let left = UIView()
        let right = UIView()
        mcvw_skeletonize(left, radius: 12, height: thumbHeight)
        mcvw_skeletonize(right, radius: 12, height: thumbHeight)
        row.addArrangedSubview(left)
        row.addArrangedSubview(right)
        return row
    }

    private func mcvw_makeTripleColumnRow(blockHeight: CGFloat) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        row.isSkeletonable = true
        for _ in 0..<3 {
            let v = UIView()
            mcvw_skeletonize(v, radius: 8, height: blockHeight)
            row.addArrangedSubview(v)
        }
        return row
    }

}
