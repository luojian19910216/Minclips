import UIKit
import Common
import SnapKit

public final class MCCToolsView: MCCBaseView {

    public let mctb_flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 0
        l.minimumLineSpacing = 8
        l.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16)
        l.scrollDirection = .vertical
        return l
    }()

    public lazy var mctb_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mctb_flow)
        cv.alwaysBounceVertical = true
        cv.backgroundColor = .clear
        cv.register(MCCToolTextCell.self, forCellWithReuseIdentifier: MCCToolTextCell.mctb_id)
        return cv
    }()

    public override func mcvw_setupUI() {
        addSubview(mctb_collectionView)
        mctb_collectionView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

}

public final class MCCToolTextCell: MCCBaseCollectionViewCell {

    public static let mctb_id = "MCCToolTextCell"

    public let mctb_textLabel: UILabel = {
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
        contentView.addSubview(mctb_textLabel)
        mctb_textLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mctb_textLabel.text = nil
    }

}
