//
//  UITabBar+Style.swift
//

import UIKit

private var mc_shadowHiddenKey: UInt8 = 0
private var mc_barStyleKey: UInt8 = 1

public enum MCETabBarStyle: Int {
    case glassDark
}

extension UITabBar {

    public var mc_shadowHidden: Bool {
        get {
            return objc_getAssociatedObject(self, &mc_shadowHiddenKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &mc_shadowHiddenKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = newValue ? 0.0 : 0.1
            self.layer.shadowRadius = 2
            self.layer.shadowOffset = .zero
        }
    }

    public var mc_barStyle: MCETabBarStyle {
        get {
            return MCETabBarStyle(rawValue: (objc_getAssociatedObject(self, &mc_barStyleKey) as? Int) ?? 0) ?? .glassDark
        }
        set {
            objc_setAssociatedObject(self, &mc_barStyleKey, newValue.rawValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            var barTintColor: UIColor!
            var normalTintColor: UIColor!
            var selectedTintColor: UIColor!
            let itemFont = UIFont.systemFont(ofSize: 11)

            switch mc_barStyle {
            case .glassDark:
                barTintColor = UIColor.black.withAlphaComponent(0.6)
                // 与选中态同色，避免仅当前 Tab 高亮、其余呈「未选」色
                let accent = UIColor.white
                normalTintColor = accent
                selectedTintColor = accent
            }

            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            // 去掉阴影线
            appearance.shadowColor = .clear
            // 背景颜色 & 模糊效果
            appearance.backgroundColor = barTintColor
            appearance.backgroundEffect = UIBlurEffect(style: .regular)
            // icon颜色
            appearance.stackedLayoutAppearance.normal.iconColor = normalTintColor
            appearance.stackedLayoutAppearance.selected.iconColor = selectedTintColor
            // title字体+颜色
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .font: itemFont,
                .foregroundColor: normalTintColor
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .font: itemFont,
                .foregroundColor: selectedTintColor
            ]

            self.standardAppearance = appearance
            self.scrollEdgeAppearance = appearance

            self.tintColor = selectedTintColor
            self.unselectedItemTintColor = normalTintColor

            self.isTranslucent = true
        }
    }

}
