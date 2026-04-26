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
        get { objc_getAssociatedObject(self, &mc_shadowHiddenKey) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &mc_shadowHiddenKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = newValue ? 0.0 : 0.1
            self.layer.shadowRadius = 2
            self.layer.shadowOffset = .zero
        }
    }

    public var mc_barStyle: MCETabBarStyle {
        get { MCETabBarStyle(rawValue: (objc_getAssociatedObject(self, &mc_barStyleKey) as? Int) ?? 0) ?? .glassDark }
        set {
            objc_setAssociatedObject(self, &mc_barStyleKey, newValue.rawValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            if #available(iOS 26.0, *) {
                self.mc_applyTabBarStyleLiquidGlass(newValue)
            } else {
                self.mc_applyTabBarStyleLegacy(newValue)
            }
        }
    }

    private func mc_applyTabBarStyleLegacy(_ style: MCETabBarStyle) {
        var barTintColor: UIColor!
        var normalTintColor: UIColor!
        var selectedTintColor: UIColor!
        let itemFont = UIFont.systemFont(ofSize: 11)

        switch style {
        case .glassDark:
            barTintColor = UIColor.black.withAlphaComponent(0.6)
            let accent = UIColor.white
            normalTintColor = accent
            selectedTintColor = accent
        }

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.backgroundColor = barTintColor
        appearance.backgroundEffect = UIBlurEffect(style: .regular)
        appearance.stackedLayoutAppearance.normal.iconColor = normalTintColor
        appearance.stackedLayoutAppearance.selected.iconColor = selectedTintColor
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

    @available(iOS 26.0, *)
    private func mc_applyTabBarStyleLiquidGlass(_ style: MCETabBarStyle) {
        let itemFont = UIFont.systemFont(ofSize: 11)

        switch style {
        case .glassDark:
            let accent = UIColor.white
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.shadowColor = .clear
            appearance.stackedLayoutAppearance.normal.iconColor = accent
            appearance.stackedLayoutAppearance.selected.iconColor = accent
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .font: itemFont,
                .foregroundColor: accent
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .font: itemFont,
                .foregroundColor: accent
            ]

            self.standardAppearance = appearance
            self.scrollEdgeAppearance = appearance

            self.tintColor = accent
            self.unselectedItemTintColor = accent
            self.isTranslucent = true
        }
    }

}
