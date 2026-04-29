import UIKit
import SnapKit
import Common

public final class MCCShotsStockPickerView: MCCBaseView {

    public static let mcvw_gridGutterValue: CGFloat = 4

    public static let mcvw_horizontalInset: CGFloat = 16

    public let mcvw_closeButton: UIButton = {
        let b = UIButton(type: .custom)
        let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        b.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(white: 0, alpha: 0.35)
        b.layer.cornerRadius = 18
        return b
    }()

    public let mcvw_titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .white
        l.text = "Shots"
        return l
    }()

    public lazy var mcvw_collectionView: UICollectionView = {
        let flow = UICollectionViewFlowLayout()
        flow.minimumInteritemSpacing = Self.mcvw_gridGutterValue
        flow.minimumLineSpacing = Self.mcvw_gridGutterValue
        flow.sectionInset = UIEdgeInsets(
            top: 8,
            left: Self.mcvw_horizontalInset,
            bottom: 120,
            right: Self.mcvw_horizontalInset
        )

        let cv = UICollectionView(frame: .zero, collectionViewLayout: flow)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.register(MCCShotsStockPickerCell.self, forCellWithReuseIdentifier: MCCShotsStockPickerCell.mcvw_reuseId)
        return cv
    }()

    private let mcvw_bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "121215")?.withAlphaComponent(0.98)
        return v
    }()

    public let mcvw_thumbStripScroll = UIScrollView()

    public let mcvw_primaryButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(hex: "2979FF")
        b.layer.cornerRadius = 26
        b.clipsToBounds = true
        b.setTitle("Add Shot", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.contentHorizontalAlignment = .center
        return b
    }()

    public let mcvw_badgeLabel: UILabel = {
        let l = UILabel()
        l.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        l.textColor = .white
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textAlignment = .center
        l.layer.cornerRadius = 14
        l.clipsToBounds = true
        l.text = " 50 "
        return l
    }()

    override public func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "0F0F12")

        addSubview(mcvw_titleLabel)
        addSubview(mcvw_closeButton)
        addSubview(mcvw_collectionView)
        addSubview(mcvw_bottomBar)
        mcvw_bottomBar.addSubview(mcvw_thumbStripScroll)
        mcvw_bottomBar.addSubview(mcvw_primaryButton)
        mcvw_primaryButton.addSubview(mcvw_badgeLabel)

        mcvw_thumbStripScroll.showsHorizontalScrollIndicator = false

        mcvw_closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(6)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(36)
        }
        mcvw_titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalTo(mcvw_closeButton)
        }
        mcvw_collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(mcvw_closeButton.snp.bottom).offset(8)
            make.bottom.equalTo(mcvw_bottomBar.snp.top)
        }
        mcvw_bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        mcvw_thumbStripScroll.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        mcvw_primaryButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(mcvw_thumbStripScroll.snp.bottom).offset(10)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.height.equalTo(52)
        }
        mcvw_badgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(40)
        }

        mcvw_stripPlaceholders()
    }

    private func mcvw_stripPlaceholders() {
        var x: CGFloat = 0
        let h: CGFloat = 48
        let pad: CGFloat = 6
        for i in 0..<3 {
            let v = UIView()
            v.layer.cornerRadius = 12
            v.clipsToBounds = true
            v.backgroundColor = UIColor(hex: "48485A")
            mcvw_thumbStripScroll.addSubview(v)
            let w: CGFloat = i == 2 ? 72 : 52
            v.frame = CGRect(x: x + pad, y: 0, width: w, height: h)
            x += pad + w + 4
        }
        mcvw_thumbStripScroll.contentSize = CGSize(width: x, height: h)
    }
}
