
public struct IntegerFormatting {
  let radix: Int
  let explicitPositiveSign: Character?
  let prefix: String?
  let minDigits: Int
  let uppercase: Bool

  // Capitalize numbers
  // Capitalize prefix
  // Prefix counts as precision?
  // As unsigned?
  // Print prefix even for 0?

  public init(
    radix: Int = 10,
    explicitPositiveSign: Character? = nil,
    prefix: String? = nil,
    minDigits: Int = 1,
    uppercase: Bool = false
  ) {
    precondition(radix >= 0 && radix <= 36)

    self.radix = radix
    self.explicitPositiveSign = explicitPositiveSign
    self.prefix = prefix
    self.minDigits = minDigits
    self.uppercase = uppercase
  }

  public static func hex(
    explicitPositiveSign: Character? = nil,
    prefix: String? = nil,
    minDigits: Int = 1,
    uppercase: Bool = false
  ) -> IntegerFormatting {
    IntegerFormatting(
      radix: 16,
      explicitPositiveSign: explicitPositiveSign,
      prefix: prefix,
      minDigits: minDigits,
      uppercase: uppercase)
  }

  public static func minDigits(
    _ i: Int,
    radix: Int = 10,
    explicitPositiveSign: Character? = nil,
    prefix: String? = nil,
    uppercase: Bool = false
  ) -> IntegerFormatting {
    IntegerFormatting(
      radix: radix,
      explicitPositiveSign: explicitPositiveSign,
      prefix: prefix,
      minDigits: i,
      uppercase: uppercase)
  }
}
extension FixedWidthInteger {
  public func format(_ options: IntegerFormatting = IntegerFormatting()) -> String {
    var result = ""
    self.format(options, into: &result)
    return result
  }

  public func format<OS: TextOutputStream>(
    _ options: IntegerFormatting = IntegerFormatting(), into os: inout OS
  ) {
    if self == 0 && options.minDigits == 0 { return }

    // TODO: Better to write directly into the stream
    let number = String(
      self.magnitude, radix: options.radix, uppercase: options.uppercase
    ).aligned(.right(columns: options.minDigits, fill: "0"))

    let sign: String
    if self < 0 {
      sign = "-"
    } else if let pos = options.explicitPositiveSign {
      sign = String(pos)
    } else {
      sign = ""
    }

    os.write(sign)
    os.write(options.prefix ?? "")
    os.write(number)
  }
}

