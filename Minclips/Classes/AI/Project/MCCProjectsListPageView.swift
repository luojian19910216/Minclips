import UIKit
import SnapKit
import SDWebImage

public final class MCCProjectsListPageView: MCCBaseView {

    /// 左右缩进与单元格间隔一致（4pt）。
    private static let mcvw_horizontalSectionInset: CGFloat = 4

    public let mcvw_flow: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.minimumInteritemSpacing = 4
        l.minimumLineSpacing = 4
        let h = MCCProjectsListPageView.mcvw_horizontalSectionInset
        l.sectionInset = UIEdgeInsets(top: 4, left: h, bottom: 4, right: h)
        return l
    }()

    /// Likes：与首页 Shots 相同瀑布流规则，三列。
    public lazy var mcvw_likesWaterfallLayout: MCCShotsWaterfallLayout = {
        let l = MCCShotsWaterfallLayout()
        l.columnCount = 3
        let h = MCCProjectsListPageView.mcvw_horizontalSectionInset
        l.sectionInset = UIEdgeInsets(top: 4, left: h, bottom: 4, right: h)
        l.minimumInteritemSpacing = 4
        l.minimumLineSpacing = 16
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_flow)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCProjectsRunCell.self, forCellWithReuseIdentifier: MCCProjectsRunCell.mcvw_reuseId)
        return cv
    }()

    /// 将 Likes 列表切换为与首页一致的瀑布流（三列），并注册 `MCCShotsListItemCell`。
    public func mcvp_activateLikesWaterfallLikeHome() {
        mcvw_collectionView.register(
            MCCShotsListItemCell.self,
            forCellWithReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId
        )
        mcvw_collectionView.setCollectionViewLayout(mcvw_likesWaterfallLayout, animated: false)
    }

    /// 当前瀑布流下单列内容宽度（用于缩略图与高度计算）。
    public func mcvp_likesWaterfallColumnWidth(collectionWidth w: CGFloat) -> CGFloat {
        let width = (w > 0 ? w : UIScreen.main.bounds.width)
        let l = mcvw_likesWaterfallLayout
        let inner = width - l.sectionInset.left - l.sectionInset.right
        let cols = max(1, l.columnCount)
        let spacing = CGFloat(cols - 1) * l.minimumInteritemSpacing
        return max(1, floor((inner - spacing) / CGFloat(cols)))
    }

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

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_imageContainer)
        mcvw_imageContainer.addSubview(mcvw_thumbView)
        mcvw_thumbView.contentMode = .scaleAspectFill
        mcvw_thumbView.clipsToBounds = true
        mcvw_imageContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_thumbView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        mcvw_thumbView.image = nil
        mcvw_thumbView.sd_cancelCurrentImageLoad()
    }

}
