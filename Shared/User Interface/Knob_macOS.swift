// Copyright © 2020 Brad Howes. All rights reserved.

import Cocoa
import os

/**
 Custom UIControl that depicts a value as a point on a circle. Changing the value is done by touching on the control and moving up to increase
 and down to decrease the current value. While touching, moving away from the control in either direction will increase the resolution of the
 touch changes, causing the value to change more slowly as vertical distance changes. Pretty much works like UISlider but with the travel path
 as an arc.

 Visual representation of the knob is done via CoreAnimation components, namely CAShapeLayer and UIBezierPath. The diameter of the arc of the knob is
 defined by the min(width, height) of the view's frame.
 */
open class Knob: NSControl {
  /// The minimum value reported by the control.
  open var minimumValue: Float = 0.0 { didSet { setValue(clampedValue(value), animated: false) } }

  /// The maximum value reported by the control.
  open var maximumValue: Float = 1.0 { didSet { setValue(clampedValue(value), animated: false) } }

  /// The current value of the control.
  open var value: Float { get { _value } set { setValue(clampedValue(newValue), animated: false) } }

  /// How much travel is need to move the width or height of the knob to go from minimumValue to maximumValue. By default this is 4x the knob size.
  open var touchSensitivity: Float = 1.0

  /// The width of the arc that is shown after the current value.
  open var trackLineWidth: CGFloat = 6 { didSet { trackLayer.lineWidth = trackLineWidth } }

  /// The color of the arc shown after the current value.
  open var trackColor: Color = Color.darkGray.darker.darker.darker { didSet { trackLayer.strokeColor = trackColor.cgColor } }

  /// The width of the arc from the start up to the current value.
  open var progressLineWidth: CGFloat = 4 { didSet { progressLayer.lineWidth = progressLineWidth } }

  /// The color of the arc from the start up to the current value.
  open var progressColor: Color = .systemOrange { didSet { progressLayer.strokeColor = progressColor.cgColor } }

  /// The width of the radial line drawn from the current value on the arc towards the arc center.
  open var indicatorLineWidth: CGFloat = 4 { didSet { indicatorLayer.lineWidth = indicatorLineWidth } }

  /// The color of the radial line drawn from the current value on the arc towards the arc center.
  open var indicatorColor: Color = .systemOrange { didSet { indicatorLayer.strokeColor = indicatorColor.cgColor } }

  /// The proportion of the radial line drawn from the current value on the arc towards the arc center.
  /// Range is from 0.0 to 1.0, where 1.0 will draw a complete line, and anything less will draw that fraction of it
  /// starting from the arc.
  open var indicatorLineLength: CGFloat = 0.3 { didSet { createShapes() } }

  /// Number of ticks to show inside the track. None are shown at the start and end position.
  open var tickCount: Int = 0 { didSet { createShapes() } }

  open var tickLineOffset: CGFloat = 0.1 { didSet { createShapes() } }

  /// Length of the tick. Range is from 0.0 to 1.0 where 1.0 will draw a line ending at the center of the knob.
  open var tickLineLength: CGFloat = 0.25 { didSet { createShapes() } }

  /// The width of the tick line.
  open var tickLineWidth: CGFloat = 0.5 { didSet { ticksLayer.lineWidth = tickLineWidth } }

  /// The color of the tick line.
  open var tickLineColor: Color = .lightGray { didSet { ticksLayer.strokeColor = tickLineColor.cgColor } }

  private let startAngle: CGFloat = -CGFloat.pi / 180.0 * 225.0
  private let endAngle: CGFloat = CGFloat.pi / 180.0 * 45.0

  private let trackLayer = CAShapeLayer()
  private let progressLayer = CAShapeLayer()
  private let indicatorLayer = CAShapeLayer()
  private let ticksLayer = CAShapeLayer()
  private let updateQueue = DispatchQueue(label: "Knob", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .main)

  private var _value: Float = 0.0
  private var panOrigin: CGPoint = .zero
  private var activeTouch: Bool = false

  override public var acceptsFirstResponder: Bool { return true }
  var backingLayer: CALayer { layer! }
  override public var wantsUpdateLayer: Bool { true }
  override public var isFlipped: Bool { true }

  /**
   Construction from an encoded representation.

   - parameter aDecoder: the representation to use
   */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  /**
   Construct a new instance with the given location and size. A knob will take the size of the smaller of width and height dimensions
   given in the `frame` parameter.

   - parameter frame: geometry of the new knob
   */
  override public init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  override public func layout() {
    super.layout()

    // To make future calculations easier, configure the layers so that (0, 0) is their center
    let layerBounds = bounds.offsetBy(dx: -bounds.midX, dy: -bounds.midY)
    let layerCenter = CGPoint(x: bounds.midX, y: bounds.midY)
    for layer in [backingLayer, trackLayer, progressLayer, indicatorLayer, ticksLayer] {
      layer.bounds = layerBounds
      layer.position = layerCenter
    }
    createShapes()
  }

  public func setValue(_ value: Float, animated: Bool = false) {
    _value = clampedValue(value)
    draw(animated: animated)
    updateLayer()
  }
}

