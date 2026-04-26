import UIKit
import SnapKit
import SDWebImage

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

    /// 与 cell 图片区一致的 **物理像素** 尺寸，供 SDWebImage `imageThumbnailPixelSize` 缩略图解码。
    public static func feedImageThumbnailPixelSize(columnWidthPoints: CGFloat) -> CGSize {
        let scale = UIScreen.main.scale
        let ptW = max(1, columnWidthPoints)
        let ptH = ptW * imageHeightPerWidth
        return CGSize(width: ptW * scale, height: ptH * scale)
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

    /// 静态封面（`posterImageUrl` / staticCoverUrl）
    public let mcvw_posterImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    /// WebP 动图（`webpImageUrl`）
    public let mcvw_webpImageView: SDAnimatedImageView = {
        let v = SDAnimatedImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    public let mcvw_durationLabel = UILabel()

    public let mcvw_proBadge = UIView()

    public let mcvw_proIcon = UIImageView(image: UIImage(systemName: "diamond.fill"))

    public let mcvw_titleLabel = UILabel()

    public override func mcvw_setupUI() {
        contentView.addSubview(mcvw_imageContainer)
        contentView.addSubview(mcvw_titleLabel)
        mcvw_imageContainer.addSubview(mcvw_posterImageView)
        mcvw_imageContainer.addSubview(mcvw_webpImageView)
        mcvw_imageContainer.addSubview(mcvw_durationLabel)
        mcvw_imageContainer.addSubview(mcvw_proBadge)
        mcvw_proBadge.addSubview(mcvw_proIcon)
        mcvw_imageContainer.layer.cornerRadius = 12
        mcvw_imageContainer.clipsToBounds = true
        mcvw_posterImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_webpImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
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
            make.trailing.bottom.equalToSuperview().inset(6)
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
        mcvw_posterImageView.sd_cancelCurrentImageLoad()
        mcvw_posterImageView.image = nil
        mcvw_clearWebpAnimated()
    }

    private static func mcvw_thumbnailContext(_ thumbnailPixelSize: CGSize) -> [SDWebImageContextOption: Any] {
        [
            .imageThumbnailPixelSize: NSValue(cgSize: thumbnailPixelSize),
            .imagePreserveAspectRatio: true
        ]
    }

    /// `cellForItem`：仅静态封面，并清掉动图层，避免复用残留。
    public func mcvw_applyPosterOnly(posterUrl: String, thumbnailPixelSize: CGSize) {
        mcvw_clearWebpAnimated()
        let ctx = Self.mcvw_thumbnailContext(thumbnailPixelSize)
        if let u = URL(string: posterUrl), !posterUrl.isEmpty {
            mcvw_posterImageView.sd_setImage(with: u, placeholderImage: nil, options: [], context: ctx)
        } else {
            mcvw_posterImageView.sd_cancelCurrentImageLoad()
            mcvw_posterImageView.image = nil
        }
    }

    /// `willDisplay`：叠加载 WebP 动图。
    public func mcvw_applyWebpAnimated(webpUrl: String, thumbnailPixelSize: CGSize) {
        let ctx = Self.mcvw_thumbnailContext(thumbnailPixelSize)
        guard let u = URL(string: webpUrl), !webpUrl.isEmpty else {
            mcvw_clearWebpAnimated()
            return
        }
        mcvw_webpImageView.isHidden = false
        mcvw_webpImageView.sd_setImage(with: u, placeholderImage: nil, options: [], context: ctx)
    }

    /// `didEndDisplaying`：取消动图请求并移除展示，省内存与解码。
    public func mcvw_clearWebpAnimated() {
        mcvw_webpImageView.sd_cancelCurrentImageLoad()
        mcvw_webpImageView.image = nil
        mcvw_webpImageView.isHidden = true
    }

    /// 进入详情前抓取当前 WebP 帧，供详情 `seek` 续播；未加载或非动图时返回 `nil`。
    public func mcvw_captureWebpPlaybackHandoff() -> MCCWebpPlaybackHandoff? {
        guard !mcvw_webpImageView.isHidden, let image = mcvw_webpImageView.image else { return nil }
        guard image.sd_imageFrameCount > 1 else { return nil }
        return MCCWebpPlaybackHandoff(
            image: image,
            frameIndex: UInt(mcvw_webpImageView.currentFrameIndex),
            loopCount: UInt(mcvw_webpImageView.currentLoopCount)
        )
    }

}
