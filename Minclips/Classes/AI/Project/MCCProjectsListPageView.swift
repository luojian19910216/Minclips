import UIKit
import SnapKit
import SDWebImage

public final class MCCProjectsListPageView: MCCBaseView {

    private static let mcvw_horizontalSectionInset: CGFloat = 4

    public let mcvw_runsWaterfallLayout: MCCShotsWaterfallLayout = {
        let l = MCCShotsWaterfallLayout()
        l.columnCount = 3
        let h = MCCProjectsListPageView.mcvw_horizontalSectionInset
        l.sectionInset = UIEdgeInsets(top: 4, left: h, bottom: 4, right: h)
        l.minimumInteritemSpacing = 4
        l.minimumLineSpacing = 4
        return l
    }()

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
        let cv = UICollectionView(frame: .zero, collectionViewLayout: mcvw_runsWaterfallLayout)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(MCCProjectsRunCell.self, forCellWithReuseIdentifier: MCCProjectsRunCell.mcvw_reuseId)
        return cv
    }()

    public func mcvw_runsWaterfallColumnWidth(collectionWidth w: CGFloat) -> CGFloat {
        let width = (w > 0 ? w : UIScreen.main.bounds.width)
        let l = mcvw_runsWaterfallLayout
        let inner = width - l.sectionInset.left - l.sectionInset.right
        let cols = max(1, l.columnCount)
        let spacing = CGFloat(cols - 1) * l.minimumInteritemSpacing
        return max(1, (inner - spacing) / CGFloat(cols))
    }

    public func mcvw_activateRunsWaterfallLayout() {
        mcvw_collectionView.setCollectionViewLayout(mcvw_runsWaterfallLayout, animated: false)
    }

    public func mcvw_activateLikesWaterfallLikeHome() {
        mcvw_collectionView.register(
            MCCShotsListItemCell.self,
            forCellWithReuseIdentifier: MCCShotsListItemCell.mcvw_reuseId
        )
        mcvw_collectionView.setCollectionViewLayout(mcvw_likesWaterfallLayout, animated: false)
    }

    public func mcvw_likesWaterfallColumnWidth(collectionWidth w: CGFloat) -> CGFloat {
        let width = (w > 0 ? w : UIScreen.main.bounds.width)
        let l = mcvw_likesWaterfallLayout
        let inner = width - l.sectionInset.left - l.sectionInset.right
        let cols = max(1, l.columnCount)
        let spacing = CGFloat(cols - 1) * l.minimumInteritemSpacing
        return max(1, (inner - spacing) / CGFloat(cols))
    }

    public private(set) var mcvw_skeletonOverlay: MCCGradientHomeSkeletonOverlay?

    public func mcvw_configureListSkeleton(isLikesLayout: Bool) {
        mcvw_skeletonOverlay?.removeFromSuperview()
        let style: MCCGradientHomeSkeletonOverlay.MCCStyle = isLikesLayout
            ? .projectsLikesThreeColumn
            : .projectsRunsThreeColumn
        let o = MCCGradientHomeSkeletonOverlay(style: style)
        addSubview(o)
        o.snp.makeConstraints { $0.edges.equalToSuperview() }
        o.isHidden = true
        mcvw_skeletonOverlay = o
    }

    public override func mcvw_setupUI() {
        addSubview(mcvw_collectionView)
        mcvw_collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public func mcvw_setListSkeletonVisible(_ visible: Bool) {
        guard let overlay = mcvw_skeletonOverlay else { return }
        if visible {
            overlay.mcvw_showHomeSkeleton()
        } else {
            overlay.mcvw_hideHomeSkeleton()
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
