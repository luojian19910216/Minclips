import UIKit
import SnapKit
import Common

public final class MCCStoryClipsComposerView: MCCBaseView {

    private static let portraitW: CGFloat = 72

    private static var portraitH: CGFloat { portraitW * 160 / 120 }

    private static let gutter: CGFloat = 8

    public let mcvw_scrollView: UIScrollView = {
        let s = UIScrollView()
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .interactive
        s.showsVerticalScrollIndicator = false
        return s
    }()

    private let mcvw_contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 16
        return s
    }()

    public let mcvw_avatarScroll = UIScrollView()
    public let mcvw_characterThumbScroll = UIScrollView()
    public let mcvw_shotBoardScroll = UIScrollView()
    public let mcvw_promptTextView = UITextView()

    private let mcvw_promptCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "1C1C21")
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let mcvw_promptBulbFooter: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lightbulb"))
        iv.tintColor = UIColor.white.withAlphaComponent(0.55)
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        return iv
    }()

    public let mcvw_resolutionChip = UIButton(type: .system)
    public let mcvw_durationChip = UIButton(type: .system)
    public let mcvw_audioChip = UIButton(type: .system)

    public let mcvw_continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.layer.cornerRadius = 26
        b.clipsToBounds = true
        b.backgroundColor = UIColor(hex: "2979FF")
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.contentHorizontalAlignment = .center
        return b
    }()

    override public func mcvw_setupUI() {
        backgroundColor = UIColor(hex: "0F0F12")

        let bottomBar = UIView()
        bottomBar.backgroundColor = UIColor(hex: "0F0F12")

        addSubview(mcvw_scrollView)
        addSubview(bottomBar)
        bottomBar.addSubview(mcvw_continueButton)
        mcvw_scrollView.addSubview(mcvw_contentStack)

        for _ in 0..<3 {
            mcvw_avatarScroll.addSubview(Self.mcvw_placeholderAvatar())
        }
        layoutAvatarRow()

        mcvw_layoutHorizontalPortraits(scroll: mcvw_characterThumbScroll, count: 4, prefixAdd: true)
        mcvw_layoutShotBoard()

        mcvw_promptTextView.backgroundColor = .clear
        mcvw_promptTextView.textColor = .white.withAlphaComponent(0.92)
        mcvw_promptTextView.font = .systemFont(ofSize: 15, weight: .regular)
        mcvw_promptTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 36, right: 12)
        mcvw_promptTextView.textContainer.lineFragmentPadding = 0

        mcvw_promptCard.addSubview(mcvw_promptTextView)
        mcvw_promptCard.addSubview(mcvw_promptBulbFooter)

        let pills = UIStackView(arrangedSubviews: [mcvw_resolutionChip, mcvw_durationChip, mcvw_audioChip])
        pills.axis = .horizontal
        pills.spacing = 8
        pills.distribution = .fillEqually

        configureChipButton(mcvw_resolutionChip, title: "720P")
        configureChipButton(mcvw_durationChip, title: "5s")
        configureChipButton(mcvw_audioChip, title: "Original")

        mcvw_contentStack.addArrangedSubview(sectionTitle("Character"))
        mcvw_contentStack.addArrangedSubview(embedScroll(h: 56, mcvw_avatarScroll))
        mcvw_contentStack.addArrangedSubview(embedScroll(h: Self.portraitH + 16, mcvw_characterThumbScroll))
        mcvw_contentStack.addArrangedSubview(sectionTitle("Shot Board"))
        mcvw_contentStack.addArrangedSubview(embedScroll(h: 96, mcvw_shotBoardScroll))
        mcvw_contentStack.addArrangedSubview(mcvw_promptCard)
        mcvw_contentStack.addArrangedSubview(pills)

        mcvw_scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        mcvw_continueButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.height.equalTo(52)
        }
        mcvw_contentStack.snp.makeConstraints { make in
            make.edges.equalTo(mcvw_scrollView.contentLayoutGuide)
            make.width.equalTo(mcvw_scrollView.frameLayoutGuide)
        }

        mcvw_promptTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(120)
        }
        mcvw_promptBulbFooter.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 22, height: 22))
        }

        mcvw_promptCard.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(120)
        }
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .white
        return l
    }

    private func embedScroll(h: CGFloat, _ sv: UIScrollView) -> UIView {
        sv.showsHorizontalScrollIndicator = false
        sv.backgroundColor = .clear
        let w = UIView()
        w.addSubview(sv)
        sv.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(h)
        }
        return w
    }

    private func layoutAvatarRow() {
        var x: CGFloat = 0
        let size: CGFloat = 48
        let gap: CGFloat = 12
        for sub in mcvw_avatarScroll.subviews {
            sub.frame = CGRect(x: x, y: 4, width: size, height: size)
            x += size + gap
        }
        mcvw_avatarScroll.contentSize = CGSize(width: max(x - gap, 0), height: size + 8)
    }

    private func mcvw_layoutHorizontalPortraits(scroll: UIScrollView, count: Int, prefixAdd: Bool) {
        var x: CGFloat = 0
        let w = Self.portraitW
        let h = Self.portraitH

        if prefixAdd {
            let add = mcvw_dashedPlusCard(size: CGSize(width: w, height: h))
            scroll.addSubview(add)
            add.frame = CGRect(x: x, y: 8, width: w, height: h)
            x += w + Self.gutter
        }
        for i in 0..<count {
            let iv = UIImageView(frame: CGRect(x: x, y: 8, width: w, height: h))
            iv.layer.cornerRadius = 12
            iv.clipsToBounds = true
            iv.backgroundColor = UIColor(hex: "2A2A32")
            iv.contentMode = .scaleAspectFill
            let label = UILabel()
            label.text = "Recent"
            label.font = .systemFont(ofSize: 10, weight: .medium)
            label.textColor = .white.withAlphaComponent(0.85)
            label.backgroundColor = UIColor.black.withAlphaComponent(0.35)
            label.textAlignment = .center
            iv.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(22)
            }
            scroll.addSubview(iv)
            _ = i
            x += w + Self.gutter
        }
        scroll.contentSize = CGSize(width: x, height: h + 16)
    }

    private func mcvw_layoutShotBoard() {
        let wTile: CGFloat = 88
        let hTile: CGFloat = 72
        var x: CGFloat = 0

        func addThumb(_ isAdd: Bool, idx: Int) {
            let v = UIView(frame: CGRect(x: x, y: 8, width: wTile, height: hTile))
            v.layer.cornerRadius = 12
            v.clipsToBounds = true
            v.backgroundColor = UIColor(hex: "25252D")
            mcvw_shotBoardScroll.addSubview(v)
            let n = UILabel()
            n.text = isAdd ? "+" : "\(idx)"
            n.font = .systemFont(ofSize: isAdd ? 24 : 14, weight: .semibold)
            n.textColor = .white
            n.frame = CGRect(x: 8, y: 6, width: 44, height: 22)
            v.addSubview(n)
            if idx == 1 {
                v.layer.borderWidth = 2
                v.layer.borderColor = UIColor(hex: "2979FF")? .cgColor
            }
            x += wTile + Self.gutter
        }

        addThumb(true, idx: 0)
        addThumb(false, idx: 1)
        addThumb(false, idx: 2)
        addThumb(false, idx: 3)
        mcvw_shotBoardScroll.contentSize = CGSize(width: x, height: hTile + 16)
    }

    private static func mcvw_placeholderAvatar() -> UIView {
        let outer = UIView()
        outer.layer.cornerRadius = 24
        outer.clipsToBounds = true
        outer.backgroundColor = UIColor(hex: "373741")
        return outer
    }

    private func mcvw_dashedPlusCard(size: CGSize) -> UIView {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1.2
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        let p = UILabel()
        p.text = "+"
        p.font = .systemFont(ofSize: 28, weight: .light)
        p.textColor = .white.withAlphaComponent(0.75)
        p.textAlignment = .center
        v.addSubview(p)
        p.snp.makeConstraints { $0.center.equalToSuperview() }
        return v
    }

    private func configureChipButton(_ b: UIButton, title: String) {
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        b.backgroundColor = UIColor(hex: "28282F")
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        b.snp.makeConstraints { $0.height.equalTo(36) }
    }
}
