// Copyright © 2020 Brad Howes. All rights reserved.

public extension View {
  /**
   Add layout constraints such that the edges of this view extend to those of the enclosing view.
   */
  func pinToSuperviewEdges() {
    guard let superview = superview else { return }
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: superview.topAnchor),
      leadingAnchor.constraint(equalTo: superview.leadingAnchor),
      bottomAnchor.constraint(equalTo: superview.bottomAnchor),
      trailingAnchor.constraint(equalTo: superview.trailingAnchor)
    ])
  }
}
