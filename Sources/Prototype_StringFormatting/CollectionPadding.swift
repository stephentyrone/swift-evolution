//public enum AlignmentAnchor {
//  case left
//  case right
//  case center // Do we want this?
//}
//
//extension RangeReplaceableCollection {
//  // TODO: Should we do something more like String.Alignment?
//  // TODO: Should we anchor where we want content to be or padding to be?
//  public mutating func pad(to newCount: Int, using fill: Element, align: AlignmentAnchor = .left) {
//    guard newCount > 0 else { return }
//
//    let currentCount = self.count
//    guard newCount > currentCount else { return }
//
//    var filler = Self(repeating: fill, count: newCount - currentCount)
//    let insertIdx: Index
//    switch align {
//    case .left:  insertIdx = filler.startIndex
//    case .right: insertIdx = filler.endIndex
//    case .center:
//      insertIdx = filler.index(filler.startIndex, offsetBy: currentCount / 2)
//    }
//    filler.insert(contentsOf: self, at: insertIdx)
//    self = filler
//  }
//}
//

@frozen
public enum CollectionBound {
  case start
  case end
}
extension CollectionBound {
  public var inverted: CollectionBound { self == .start ? .end : .start }
}

extension RangeReplaceableCollection {
  public mutating func pad(
    to newCount: Int, using fill: Self.Element, at bound: CollectionBound = .end
  ) {
    guard newCount > 0 else { return }

    let currentCount = self.count
    guard newCount > currentCount else { return }

    let filler = repeatElement(fill, count: newCount &- currentCount)
    let insertIdx = bound == .start ? self.startIndex : self.endIndex
    self.insert(contentsOf: filler, at: insertIdx)
  }
}
