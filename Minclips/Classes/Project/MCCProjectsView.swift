import UIKit
import Common
import SnapKit
import JXPagingView

public final class MCCProjectsView: MCCBaseView {

    public let mcpj_tagFlowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumInteritemSpacing = 12
        l.minimumLineSpacing = 0
        return l
    }()

    public lazy var mcpj_tagCollection: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcpj_tagFlowLayout)
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        cv.register(MCCShotsTagCell.self, forCellWithReuseIdentifier: MCCShotsTagCell.mcsv_reuseId)
        return cv
    }()

    public let mcpj_pinHeaderView: UIView = {
        let v = UIView()
        let h = max(20, MCCScreenSize.statusBarHeight)
        v.frame = CGRect(x: 0, y: 0, width: 0, height: h)
        return v
    }()

    private var mcpj_pagingViewRef: JXPagingListRefreshView?

    public var mcpj_pagingListContainer: JXPagingListContainerView? { mcpj_pagingViewRef?.listContainerView }

    public override func mcvw_setupUI() {
        mcpj_pinHeaderView.addSubview(mcpj_tagCollection)
        mcpj_tagCollection.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public func mcpj_setupPagingView(delegate: JXPagingViewDelegate) {
        let pv = JXPagingListRefreshView(delegate: delegate, listContainerType: .scrollView)
        pv.mainTableView.backgroundColor = .clear
        pv.allowsCacheList = true
        mcpj_pagingViewRef = pv
        if pv.superview == nil {
            addSubview(pv)
        }
        pv.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    public func mcpj_setPagingHidden(_ hidden: Bool) {
        mcpj_pagingViewRef?.isHidden = hidden
    }

    public func mcpj_applyPagingTagReload(selectedIndex: Int, hasTags: Bool) {
        guard let pv = mcpj_pagingViewRef else { return }
        if hasTags {
            pv.defaultSelectedIndex = selectedIndex
        }
        pv.reloadData()
    }

    public func mcpj_scrollTagToIndex(_ index: Int, animated: Bool) {
        let p = IndexPath(item: index, section: 0)
        mcpj_tagCollection.layoutIfNeeded()
        mcpj_tagCollection.scrollToItem(at: p, at: .centeredHorizontally, animated: animated)
    }

}
