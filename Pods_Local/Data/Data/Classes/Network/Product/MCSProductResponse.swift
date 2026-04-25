//
//  ProductResponseModel.swift
//

import Foundation

///
public struct MCSProductFindAllResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeEnum public var ab: MCEAB
    ///
    @MCSSafeBool public var isDiscountRetention: Bool
    ///
    @MCSSafeString public var deepLike: String
    ///
    @MCSSafeArray public var product: [MCSProductItem] = []
}

///
public struct MCSProductItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var id: String
    ///
    @MCSSafeString public var productType: String
    ///
    @MCSSafeEnum public var duration: MCEDuration
    ///
    @MCSSafeString public var title: String
    ///
    @MCSSafeString public var benefit: String
    ///
    @MCSSafeInt public var discount: Int
    ///
    @MCSSafeString public var discountDesc: String
    ///
    @MCSSafeString public var priceDesc: String
    ///
    @MCSSafeString public var discountPrice: String
    ///
    @MCSSafeInt public var freeTrial: Int
    ///
    @MCSSafeInt public var giftIntegral: Int
    ///
    @MCSSafeInt public var integralCount: Int
    ///
    @MCSSafeString public var integralRate: String
    ///
    @MCSSafeString public var name: String
    ///
    @MCSSafeInt public var originIntegralCount: Int
    ///
    @MCSSafeString public var originalPrice: String
    ///
    @MCSSafeString public var payLevel: String
    ///
    @MCSSafeString public var priceDescription: String
    ///
    @MCSSafeInt public var selected: Int
    ///
    @MCSSafeInt public var totalIntegral: Int
    ///
    @MCSSafeString public var unit: String
    ///
    @MCSSafeString public var tip: String
    ///
    @MCSSafeBool public var isShowWeek: Bool
    ///
    @MCSSafeBool public var isShowWeekV2: Bool
    ///
    @MCSSafeString public var label: String
    ///
    @MCSSafeBool public var isFb: Bool
    ///
    @MCSSafeString public var advocacy: String
    ///
    @MCSSafeString public var confirmBtn: String
    ///
    @MCSSafeArray public var placard: [MCSPlacard]
    ///
    @MCSSafeArray public var backPlacard: [MCSPlacard]
