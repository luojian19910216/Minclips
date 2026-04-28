import UIKit
import Common
import SnapKit
import JXPagingView
import SDWebImage

public final class MCCProjectsView: MCCBaseView {

    public let mcvw_tagFlowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumInteritemSpacing = 24
        l.minimumLineSpacing = 0
        l.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        return l
    }()

    public lazy var mcvw_tagCollection: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_tagFlowLayout)
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.contentInset = .zero
        cv.contentInsetAdjustmentBehavior = .never
        cv.register(MCCProjectsTagCell.self, forCellWithReuseIdentifier: MCCProjectsTagCell.mcvw_reuseId)
        return cv
    }()

    public let mcvw_pinHeaderView: UIView = {
        let v = UIView()

        let h = max(20, MCCScreenSize.statusBarHeight)
        v.frame = CGRect(x: 0, y: 0, width: 0, height: h)
        return v
    }()

    private var mcvw_pagingViewRef: JXPagingListRefreshView?

    public var mcvw_pagingListContainer: JXPagingListContainerView? { mcvw_pagingViewRef?.listContainerView }

    public override func mcvw_setupUI() {
        mcvw_pinHeaderView.addSubview(mcvw_tagCollection)
        mcvw_tagCollection.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public func mcvw_setupPagingView(delegate: JXPagingViewDelegate) {
        let pv = JXPagingListRefreshView(delegate: delegate, listContainerType: .scrollView)
        pv.mainTableView.backgroundColor = .clear
        pv.allowsCacheList = true
        mcvw_pagingViewRef = pv
        if pv.superview == nil {
            addSubview(pv)
        }
        pv.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    public func mcvw_setPagingHidden(_ hidden: Bool) {
        mcvw_pagingViewRef?.isHidden = hidden
    }

    public func mcvw_applyPagingTagReload(selectedIndex: Int, hasTags: Bool) {
        guard let pv = mcvw_pagingViewRef else { return }
        if hasTags {
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

public final class MCCProjectsTagCell: MCCBaseCollectionViewCell {

    public static let mcvw_reuseId = "MCCProjectsTagCell"

    public let mcvw_iconView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        v.layer.cornerRadius = 2
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_titleLabel = UILabel()

    private let mcvw_rowStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 4
        return s
    }()

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
