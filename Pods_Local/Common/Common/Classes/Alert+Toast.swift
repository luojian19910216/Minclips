//
//  Alert+Toast.swift
//

import UIKit
import Combine
import SnapKit

open class MCCAlertManager: UIAlertController {
    
    public static func alert(
        title: String?,
        message: String?,
        confirmBtnTitle: String? = nil,
        confirmBtnAction: (() -> Void)? = nil,
        cancelBtnTitle: String? = nil,
        cancelBtnAction: (() -> Void)? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .dark
        alert.setValue({
            let att: NSMutableAttributedString = .init()
            if let title = title, !title.isEmpty {
                att.append(.init(string: title, attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                    .foregroundColor: UIColor.white
                ]))
            }
            if title?.count ?? 0 > 0 && message?.count ?? 0 > 0 {
                att.append(.init(string: "\n\n", attributes: [
                    .font: UIFont.systemFont(ofSize: 2)
                ]))
            }
            if let message = message, !message.isEmpty {
                att.append(.init(string: message, attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.white
                ]))
            }
            att.addAttributes([
                .paragraphStyle: {
                    let style: NSMutableParagraphStyle = .init()
                    style.lineSpacing = 4
                    style.alignment = .center
                    return style
                }()
            ], range: .init(location: 0, length: att.length))
            return att
        }(), forKey: "attributedMessage")
        if let cancelBtnTitle = cancelBtnTitle, !cancelBtnTitle.isEmpty {
            alert.addAction({
                let action = UIAlertAction(title: cancelBtnTitle, style: .default) { _ in
                    cancelBtnAction?()
                }
                action.setValue(UIColor.white.withAlphaComponent(0.6), forKey: "_titleTextColor")
                return action
            }())
        }
        if let confirmBtnTitle = confirmBtnTitle, !confirmBtnTitle.isEmpty {
            alert.addAction({
                let action = UIAlertAction(title: confirmBtnTitle, style: .destructive) { _ in
                    confirmBtnAction?()
                }
//                action.setValue(UIColor.white, forKey: "_titleTextColor")
                return action
            }())
        }
        return alert
    }
    
}

public final class MCCToastManager {
    
    public static let shared: MCCToastManager = .init()
        
    private weak var currentView: MCCToastView?
    
    private init() {}
        
    public static func showHUD(_ message: String? = nil, in view: UIView? = nil) {
        shared.show(isHUD: true, message: message, in: view)
    }
    
    public static func showToast(_ message: String, in view: UIView? = nil) {
        shared.show(isHUD: false, message: message, in: view)
    }
            
    private func show(isHUD: Bool, message: String?, in view: UIView?) {
        guard let container = view ?? MCCScreenSize.keyWindow else { return }
        
        currentView?.hide()
        
        if !isHUD && message?.count ?? 0 == 0 {return}
        
        let toast = MCCToastView(isHUD: isHUD, message: message)
        container.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        toast.show(with: isHUD)
        
        if isHUD {
            container.endEditing(true)
        } else {
            let duration = min(max(Double(message?.count ?? 0) * 0.06 + 0.5, 1.5), 4.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak toast] in
                toast?.hide()
            }
        }
        
        currentView = toast
    }
    
    public static func hide() {
        shared.currentView?.hide()
    }
    
}

private final class MCCToastView: UIView {
    
    private lazy var contentView: UIView = {
        let item: UIView = .init()
        item.backgroundColor = .black.withAlphaComponent(0.7)
        item.layer.cornerRadius = 8
        item.alpha = 0
        return item
    }()
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let item: UIActivityIndicatorView = .init(style: .large)
        item.tintColor = .white
        item.startAnimating()
        return item
    }()
    
    private lazy var descLab: UILabel = {
        let item: UILabel = .init()
        item.numberOfLines = 0
        item.font = .systemFont(ofSize: 14)
        item.textColor = .white
        item.textAlignment = .center
        item.lineBreakMode = .byWordWrapping
        return item
    }()
        
    required
    init?(coder: NSCoder) { fatalError() }
    
    init(isHUD: Bool, message: String?) {
        super.init(frame: .zero)
        
        self.isUserInteractionEnabled = isHUD
        self.backgroundColor = .clear
        
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.leading.greaterThanOrEqualToSuperview().inset(20)
        }
        
        if isHUD {
            self.contentView.addSubview(self.indicatorView)
            self.indicatorView.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(20)
                make.centerX.equalToSuperview()
                if message?.count ?? 0 == 0 {
                    make.leading.equalToSuperview().inset(20)
                    make.bottom.equalToSuperview().inset(20)
                }
            }
        }
        
        if let message = message, !message.isEmpty {
            self.descLab.text = message
            self.contentView.addSubview(descLab)
            self.descLab.snp.makeConstraints { make in
                if isHUD {
                    make.top.equalTo(self.indicatorView.snp.bottom).offset(20)
                } else {
                    make.top.equalToSuperview().inset(10)
                }
                make.bottom.equalToSuperview().inset(isHUD ? 20 : 10)
                make.leading.equalToSuperview().inset(10)
                make.centerX.equalToSuperview()
            }
        }
    }
        
    func show(with needDelay: Bool = false) {
        if needDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                UIView.animate(withDuration: 0.2) {
                    self.contentView.alpha = 1
                }
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.contentView.alpha = 1
            }
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2) {
            self.contentView.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
}
