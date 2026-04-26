import UIKit

public protocol MCCShotsWaterfallLayoutDelegate: AnyObject {

    func waterfallLayout(
        _ layout: MCCShotsWaterfallLayout,
        heightForItemAt indexPath: IndexPath,
        itemWidth: CGFloat
    ) -> CGFloat

}

/// 双列瀑布流：每条 item 高度由 delegate 提供，新 item 落在当前总高度更短的一列。
public final class MCCShotsWaterfallLayout: UICollectionViewLayout {

    public weak var delegate: MCCShotsWaterfallLayoutDelegate?

    public var columnCount: Int = 2

    public var sectionInset: UIEdgeInsets = .zero

    public var minimumInteritemSpacing: CGFloat = 4

    /// 同一列内相邻 cell 的垂直间距
    public var minimumLineSpacing: CGFloat = 4

    private var cache: [UICollectionViewLayoutAttributes] = []

    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat = 0

    public override func prepare() {
        super.prepare()
        cache.removeAll()
        guard let cv = collectionView else { return }
        contentWidth = cv.bounds.width
        let count = cv.numberOfItems(inSection: 0)
        guard count > 0, let delegate = delegate else {
            contentHeight = sectionInset.top + sectionInset.bottom
            return
        }

        let innerW = contentWidth - sectionInset.left - sectionInset.right
        let cols = max(1, columnCount)
        let colW = (innerW - CGFloat(cols - 1) * minimumInteritemSpacing) / CGFloat(cols)
        guard colW > 0 else {
            contentHeight = sectionInset.top + sectionInset.bottom
            return
        }

        var colHeights = [CGFloat](repeating: sectionInset.top, count: cols)

        for item in 0..<count {
            let indexPath = IndexPath(item: item, section: 0)
            let h = delegate.waterfallLayout(self, heightForItemAt: indexPath, itemWidth: colW)
            let col = colHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let x = sectionInset.left + CGFloat(col) * (colW + minimumInteritemSpacing)
            let y = colHeights[col]
            let frame = CGRect(x: x, y: y, width: colW, height: h)
            let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attrs.frame = frame
            cache.append(attrs)
            colHeights[col] = y + h + minimumLineSpacing
        }

        let maxCol = colHeights.max() ?? sectionInset.top
        contentHeight = maxCol - minimumLineSpacing + sectionInset.bottom
        if contentHeight < sectionInset.top + sectionInset.bottom {
            contentHeight = sectionInset.top + sectionInset.bottom
        }
    }

    public override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache
            .filter { $0.frame.intersects(rect) }
            .map { $0.copy() as! UICollectionViewLayoutAttributes }
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.indexPath == indexPath }?.copy() as? UICollectionViewLayoutAttributes
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let cv = collectionView else { return false }
        // 滑动时只有 bounds.origin 变，width 不变；若此处总返回 true，会每帧 invalidate → 全量 prepare → 极度卡顿、cell 闪烁。
        return newBounds.size.width != cv.bounds.size.width
    }

}
