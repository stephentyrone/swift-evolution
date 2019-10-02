extension Collection where SubSequence == Self {
  mutating func _eat(_ n: Int = 1) -> SubSequence {
    defer { self = self.dropFirst(n) }
    return self.prefix(n)
  }
}

public protocol SwiftyStringFormatting {
  // FIXME: Some of these, if fully defaulted, might conflict with
  // CustomStringConvertible...

  // %s, but general over anything that can be printed
  mutating func appendInterpolation<S: Sequence>(
    _ s: S,
    maxPrefixLength: Int, // Int.max by default
    align: String.Alignment // .right(columns: 0, fill: " ") by default
  ) where S.Element: CustomStringConvertible

  // %x and %X
  mutating func appendInterpolation<I: FixedWidthInteger>(
    hex: I,
    uppercase: Bool, // false by default
    includePrefix: Bool, // false by default
    minDigits: Int, // 1 by default
    explicitPositiveSign: Character?, // nil by default
    align: String.Alignment) // .right(columns: 0, fill: " ") by default

  // %o
  mutating func appendInterpolation<I: FixedWidthInteger>(
    octal: I,
    includePrefix: Bool, // false by default
    minDigits: Int, // 1 by default
    explicitPositiveSign: Character?, // nil by default
    align: String.Alignment) // .right(columns: 0, fill: " ") by default

  // %d, %i
  mutating func appendInterpolation<I: FixedWidthInteger>(
    _: I,
    thousandsSeparator: Character?, // nil by default
    minDigits: Int, // 1 by default
    explicitPositiveSign: Character?, // nil by default
    align: String.Alignment) // .right(columns: 0, fill: " ") by default

  // TODO: Consider removing this one...
  // %u
  mutating func appendInterpolation<I: FixedWidthInteger>(
    asUnsigned: I,
    thousandsSeparator: Character?, // nil by default
    minDigits: Int, // 1 by default
    align: String.Alignment) // .right(columns: 0, fill: " ") by default

  // %f, %F
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
    hex: I,
    uppercase: Bool = false,
    includePrefix: Bool = false,
    minDigits: Int = 1,
    explicitPositiveSign: Character? = nil,
    align: String.Alignment = String.Alignment()
  ) {
    appendInterpolation(
      hex: hex,
      uppercase: uppercase,
      includePrefix: includePrefix,
      minDigits: minDigits,
      explicitPositiveSign: explicitPositiveSign,
      align: align)
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    octal: I,
    includePrefix: Bool = false,
    minDigits: Int = 1,
    explicitPositiveSign: Character? = nil,
    align: String.Alignment = String.Alignment()
  ) {
    appendInterpolation(
      octal: octal,
      includePrefix: includePrefix,
      minDigits: minDigits,
      explicitPositiveSign: explicitPositiveSign,
      align: align)
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    _ value: I,
    thousandsSeparator: Character? = nil,
    minDigits: Int = 1,
    explicitPositiveSign: Character? = nil,
    align: String.Alignment = String.Alignment()
  ) {
    appendInterpolation(
      value,
      thousandsSeparator: thousandsSeparator,
      minDigits: minDigits,
      explicitPositiveSign: explicitPositiveSign,
      align: align)
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    asUnsigned: I,
    thousandsSeparator: Character? = nil,
    minDigits: Int = 1,
    align: String.Alignment = String.Alignment()
  ) {
    appendInterpolation(
      asUnsigned: asUnsigned,
      thousandsSeparator: thousandsSeparator,
      minDigits: minDigits,
      align: align)
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
    hex: I,
    uppercase: Bool,
    includePrefix: Bool,
    minDigits: Int,
    explicitPositiveSign: Character?,
    align: String.Alignment = String.Alignment()
  ) {
    let addPrefix: String? = includePrefix ? (uppercase ? "0X" : "0x") : nil

    let result = hex.format(.hex(
      explicitPositiveSign: explicitPositiveSign,
      prefix: hex == 0 ? nil : addPrefix,
      minDigits: minDigits,
      uppercase: uppercase))

    self.appendInterpolation(result.aligned(align))
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    octal: I,
    includePrefix: Bool,
    minDigits: Int,
    explicitPositiveSign: Character?,
    align: String.Alignment = String.Alignment()
  ) {
    let addPrefix: String? = includePrefix ? "0" : nil

    let result: String

    if octal == 0 && (includePrefix && minDigits == 0 || minDigits == 1) {
      result = "0"
    } else {
      result = octal.format(IntegerFormatting(
        radix: 8,
        explicitPositiveSign: explicitPositiveSign,
        prefix: addPrefix,
        minDigits: addPrefix == nil ? minDigits : minDigits - 1,
        uppercase: false))
    }

    self.appendInterpolation(result.aligned(align))
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    _ value: I,
    thousandsSeparator: Character?,
    minDigits: Int,
    explicitPositiveSign: Character?,
    align: String.Alignment
  ) {
    let valueStr = value.format(IntegerFormatting(
      explicitPositiveSign: explicitPositiveSign,
      prefix: nil,
      minDigits: minDigits,
      uppercase: false))

    guard let thousands = thousandsSeparator else {
      appendInterpolation(valueStr.aligned(align))
      return
    }

    let hasSign = value < 0 || explicitPositiveSign != nil
    let numLength = valueStr.count - (hasSign ? 1 : 0)
    var result = ""
    var scanner = valueStr[...]
    if hasSign {
      result.append(contentsOf: scanner._eat())
    }
    if numLength % 3 != 0 {
      result.append(contentsOf: scanner._eat(numLength % 3))
      if !scanner.isEmpty {
        result.append(thousands)
      }
    }
    while !scanner.isEmpty {
      result.append(contentsOf: scanner._eat(3))
      if !scanner.isEmpty {
        result.append(thousands)
      }
    }
    appendInterpolation(result.aligned(align))
  }

  public mutating func appendInterpolation<I: FixedWidthInteger>(
    asUnsigned: I,
    thousandsSeparator: Character?,
    minDigits: Int,
    align: String.Alignment
  ) {
    fatalError()

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
