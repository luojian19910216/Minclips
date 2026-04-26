import UIKit
import Common
import SnapKit

public final class MCCToolsListPageView: MCCBaseView {

    public let mcvw_flowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .vertical
        l.minimumInteritemSpacing = 8
        l.minimumLineSpacing = 8
        l.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16)
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_flowLayout)
        cv.alwaysBounceVertical = true
        cv.backgroundColor = .clear
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCToolTextCell.self, forCellWithReuseIdentifier: MCCToolTextCell.mcvw_id)
        return cv
    }()

    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

}
