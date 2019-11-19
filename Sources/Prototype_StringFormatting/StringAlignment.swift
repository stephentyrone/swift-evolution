extension String {
  public struct Alignment {
    // TODO: max length?

    public var minimumColumnWidth: Int
    public var anchor: AlignmentAnchor
    public var fill: Character

    // FIXME: What about full-width and wide characters?

    public init(
      minimumColumnWidth: Int = 0,
      anchor: AlignmentAnchor = .right,
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
    var copy = String(self)
    copy.pad(to: align.minimumColumnWidth, using: align.fill, align: align.anchor)
    return copy
  }

  public func indented(_ columns: Int, fill: Character = " ") -> String {
    String(repeating: fill, count: columns) + self
  }
}

