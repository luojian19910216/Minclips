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
        get { objc_getAssociatedObject(self, &mc_shadowHiddenKey) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &mc_shadowHiddenKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = newValue ? 0.0 : 0.1
            self.layer.shadowRadius = 2
            self.layer.shadowOffset = .zero
        }
    }

    public var mc_barStyle: MCENavigationBarStyle {
        get { MCENavigationBarStyle(rawValue: (objc_getAssociatedObject(self, &mc_barStyleKey) as? Int) ?? 0) ?? .transparentDark }
        set {
            objc_setAssociatedObject(self, &mc_barStyleKey, newValue.rawValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)

            if #available(iOS 26.0, *) {
                self.mc_applyNavigationBarStyleLiquidGlass(newValue)
            } else {
                self.mc_applyNavigationBarStyleLegacy(newValue)
            }
        }
    }

    private func mc_applyNavigationBarStyleLegacy(_ style: MCENavigationBarStyle) {
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let itemFont = UIFont.systemFont(ofSize: 16)
        var tintColor: UIColor = .black

        let appearance = UINavigationBarAppearance()
        appearance.shadowColor = .clear

        switch style {
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
        self.isTranslucent = style != .opaqueLight
    }

    @available(iOS 26.0, *)
    private func mc_applyNavigationBarStyleLiquidGlass(_ style: MCENavigationBarStyle) {
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let itemFont = UIFont.systemFont(ofSize: 16)
        let tintColor: UIColor
        let titleColor: UIColor

        switch style {
        case .transparentDark:
            tintColor = .black
            titleColor = .black
        case .transparentLight:
            tintColor = .white
            titleColor = .white
        case .opaqueLight:
            tintColor = .label
            titleColor = .label
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: titleFont,
            .foregroundColor: titleColor
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
        self.compactAppearance = appearance
        self.compactScrollEdgeAppearance = appearance

        self.tintColor = tintColor
        self.isTranslucent = true
    }

}