extension Knob {
  override public func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    return true
  }

  override open func mouseDown(with event: NSEvent) {
    panOrigin = event.locationInWindow
    activeTouch = true
    updateQueue.async { self.sendAction(self.action, to: self.target) }
  }

  override open func mouseDragged(with event: NSEvent) {
    guard activeTouch == true else { return }
    let point = event.locationInWindow

    // Scale touchSensitivity by how far away in the X direction the touch is -- farther away the larger the sensitivity, thus making for smaller value changes for the same
    // distance traveled in the Y direction.
    let scaleT = log10(max(abs(Float(panOrigin.x - point.x)), 1.0)) + 1
    let deltaT = Float(point.y - panOrigin.y) / (Float(min(bounds.height, bounds.width)) * touchSensitivity * scaleT)
    defer { panOrigin = CGPoint(x: panOrigin.x, y: point.y) }
    let change = deltaT * (maximumValue - minimumValue)
    value += change
    updateQueue.async { self.sendAction(self.action, to: self.target) }
  }

  override open func mouseUp(with event: NSEvent) {
    activeTouch = false
    updateQueue.async { self.sendAction(self.action, to: self.target) }
  }
}

extension Knob {
  private func initialize() {
    layer = CALayer()
    wantsLayer = true

    backingLayer.drawsAsynchronously = true
    trackLayer.drawsAsynchronously = true
    progressLayer.drawsAsynchronously = true
    indicatorLayer.drawsAsynchronously = true
    ticksLayer.drawsAsynchronously = true

    trackLayer.fillColor = Color.clear.cgColor
    progressLayer.fillColor = Color.clear.cgColor
    indicatorLayer.fillColor = Color.clear.cgColor
    ticksLayer.fillColor = Color.clear.cgColor

    backingLayer.addSublayer(ticksLayer)
    backingLayer.addSublayer(trackLayer)
    backingLayer.addSublayer(progressLayer)
    backingLayer.addSublayer(indicatorLayer)

    trackLayer.lineWidth = trackLineWidth
    trackLayer.strokeColor = trackColor.cgColor
    trackLayer.lineCap = .round
    trackLayer.strokeStart = 0.0
    trackLayer.strokeEnd = 1.0

    progressLayer.lineWidth = progressLineWidth
    progressLayer.strokeColor = progressColor.cgColor
    progressLayer.lineCap = .round
    progressLayer.strokeStart = 0.0
    progressLayer.strokeEnd = 0.0

    indicatorLayer.lineWidth = indicatorLineWidth
    indicatorLayer.strokeColor = indicatorColor.cgColor
    indicatorLayer.lineCap = .round

    ticksLayer.lineWidth = tickLineWidth
    ticksLayer.strokeColor = tickLineColor.cgColor
    ticksLayer.lineCap = .round
  }

  private func createShapes() {
    createTrack()
    createIndicator()
    createTicks()
    createProgressTrack()

    draw(animated: false)
  }

  private func createRing() -> NSBezierPath {
    let ring = NSBezierPath()
    var points = [CGPoint]()
    for theta in 0...270 {
      let xPos = radius * cos(CGFloat(theta) * .pi / 180.0)
      let yPos = radius * sin(CGFloat(theta) * .pi / 180.0)
      points.append(CGPoint(x: xPos, y: yPos))
    }

    ring.appendPoints(&points, count: points.count)
    ring.apply(CGAffineTransform(rotationAngle: CGFloat.pi / 180.0 * (90 + 45)))
    return ring
  }

  private func createTrack() {
    let ring = createRing()
    trackLayer.path = ring.cgPath
  }

  private func createIndicator() {
    let indicator = NSBezierPath()
    indicator.move(to: CGPoint(x: radius, y: 0.0))
    indicator.line(to: CGPoint(x: radius * (1.0 - indicatorLineLength), y: 0.0))
    indicatorLayer.path = indicator.cgPath
  }

  private func createProgressTrack() {
    let ring = createRing()
    progressLayer.path = ring.cgPath
  }

  private func createTicks() {
    let ticks = NSBezierPath()
    for tickIndex in 0..<tickCount {
      let tick = NSBezierPath()
      let theta = angle(for: Float(tickIndex) / max(1.0, Float(tickCount - 1)))
      tick.move(to: CGPoint(x: 0.0 + radius * (1.0 - tickLineOffset), y: 0.0))
      tick.line(to: CGPoint(x: 0.0 + radius * (1.0 - tickLineLength), y: 0.0))
      tick.apply(CGAffineTransform(rotationAngle: theta))
      ticks.append(tick)
    }
    ticksLayer.path = ticks.cgPath
  }

  private func draw(animated: Bool = false) {
    if activeTouch || !animated { CATransaction.setDisableActions(true) }
    progressLayer.removeAllAnimations()
    progressLayer.strokeEnd = CGFloat((value - minimumValue) / (maximumValue - minimumValue))
    indicatorLayer.removeAllAnimations()
    indicatorLayer.transform = CATransform3DMakeRotation(angleForValue, 0, 0, 1)
  }

  private var radius: CGFloat { (min(trackLayer.bounds.width, trackLayer.bounds.height) / 2) - trackLineWidth }

  private var angleForValue: CGFloat { angle(for: (value - minimumValue) / (maximumValue - minimumValue)) }

  private func angle(for normalizedValue: Float) -> CGFloat { CGFloat(normalizedValue) * (endAngle - startAngle) + startAngle }

  private func clampedValue(_ value: Float) -> Float { min(maximumValue, max(minimumValue, value)) }
}

public extension NSBezierPath {
  func apply(_ transform: CGAffineTransform) {
    self.transform(using: AffineTransform(m11: transform.a, m12: transform.b, m21: transform.c,
                                          m22: transform.d, tX: transform.tx, tY: transform.ty))
  }

  var cgPath: CGPath {
    let path = CGMutablePath()
    var points = [CGPoint](repeating: .zero, count: 3)
    for index in 0..<elementCount {
      let type = element(at: index, associatedPoints: &points)
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
