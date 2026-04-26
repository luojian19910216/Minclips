import UIKit
import Common
import SnapKit

public final class MCCToolsView: MCCBaseView {

    public let mcpj_flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 0
        l.minimumLineSpacing = 8
        l.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16)
        l.scrollDirection = .vertical
        return l
    }()

    public lazy var mcpj_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcpj_flow)
        cv.alwaysBounceVertical = true
        cv.backgroundColor = .clear
        cv.register(MCCToolTextCell.self, forCellWithReuseIdentifier: MCCToolTextCell.mcpj_id)
        return cv
    }()

    public override func mcvw_setupUI() {
        addSubview(mcpj_collectionView)
        mcpj_collectionView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

}

public final class MCCToolTextCell: MCCBaseCollectionViewCell {

    public static let mcpj_id = "MCCToolTextCell"

    public let mcpj_textLabel: UILabel = {
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
        contentView.addSubview(mcpj_textLabel)
        mcpj_textLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcpj_textLabel.text = nil
    }

}
