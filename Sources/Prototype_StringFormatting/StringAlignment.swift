extension String {
  public struct Alignment {
    // TODO: max length?

    public enum Anchor {
      case left
      case right
      case center
    }

    public var minimumColumnWidth: Int
    public var anchor: Anchor
    public var fill: Character

    // FIXME: What about full-width and wide characters?

    public init(
      minimumColumnWidth: Int = 0,
      anchor: Anchor = Anchor.right,
      fill: Character = " "
    ) {
      self.minimumColumnWidth = minimumColumnWidth
      self.anchor = anchor
      self.fill = fill
    }

    public static var right: Alignment { Alignment(anchor: .right) }

    public static var left: Alignment { Alignment(anchor: .left) }

    public static var center: Alignment { Alignment(anchor: .center) }

    public static var none: Alignment { .right  }

    public static func right(
      columns: Int = 0, fill: Character = " "
    ) -> Alignment {
      Alignment.right.columns(columns).fill(fill)
    }
    public static func left(
      columns: Int = 0, fill: Character = " "
    ) -> Alignment {
      Alignment.left.columns(columns).fill(fill)
    }
    public static func center(
      columns: Int = 0, fill: Character = " "
    ) -> Alignment {
      Alignment.center.columns(columns).fill(fill)
    }

    public func columns(_ i: Int) -> Alignment {
      var result = self
      result.minimumColumnWidth = i
      return result
    }

    public func fill(_ c: Character) -> Alignment {
      var result = self
      result.fill = c
      return result
    }
  }
}

extension StringProtocol {
  public func aligned(_ align: String.Alignment) -> String {
    guard align.minimumColumnWidth > 0 else { return String(self) }

    let segmentLength = self.count
    let fillerCount = align.minimumColumnWidth - segmentLength

    guard fillerCount > 0 else { return String(self) }

    var filler = String(repeating: align.fill, count: fillerCount)
    let insertIdx: String.Index
    switch align.anchor {
    case .left:  insertIdx = filler.startIndex
    case .right: insertIdx = filler.endIndex
    case .center:
      insertIdx = filler.index(filler.startIndex, offsetBy: fillerCount / 2)
    }
    filler.insert(contentsOf: self, at: insertIdx)
    return filler
  }

  public func indented(_ columns: Int, fill: Character = " ") -> String {
    String(repeating: fill, count: columns) + self
  }
}
