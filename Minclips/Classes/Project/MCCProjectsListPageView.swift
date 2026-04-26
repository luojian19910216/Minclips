import UIKit
import SnapKit
import SDWebImage

public final class MCCProjectsListPageView: MCCBaseView {

    public let mcvw_flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 8
        l.minimumLineSpacing = 8
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_flow)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCProjectsRunCell.self, forCellWithReuseIdentifier: MCCProjectsRunCell.mcvw_reuseId)
        return cv
    }()

    public lazy var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay = {
        MCCGradientHomeSkeletonOverlay(style: .tripleColumnGrid)
    }()

    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(mcvw_skeletonOverlay)
        mcvw_skeletonOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
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

public final class MCCProjectsRunCell: MCCBaseCollectionViewCell {

    public static let mcvw_reuseId = "MCCProjectsRunCell"

    public let mcvw_imageContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_thumbView = SDAnimatedImageView()

    public let mcvw_captionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textColor = UIColor(white: 1, alpha: 0.55)
        l.numberOfLines = 1
        return l
    }()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_imageContainer)
        mcvw_imageContainer.addSubview(mcvw_thumbView)
        contentView.addSubview(mcvw_captionLabel)
        mcvw_thumbView.contentMode = .scaleAspectFill
        mcvw_thumbView.clipsToBounds = true
        mcvw_imageContainer.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        mcvw_thumbView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_captionLabel.snp.makeConstraints { make in
            make.top.equalTo(mcvw_imageContainer.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_thumbView.image = nil
        mcvw_thumbView.sd_cancelCurrentImageLoad()
    }

}
