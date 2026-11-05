//
//  OcrKoreanSymbolFixer.swift
//  HWPViewer
//
//  Puts back the symbols of Korean documents that Vision reads as look-alike Latin characters
//  (ESI05-71). Measured on the OCR test pages: the Hangul itself comes out right, the symbols
//  around it do not —
//    ₩12,500      → W12,500         (won sign as a capital W)
//    『별첨』       → 「별첨』          (double corner bracket opened with the single one, or the reverse)
//  Only lines that contain Hangul are touched, and only in spots where the Latin reading makes no
//  sense in Korean text, so English and numbers elsewhere stay as read. Bullets are left alone:
//  a "0" / "o" at the start of a line may be ○, ㅇ or a real Latin "o" (government documents use
//  all three), so guessing would trade one error for another. Shapes Vision does not read at all
//  (■ ▶ ★) stay in the page's background picture.
//

import Foundation

enum OcrKoreanSymbolFixer {
    private static let hangul = try! NSRegularExpression(pattern: "[\\x{AC00}-\\x{D7A3}]")
    /// A "W" glued to a number and not part of a word: "W12,500", "(W3,000)".
    private static let wonSign = try! NSRegularExpression(pattern: "(?<![A-Za-z0-9])W(?=\\d)")
    /// 「…』 → 『…』 (the closing bracket is read more reliably than the opening one).
    private static let doubleBracket = try! NSRegularExpression(pattern: "「([^「」『』]*)』")
    /// 『…」 → 「…」
    private static let singleBracket = try! NSRegularExpression(pattern: "『([^「」『』]*)」")

    static func fix(_ line: String) -> String {
        guard hangul.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil else { return line }
        var text = line
        text = replace(wonSign, in: text, with: "₩")
        text = replace(doubleBracket, in: text, with: "『$1』")
        text = replace(singleBracket, in: text, with: "「$1」")
        return text
    }

    private static func replace(_ regex: NSRegularExpression, in text: String, with template: String) -> String {
        regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
    }
}
