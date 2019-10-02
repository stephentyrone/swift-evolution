import Prototype_StringFormatting

func p<C: Collection>(
  _ s: C, line: Int = #line, indent: Int = 2
) where C.Element == Character {
  print("\(line): \(s)".indented(indent))
}

print("Examples:")

p("\(hex: 54321)")
// "d431"

p("\(hex: 54321, uppercase: true)")
// "D431"

p("\(hex: 1234567890, includePrefix: true, minDigits: 12, align: .right(columns: 20))")
// "      0x0000499602d2"

p("\(hex: 9876543210, explicitPositiveSign: "👍", align: .center(columns: 20, fill: "-"))")
// "-----👍24cb016ea-----"

p("\("Hi there", align: .left(columns: 20))!")
// "Hi there            !"

p("\(hex: -1234567890, includePrefix: true, minDigits: 12, align: .right(columns: 20))")
// "     -0x0000499602d2"

p("\(1234567890, thousandsSeparator: "⌟")")
// "1⌟234⌟567⌟890"

p("\(123.4567)")
// "123.4567"
