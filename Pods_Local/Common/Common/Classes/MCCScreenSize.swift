//
//  MCCScreenSize.swift
//

import UIKit

public final class MCCScreenSize {
    
    public static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    public static var isDark: Bool {
        keyWindow?.traitCollection.userInterfaceStyle == .dark
    }

    public static var scale: CGFloat {
        UIScreen.main.scale
    }

    public static var bounds: CGRect {
        UIScreen.main.bounds
    }

    public static var size: CGSize {
        UIScreen.main.bounds.size
    }

    public static var width: CGFloat {
        UIScreen.main.bounds.size.width
    }

    public static var height: CGFloat {
        UIScreen.main.bounds.size.height
    }

    
    public static var topSafeHeight: CGFloat {
        keyWindow?.safeAreaInsets.top ?? Self.statusBarHeight
    }

    public static var bottomSafeHeight: CGFloat {
        keyWindow?.safeAreaInsets.bottom ?? 0
    }
    
    public static var statusBarHeight: CGFloat {
        let h = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.statusBarManager?.statusBarFrame.height ?? 0
        if h > 0 { return h }
        return keyWindow?.safeAreaInsets.top ?? 20
    }
    
    public static var navigationBarHeight: CGFloat {
        44.0 + topSafeHeight
    }

    public static var tabBarHeight: CGFloat {
        49.0 + bottomSafeHeight
    }

    public static var onePixel: CGFloat {
        1.0 / scale
    }
    
}
