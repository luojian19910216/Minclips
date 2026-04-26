import UIKit
import Common

public final class MCCProView: MCCBaseView {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    public override func mcvw_setupUI() {
        backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
        let title = UILabel()
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = .white
        title.numberOfLines = 0
        title.text = "Upgrade to Pro"
        let subtitle = UILabel()
        subtitle.font = .systemFont(ofSize: 16, weight: .regular)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitle.numberOfLines = 0
        subtitle.text = "Unlock all premium features."
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
    }
}
