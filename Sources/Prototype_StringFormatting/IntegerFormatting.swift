


public struct SeparatorFormatting {
  public var separator: Character?
  public var spacing: Int

  public init(separator: Character? = nil, spacing: Int = 3) {
    self.separator = separator
    self.spacing = spacing
  }

  public static var none: SeparatorFormatting {
    SeparatorFormatting()
  }

  public static func every(_ n: Int, _ separator: Character = ",") -> SeparatorFormatting {
    SeparatorFormatting(separator: separator, spacing: n)
  }

  public static func thousands(_ separator: Character = ",") -> SeparatorFormatting {
    .every(3, separator)
  }
  public static var thousands: SeparatorFormatting { .thousands() }

}

public struct IntegerFormatting {
  var radix: Int
  var explicitPositiveSign: Bool
  var includePrefix: Bool
  var uppercase: Bool
  var minDigits: Int
  var separator: SeparatorFormatting

  public init(
    radix: Int = 10,
    explicitPositiveSign: Bool = false,
    includePrefix: Bool = false,
    uppercase: Bool = false,
    minDigits: Int = 1,
    separator: SeparatorFormatting = .none
  ) {
    precondition(radix >= 0 && radix <= 36)

    self.radix = radix
    self.explicitPositiveSign = explicitPositiveSign
    self.includePrefix = includePrefix
    self.uppercase = uppercase
    self.minDigits = minDigits
    self.separator = separator
  }

  public static func decimal(
    explicitPositiveSign: Bool = false,
    minDigits: Int = 1,
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    return IntegerFormatting(
      radix: 10,
      explicitPositiveSign: explicitPositiveSign,
      minDigits: minDigits,
      separator: separator)
  }

  public static var decimal: IntegerFormatting { .decimal() }

  public static func hex(
    explicitPositiveSign: Bool = false,
    includePrefix: Bool = false,
    uppercase: Bool = false,
    minDigits: Int = 1,
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    return IntegerFormatting(
      radix: 16,
      explicitPositiveSign: explicitPositiveSign,
      includePrefix: includePrefix,
      uppercase: uppercase,
      minDigits: minDigits,
      separator: separator)
  }

  public static var hex: IntegerFormatting { .hex() }

  public static func octal(
    explicitPositiveSign: Bool = false,
    includePrefix: Bool = false,
    uppercase: Bool = false,
    minDigits: Int = 1,  // TODO: document if prefix is zero!
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    IntegerFormatting(
      radix: 8,
      explicitPositiveSign: explicitPositiveSign,
      includePrefix: includePrefix,
      uppercase: uppercase,
      minDigits: minDigits,
      separator: separator)
  }
}

extension IntegerFormatting {
  // On Prefixes
  //
  // `fprintf` has oddball prefix behaviors.
  //   * We want signed and unsigned prefixes (former cannot be easily emulated)
  //   * The precision-adjusting octal prefix won't be missed.
  //     * Nor the special case for minDigits == 0
  //   * We want a hexadecimal prefix to be printed if requested, even for the value 0.
  //   * We don't want to conflate prefix capitalization with hex-digit capitalization.
  //   * A binary prefix for radix 2 is nice to have
  //
  // Instead, we go with Swift literal syntax. If a prefix is requested, and radix is:
  //   2: "0b1010"
  //   8: "0o1234"
  //  16: "0x89ab"
  //
  // This can be sensibly emulated using `fprintf` for unsigned types by just adding it before the
  // specifier.
  fileprivate var _prefix: String {
    guard includePrefix else { return "" }
    switch radix {
    case 2: return "0b"
    case 8: return "0o"
    case 16: return "0x"
    default: return ""
    }
  }
}

extension FixedWidthInteger {
  // TODO: Is this interface essential? Should we take an alignment struct?
  public func format<OS: TextOutputStream>(
    _ options: IntegerFormatting = IntegerFormatting(), into os: inout OS
  ) {
    if self == 0 && options.minDigits == 0 {
      return
    }

    // Sign
    if self < 0 {
      os.write("-")
    } else if options.explicitPositiveSign {
      os.write("+")
    }

    // Prefix
    os.write(options._prefix)

    // Digits
    let number = String(
      self.magnitude, radix: options.radix, uppercase: options.uppercase
    ).aligned(.right(columns: options.minDigits, fill: "0"))

    if let separator = options.separator.separator {
      var num = number
      num.intersperse(separator, every: options.separator.spacing, startingFrom: .end)
      os.write(num)
    } else {
      os.write(number)
    }
  }
}

