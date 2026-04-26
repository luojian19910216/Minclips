import UIKit
import SnapKit

public final class MCCShotsListPageView: MCCBaseView {

    public let mcsv_flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 8
        l.minimumLineSpacing = 10
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        return l
    }()

    public lazy var mcsv_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcsv_flow)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCShotsListItemCell.self, forCellWithReuseIdentifier: MCCShotsListItemCell.mcsv_reuseId)
        return cv
    }()

    public override func mcvw_setupUI() {
        addSubview(mcsv_collectionView)
        mcsv_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

}

public final class MCCShotsListItemCell: MCCBaseCollectionViewCell {

    public static let mcsv_reuseId = "MCCShotsListItemCell"

    public let mcsv_imageContainer = UIView()

    public let mcsv_durationLabel = UILabel()

    public let mcsv_proBadge = UIView()

    public let mcsv_proIcon = UIImageView(image: UIImage(systemName: "diamond.fill"))

    public let mcsv_titleLabel = UILabel()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcsv_imageContainer)
        contentView.addSubview(mcsv_titleLabel)
        mcsv_imageContainer.addSubview(mcsv_durationLabel)
        mcsv_imageContainer.addSubview(mcsv_proBadge)
        mcsv_proBadge.addSubview(mcsv_proIcon)
        mcsv_imageContainer.layer.cornerRadius = 12
        mcsv_imageContainer.clipsToBounds = true
        mcsv_imageContainer.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        mcsv_titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mcsv_imageContainer.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
        mcsv_durationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(6)
        }
        mcsv_proBadge.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(6)
            make.size.equalTo(24)
        }
        mcsv_proIcon.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcsv_proBadge.isHidden = true
    }

}
