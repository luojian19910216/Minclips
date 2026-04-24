//
//  MCCScreenSize.swift
//

import UIKit

public final class MCCScreenSize {

    // MARK: - Window
    
    public static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    // MARK: - Appearance
    
    public static var isDark: Bool {
        keyWindow?.traitCollection.userInterfaceStyle == .dark
    }
    
    // MARK: - Screen

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

    // MARK: - UI Metrics
    
    public static var topSafeHeight: CGFloat {
        keyWindow?.safeAreaInsets.top ?? Self.statusBarHeight
    }

    public static var bottomSafeHeight: CGFloat {
        keyWindow?.safeAreaInsets.bottom ?? 0
    }
    
    private static var statusBarHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.statusBarManager?.statusBarFrame.height ?? 0
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
