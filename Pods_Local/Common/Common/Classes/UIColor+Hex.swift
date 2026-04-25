//
//  UIColor+Hex.swift
//  Common
//

import UIKit

extension UIColor {

    /// 由十六进制字符串创建颜色；支持带或不带 `#`。
    /// - 3 位：`#RGB`（每位重复成 `RR GG BB`）
    /// - 6 位：`#RRGGBB`（`alpha` 使用参数，默认 1）
    /// - 8 位：`#RRGGBBAA`（最后两位为 alpha，`alpha` 参数忽略）
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
