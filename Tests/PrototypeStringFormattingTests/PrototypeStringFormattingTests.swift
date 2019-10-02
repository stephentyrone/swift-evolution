import XCTest
@testable import Prototype_StringFormatting

extension FixedWidthInteger {
  var negated: Self? {
    guard case (let value, false) = Self(0).subtractingReportingOverflow(self) else { return nil }
    return value
  }
}

let positiveValues = [
  Int.min,
  Int(Int8.min),
  Int(Int16.min),
  Int(Int32.min),
  0,
  1,
  16,
  341,
  12345,
  Int(Int8.max),
  Int(Int16.max),
  Int(Int32.max),
  Int.max,
]
let testValues: Array<Int> = positiveValues + positiveValues.compactMap { $0.negated }
let uint32BitpatternValues: [UInt32] = testValues.map {
  UInt32(bitPattern: Int32(truncatingIfNeeded: $0))
}


final class Prototype_StringFormatting: XCTestCase {

  func test_fprintfEquivalency() {
    func equivalent<T: CVarArg>(_ t: T, format: String,
      file: StaticString = #file, line: UInt = #line,
      _ f: (T) -> String
    ) {
      if String(format: format, t) == f(t) { return }

      print("""
        Formatting \(t) with  \(format)
        """)

      expectEqual(String(format: format, t), f(t), file: file, line: line)
    }

    for value in uint32BitpatternValues {
      for precision in (0..<11) {
        for width in (0..<15) {
          for align in [String.Alignment.left(columns: width), .right(columns: width)] {
            let justify = align.anchor == .left ? "-" : ""

            for (includePrefix) in [false, true] {
              let hash = includePrefix ? "#" : ""

              // Hex
              for (specifier, uppercase) in [("x", false), ("X", true)] {

                let format = "%\(justify)\(hash)\(width).\(precision)\(specifier)"
                // Note: hex is considered unsigned, so no positive sign tests
                equivalent(value, format: format) { """
                  \(hex: $0, uppercase: uppercase, includePrefix: includePrefix,
                     minDigits: precision,
                     align: align)
                  """
                }

                // Special zero-fill
                if align.anchor == .right && precision == 1 && width != 0 {
                  // It seems like a 0 width, even expressed as `%00x` is
                  // interpreted as just the 0 flag.

                  let format = "%0\(hash)\(width)\(specifier)"
                  // Note: hex is considered unsigned, so no positive sign tests
                  equivalent(value, format: format) { """
                    \(hex: $0, uppercase: uppercase, includePrefix: includePrefix,
                       minDigits: (value != 0 && includePrefix) ? width - 2 : width,
                       align: align.fill("0"))
                    """
                  }
                }

              }

              // Octal
              let format = "%\(justify)\(hash)\(width).\(precision)o"
              // Note: octal is considered unsigned, so no positive sign tests
              equivalent(value, format: format) { """
                \(octal: $0, includePrefix: includePrefix,
                   minDigits: precision,
                   align: align)
                """
              }

              // Special zero-fill
              if align.anchor == .right && precision == 1 && width != 0 {
                // It seems like a 0 width, even expressed as `%00x` is
                // interpreted as just the 0 flag.

                let format = "%0\(hash)\(width)o"
                // Note: hex is considered unsigned, so no positive sign tests
                equivalent(value, format: format) { """
                  \(octal: $0, includePrefix: includePrefix,
                     minDigits: width,
                     align: align.fill("0"))
                  """
                }
              }
            }
          }
        }
      }
    }
  }

  func test_negative() {
    for value in testValues {
      expectEqual(value < 0 ? "-" : "👍", "\(hex: value, explicitPositiveSign: "👍")".first!)
      // TODO: Check moar
    }
  }
}

