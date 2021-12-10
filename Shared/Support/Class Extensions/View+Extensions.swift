// Copyright © 2021 Brad Howes. All rights reserved.

public extension View {
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
