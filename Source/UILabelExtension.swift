// FittableLabel.swift
//
// Copyright (c) 2016 Tom Baranes (https://github.com/tbaranes)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

extension UILabel {

    /**
     Resize the font to make the current text fit the label frame.

     - parameter maxFontSize:  The max font size available
     - parameter minFontScale: The min font scale that the font will have
     - parameter rectSize:     Rect size where the label must fit
     */
    public func fontSizeToFit(maxFontSize: CGFloat = 100, minFontScale: CGFloat = 0.1, rectSize: CGSize? = nil) {
        guard let unwrappedText = self.text else {
            return
        }

        let newFontSize = fontSizeThatFits(text: unwrappedText, maxFontSize: maxFontSize, minFontScale: minFontScale, rectSize: rectSize)
        font = font.withSize(newFontSize)
    }

    /**
     Returns a font size of a specific string in a specific font that fits a specific size

     - parameter text:         The text to use
     - parameter maxFontSize:  The max font size available
     - parameter minFontScale: The min font scale that the font will have
     - parameter rectSize:     Rect size where the label must fit
     */
    public func fontSizeThatFits(text string: String, maxFontSize: CGFloat = 100, minFontScale: CGFloat = 0.1, rectSize: CGSize? = nil, lineSpacingMultiplier: CGFloat = 0) -> CGFloat {
        let maxFontSize = maxFontSize.isNaN ? 100 : maxFontSize
        let minFontScale = minFontScale.isNaN ? 0.1 : minFontScale
        let minimumFontSize = maxFontSize * minFontScale
        let rectSize = rectSize ?? bounds.size
        guard !string.isEmpty else {
            return self.font.pointSize
        }

        let constraintSize = numberOfLines == 1 ?
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: rectSize.height) :
            CGSize(width: rectSize.width, height: CGFloat.greatestFiniteMagnitude)
        let calculatedFontSize = binarySearch(string: string, minSize: minimumFontSize, maxSize: maxFontSize, size: rectSize, constraintSize: constraintSize, lineSpacingMultiplier: lineSpacingMultiplier)
        return (calculatedFontSize * 10.0).rounded(.down) / 10.0
    }

}

// MARK: - Helpers

extension UILabel {

    private func currentAttributedStringAttributes() -> [NSAttributedString.Key: Any] {
        var newAttributes = [NSAttributedString.Key: Any]()
        attributedText?.enumerateAttributes(in: NSRange(0..<(text?.count ?? 0)), options: .longestEffectiveRangeNotRequired, using: { attributes, _, _ in
            newAttributes = attributes
        })
        return newAttributes
    }

}

// MARK: - Search

extension UILabel {

    private enum FontSizeState {
        case fit, tooBig, tooSmall
    }

    private func binarySearch(string: String, minSize: CGFloat, maxSize: CGFloat, size: CGSize, constraintSize: CGSize, lineSpacingMultiplier: CGFloat) -> CGFloat {
        let fontSize = (minSize + maxSize) / 2
        var attributes = currentAttributedStringAttributes()
        let tempFont = font.withSize(fontSize)
        attributes[NSAttributedString.Key.font] = tempFont

        if let paragraphStyle = (attributes[.paragraphStyle] as? NSMutableParagraphStyle) {
            paragraphStyle.lineSpacing = tempFont.lineHeight * lineSpacingMultiplier
            attributes[.paragraphStyle] = paragraphStyle
        }
        
        let rect = string.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        let state = numberOfLines == 1 ? singleLineSizeState(rect: rect, size: size) : multiLineSizeState(rect: rect, size: size)

        // if the search range is smaller than 0.1 of a font size we stop
        // returning either side of min or max depending on the state
        let diff = maxSize - minSize
        guard diff > 0.1 else {
            switch state {
            case .tooSmall:
                return maxSize
            default:
                return minSize
            }
        }

        switch state {
        case .fit: return fontSize
        case .tooBig: return binarySearch(string: string, minSize: minSize, maxSize: fontSize, size: size, constraintSize: constraintSize, lineSpacingMultiplier: lineSpacingMultiplier)
        case .tooSmall: return binarySearch(string: string, minSize: fontSize, maxSize: maxSize, size: size, constraintSize: constraintSize, lineSpacingMultiplier: lineSpacingMultiplier)
        }
    }

    private func singleLineSizeState(rect: CGRect, size: CGSize) -> FontSizeState {
        if rect.width >= size.width + 10 && rect.width <= size.width {
            return .fit
        } else if rect.width > size.width {
            return .tooBig
        } else {
            return .tooSmall
        }
    }

    private func multiLineSizeState(rect: CGRect, size: CGSize) -> FontSizeState {
        // if rect within 10 of size
        if rect.height < size.height + 10 &&
           rect.height > size.height - 10 &&
           rect.width > size.width + 10 &&
           rect.width < size.width - 10 {
            return .fit
        } else if rect.height > size.height || rect.width > size.width {
            return .tooBig
        } else {
            return .tooSmall
        }
    }

}