//    ///
//    public var storeStatus: Bool = false
//    ///
//    public var product: Product?
//    ///
//    public var priceServer: Decimal = 0
//    ///
//    public var discountPriceServer: Decimal = 0
//    ///
//    public var discountPriceWeekServer: Decimal = 0
//    ///
//    public var priceDescServer: String = ""
//    ///
//    public var discountPriceDescServer: String = ""
//    ///
//    public var discountPriceWeekDescServer: String = ""
//    ///
//    public var fbPrice: String = ""
//    ///
//    public var fbUnit: String = ""
//
//    public func placardAtt(with isGuide: Bool = false, isDiscount: Bool = false, isNewHome: Int = 0, isDetail: Bool = false) -> NSAttributedString {
//        let result = NSMutableAttributedString()
//        for item in self.placard {
//            let font = UIFont.systemFont(ofSize: 13, weight: .regular)
//            let color = {
//                if item.highlight {
//                    return UIColor(hex: 0xFFFFFF, a: isDetail ? 0.8 : 1)
//                }
//                return UIColor(hex: 0x989898)
//            }()
//
//            result.append({
//                let line = NSMutableAttributedString()
//                if let image = {
//                    if isNewHome == 2 {
//                        return UIImage(named: "icon_power_desc_8")
//                    }
//                    if isNewHome == 1 {
//                        return UIImage(named: "icon_power_desc_7")
//                    }
//                    guard item.highlight else {
//                        return UIImage(named: "icon_power_desc_1")
//                    }
//                    if isGuide {
//                        return UIImage(named: "icon_power_desc_2")
//                    }
//                    if isDiscount {
//                        return UIImage(named: "icon_power_desc_5")
//                    }
//                    if isDetail {
//                        return UIImage(named: "icon_power_desc_6")
//                    }
//                    if self.id.contains("Super") {
//                        return UIImage(named: "icon_power_desc_4")
//                    }
//                    return UIImage(named: "icon_power_desc_3")
//                }() {
//                    line.append(NSAttributedString(attachment: {
//                        let attachment = NSTextAttachment()
//                        attachment.image = image
//                        attachment.bounds = CGRect(
//                            x: 0,
//                            y: (font.capHeight - image.size.height) / 2,
//                            width: image.size.width,
//                            height: image.size.height
//                        )
//                        return attachment
//                    }()))
//                    line.append(NSAttributedString(string: "   "))
//                }
//                line.append({
//                    let att = NSMutableAttributedString(string: item.text, attributes: [
//                        .font: font,
//                        .foregroundColor: color
//                    ])
//                    if !item.highlightText.isEmpty {
//                        let highlightTexts = item.highlightText.components(separatedBy: ";")
//                        for highlightText in highlightTexts {
//                            if !highlightText.isEmpty, let range = item.text.range(of: highlightText) {
//                                att.addAttributes([
//                                    .font: UIFont.systemFont(ofSize: 13, weight: .bold),
//                                    .foregroundColor: UIColor.white
//                                ], range: NSRange(range, in: item.text))
//                            }
//                        }
//                    }
//                    return att
//                }())
//                if let image = item.tailMarkingImage() {
//                    line.append(NSAttributedString(string: "  "))
//                    line.append(NSAttributedString(attachment: {
//                        let attachment = NSTextAttachment()
//                        attachment.image = image
//                        attachment.bounds = CGRect(
//                            x: 0,
//                            y: (font.capHeight - image.size.height) / 2,
//                            width: image.size.width,
//                            height: image.size.height
//                        )
//                        return attachment
//                    }()))
//                }
//                line.addAttributes([
//                    .paragraphStyle: {
//                        let style: NSMutableParagraphStyle = .init()
//                        style.headIndent = 16 + (isDetail ? 16 : 16)
//                        style.lineSpacing = 4
//                        style.alignment = .left
//                        return style
//                    }()
//                ], range: .init(location: 0, length: line.length))
//                return line
//            }())
//            result.append(.init(string: "\n\n", attributes: [
//                .font: UIFont.systemFont(ofSize: isDetail ? 2 : 8)
//            ]))
//        }
//        return result
//    }
//    ///
//    public func labelImage() -> UIImage? {
//        if self.label.isEmpty { return nil }
//
//        let font = UIFont.boldSystemFont(ofSize: 10)
//        let textSize = (self.label as NSString).size(withAttributes: [.font: font])
//
//        let size = CGSize(
//            width: textSize.width + 16,
//            height: textSize.height + 8
//        )
//
//        let textRect = CGRect(
//            x: 8,
//            y: 4,
//            width: textSize.width,
//            height: textSize.height
//        )
//
//        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
//        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
//
//        let rect = CGRect(origin: .zero, size: size)
//        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
//        ctx.saveGState()
//        path.addClip()
//
//        // 左 → 右 渐变
//        let colors = [
//            UIColor(hex: 0xFF3C00)!.cgColor,
//            UIColor(hex: 0xEF6BBA)!.cgColor
//        ] as CFArray
//        let gradient = CGGradient(
//            colorsSpace: CGColorSpaceCreateDeviceRGB(),
//            colors: colors,
//            locations: [0.0, 1.0]
//        )!
//        ctx.drawLinearGradient(
//            gradient,
//            start: CGPoint(x: 0, y: size.height / 2),
//            end: CGPoint(x: size.width, y: size.height / 2),
//            options: []
//        )
//        ctx.restoreGState()
//
//        // 绘制文字
//        (self.label as NSString).draw(in: textRect, withAttributes: [
//            .font: font,
//            .foregroundColor: UIColor.white
//        ])
//
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return image
//    }
//    ///
//    public var discountDescFinal: String {
//        var text = discountDesc
//        text = text.replacingOccurrences(of: "$price", with: self.discountPriceDescServer)
//        text = text.replacingOccurrences(of: "$originalPrice", with: self.priceDescServer)
//        text = text.replacingOccurrences(of: "$credit", with: "\(self.originIntegralCount)")
//        text = text.replacingOccurrences(of: "$bonusCredit", with: "\(self.giftIntegral)")
//        return text
//    }
//    ///
//    public var priceDescFinal: String {
//        var text = priceDesc
//        text = text.replacingOccurrences(of: "$originalPrice", with: self.priceDescServer)
//        text = text.replacingOccurrences(of: "$price", with: self.discountPriceDescServer)
//        text = text.replacingOccurrences(of: "$weekPrice", with: self.discountPriceWeekDescServer)
//        text = text.replacingOccurrences(of: "$credit", with: "\(self.originIntegralCount)")
//        text = text.replacingOccurrences(of: "$bonusCredit", with: "\(self.giftIntegral)")
//        return text
//    }
//    ///
//    public var advocacyFinal: String {
//        var text = advocacy
//        text = text.replacingOccurrences(of: "$originalPrice", with: self.priceDescServer)
//        text = text.replacingOccurrences(of: "$price", with: self.discountPriceDescServer)
//        text = text.replacingOccurrences(of: "$weekPrice", with: self.discountPriceWeekDescServer)
//        text = text.replacingOccurrences(of: "$credit", with: "\(self.originIntegralCount)")
//        text = text.replacingOccurrences(of: "$bonusCredit", with: "\(self.giftIntegral)")
//        return text
//    }
//    ///
//    public var confirmBtnFinal: String {
//        var text = confirmBtn
//        text = text.replacingOccurrences(of: "$originalPrice", with: self.priceDescServer)
//        text = text.replacingOccurrences(of: "$price", with: self.discountPriceDescServer)
//        text = text.replacingOccurrences(of: "$weekPrice", with: self.discountPriceWeekDescServer)
//        text = text.replacingOccurrences(of: "$credit", with: "\(self.originIntegralCount)")
//        text = text.replacingOccurrences(of: "$bonusCredit", with: "\(self.giftIntegral)")
//        return text
//    }
}

///
public struct MCSPlacard: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var text: String
    ///
    @MCSSafeString public var highlightText: String
    ///
    @MCSSafeBool public var highlight: Bool
    ///
    @MCSSafeString public var tailMarking: String
}
