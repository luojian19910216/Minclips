import UIKit
import SnapKit

public final class MCCShotsListPageView: MCCBaseView {

    public let mcvw_flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 8
        l.minimumLineSpacing = 10
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_flow)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCShotsListItemCell.self, forCellWithReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId)
        return cv
    }()

    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

}

public final class MCCShotsListItemCell: MCCBaseCollectionViewCell {

    public static let mcvw_reuseId = "MCCShotsListItemCell"

    public let mcvw_imageContainer = UIView()

    public let mcvw_durationLabel = UILabel()

    public let mcvw_proBadge = UIView()

    public let mcvw_proIcon = UIImageView(image: UIImage(systemName: "diamond.fill"))

    public let mcvw_titleLabel = UILabel()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_imageContainer)
        contentView.addSubview(mcvw_titleLabel)
        mcvw_imageContainer.addSubview(mcvw_durationLabel)
        mcvw_imageContainer.addSubview(mcvw_proBadge)
        mcvw_proBadge.addSubview(mcvw_proIcon)
        mcvw_imageContainer.layer.cornerRadius = 12
        mcvw_imageContainer.clipsToBounds = true
        mcvw_imageContainer.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        mcvw_titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mcvw_imageContainer.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
        mcvw_durationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(6)
        }
        mcvw_proBadge.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(6)
            make.size.equalTo(24)
        }
        mcvw_proIcon.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_proBadge.isHidden = true
    }

}
