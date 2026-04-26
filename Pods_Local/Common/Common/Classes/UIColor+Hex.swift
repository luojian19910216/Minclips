//
//  UIColor+Hex.swift
//  Common
//

import UIKit

extension UIColor {

    public static let hex_d3d0cd = UIColor(hex: "D3D0CD")!

    public convenience init?(hex: String, alpha: CGFloat = 1) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        s = s.uppercased()
        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else {
            return nil
        }
        let r, g, b, a: CGFloat
        switch s.count {
        case 3:
            r = CGFloat((value >> 8) & 0x0F) * 17.0 / 255.0
            g = CGFloat((value >> 4) & 0x0F) * 17.0 / 255.0
            b = CGFloat(value & 0x0F) * 17.0 / 255.0
            a = alpha
        case 6:
            r = CGFloat((value >> 16) & 0xFF) / 255.0
            g = CGFloat((value >> 8) & 0xFF) / 255.0
            b = CGFloat(value & 0xFF) / 255.0
            a = alpha
        case 8:
            r = CGFloat((value >> 24) & 0xFF) / 255.0
            g = CGFloat((value >> 16) & 0xFF) / 255.0
            b = CGFloat((value >> 8) & 0xFF) / 255.0
            a = CGFloat(value & 0xFF) / 255.0
        default:
            return nil
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
