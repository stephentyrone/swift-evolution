extension String {
  public struct Alignment {
    // TODO: max length?

    public var minimumColumnWidth: Int
    public var anchor: CollectionBound
    public var fill: Character

    // FIXME: What about full-width and wide characters?

    public init(
      minimumColumnWidth: Int = 0,
      anchor: CollectionBound = .end,
      fill: Character = " "
    ) {
      self.minimumColumnWidth = minimumColumnWidth
      self.anchor = anchor
      self.fill = fill
    }

    public static var right: Alignment { Alignment(anchor: .end) }

    public static var left: Alignment { Alignment(anchor: .start) }

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
    copy.pad(to: align.minimumColumnWidth, using: align.fill, at: align.anchor.inverted)
    return copy
  }

  public func indented(_ columns: Int, fill: Character = " ") -> String {
    String(repeating: fill, count: columns) + self
  }
}

