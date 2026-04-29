import UIKit
import SnapKit
import SDWebImage
import FSPagerView
import Common

public enum MCCShotsCarouselMetrics {

    /// 轮播 strip 底色（占位 / 留白时露出）。仅涂在 header 根视图，下层勿再叠同色以免发灰。
    public static let mcvw_carouselBackgroundFill = UIColor.white.withAlphaComponent(0.06)

    /// Hero height: width × (256 / 375). Replace when API-backed banner sizing exists.
    public static func headerHeight(forWidth width: CGFloat) -> CGFloat {
        let w = max(1, width)
        return ceil(w * (256.0 / 375.0))
    }

    /// 底部叠渐变层高度（上沿透明 → 下沿 `#0F0F12`）
    public static let mcvw_carouselBottomGradientHeight: CGFloat = 96

    /// 顶部叠渐变层高度（上沿黑 72% alpha → 下沿透明）
    public static let mcvw_carouselTopGradientHeight: CGFloat = 120
}

private final class MCCShotsPagerCell: FSPagerViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        mcvw_stripFSPagerCellDefaultHeavyShadow()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        mcvw_stripFSPagerCellDefaultHeavyShadow()
    }

    /// `FSPagerViewCell.commonInit()` 默认给 contentView `shadowOpacity = 0.75`，整块会像又脏又深的灰底。
    private func mcvw_stripFSPagerCellDefaultHeavyShadow() {
        contentView.layer.shadowOpacity = 0
        contentView.layer.shadowColor = UIColor.clear.cgColor
        contentView.layer.shadowRadius = 0
        layer.shadowOpacity = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowOpacity = 0
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        if let iv = imageView {
            iv.frame = contentView.bounds
            iv.clipsToBounds = true
        }
    }
}

public final class MCCShotsCarouselHeaderView: UIView, FSPagerViewDataSource, FSPagerViewDelegate {

    private let mcvw_bottomGradientHost: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()

    private let mcvw_bottomGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [UIColor.clear.cgColor, UIColor(hex: "0F0F12")!.cgColor]
        l.locations = [0, 1]
        l.startPoint = CGPoint(x: 0.5, y: 0)
        l.endPoint = CGPoint(x: 0.5, y: 1)
        return l
    }()

    private let mcvw_topGradientHost: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()

    private let mcvw_topGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [UIColor.black.withAlphaComponent(0.72).cgColor, UIColor.clear.cgColor]
        l.locations = [0, 1]
        l.startPoint = CGPoint(x: 0.5, y: 0)
        l.endPoint = CGPoint(x: 0.5, y: 1)
        return l
    }()

    private let mcvw_pager: FSPagerView = {
        let p = FSPagerView()
        p.isInfinite = true
        p.automaticSlidingInterval = 4
        p.itemSize = FSPagerView.automaticSize
        p.interitemSpacing = 0
        p.removesInfiniteLoopForSingleItem = true
        p.backgroundColor = .clear
        p.clipsToBounds = true
        return p
    }()

    /// 系统控件按点距布局；`FSPageControl` 固定步长在「圆点 + 长条选中」混搭时易与相邻重叠。
    private let mcvw_pageControl: UIPageControl = {
        let p = UIPageControl()
        p.isUserInteractionEnabled = false
        p.currentPageIndicatorTintColor = .white
        p.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.38)
        return p
    }()

    /// Stub asset count (replace with remote model later).
    private static let mcvw_stubImageURLs: [URL] = {
        [
            "https://images.unsplash.com/photo-1552674605-db6ffd4acf9f?w=960&q=80",
            "https://images.unsplash.com/photo-1434394354979-a235cd36269d?w=960&q=80",
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=960&q=80",
        ]
            .compactMap { URL(string: $0) }
    }()

    private var mcvw_lastSyncedPage = -1

    public override init(frame: CGRect) {
        super.init(frame: frame)
        mcvw_setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func mcvw_setup() {
        backgroundColor = MCCShotsCarouselMetrics.mcvw_carouselBackgroundFill
        clipsToBounds = true

        mcvw_pager.dataSource = self
        mcvw_pager.delegate = self
        mcvw_pager.register(MCCShotsPagerCell.self, forCellWithReuseIdentifier: "carousel")

        let n = Self.mcvw_stubImageURLs.count
        mcvw_pageControl.numberOfPages = n
        mcvw_pageControl.isHidden = n <= 1

        addSubview(mcvw_pager)
        addSubview(mcvw_bottomGradientHost)
        addSubview(mcvw_topGradientHost)
        addSubview(mcvw_pageControl)
        mcvw_bottomGradientHost.layer.insertSublayer(mcvw_bottomGradientLayer, at: 0)
        mcvw_topGradientHost.layer.insertSublayer(mcvw_topGradientLayer, at: 0)

        mcvw_pager.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_bottomGradientHost.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(MCCShotsCarouselMetrics.mcvw_carouselBottomGradientHeight)
        }
        mcvw_topGradientHost.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(MCCShotsCarouselMetrics.mcvw_carouselTopGradientHeight)
        }
        mcvw_pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }

        mcvw_pager.reloadData()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        mcvw_bottomGradientLayer.frame = mcvw_bottomGradientHost.bounds
        mcvw_topGradientLayer.frame = mcvw_topGradientHost.bounds
    }

    private func mcvw_syncPageIndicatorIfNeeded(_ index: Int) {
        guard index != mcvw_lastSyncedPage else { return }
        mcvw_lastSyncedPage = index
        guard Self.mcvw_stubImageURLs.count > 1 else { return }
        mcvw_pageControl.currentPage = index
    }

    // MARK: - FSPagerViewDataSource

    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        Self.mcvw_stubImageURLs.count
    }

    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "carousel", at: index) as! MCCShotsPagerCell
        if let iv = cell.imageView {
            iv.contentMode = .scaleAspectFill
            iv.backgroundColor = .clear
            iv.clipsToBounds = true
            iv.sd_setImage(with: Self.mcvw_stubImageURLs[index], placeholderImage: nil, options: [.retryFailed])
        }
        return cell
    }

    // MARK: - FSPagerViewDelegate

    public func pagerViewDidScroll(_ pagerView: FSPagerView) {
        if pagerView.isTracking { return }
        mcvw_syncPageIndicatorIfNeeded(pagerView.currentIndex)
    }

    public func pagerViewDidEndDecelerating(_ pagerView: FSPagerView) {
        mcvw_syncPageIndicatorIfNeeded(pagerView.currentIndex)
    }

    public func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
        mcvw_syncPageIndicatorIfNeeded(pagerView.currentIndex)
    }
}
