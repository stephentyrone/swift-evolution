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

// NOTE: If these are all OffsetBound, then that would also work and actually generalize it a
// little bit... OR, maybe we define a CollectionBoundExpression to be what OffsetBound tried
// to be...

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
  // TODO: Align/justify version, which just swaps the bound?
}


// Intersperse
extension Collection where SubSequence == Self {
  internal mutating func _eat(_ n: Int = 1) -> SubSequence {
    defer { self = self.dropFirst(n) }
    return self.prefix(n)
  }
}

extension RangeReplaceableCollection {
  // TODO: Needs a new replaceSubrange hook that returns the new range for efficiency
  // pitch the customization hook on its own, default behavior does the count thing
  //
  public mutating func intersperse(
    _ newElement: Element, every n: Int, startingFrom bound: CollectionBound
  ) {
    self.intersperse(contentsOf: CollectionOfOne(newElement), every: n, startingFrom: bound)
  }

  public mutating func intersperse<C: Collection>(
    contentsOf newElements : C, every n: Int, startingFrom bound: CollectionBound
  ) where C.Element == Element {
    precondition(n > 0)

    let currentCount = self.count
    guard currentCount > n else { return }

    let remainder = currentCount % n

    let newCount = currentCount + currentCount / n - (remainder == 0 ? 1 : 0)
    var result = Self()
    result.reserveCapacity(newCount)

    var selfConsumer = self[...]

    // Handle any prefix stragglers
    if remainder != 0 && bound == .end {
      result.append(contentsOf: selfConsumer._eat(remainder))
      assert(!selfConsumer.isEmpty, "Guarded count above")
      result.append(contentsOf: newElements)
    }
    while !selfConsumer.isEmpty {
      result.append(contentsOf: selfConsumer._eat(n))
      if !selfConsumer.isEmpty {
        result.append(contentsOf: newElements)
      }
    }
    self = result  }
}
