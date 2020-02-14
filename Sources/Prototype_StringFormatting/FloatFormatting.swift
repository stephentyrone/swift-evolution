
public struct FloatFormatting: Equatable {

  // Steve: default should be Swift optimal format
  // Me: readable as a Swift literal (as a tie breaker).

  // let x = 0x1.12_32_44p0
  // Steve: prefer to normalize so it is 1.whatever
  //   don't customize this for stdlib

  // Me: don't need to be too concerned with extenswibility, packages
  // can define their own struct and interpolation overloads

  // NOTE: frpintf will read from C locale. Swift print uses dot.
  // We could consider a global var for the c locale's character.
  // OSLog will likely end up just getting C locale behavior, which
  // might be a necessary divergence
  public var radixCharacter: Character = "."

  // NOTE: Optional because we may want swift-default variable precision,
  // whereas printf default precision might be something hard coded, like 6
  //
  // NOTE: Don't just do minimal-padd-with-zeroes. Ask Steve
  //
  // Steve: Consider: precision is # of significant digits
  //
  // significant digits is radix-position-agnostic (exponent-agnostic)
  // accuracy is post-radix # of digits (non-exponential repr)
  //
  // alternatively: Int and Bool for # and relative vs absolute
  // or, it's an enum (shouldn't want both)
  //
  // accuracy can be negative to mean pre-radix?
  public var precision: Int?

  public var explicitPositiveSign: Bool // space is left to higher level, use col width

  // NOTE: `#` flag, include radix even if there are no digits after the radix character.
  // only relevant if precision is nil or zero, maybe fold into precision?
  public var includeRadix: Bool

  // f / F. TODO: separate out `e/E`? "inf / INF"? "infinity vs inf"?
  //
  // Me: we are not interested in capital-X
  //
  // Tim: infinity needs to be a customizable String
  //   nan too, signaling too,
  //
  // NO nan PAYLOAD
  //
  public var uppercase: Bool

  // TODO: Look at Google's "double precision" library...
  // TODO: Consider constant strings for inf/nan/exponent, ...

  // TODO: Pad with leading zeroes. Does a "min digits" make sense here? Counting radix?

  public enum Notation {
    case decimal // %f
    case exponential // %e
    case optimal // Swift default, for logging it's %g
    case hex // an exponential, base-16 format
  }

  // TODO: does printing preserve sign of zero? YES

  // Steve: default is round-trippable, shortest, "optimal" form

  // TODO: Brainstorm on whiteboard float literals

}

extension FloatFormatting {
  // @_compilerEvaluable
  public func toFormatString<I: FloatingPoint>(
    _ align: String.Alignment = .none, for type: I.Type
  ) -> String? {
    fatalError()
  }
}
