
public protocol FixedWidthIntegerFormatter {
  func format<I: FixedWidthInteger, OS: TextOutputStream>(_: I, into: inout OS)
}
extension FixedWidthIntegerFormatter {
  public func format<I: FixedWidthInteger>(_ x: I) -> String {
    var result = ""
    self.format(x, into: &result)
    return result
  }
}


