import Prototype_StringFormatting

func p<C: Collection>(
  _ s: C, line: Int = #line, indent: Int = 2
) where C.Element == Character {
  print("\(line): \(s)".indented(indent))
}

print("Examples:")

p("\(54321, format: .hex)")
// "d431"

p("\(54321, format: .hex(uppercase: true))")
// "D431"

p("\(1234567890, format: .hex(includePrefix: true, minDigits: 12), align: .right(columns: 20))")
// "      0x0000499602d2"

p("\(9876543210, format: .hex(explicitPositiveSign: true), align: .right(columns: 20, fill: "-"))")
// "----------+24cb016ea"

p("\("Hi there", align: .left(columns: 20))!")
// "Hi there            !"

p("\(-1234567890, format: .hex(includePrefix: true, minDigits: 12), align: .right(columns: 20))")
// "     -0x0000499602d2"

p("\(-1234567890, format: .hex(minDigits: 12, separator: .every(2, "_")), align: .right(columns: 20))")
// "     -00_00_49_96_02_d2"

p("\(1234567890, format: .decimal(separator: .thousands("⌟")))")
// "1⌟234⌟567⌟890"

p("\(123.4567)")
// "123.4567"

p("\(98765, format: .hex(includePrefix: true, minDigits: 8, separator: .every(2, "_")))")
// 0x00_01_81_cd

p("\(12345, format: .hex(minDigits: 5))")

import Foundation
p("")
p(String(format: "%x", 12345))
p(String(format: "%+x", 12345))
p(String(format: "% x", 12345))
p(String(format: "%d", 12345))
p(String(format: "%+d", 12345))
p(String(format: "% d", 12345))

print(IntegerFormatting.inspectType(UInt8.self))
print(IntegerFormatting.inspectType(Int8.self))
print(IntegerFormatting.inspectType(Int32.self))
print(IntegerFormatting.inspectType(Int.self))
print(IntegerFormatting.inspectType(Int64.self))
print(IntegerFormatting.inspectType(UInt64.self))

struct BigInt: FixedWidthInteger {
  init<T>(_ source: T) where T : BinaryInteger { fatalError() }
  var magnitude: UInt { fatalError() }
  static var isSigned: Bool { fatalError() }
  var words: CollectionOfOne<UInt> { fatalError() }
  var trailingZeroBitCount: Int { fatalError() }
  static func / (lhs: BigInt, rhs: BigInt) -> BigInt { fatalError() }
  static func /= (lhs: inout BigInt, rhs: BigInt) { fatalError() }
  static func % (lhs: BigInt, rhs: BigInt) -> BigInt { fatalError() }
  static func %= (lhs: inout BigInt, rhs: BigInt) { fatalError() }
  static func &= (lhs: inout BigInt, rhs: BigInt) { fatalError() }
  static func |= (lhs: inout BigInt, rhs: BigInt) { fatalError() }
  static func ^= (lhs: inout BigInt, rhs: BigInt) { fatalError() }
  static func - (lhs: BigInt, rhs: BigInt) -> BigInt { fatalError() }
  init?<T>(exactly source: T) where T : BinaryInteger { fatalError() }
  init<T>(_truncatingBits source: T) where T : BinaryInteger { fatalError() }
  static func * (lhs: BigInt, rhs: BigInt) -> BigInt { fatalError() }
  static func *= (lhs: inout BigInt, rhs: BigInt) { fatalError() }
  static func += (lhs: inout BigInt, rhs: BigInt) { fatalError() }
  init(integerLiteral value: Int) { fatalError() }
  static var bitWidth: Int { fatalError() }
  static var max: BigInt { fatalError() }
  static var min: BigInt { fatalError() }
  func addingReportingOverflow(_ rhs: BigInt) -> (partialValue: BigInt, overflow: Bool) {
    fatalError()
  }
  func subtractingReportingOverflow(_ rhs: BigInt) -> (partialValue: BigInt, overflow: Bool) {
    fatalError()
  }
  func multipliedReportingOverflow(by rhs: BigInt) -> (partialValue: BigInt, overflow: Bool) {
    fatalError()
  }
  func dividedReportingOverflow(by rhs: BigInt) -> (partialValue: BigInt, overflow: Bool) {
    fatalError()
  }
  func remainderReportingOverflow(
    dividingBy rhs: BigInt
  ) -> (partialValue: BigInt, overflow: Bool) { fatalError() }
  func multipliedFullWidth(by other: BigInt) -> (high: BigInt, low: BigInt.Magnitude) {
    fatalError()
  }
  func dividingFullWidth(
    _ dividend: (high: BigInt, low: BigInt.Magnitude)
  ) -> (quotient: BigInt, remainder: BigInt) { fatalError() }
  var nonzeroBitCount: Int { fatalError() }
  var leadingZeroBitCount: Int { fatalError() }
  var byteSwapped: BigInt { fatalError() }
  static func + (lhs: BigInt, rhs: BigInt) -> BigInt { fatalError() }
  static func -= (lhs: inout BigInt, rhs: BigInt) { fatalError() }
}

print(IntegerFormatting.inspectType(BigInt.self))

