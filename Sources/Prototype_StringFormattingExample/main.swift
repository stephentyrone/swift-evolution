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

p("\(9876543210, format: .hex(explicitPositiveSign: "👍"), align: .center(columns: 20, fill: "-"))")
// "-----👍24cb016ea-----"

p("\("Hi there", align: .left(columns: 20))!")
// "Hi there            !"

p("\(-1234567890, format: .hex(includePrefix: true, minDigits: 12), align: .right(columns: 20))")
// "     -0x0000499602d2"

p("\(-1234567890, format: .hex(minDigits: 12, separator: .every(2, "_")), align: .right(columns: 20))")
// "     -0x0000499602d2"

p("\(1234567890, format: .decimal(separator: .thousands("⌟")))")
// "1⌟234⌟567⌟890"

p("\(123.4567)")
// "123.4567"

p("\(98765, format: .hex(includePrefix: true, minDigits: 8, separator: .every(2, "_")))")
// 0x00_01_81_cd
