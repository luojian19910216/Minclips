import UIKit
import Combine

public protocol MCPViewInit {
    
    func mcvw_setupUI()

    func mcvw_bind()

}

open class MCCBaseView: UIView, MCPViewInit {

    public enum MCESection {
        case main
    }

    public var cancellables = Set<AnyCancellable>()

    open func mcvw_setupUI() {}

    open func mcvw_bind() {}

    required
    public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        mcvw_setupUI()
        mcvw_bind()
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        mcvw_setupUI()
        mcvw_bind()
    }

    deinit {
        print("View deinit（\(classForCoder)）")
    }

}

open class MCCBaseCollectionReusableView: UICollectionReusableView, MCPViewInit {

    public var cancellables = Set<AnyCancellable>()

    open func mcvw_setupUI() {}

    open func mcvw_bind() {}

    required
    public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        mcvw_setupUI()
        mcvw_bind()
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        mcvw_setupUI()
        mcvw_bind()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
    }

    deinit {
        print("View deinit（\(classForCoder)）")
    }

}

open class MCCBaseCollectionViewCell: UICollectionViewCell, MCPViewInit {

    public var cancellables = Set<AnyCancellable>()

    open func mcvw_setupUI() {}

    open func mcvw_bind() {}

    required
    public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        mcvw_setupUI()
        mcvw_bind()
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        mcvw_setupUI()
        mcvw_bind()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
    }

    deinit {
        print("View deinit（\(classForCoder)）")
    }

}

open class MCCBasePopView: MCCBaseView {

    public lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        return view
    }()

    public lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.clipsToBounds = true
        return view
    }()

    open override func mcvw_setupUI() {
        backgroundColor = .clear
        
        addSubview(dimmingView)
        addSubview(cardView)
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        for subview in subviews.reversed() where subview !== dimmingView {
            guard !subview.isHidden, subview.isUserInteractionEnabled, subview.alpha > 0.01 else { continue }
            if let hit = subview.hitTest(subview.convert(point, from: self), with: event) {
                return hit
            }
        }
        if dimmingView.frame.contains(point) {
            return dimmingView
        }
        return nil
    }

}
