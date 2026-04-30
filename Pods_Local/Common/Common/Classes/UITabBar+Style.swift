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
            
            var barTintColor: UIColor!
            var normalTintColor: UIColor!
            var selectedTintColor: UIColor!
            let itemFont = UIFont.systemFont(ofSize: 11)
            
            switch mc_barStyle {
            case .glassDark:
                barTintColor = UIColor.white.withAlphaComponent(0.06)
                normalTintColor = UIColor.white
                selectedTintColor = UIColor(hex: "0077FF")
            }
            
            let appearance = UITabBarAppearance()
            
            if #available(iOS 26.0, *) {
                appearance.configureWithDefaultBackground()
            } else {
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = UIBlurEffect(style: .regular)
            }
            
            appearance.shadowColor = .clear
            appearance.backgroundColor = barTintColor
            
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
            
            self.unselectedItemTintColor = normalTintColor
            self.tintColor = selectedTintColor
            
            self.isTranslucent = true
        }
        
    }

}
