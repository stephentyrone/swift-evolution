import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Prototype_StringFormatting.allTests),
    ]
}
#endif
