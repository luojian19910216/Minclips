import UIKit
import SnapKit
import SkeletonView

private enum MCCHomeSkeletonAppearance {
    static let gradient = SkeletonGradient(
        baseColor: UIColor(white: 0.22, alpha: 1),
        secondaryColor: UIColor(white: 0.40, alpha: 1)
    )
}

private enum MCCToolsListSkeletonMetrics {
    static let sectionTopInset: CGFloat = 24
    static let sectionHorizontalInset: CGFloat = 12
    static let lineSpacing: CGFloat = 12
    static let cardHeight: CGFloat = 128
    static let cardCornerRadius: CGFloat = 12
    static let rowCount: Int = 8
}

private enum MCCShotsSkeletonMetrics {
    static let tagPinHeaderHeight: CGFloat = 48
    static let tagSkeletonPillHeight: CGFloat = 32
    static let tagHorizontalInset: CGFloat = 12
    /// 与列表 `MCCShotsWaterfallLayout.sectionInset` 左右一致
    static let gridHorizontalInset: CGFloat = 4
    /// 标签条下缘到首行 cell：`sectionInset.top`
    static let tagToFirstGridRowSpacing: CGFloat = 4
    static let columnSpacing: CGFloat = 4
    /// 与 `minimumLineSpacing`
    static let waterfallLineSpacing: CGFloat = 16
    static let thumbCornerRadius: CGFloat = 12
    static let imageHeightPerWidth: CGFloat = MCCShotsListItemMetrics.imageHeightPerWidth
    static let imageToTitleSpacing: CGFloat = MCCShotsListItemMetrics.imageToTitleSpacing
    static let titleBlockHeight: CGFloat = 32

    static func columnWidth(containerWidth w: CGFloat) -> CGFloat {
        let inner = w - gridHorizontalInset * 2
        return max(1, (inner - columnSpacing) / 2)
    }

    static func thumbHeight(containerWidth w: CGFloat) -> CGFloat {
        columnWidth(containerWidth: w) * imageHeightPerWidth
    }

    static func waterfallRowHeight(containerWidth w: CGFloat) -> CGFloat {
        thumbHeight(containerWidth: w) + imageToTitleSpacing + titleBlockHeight
    }
}

private enum MCCProjectsListSkeletonMetrics {

    static let horizontalSectionInset: CGFloat = 4
    static let sectionTopInset: CGFloat = 4
    static let columnCount = 3
    static let interitemSpacing: CGFloat = 4
    static let runsLineSpacing: CGFloat = 4
    static let likesLineSpacing: CGFloat = 16
    static let skeletonWidth: CGFloat = UIScreen.main.bounds.width

    static func columnWidth(containerWidth: CGFloat) -> CGFloat {
        let inner = containerWidth - horizontalSectionInset * 2
        let gutters = CGFloat(columnCount - 1) * interitemSpacing
        return max(1, (inner - gutters) / CGFloat(columnCount))
    }

    static var runsBlockHeight: CGFloat {
        columnWidth(containerWidth: skeletonWidth) * 160 / 120
    }

    static var likesThumbHeight: CGFloat {
        columnWidth(containerWidth: skeletonWidth) * (4.0 / 3.0)
    }

    static let projectsLikesTitleBlockHeight: CGFloat = 30

    static var likesRowHeight: CGFloat {
        likesThumbHeight + MCCShotsListItemMetrics.imageToTitleSpacing + projectsLikesTitleBlockHeight
    }

    static let rowsRuns = 9
    static let rowsLikes = 10
}

public final class MCCGradientHomeSkeletonOverlay: UIView {

    public enum MCCStyle {
        case tagsAndDoubleColumn
        case singleColumnList
        case doubleColumnGrid
        case projectsRunsThreeColumn
        case projectsLikesThreeColumn
    }

    private let mcvw_style: MCCStyle
    /// Shots：`tagsAndDoubleColumn` 下与真实轮播宽高、网格列宽同步。
    private weak var mcvw_shotsCarouselPlaceholder: UIView?
    private var mcvw_shotsWaterfallSkeletonRows: [(wrap: UIView, thumbs: [UIView])] = []

