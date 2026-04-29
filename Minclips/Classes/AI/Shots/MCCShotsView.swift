import UIKit
import Common
import SnapKit
import JXPagingView
import SDWebImage

public final class MCCShotsView: MCCBaseView {

    /// JXPaging `tableHeaderView`: paging-sized height comes from `MCCShotsController.tableHeaderViewHeight`.
    public lazy var mcvw_carouselHeaderView: MCCShotsCarouselHeaderView = {
        let v = MCCShotsCarouselHeaderView()
        return v
    }()

    public let mcvw_tagFlowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumInteritemSpacing = 24
        l.minimumLineSpacing = 0
        return l
    }()

    public lazy var mcvw_tagCollection: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_tagFlowLayout)
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.delaysContentTouches = false
        cv.canCancelContentTouches = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        cv.register(MCCShotsTagCell.self, forCellWithReuseIdentifier: MCCShotsTagCell.mcvw_reuseId)
        return cv
    }()

    public let mcvw_pinHeaderView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 48))
        return v
    }()
    
    private var mcvw_pagingViewRef: JXPagingListRefreshView?

    public var mcvw_pagingListContainer: JXPagingListContainerView? { mcvw_pagingViewRef?.listContainerView }

    public lazy var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay = {
        let item = MCCGradientHomeSkeletonOverlay(style: .tagsAndDoubleColumn)
        item.isHidden = true
        return item
    }()

    public override func mcvw_setupUI() {
        mcvw_pinHeaderView.addSubview(mcvw_tagCollection)
        mcvw_tagCollection.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(mcvw_skeletonOverlay)
        mcvw_skeletonOverlay.isUserInteractionEnabled = false
        mcvw_skeletonOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func mcvw_setupPagingView(delegate: JXPagingViewDelegate) {
        let pv = JXPagingListRefreshView(delegate: delegate, listContainerType: .scrollView)
        pv.mainTableView.backgroundColor = .clear
        pv.mainTableView.contentInsetAdjustmentBehavior = .never
        pv.allowsCacheList = true
        mcvw_pagingViewRef = pv
        if pv.superview == nil {
            addSubview(pv)
        }
        pv.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        bringSubviewToFront(mcvw_skeletonOverlay)
    }

    public func mcvw_setTabHomeSkeletonVisible(_ visible: Bool) {
        mcvw_skeletonOverlay.isUserInteractionEnabled = visible
        if visible {
            mcvw_skeletonOverlay.mcvw_showHomeSkeleton()
        } else {
            mcvw_skeletonOverlay.mcvw_hideHomeSkeleton()
        }
    }

    public func mcvw_setPagingHidden(_ hidden: Bool) {
        mcvw_pagingViewRef?.isHidden = hidden
    }

    public func mcvw_applyPagingTagReload(selectedIndex: Int, hasLabels: Bool) {
        guard let pv = mcvw_pagingViewRef else { return }
        if hasLabels {
            pv.defaultSelectedIndex = selectedIndex
        }
        pv.reloadData()
    }

    public func mcvw_scrollTagToIndex(_ index: Int, animated: Bool) {
        let p = IndexPath(item: index, section: 0)
        mcvw_tagCollection.layoutIfNeeded()
        mcvw_tagCollection.scrollToItem(at: p, at: .centeredHorizontally, animated: animated)
    }

}

public final class MCCShotsTagCell: MCCBaseCollectionViewCell {

    public static let mcvw_reuseId = "MCCShotsTagCell"

    private let mcvw_rowStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 6
        return s
    }()
    
    public let mcvw_iconView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        return v
    }()

    public let mcvw_titleLabel = UILabel()
    
    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_rowStack)
        mcvw_rowStack.addArrangedSubview(mcvw_iconView)
        mcvw_rowStack.addArrangedSubview(mcvw_titleLabel)
        mcvw_iconView.snp.makeConstraints { $0.size.equalTo(18) }
        mcvw_rowStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_iconView.sd_cancelCurrentImageLoad()
        mcvw_iconView.image = nil
    }

}
