import UIKit
import SnapKit
import JXPagingView
import SDWebImage

public final class MCCShotsView: MCCBaseView {

    public let mcsv_tagFlowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumInteritemSpacing = 12
        l.minimumLineSpacing = 0
        return l
    }()

    public lazy var mcsv_tagCollection: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcsv_tagFlowLayout)
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        cv.register(MCCShotsTagCell.self, forCellWithReuseIdentifier: MCCShotsTagCell.mcsv_reuseId)
        return cv
    }()

    public let mcsv_pinHeaderView: UIView = {
        let v = UIView()
        v.frame = CGRect(x: 0, y: 0, width: 0, height: 44)
        return v
    }()

    private var mcsv_pagingViewRef: JXPagingView?

    public var mcsv_pagingListContainer: JXPagingListContainerView? { mcsv_pagingViewRef?.listContainerView }

    public override func mcvw_setupUI() {
        mcsv_pinHeaderView.addSubview(mcsv_tagCollection)
        mcsv_tagCollection.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public func mcsv_setupPagingView(delegate: JXPagingViewDelegate) {
        let pv = JXPagingView(delegate: delegate, listContainerType: .scrollView)
        pv.allowsCacheList = true
        mcsv_pagingViewRef = pv
        if pv.superview == nil {
            addSubview(pv)
        }
        pv.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    public func mcsv_setPagingHidden(_ hidden: Bool) {
        mcsv_pagingViewRef?.isHidden = hidden
    }

    public func mcsv_applyPagingTagReload(selectedIndex: Int, hasLabels: Bool) {
        guard let pv = mcsv_pagingViewRef else { return }
        if hasLabels {
            pv.defaultSelectedIndex = selectedIndex
        }
        pv.reloadData()
    }

    public func mcsv_scrollTagToIndex(_ index: Int, animated: Bool) {
        let p = IndexPath(item: index, section: 0)
        mcsv_tagCollection.layoutIfNeeded()
        mcsv_tagCollection.scrollToItem(at: p, at: .centeredHorizontally, animated: animated)
    }

}

public final class MCCShotsTagCell: MCCBaseCollectionViewCell {

    public static let mcsv_reuseId = "MCCShotsTagCell"

    public let mcsv_iconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        v.layer.cornerRadius = 2
        v.clipsToBounds = true
        return v
    }()

    public let mcsv_titleLabel = UILabel()

    private let mcsv_rowStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 4
        return s
    }()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcsv_rowStack)
        mcsv_rowStack.addArrangedSubview(mcsv_iconView)
        mcsv_rowStack.addArrangedSubview(mcsv_titleLabel)
        mcsv_iconView.snp.makeConstraints { $0.size.equalTo(18) }
        mcsv_rowStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcsv_iconView.sd_cancelCurrentImageLoad()
        mcsv_iconView.image = nil
    }

}