extension IntegerFormatting {

  // Returns the length modifier and which decimal (signed vs unsigned) specifier to use
  //
  // @_compilerEvaluable
  /*private*/ public // for testing
  static func inspectType<I: FixedWidthInteger>(
    _ type: I.Type
  ) -> (lengthModifier: String, decimalSpecifier: Character)? { // TODO: better name
    // IEEE Std 1003.1-2017, length modifiers:

    switch type {
    //   hh - d, i, o, u, x, or X conversion specifier applies to (signed|unsigned) char
    case is CChar.Type: return ("hh", "d")
    case is CUnsignedChar.Type: return ("hh", "u")

    //   h  - d, i, o, u, x, or X conversion specifier applies to (signed|unsigned) short
    case is CShort.Type: return ("h", "d")
    case is CUnsignedShort.Type: return ("h", "u")

    case is CInt.Type: return ("", "d")
    case is CUnsignedInt.Type: return ("", "u")

    //   l  - d, i, o, u, x, or X conversion specifier applies to (signed|unsigned) long
    case is CLong.Type: return ("l", "d")
    case is CUnsignedLong.Type: return ("l", "u")

    //   ll - d, i, o, u, x, or X conversion specifier applies to (signed|unsigned) long long
    case is CLongLong.Type: return ("ll", "d")

    case is CUnsignedLongLong.Type: return ("ll", "u")

    default: return nil
    }
  }

  // @_compilerEvaluable
  public func toFormatString<I: FixedWidthInteger>(
    _ align: String.Alignment = .none, for type: I.Type
  ) -> String? {
    // Based on IEEE Std 1003.1-2017

    // Length modifier and which signed specifier to use if decimal
    guard let (lengthMod, decimalSpecifier) = IntegerFormatting.inspectType(type) else {
      return nil
    }

    var flags = ""

//    // Explicit positive sign
//    if let sign = explicitPositiveSign {
//      // IEEE Std 1003.1-2017, flag characters:
//      //   +       The result of a signed conversion shall always begin with '+' or '-'
//      //   <space> If the first character of a signed conversion is not a sign or if a signed
//      //           conversion results in no characters, a <space> shall be prefixed to the result
//
//      //  Format strings only support explicit `+` or ` ` on signed conversions, which only exist
//      //  on decimal numbers
//      guard radix == 10 else { return nil }
//
//      // + or <space> are the only signs supported
//      guard sign == " " || sign == "+" else { return nil }
//
//      // Only applies to signed conversions
//      guard decimalSpecifier != "u" else { return nil }
//
//      // FIXME: this isn't quite right for <space>, because it will force a space if no characters
//      //        are printed
//
//      flags.append(sign)
//    }
//
//    // Prefix
//    //
//    // IEEE Std 1003.1-2017, flag characters:
//    //   # Specifies that the value is to be converted to an alternative form:
//    //     o    Increase the precision, if and only if necessary, to force the first digit of the
//    //          result to be a zero (if the value and precision are both 0, a single 0 is printed).
//    //     x/X  A non-zero result shall have 0x (or 0X) prefixed to it.
//    let prefixFlag: String
//    switch prefix {
//    case .always(_): return nil
//
//    case .none:
//      prefixFlag = ""
//
//    case .ifNonZero(let s):
//      guard radix == 16 else { return nil }
//      guard s == "0X" && uppercase || s == "0x" && !uppercase else { return nil }
//      prefixFlag = "#"
//
//    case .leadingZero:
//      guard radix == 8 else { return nil }
//      prefixFlag = "#"
//    }

    // Pick the specifier
    let specifier: Character
    switch radix {
    case 16:
      specifier = uppercase ? "X" : "x"
    case 10:
      specifier = decimalSpecifier
    case 8:
      specifier = "o"
    default: return nil
    }

    fatalError()
  }
}
