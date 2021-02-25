// Copyright © 2021 Brad Howes. All rights reserved.

#if os(iOS)

import UIKit
public typealias Color = UIColor
public typealias Control = UIControl
public typealias Label = UILabel
public typealias Slider = UISlider
public typealias Storyboard = UIStoryboard
public typealias View = UIView
public typealias BezierPath = UIBezierPath

#elseif os(macOS)

import AppKit
public typealias Color = NSColor
public typealias Control = NSControl
public typealias Label = NSTextField
public typealias Slider = NSSlider
public typealias Storyboard = NSStoryboard
public typealias View = NSView
public typealias BezierPath = NSBezierPath

public extension NSView {
    func setNeedsDisplay() { self.needsDisplay = true }
    func setNeedsLayout() { self.needsLayout = true }
    @objc func layoutSubviews() { self.layout() }

    var backgroundColor: NSColor? {
        get {
            guard let colorRef = self.layer?.backgroundColor else { return nil }
            return NSColor(cgColor: colorRef)
        }
        set {
            self.wantsLayer = true
            self.layer?.backgroundColor = newValue?.cgColor
        }
    }
}

public extension NSTextField {
    var text: String? {
        get { self.stringValue }
        set { self.stringValue = newValue ?? "" }
    }
}

public extension NSSlider {
    var minimumValue: Float {
        get { Float(self.minValue) }
        set { self.minValue = Double(newValue) }
    }

    var maximumValue: Float {
        get { Float(self.maxValue) }
        set { self.maxValue = Double(newValue) }
    }

    var value: Float {
        get { self.floatValue }
        set { self.floatValue = newValue }
    }
}

public extension NSBezierPath {

    convenience init(arcCenter: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        self.init()
        appendArc(withCenter: arcCenter, radius: radius, startAngle: startAngle, endAngle: endAngle,
                  clockwise: clockwise)
    }

    func addLine(to pos: CGPoint) { self.line(to: pos) }

    func apply(_ transform: CGAffineTransform) {
        self.transform(using: AffineTransform.init(m11: transform.a, m12: transform.b, m21: transform.c,
                                                   m22: transform.d, tX: transform.tx, tY: transform.ty))
    }

    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            @unknown default: break
            }
        }
        return path
    }
}

#endif
