// I don't know if anything in this file is worth doing.

protocol EmptyInitializable {
  init()
}

protocol Formattable: CustomStringConvertible {
  associatedtype FormattingOptions: EmptyInitializable

  func format<OS: TextOutputStream>(_: FormattingOptions, into: inout OS)
}

extension Formattable {
  public func format<OS: TextOutputStream>(
    _ options: FormattingOptions = FormattingOptions(), into: inout OS
  ) {
    self.format(options, into: &into)
  }

  public func format(_ options: FormattingOptions = FormattingOptions()) -> String {
    var result = ""
    self.format(options, into: &result)
    return result
  }
}

extension IntegerFormatting: EmptyInitializable {
  public init() { self = .decimal }
}

extension FixedWidthInteger { // : Formattable
  public typealias FormattingOptions = IntegerFormatting
  public func format(_ options: FormattingOptions = FormattingOptions()) -> String {
    var result = ""
    self.format(options, into: &result)
    return result
  }
}

extension Int: Formattable {}
// ...

