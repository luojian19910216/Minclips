//
//  UINavigationBar+Style.swift
//

import UIKit

private var mc_shadowHiddenKey: UInt8 = 0
private var mc_barStyleKey: UInt8 = 1

public enum MCENavigationBarStyle: Int {
    case transparentDark
    case transparentLight
}

extension UINavigationBar {

    // MARK: - Shadow

    public var mc_shadowHidden: Bool {
        get {
            return objc_getAssociatedObject(self, &mc_shadowHiddenKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &mc_shadowHiddenKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            // 设置阴影
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = newValue ? 0.0 : 0.1
            self.layer.shadowRadius = 2
            self.layer.shadowOffset = .zero
        }
    }

    // MARK: - Style

    public var mc_barStyle: MCENavigationBarStyle {
        get {
            return MCENavigationBarStyle(rawValue: (objc_getAssociatedObject(self, &mc_barStyleKey) as? Int) ?? 0) ?? .transparentDark
        }
        set {
            objc_setAssociatedObject(self, &mc_barStyleKey, newValue.rawValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            // 设置风格
            var barTintColor: UIColor = .clear
            var tintColor: UIColor = .black
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let itemFont = UIFont.systemFont(ofSize: 16)

            switch mc_barStyle {
            case .transparentDark:
                barTintColor = .clear
                tintColor = UIColor.black
            case .transparentLight:
                barTintColor = .clear
                tintColor = UIColor.white
            }

            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            // 去掉阴影线
            appearance.shadowColor = .clear
            // 背景颜色 & 模糊效果
            appearance.backgroundColor = barTintColor
            appearance.backgroundEffect = nil
            // title字体+颜色
            appearance.titleTextAttributes = [
                .font: titleFont,
                .foregroundColor: tintColor
            ]
            // item字体+颜色
            appearance.buttonAppearance.normal.titleTextAttributes = [
                .font: itemFont,
                .foregroundColor: tintColor
            ]
            appearance.buttonAppearance.highlighted.titleTextAttributes = [
                .font: itemFont,
                .foregroundColor: tintColor
            ]

            self.standardAppearance = appearance
            self.scrollEdgeAppearance = appearance

            self.tintColor = tintColor
            self.isTranslucent = true
        }
    }

}
