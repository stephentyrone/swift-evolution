# Lift overflow arithmetic to BinaryInteger

* Proposal: [SE-0000](0000-hoist-overflow-operations.md)
* Author: [Stephen Canon](https://github.com/stephentyrone)
* Review Manager: TBD
* Status: **Pitch**
* Implementation: [apple/swift#20162](https://github.com/apple/swift/pull/20162)
* Bugs: [SR-4924](https://bugs.swift.org/browse/SR-4924)

## Introduction

When writing generic code against `BinaryInteger`, it turns out to be useful to use the 
overflow and wrapping arithmetic operations, even though some types conforming to 
`BinaryInteger` may not wrap or overflow. This proposal would move those operations 
from `FixedWidthInteger` up to `BinaryInteger` so that they are available.

## Motivation

This change is slightly counter-intuitive, but makes perfect sense semantically, and also 
enables some useful idioms:

1. Suppose we want to produce a bitmask with the low-order `n` bits set, and we know a 
priori that `n <= bitWidth` if the type is fixed-width. The natural way to write this would 
be `(1 as Self << n) - 1`, but this will trap on overflow when `n == bitWidth`. If `&-`
is available on `BinaryInteger`, we can write this as `(1 as Self << n) &- 1` and have
correct behavior for both fixed-width and arbitrary precision types.

2. There are frequently computations that we know a priori cannot overflow, and we would
like to be able to elide the overflow checks that the normal arithmetic operators would invoke
for performance reasons. When writing against `BinaryInteger`, this is currently impossible.

3. The overflow operations like `addingReportingOverflow` have the same difficulties--
having `addingReportingOverflow` defined for all `BinaryInteger` types lets us write
generic code that is otherwise very cumbersome or requires conditional implementations.

## Proposed solution

Move the following API from `FixedWidthInteger` to `BinaryInteger`:
```swift
func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool)
func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool)
func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool)
func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool)
func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool)

static func &+ (lhs: Self, rhs: Self) -> Self 
static func &+= (lhs: inout Self, rhs: Self)
static func &- (lhs: Self, rhs: Self) -> Self 
static func &-= (lhs: inout Self, rhs: Self)
static func &* (lhs: Self, rhs: Self) -> Self 
static func &*= (lhs: inout Self, rhs: Self)
```

## Detailed design

The `xxxReportingOverflow( )` functions are new protocol requriements on 
`BinaryInteger`. Default implementations are *provided but marked deprecated*:
```swift
extension BinaryInteger {
  @available(*, deprecated, message: "Concrete types must implement this operation.")
  public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
    fatalError()
  }
  ...
}
```
This means that existing code that has types that conform to `BinaryInteger` but not 
`FixedWidthInteger` will continue to work (because it does not use these operations),
but if the programmer *uses* one of these operations on such a type in a concrete context,
they will get a warning at compile time; if they use it in an algorithm generic on 
`BinaryInteger`, it would trap (the only safe result).

For types conforming to `FixedWidthInteger`, we go a step further and mark the defaulted
implementation *unavailable*:
```swift
extension FixedWidthInteger {
  @available(*, unavailable, message: "Concrete types must implement this operation.")
  public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
    fatalError()
  }
  ...
}
```
This hides the deprecated default implementation defined on `BinaryInteger`, and
maintains the current state where types conforming to `FixedWidthInteger` must 
implement these operations in order to compile.

The wrapping operators like `&+` are not customization points; they are defined in
an extension on `BinaryInteger` in terms of the `ReportingOverflow` functions. These
definitions are unchanged from the current implementations on `FixedWidthInteger`.

## Source compatibility
For types conforming to `FixedWidthInteger`, no changes are needed. Types
conforming only to `BinaryInteger` will continue to work until you attempt to use these
new functions and operators; at that point there will be a compile-time warning and run-time
error unless you implement the required functions. The expectation is that any type
conforming to `BinaryInteger` will implement these eventually, but this allows a grace
period for people to make this change.

## Effect on ABI stability

Because of the way in which protocol witnesses work, this change must be made before
ABI stability is declared if we are going to do it at all.

## Effect on API resilience

This introduces new conformances on `BinaryInteger`; the interface of standard library
concrete types is unchanged. There are no standard library types that conform to
`BinaryInteger` but not `FixedWidthInteger`, but there are some third-party types that
do so. They will need to implement the `ReportingOverflow` functions.

## Alternatives considered

Not much to speak of. The one significant alternative option would be to not make the
deprecated default implementations on `BinaryInteger` fatalError, but instead return e.g.
`(partialValue: self + other, overflow: false)`, which is the "best effort" result 
for a type that conforms to `BinaryInteger` and not `FixedWidthInteger`. This is not
guaranteed to be correct by the semantics of `BinaryInteger`, however, so `fatalError`
is safer.
