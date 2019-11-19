extension Collection where SubSequence == Self {
  mutating func _eat(_ n: Int = 1) -> SubSequence {
    defer { self = self.dropFirst(n) }
    return self.prefix(n)
  }
}


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
  public enum Prefix: Equatable {
    case none
    case leadingZero
    case always(String)
    case ifNonZero(String)
  }

  var radix: Int
  var explicitPositiveSign: Character?
  var prefix: Prefix
  var uppercase: Bool
  var minDigits: Int // TODO: document if prefix is zero!
  var separator: SeparatorFormatting

  // Capitalize prefix as well?
  // Prefix counts as precision?
  // As unsigned?
  // Print prefix even for 0?
  // Thousands separator?

  public init(
    radix: Int = 10,
    explicitPositiveSign: Character? = nil,
    prefix: Prefix = .none,
    uppercase: Bool = false,
    minDigits: Int = 1, // TODO: document if prefix is zero!
    separator: SeparatorFormatting = .none
  ) {
    precondition(radix >= 0 && radix <= 36)

    self.radix = radix
    self.explicitPositiveSign = explicitPositiveSign
    self.prefix = prefix
    self.uppercase = uppercase
    self.minDigits = minDigits
    self.separator = separator
  }

  public static func decimal(
    explicitPositiveSign: Character? = nil,
    prefix: String? = nil,
    zeroDropsPrefix: Bool = false,
    uppercase: Bool = false,
    minDigits: Int = 1,
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    return IntegerFormatting(
      radix: 10,
      explicitPositiveSign: explicitPositiveSign,
      prefix: .none,
      uppercase: uppercase,
      minDigits: minDigits,
      separator: separator)
  }

  public static var decimal: IntegerFormatting { .decimal() }

  public static func hex(
    explicitPositiveSign: Character? = nil,
    includePrefix: Bool = false,
    zeroDropsPrefix: Bool = true,
    uppercase: Bool = false,
    uppercasePrefixIfUppercase: Bool = true,
    minDigits: Int = 1,
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    let pre: Prefix
    if includePrefix {
      let p = uppercasePrefixIfUppercase && uppercase ? "0X" : "0x"
      pre = zeroDropsPrefix ? .ifNonZero(p) : .always(p)
    } else {
      pre = .none
    }

    return IntegerFormatting(
      radix: 16,
      explicitPositiveSign: explicitPositiveSign,
      prefix: pre,
      uppercase: uppercase,
      minDigits: minDigits,
      separator: separator)
  }

  public static var hex: IntegerFormatting { .hex() }

  public static func octal(
    explicitPositiveSign: Character? = nil,
    includeLeadingZero: Bool = false,
    uppercase: Bool = false,
    minDigits: Int = 1,  // TODO: document if prefix is zero!
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    IntegerFormatting(
      radix: 8,
      explicitPositiveSign: explicitPositiveSign,
      prefix: includeLeadingZero ? .leadingZero : .none,
      uppercase: uppercase,
      minDigits: minDigits,
      separator: separator)
  }

//  public var dropPrefixIfZero: IntegerFormatting {
//    var copy = self
//    copy.zeroDropsPrefix = true
//    return copy
//  }

}
extension FixedWidthInteger {
  public func format<OS: TextOutputStream>(
    _ options: IntegerFormatting = IntegerFormatting(), into os: inout OS
  ) {
    if self == 0 && options.minDigits == 0 && options.prefix != .leadingZero {
      return
    }

    // Sign
    if self < 0 {
      os.write("-")
    } else if let pos = options.explicitPositiveSign {
      os.write(String(pos))
    }

    let number = String(
      self.magnitude, radix: options.radix, uppercase: options.uppercase
    ).aligned(.right(columns: options.minDigits, fill: "0"))

    // Prefix
    switch options.prefix {
    case .leadingZero where number.first != "0":
      os.write("0")
    case .always(let pre):
      os.write(pre)
    case .ifNonZero(let pre) where self != 0:
      os.write(pre)
    default: break
    }

    if let separator = options.separator.separator {
      var num = number[...]
      let spacing = options.separator.spacing
      if num.count % spacing != 0 {
        os.write(String(num._eat(number.count % options.separator.spacing)))
        if !num.isEmpty {
          os.write(String(separator))
        }
      }

      while !num.isEmpty {
        assert(num.count % options.separator.spacing == 0)
        os.write(String(num._eat(options.separator.spacing)))
        if !num.isEmpty {
          os.write(String(separator))
        }
      }
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

    // Explicit positive sign
    if let sign = explicitPositiveSign {
      // IEEE Std 1003.1-2017, flag characters:
      //   +       The result of a signed conversion shall always begin with '+' or '-'
      //   <space> If the first character of a signed conversion is not a sign or if a signed
      //           conversion results in no characters, a <space> shall be prefixed to the result

      //  Format strings only support explicit `+` or ` ` on signed conversions, which only exist
      //  on decimal numbers
      guard radix == 10 else { return nil }

      // + or <space> are the only signs supported
      guard sign == " " || sign == "+" else { return nil }

      // Only applies to signed conversions
      guard decimalSpecifier != "u" else { return nil }

      // FIXME: this isn't quite right for <space>, because it will force a space if no characters
      //        are printed

      flags.append(sign)
    }

    // Prefix
    //
    // IEEE Std 1003.1-2017, flag characters:
    //   # Specifies that the value is to be converted to an alternative form:
    //     o    Increase the precision, if and only if necessary, to force the first digit of the
    //          result to be a zero (if the value and precision are both 0, a single 0 is printed).
    //     x/X  A non-zero result shall have 0x (or 0X) prefixed to it.
    let prefixFlag: String
    switch prefix {
    case .always(_): return nil

    case .none:
      prefixFlag = ""

    case .ifNonZero(let s):
      guard radix == 16 else { return nil }
      guard s == "0X" && uppercase || s == "0x" && !uppercase else { return nil }
      prefixFlag = "#"

    case .leadingZero:
      guard radix == 8 else { return nil }
      prefixFlag = "#"
    }

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