    private let mcvw_stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 12
        return s
    }()

    public init(style: MCCStyle) {
        mcvw_style = style
        super.init(frame: .zero)
        isSkeletonable = false
        backgroundColor = .clear
        addSubview(mcvw_stack)
        let topInset: CGFloat
        let horizontalInset: CGFloat
        switch style {
        case .tagsAndDoubleColumn, .doubleColumnGrid:
            topInset = 0
            horizontalInset = 0
        case .singleColumnList:
            topInset = MCCToolsListSkeletonMetrics.sectionTopInset
            horizontalInset = MCCToolsListSkeletonMetrics.sectionHorizontalInset
        case .projectsRunsThreeColumn, .projectsLikesThreeColumn:
            topInset = MCCProjectsListSkeletonMetrics.sectionTopInset
            horizontalInset = MCCProjectsListSkeletonMetrics.horizontalSectionInset
        }
        mcvw_stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topInset)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        mcvw_build(style: style)
    }

    required init?(coder: NSCoder) { fatalError() }

    public func mcvw_showHomeSkeleton() {
        guard isHidden else { return }
        mcvw_recursiveHideSkeleton(in: self)
        isHidden = false
        layoutIfNeeded()
        mcvw_recursiveShowSkeleton(in: self, gradient: MCCHomeSkeletonAppearance.gradient)
    }

    public func mcvw_hideHomeSkeleton() {
        guard !isHidden else { return }
        mcvw_recursiveHideSkeleton(in: self)
        isHidden = true
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

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard mcvw_style == .tagsAndDoubleColumn else { return }
        let w = bounds.width
        guard w > 1 else { return }

        let carH = MCCShotsCarouselMetrics.headerHeight(forWidth: w)
        if let carousel = mcvw_shotsCarouselPlaceholder {
            _ = carousel.snp.updateConstraints { $0.height.equalTo(carH) }
        }

        let thumbH = MCCShotsSkeletonMetrics.thumbHeight(containerWidth: w)
        let rowH = MCCShotsSkeletonMetrics.waterfallRowHeight(containerWidth: w)
        for row in mcvw_shotsWaterfallSkeletonRows {
            _ = row.wrap.snp.updateConstraints { $0.height.equalTo(rowH) }
            for t in row.thumbs {
                _ = t.snp.updateConstraints { $0.height.equalTo(thumbH) }
            }
        }
    }

    private func mcvw_build(style: MCCStyle) {
        switch style {
        case .tagsAndDoubleColumn:
            mcvw_shotsWaterfallSkeletonRows.removeAll()
            mcvw_stack.spacing = MCCShotsSkeletonMetrics.waterfallLineSpacing

            let refW = bounds.width > 1 ? bounds.width : UIScreen.main.bounds.width
            let carH = MCCShotsCarouselMetrics.headerHeight(forWidth: refW)
            let carouselSk = UIView()
            carouselSk.layer.cornerRadius = 6
            carouselSk.clipsToBounds = true
            mcvw_skeletonize(carouselSk, radius: 6, height: carH)
            mcvw_shotsCarouselPlaceholder = carouselSk
            mcvw_stack.addArrangedSubview(carouselSk)

            let tagHost = UIView()
            tagHost.snp.makeConstraints { $0.height.equalTo(MCCShotsSkeletonMetrics.tagPinHeaderHeight) }
            let tagBar = UIView()
            tagBar.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
            tagHost.addSubview(tagBar)
            tagBar.isSkeletonable = true
            tagBar.skeletonCornerRadius = 8
            tagBar.clipsToBounds = true
            tagBar.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(MCCShotsSkeletonMetrics.tagHorizontalInset)
                make.trailing.equalToSuperview().offset(-MCCShotsSkeletonMetrics.tagHorizontalInset)
                make.centerY.equalToSuperview()
                make.height.equalTo(MCCShotsSkeletonMetrics.tagSkeletonPillHeight)
            }
            mcvw_stack.addArrangedSubview(tagHost)
            // tableHeader 与 pinHeader 紧贴
            mcvw_stack.setCustomSpacing(0, after: carouselSk)
            // 与列表 `sectionInset.top` 一致（首行 cell 顶距）
            mcvw_stack.setCustomSpacing(MCCShotsSkeletonMetrics.tagToFirstGridRowSpacing, after: tagHost)

            let thumbH = MCCShotsSkeletonMetrics.thumbHeight(containerWidth: refW)
            let rowH = MCCShotsSkeletonMetrics.waterfallRowHeight(containerWidth: refW)
            for _ in 0..<Self.mcvw_rowCountShotsWaterfall {
                let built = mcvw_makeShotsWaterfallRow(thumbHeight: thumbH, rowHeight: rowH)
                mcvw_shotsWaterfallSkeletonRows.append((wrap: built.wrap, thumbs: built.thumbs))
                mcvw_stack.addArrangedSubview(built.wrap)
            }
        case .doubleColumnGrid:
            mcvw_stack.spacing = MCCShotsSkeletonMetrics.waterfallLineSpacing
            let gw = bounds.width > 1 ? bounds.width : UIScreen.main.bounds.width
            let th = MCCShotsSkeletonMetrics.thumbHeight(containerWidth: gw)
            let rh = MCCShotsSkeletonMetrics.waterfallRowHeight(containerWidth: gw)
            let topPad = UIView()
            topPad.snp.makeConstraints { $0.height.equalTo(MCCShotsSkeletonMetrics.tagToFirstGridRowSpacing) }
            mcvw_stack.addArrangedSubview(topPad)
            mcvw_stack.setCustomSpacing(0, after: topPad)
            for _ in 0..<Self.mcvw_rowCountShotsWaterfall {
                let built = mcvw_makeShotsWaterfallRow(thumbHeight: th, rowHeight: rh)
                mcvw_stack.addArrangedSubview(built.wrap)
            }
        case .singleColumnList:
            mcvw_stack.spacing = MCCToolsListSkeletonMetrics.lineSpacing
            for _ in 0..<MCCToolsListSkeletonMetrics.rowCount {
                let row = UIView()
                mcvw_skeletonize(
                    row,
                    radius: MCCToolsListSkeletonMetrics.cardCornerRadius,
                    height: MCCToolsListSkeletonMetrics.cardHeight
                )
                mcvw_stack.addArrangedSubview(row)
            }
        case .projectsRunsThreeColumn:
            mcvw_stack.spacing = MCCProjectsListSkeletonMetrics.runsLineSpacing
            let h = MCCProjectsListSkeletonMetrics.runsBlockHeight
            for _ in 0..<MCCProjectsListSkeletonMetrics.rowsRuns {
                mcvw_stack.addArrangedSubview(mcvw_makeProjectsRunsTripleRow(blockHeight: h))
            }
        case .projectsLikesThreeColumn:
            mcvw_stack.spacing = MCCProjectsListSkeletonMetrics.likesLineSpacing
            let thumbH = MCCProjectsListSkeletonMetrics.likesThumbHeight
            let rowH = MCCProjectsListSkeletonMetrics.likesRowHeight
            for _ in 0..<MCCProjectsListSkeletonMetrics.rowsLikes {
                mcvw_stack.addArrangedSubview(mcvw_makeProjectsLikesTripleRow(thumbHeight: thumbH, rowHeight: rowH))
            }
        }
    }

    private static let mcvw_rowCountShotsWaterfall = 5

    private func mcvw_makeShotsWaterfallColumn(thumbHeight: CGFloat) -> (column: UIStackView, thumb: UIView) {
        let col = UIStackView()
        col.axis = .vertical
        col.alignment = .fill
        col.spacing = MCCShotsSkeletonMetrics.imageToTitleSpacing
        let thumb = UIView()
        thumb.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        thumb.isSkeletonable = true
        thumb.skeletonCornerRadius = Float(MCCShotsSkeletonMetrics.thumbCornerRadius)
        thumb.clipsToBounds = true
        thumb.snp.makeConstraints { make in
            make.height.equalTo(thumbHeight)
        }
        let title = UIView()
        title.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        mcvw_skeletonize(title, radius: 4, height: MCCShotsSkeletonMetrics.titleBlockHeight)
        col.addArrangedSubview(thumb)
        col.addArrangedSubview(title)
        return (col, thumb)
    }

    private func mcvw_makeShotsWaterfallRow(thumbHeight: CGFloat, rowHeight: CGFloat) -> (wrap: UIView, thumbs: [UIView]) {
        let wrap = UIView()
        wrap.snp.makeConstraints { $0.height.equalTo(rowHeight) }
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = MCCShotsSkeletonMetrics.columnSpacing
        row.distribution = .fillEqually
        wrap.addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0,
                    left: MCCShotsSkeletonMetrics.gridHorizontalInset,
                    bottom: 0,
                    right: MCCShotsSkeletonMetrics.gridHorizontalInset
                )
            )
        }
        let a = mcvw_makeShotsWaterfallColumn(thumbHeight: thumbHeight)
        let b = mcvw_makeShotsWaterfallColumn(thumbHeight: thumbHeight)
        row.addArrangedSubview(a.column)
        row.addArrangedSubview(b.column)
        return (wrap, [a.thumb, b.thumb])
    }

    private func mcvw_makeProjectsRunsTripleRow(blockHeight: CGFloat) -> UIView {
        let wrap = UIView()
        wrap.snp.makeConstraints { $0.height.equalTo(blockHeight) }
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = MCCProjectsListSkeletonMetrics.interitemSpacing
        row.distribution = .fillEqually
        wrap.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        for _ in 0..<MCCProjectsListSkeletonMetrics.columnCount {
            let v = UIView()
            mcvw_skeletonize(v, radius: 8, height: blockHeight)
            row.addArrangedSubview(v)
        }
        return wrap
    }

    private func mcvw_makeProjectsLikesSkeletonColumn(thumbHeight: CGFloat) -> UIStackView {
        let col = UIStackView()
        col.axis = .vertical
        col.alignment = .fill
        col.spacing = MCCShotsListItemMetrics.imageToTitleSpacing
        let thumb = UIView()
        thumb.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        thumb.isSkeletonable = true
        thumb.skeletonCornerRadius = Float(MCCShotsSkeletonMetrics.thumbCornerRadius)
        thumb.clipsToBounds = true
        thumb.snp.makeConstraints { make in
            make.height.equalTo(thumbHeight)
        }
        let title = UIView()
        title.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        mcvw_skeletonize(title, radius: 4, height: MCCProjectsListSkeletonMetrics.projectsLikesTitleBlockHeight)
        col.addArrangedSubview(thumb)
        col.addArrangedSubview(title)
        return col
    }

    private func mcvw_makeProjectsLikesTripleRow(thumbHeight: CGFloat, rowHeight: CGFloat) -> UIView {
        let wrap = UIView()
        wrap.snp.makeConstraints { $0.height.equalTo(rowHeight) }
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = MCCProjectsListSkeletonMetrics.interitemSpacing
        row.distribution = .fillEqually
        wrap.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        for _ in 0..<MCCProjectsListSkeletonMetrics.columnCount {
            row.addArrangedSubview(mcvw_makeProjectsLikesSkeletonColumn(thumbHeight: thumbHeight))
        }
        return wrap
    }

    private func mcvw_skeletonize(_ v: UIView, radius: CGFloat, height: CGFloat) {
        v.backgroundColor = MCCShotsListItemMetrics.listItemImageContainerBackground
        v.isSkeletonable = true
        v.skeletonCornerRadius = Float(radius)
        v.clipsToBounds = true
        v.snp.makeConstraints { $0.height.equalTo(height) }
    }
}
