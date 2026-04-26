import UIKit
import SnapKit
import SDWebImage

public final class MCCProjectsListPageView: MCCBaseView {

    public let mcpj_flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 8
        l.minimumLineSpacing = 8
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        return l
    }()

    public lazy var mcpj_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcpj_flow)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCProjectsRunCell.self, forCellWithReuseIdentifier: MCCProjectsRunCell.mcpj_reuseId)
        return cv
    }()

    public override func mcvw_setupUI() {
        addSubview(mcpj_collectionView)
        mcpj_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

}

public final class MCCProjectsRunCell: MCCBaseCollectionViewCell {

    public static let mcpj_reuseId = "MCCProjectsRunCell"

    public let mcpj_imageContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        return v
    }()

    public let mcpj_thumbView = UIImageView()

    public let mcpj_captionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textColor = UIColor(white: 1, alpha: 0.55)
        l.numberOfLines = 1
        return l
    }()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcpj_imageContainer)
        mcpj_imageContainer.addSubview(mcpj_thumbView)
        contentView.addSubview(mcpj_captionLabel)
        mcpj_thumbView.contentMode = .scaleAspectFill
        mcpj_thumbView.clipsToBounds = true
        mcpj_imageContainer.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        mcpj_thumbView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcpj_captionLabel.snp.makeConstraints { make in
            make.top.equalTo(mcpj_imageContainer.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcpj_thumbView.image = nil
        mcpj_thumbView.sd_cancelCurrentImageLoad()
    }

}
