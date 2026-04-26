//
//  UINavigationBar+Style.swift
//

import UIKit

private var mc_shadowHiddenKey: UInt8 = 0
private var mc_barStyleKey: UInt8 = 1

public enum MCENavigationBarStyle: Int {
    case transparentDark
    case transparentLight
    case opaqueLight
}

extension UINavigationBar {

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

    public var mc_barStyle: MCENavigationBarStyle {
        get {
            return MCENavigationBarStyle(rawValue: (objc_getAssociatedObject(self, &mc_barStyleKey) as? Int) ?? 0) ?? .transparentDark
        }
        set {
            objc_setAssociatedObject(self, &mc_barStyleKey, newValue.rawValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let itemFont = UIFont.systemFont(ofSize: 16)
            var tintColor: UIColor = .black

            let appearance = UINavigationBarAppearance()
            appearance.shadowColor = .clear

            switch mc_barStyle {
            case .transparentDark:
                tintColor = .black
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.backgroundEffect = nil
            case .transparentLight:
                tintColor = .white
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.backgroundEffect = nil
            case .opaqueLight:
                tintColor = .label
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .white
                appearance.backgroundEffect = nil
            }

            appearance.titleTextAttributes = [
                .font: titleFont,
                .foregroundColor: tintColor
            ]
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
            self.isTranslucent = mc_barStyle != .opaqueLight
        }
    }

}
