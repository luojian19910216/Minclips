import UIKit
import SnapKit
import SDWebImage

public enum MCCShotsCarouselMetrics {

    /// Hero aspect tuned for shots header; swaps with API-driven assets later.
    public static func headerHeight(forWidth width: CGFloat) -> CGFloat {
        let w = max(1, width)
        return ceil(w * (200.0 / 375.0))
    }
}

public final class MCCShotsCarouselHeaderView: UIView, UIScrollViewDelegate {

    private let mcvw_scrollView: UIScrollView = {
        let s = UIScrollView()
        s.isPagingEnabled = true
        s.showsHorizontalScrollIndicator = false
        s.showsVerticalScrollIndicator = false
        s.bounces = true
        s.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        s.contentInsetAdjustmentBehavior = .never
        return s
    }()

    private let mcvw_pageStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 6
        s.distribution = .equalSpacing
        return s
    }()

    private var mcvw_pageDots: [UIView] = []
    private var mcvw_imageViews: [UIImageView] = []
    private var mcvw_appliedDotPage = -1

    private static let mcvw_stubImageURLs: [URL] = {
        let s = [
            "https://images.unsplash.com/photo-1552674605-db6ffd4acf9f?w=960&q=80",
            "https://images.unsplash.com/photo-1434394354979-a235cd36269d?w=960&q=80",
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=960&q=80",
        ]
        return s.compactMap { URL(string: $0) }
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        mcvw_setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func mcvw_setup() {
        backgroundColor = .clear
        clipsToBounds = true
        mcvw_scrollView.delegate = self
        addSubview(mcvw_scrollView)
        addSubview(mcvw_pageStack)

        let pageCount = Self.mcvw_stubImageURLs.count

        let ivs = (0 ..< pageCount).map { i -> UIImageView in
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.backgroundColor = UIColor.white.withAlphaComponent(0.06)
            iv.sd_setImage(with: Self.mcvw_stubImageURLs[i], placeholderImage: nil, options: [.retryFailed])
            mcvw_scrollView.addSubview(iv)
            return iv
        }
        mcvw_imageViews = ivs

        for _ in 0 ..< pageCount {
            let dot = UIView()
            dot.layer.cornerRadius = 3
            mcvw_pageDots.append(dot)
            mcvw_pageStack.addArrangedSubview(dot)
            dot.snp.makeConstraints { $0.width.height.equalTo(6) }
        }

        mcvw_scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mcvw_pageStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }

        mcvw_refreshPageIndicator(page: 0)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height
        guard w > 0.5, h > 0.5 else { return }

        let count = CGFloat(mcvw_imageViews.count)
        mcvw_scrollView.contentSize = CGSize(width: w * count, height: h)
        var x: CGFloat = 0
        for iv in mcvw_imageViews {
            iv.frame = CGRect(x: x, y: 0, width: w, height: h)
            x += w
        }
        mcvw_syncPageIndicatorsFromScroll()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === mcvw_scrollView, bounds.width > 0 else { return }
        let page = Int(round(scrollView.contentOffset.x / max(1, bounds.width)))
        mcvw_refreshPageIndicator(page: page)
    }

    private func mcvw_syncPageIndicatorsFromScroll() {
        let w = max(1, bounds.width)
        let page = Int(round(mcvw_scrollView.contentOffset.x / w))
        mcvw_refreshPageIndicator(page: page)
    }

    private func mcvw_refreshPageIndicator(page: Int) {
        let n = mcvw_pageDots.count
        guard n > 0 else { return }
        let p = min(max(0, page), n - 1)
        guard p != mcvw_appliedDotPage else { return }
        mcvw_appliedDotPage = p
        for (i, dot) in mcvw_pageDots.enumerated() {
            let active = i == p
            dot.backgroundColor = active ? .white : UIColor.white.withAlphaComponent(0.35)
            dot.layer.cornerRadius = active ? 2 : 3
            dot.snp.remakeConstraints { make in
                if active {
                    make.width.equalTo(18)
                    make.height.equalTo(4)
                } else {
                    make.width.height.equalTo(6)
                }
            }
        }
    }
}
