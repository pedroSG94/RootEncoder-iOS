//
//  Created by Pedro  on 24/07/26.
//

import common
import Foundation
import CoreImage
import UIKit

public class TextFilterRender: BaseObjectFilterRender {

    private var text = ""
    private var textSize: CGFloat = 0
    private var textColor: UIColor = .white
    private var backgroundColor: UIColor = .clear
    private var font: UIFont? = nil

    public func setText(text: String, textSize: CGFloat, textColor: UIColor, backgroundColor: UIColor = .clear, font: UIFont? = nil) {
        self.text = text
        self.textSize = textSize
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.font = font
        setObject(image: textAsImage())
    }

    public func addText(text: String) {
        setText(text: self.text + text, textSize: textSize, textColor: textColor, backgroundColor: backgroundColor, font: font)
    }

    public func updateColor(textColor: UIColor) {
        setText(text: text, textSize: textSize, textColor: textColor, backgroundColor: backgroundColor, font: font)
    }

    public func updateTextSize(textSize: CGFloat) {
        setText(text: text, textSize: textSize, textColor: textColor, backgroundColor: backgroundColor, font: font)
    }

    public func updateFont(font: UIFont) {
        setText(text: text, textSize: textSize, textColor: textColor, backgroundColor: backgroundColor, font: font)
    }

    private func textAsImage() -> CIImage? {
        let font = (self.font ?? UIFont.systemFont(ofSize: textSize)).withSize(textSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textBounds = (text as NSString).size(withAttributes: attributes)
        let width = max(1, ceil(textBounds.width))
        let height = max(1, ceil(textBounds.height))
        let format = UIGraphicsImageRendererFormat()
        // 1 point = 1 pixel like Android textSize, needed to keep setDefaultScale in real pixels
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            (text as NSString).draw(at: .zero, withAttributes: attributes)
        }
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }
}
