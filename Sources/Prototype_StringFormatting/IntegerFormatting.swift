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
  var zeroDropsPrefix: Bool // true for hex in fprintf...
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
    zeroDropsPrefix: Bool = false,
    uppercase: Bool = false,
    minDigits: Int = 1, // TODO: document if prefix is zero!
    separator: SeparatorFormatting = .none
  ) {
    precondition(radix >= 0 && radix <= 36)

    self.radix = radix
    self.explicitPositiveSign = explicitPositiveSign
    self.prefix = prefix
    self.zeroDropsPrefix = zeroDropsPrefix
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

    let pre: Prefix
    if let p = prefix {
      pre = .always(p)
    } else {
      pre = .none
    }

    return IntegerFormatting(
      radix: 10,
      explicitPositiveSign: explicitPositiveSign,
      prefix: pre,
      zeroDropsPrefix: zeroDropsPrefix,
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
    minDigits: Int = 1,
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    IntegerFormatting(
      radix: 16,
      explicitPositiveSign: explicitPositiveSign,
      prefix: includePrefix ? (uppercase ? .ifNonZero("0X") : .ifNonZero("0x")) : .none,
      zeroDropsPrefix: zeroDropsPrefix,
      uppercase: uppercase,
      minDigits: minDigits,
      separator: separator)
  }

  public static var hex: IntegerFormatting { .hex() }

  public static func octal(
    explicitPositiveSign: Character? = nil,
    includeLeadingZero: Bool = false,
    zeroDropsPrefix: Bool = false,
    uppercase: Bool = false,
    minDigits: Int = 1,  // TODO: document if prefix is zero!
    separator: SeparatorFormatting = .none
  ) -> IntegerFormatting {
    IntegerFormatting(
      radix: 8,
      explicitPositiveSign: explicitPositiveSign,
      prefix: includeLeadingZero ? .leadingZero : .none,
      zeroDropsPrefix: zeroDropsPrefix,
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

