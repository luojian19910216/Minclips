import UIKit
import Common
import SnapKit
import JXPagingView

public final class MCCToolsView: MCCBaseView {

    public let mcvw_tagFlowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumInteritemSpacing = 12
        l.minimumLineSpacing = 0
        return l
    }()

    public lazy var mcvw_tagCollection: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_tagFlowLayout)
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        cv.register(MCCToolsTagCell.self, forCellWithReuseIdentifier: MCCToolsTagCell.mcvw_reuseId)
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

    public func mcvw_applyPagingTagReload(selectedIndex: Int, hasGroups: Bool) {
        guard let pv = mcvw_pagingViewRef else { return }
        if hasGroups {
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

public final class MCCToolsTagCell: MCCBaseCollectionViewCell {

    public static let mcvw_reuseId = "MCCToolsTagCell"

    public let mcvw_titleLabel = UILabel()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_titleLabel)
        mcvw_titleLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

}

public final class MCCToolTextCell: MCCBaseCollectionViewCell {

    public static let mcvw_id = "MCCToolTextCell"

    public let mcvw_textLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.numberOfLines = 2
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.5
        return l
    }()

    public override func mcvw_setupUI() {
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true
        contentView.addSubview(mcvw_textLabel)
        mcvw_textLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_textLabel.text = nil
    }

}
