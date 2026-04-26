import UIKit
import SnapKit

public enum MCCShotsListItemMetrics {

    /// 图片区域与标题间距
    public static let imageToTitleSpacing: CGFloat = 8

    /// 列表标题：字号 14pt，字重 400（`UIFont.Weight.regular`）。
    public static let titleFont = UIFont.systemFont(ofSize: 14, weight: .regular)

    public static let titleLineHeight: CGFloat = 16

    public static let titleMaxLines = 2

    /// 图片区域 高 / 宽
    public static let imageHeightPerWidth: CGFloat = 4.0 / 3.0

    public static func titleTextAttributes(textColor: UIColor) -> [NSAttributedString.Key: Any] {
        let p = NSMutableParagraphStyle()
        p.minimumLineHeight = titleLineHeight
        p.maximumLineHeight = titleLineHeight
        return [.font: titleFont, .paragraphStyle: p, .foregroundColor: textColor]
    }

}

public final class MCCShotsListPageView: MCCBaseView {

    public let mcvw_waterfallLayout: MCCShotsWaterfallLayout = {
        let l = MCCShotsWaterfallLayout()
        l.columnCount = 2
        l.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 12, right: 4)
        l.minimumInteritemSpacing = 4
        l.minimumLineSpacing = 16
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_waterfallLayout)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCShotsListItemCell.self, forCellWithReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId)
        return cv
    }()

    public lazy var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay = {
        MCCGradientHomeSkeletonOverlay(style: .doubleColumnGrid)
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
        mcvw_imageContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(mcvw_imageContainer.snp.width).multipliedBy(MCCShotsListItemMetrics.imageHeightPerWidth)
        }
        mcvw_titleLabel.font = MCCShotsListItemMetrics.titleFont
        mcvw_titleLabel.numberOfLines = MCCShotsListItemMetrics.titleMaxLines
        mcvw_titleLabel.lineBreakMode = .byTruncatingTail
        mcvw_titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mcvw_imageContainer.snp.bottom).offset(MCCShotsListItemMetrics.imageToTitleSpacing)
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
