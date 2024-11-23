#if os(iOS)

import CoreGraphics
import UIKit

public enum Theme {

  public enum ColorKind: String {
    case knobLabelColor
    case knobProgressColor
    case backgroundTitleColor
  }

  public static func color(_ kind: ColorKind) -> UIColor {
    guard let color = UIColor(named: kind.rawValue, in: Bundle.module, compatibleWith: nil) else {
      fatalError("failed to locate color '\(kind.rawValue)'")
    }
    return color
  }

  public static func titleFont(size: CGFloat) -> UIFont {
    let fontName = "Desdemona"

    guard let fontURL = Bundle.module.url(forResource: fontName, withExtension: "ttf") else {
      fatalError("missing font file in package bundle")
    }

    guard
      let provider = CGDataProvider(url: fontURL as CFURL),
      let font = CGFont(provider)
    else {
      fatalError("invalid or corrupted font file")
    }

    var cfError: Unmanaged<CFError>?
    CTFontManagerRegisterGraphicsFont(font, &cfError)
    if let error = cfError as? Error {
      fatalError("failed to register font - \(error.localizedDescription)")
    }

    guard let uiFont = UIFont(name: fontName, size: size) else {
      fatalError("failed to get UIFont")
    }

    return uiFont
  }
}

#endif
