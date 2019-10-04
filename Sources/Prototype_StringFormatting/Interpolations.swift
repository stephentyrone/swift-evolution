public protocol SwiftyStringFormatting {
  // FIXME: Some of these, if fully defaulted, might conflict with
  // CustomStringConvertible...

  // %s, but general over anything that can be printed
  mutating func appendInterpolation<S: Sequence>(
    _ s: S,
    maxPrefixLength: Int, // Int.max by default
    align: String.Alignment // .right(columns: 0, fill: " ") by default
  ) where S.Element: CustomStringConvertible

  // %x, %X, %o, %d, %i
  // TODO: %u?
  mutating func appendInterpolation<I: FixedWidthInteger>(
    _ value: I,
    format: IntegerFormatting, // .decimal(minDigits: 1) by default
    align: String.Alignment // .right(columns: 0, fill: " ") by default
  )

  // %f, %F
  // TODO: FloatFormatting struct
  mutating func appendInterpolation<F: FloatingPoint>(
    _ value: F,
    explicitRadix: Bool, // false by default
    precision: Int?, // nil by default
    uppercase: Bool, // false by default
    zeroFillFinite: Bool, // false by default
    minDigits: Int, // 1 by default
    explicitPositiveSign: Character?, // nil by default
    align: String.Alignment) // .right(columns: 0, fill: " ") by default

}

// Default argument values
extension SwiftyStringFormatting {
  public mutating func appendInterpolation<S: Sequence>(
    _ s: S,
    maxPrefixLength: Int = Int.max,
    align: String.Alignment = String.Alignment()
  ) where S.Element: CustomStringConvertible {
    appendInterpolation(s, maxPrefixLength: maxPrefixLength, align: align)
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    _ value: I,
    format: IntegerFormatting, // .decimal(minDigits: 1) by default
    align: String.Alignment // .right(columns: 0, fill: " ") by default
  ) {
    appendInterpolation(value, format: format, align: align)
  }

  // %f, %F
  public mutating func appendInterpolation<F: FloatingPoint>(
    _ value: F,
    explicitRadix: Bool = false,
    precision: Int? = nil,
    uppercase: Bool = false,
    zeroFillFinite: Bool = false,
    minDigits: Int = 1,
    explicitPositiveSign: Character? = nil,
    align: String.Alignment = String.Alignment()
  ) {
    appendInterpolation(
      value,
      explicitRadix: explicitRadix,
      precision: precision,
      uppercase: uppercase,
      zeroFillFinite: zeroFillFinite,
      minDigits: minDigits,
      explicitPositiveSign: explicitPositiveSign,
      align: align)
  }
}

extension DefaultStringInterpolation: SwiftyStringFormatting {

  public mutating func appendInterpolation<S: Sequence>(
    _ seq: S,
    maxPrefixLength: Int,
    align: String.Alignment = String.Alignment()
  ) where S.Element: CustomStringConvertible {
    var str = ""
    var iter = seq.makeIterator()
    var count = 0
    while let next = iter.next(), count < maxPrefixLength {
      str.append(next.description)
      count += 1
    }
    appendInterpolation(str.aligned(align))
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    _ value: I,
    format: IntegerFormatting = .decimal,
    align: String.Alignment = .right
  ) {
    appendInterpolation(value.format(format).aligned(align))
  }


  // %f, %F
  public mutating func appendInterpolation<F: FloatingPoint>(
    _ value: F,
    explicitRadix: Bool,
    precision: Int?,
    uppercase: Bool,
    zeroFillFinite: Bool,
    minDigits: Int,
    explicitPositiveSign: Character?,
    align: String.Alignment
  ) {
    let valueStr: String
    if value.isNaN {
      valueStr = uppercase ? "NAN" : "nan"
    } else if value.isInfinite {
      valueStr = uppercase ? "INF" : "inf"
    } else {
      if let dValue = value as? Double {
        valueStr = String(dValue)
      } else if let fValue = value as? Float {
        valueStr = String(fValue)
      } else {
        fatalError("TODO")
      }

      // FIXME: Precision, minDigits, radix, zeroFillFinite, ...
      guard explicitRadix == false else { fatalError() }
      guard precision == nil else { fatalError() }
      guard uppercase == false else { fatalError() }
      guard minDigits == 1 else { fatalError() }
      guard zeroFillFinite == false else { fatalError() }
      guard explicitPositiveSign == nil else { fatalError() }
    }

    appendInterpolation(valueStr.aligned(align))
  }

}
