import UIKit
import Common
import SnapKit

public final class MCCToolsView: MCCBaseView {

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

    public lazy var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay = {
        MCCGradientHomeSkeletonOverlay(style: .singleColumnList)
    }()

    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        addSubview(mcvw_skeletonOverlay)
        mcvw_skeletonOverlay.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        mcvw_skeletonOverlay.isHidden = true
    }

    public func mcvw_setListSkeletonVisible(_ visible: Bool) {
        if visible {
            mcvw_skeletonOverlay.mcvw_showHomeSkeleton()
        } else {
            mcvw_skeletonOverlay.mcvw_hideHomeSkeleton()
        }
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
