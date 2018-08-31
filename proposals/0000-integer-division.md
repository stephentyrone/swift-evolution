# Division revision

* Proposal: [SE-NNNN](NNNN-integer-division.md)
* Authors: [Stephen Canon](https://github.com/stephentyrone)
* Review Manager: TBD
* Status: **Awaiting Review**

*During the review process, add the following fields as needed:*

* Implementation: [apple/swift#NNNNN](https://github.com/apple/swift/pull/NNNNN)

## Introduction

Like the majority of programming languages, Swift uses "truncating division". This proposal
would add APIs with explicit control of rounding in division, which is generally useful, as well
as a new `mod` function that makes the commonsense behavior of modular arithmetic
somewhat easier to achieve.

Swift-evolution threads:
['Double modulo' operator](https://forums.swift.org/t/double-modulo-operator/2718)
[Even and Odd Integers](https://forums.swift.org/t/even-and-odd-integers/11774)

## Motivation

Integer division is defined by the equation
~~~~
a = qb + r
~~~~
where `q` is the *quotient* `a/b` and `r` is the *remainder* `a%b`, with the additional
requirement that `|r|` < `|b|`. When `r` is non-zero, this rule does not suffice to fully
determine `q` and `r`. For example, if `a = 3` and `b = 2`, then we could have
`3 = 1*2 + 1` or `3 = 2*2 - 1`, so `(1,1)` and `(2,-1)` are both satisfactory `(q,r)` pairs.

In order to define the division and remainder operations it is necessary to choose a *rounding
rule* that specifies how such non-exact quotients are to be handled. The Swift `/` and `%`
operators match the behavior of C, C++, C#, D, Go, Java, Julia, Kotlin, and most other
languages in rounding the quotient `q` *towards zero* (also called "truncating division"). This
is equivalent to adding the requirement that the sign of `r` matches the sign of `b`.

However, other rounding rules are possible, and even desireable. Knuth [TAoCP, Vol. 1] argues
for "flooring division", where the quotient is always rounded *down* (towards minus infinity).
This has the desirable property that the sign of the remainder matches the sign of the
divisor. Why is this property desirable? Frequently when we use the remainder operator, we
have a constant positive divisor. E.g. consider a much-discussed check to see if a number is
odd:
```swift
func isOdd(x: Int) -> Bool {
  x % 2 == 1
}
```
If you followed the "Even and Odd Integers" thread on Swift-Evolution, you already know this,
but this implementation has a bug! Consider what happens when `x == -1`: because Swift 
uses truncating division, `-1/2 = 0` and `-1%2 = -1`, so the test returns `false`. If we used
flooring division instead, we would not have this problem, because the remainder will always
be in the set {0, 1}--0 if the number is even, and 1 if it is odd.

Division that rounds up is another common use case, especially when working with sizes.
How many `UInt` words are required to store a `n`-bit integer? In the standard lib, this appears
in one place as follows:
```swift
let (quotient, remainder) = bitWidth.quotientAndRemainder(
  dividingBy: UInt64.bitWidth
)
for i in 0 ..< quotient + remainder.signum() {
```
if we can make division round up, this can be made much simpler:
```swift
for i in 0 ..< bitWidth.divided(by: UInt64.bitWidth, rounding: .up)
```
Even rounding to nearest has a use--it comes up when implementing decimal floating-point
arithmetic using integer operations.

## Proposed solution

- Rename `FloatingPointRoundingRule` to `RoundingRule`.

- Provide new divide functions, or extend existing functions where possible, to take an 
optional `RoundingRule` parameter to control the rounding direction for the quotient.

- Provide a simple affordance specifically for the mathematical modulo operation (distinct
from the remainder operation `%`).

- Provide a new `shiftedRight`  function with rounding control, specifically for the extremely
common case of division by known powers of two. This is needed for implementing
software backed floating-point (like generic conversions from integer to floating-point), but
is also exceedingly useful for implementing a number of integer arithmetic operations, and is
found in most bignum libraries.

## Detailed design

On the  `BinaryInteger` protocol, add the following three functions:
```swift
/// Divides this value by `divisor`, rounding the result according to
/// `rule` to produce `quotient` and `remainder`.
///
/// For every value of `self`, and `divisor`, the following constraints
/// are satisfied by the results.
///
/// - self == quotient*divisor + remainder
/// - 0 <= remainder.magnitude && remainder.magnitude < divisor.magnitude
///
/// If these constraints cannot be satisfied, a trap occurs. These
/// constraints do not fully specify the behavior of the function; for
/// most values of `self` and `divisor`, there are two possible result
/// pairs that we must select between.
///
/// Let ratio be the real number self/divisor. This real number is rounded
/// to the integer quotient following the specified rounding rule, and the
/// remainder is determined by self - quotient*divisor.
///
/// A few rounding rules are worth calling out specifically:
///
/// - `.towardZero` matches the behavior of the `/` and `%` operators in
///   Swift and C-family languages. This is sometimes called "truncating
///   division".
///
/// - `.down` is sometimes called "floored" or "flooring" division. This
///   matches the behavior of most languages that doe not use truncating
///   division. It has the nice property that the sign of the remainder
///   always matches the sign of the divisor (in particular, in the
///   common case of a positive divisor, the remainder is always
///   contained in `0..<divisor`.
///
/// - `.up` and `.awayFromZero` are used with sizes and counts, where you
///   want to round the quotient to a larger value if the remainder is
///   nonzero.
///
/// - .towardNearestOrEven and .towardNearestOrAwayFromZero are used with
///   integers when you want to select the result with the smallest-
///   magnitude remainder, but are also useful for implementing and 
///   emulating floating- point arithmetic in integer.
///
/// - Parameters:
///   - divisor: the value by which to divide.
///   - rule: the `RoundingRule` describing how to select the result.
///
/// - Returns: the quotient and remainder.
///
/// See also `mod(_:)`.
func divided(by: Self, rounding: RoundingRule = .towardZero)
  -> (quotient: Self, remainder: Self)

/// The mathematical modulo operation.
///
/// This operation is similar to the `%` operator and the `remainder`
/// result of the `.divided(by:, rounding:)` function, but differs
/// importantly in how it handles negative numbers. The `modulus` must
/// be positive, and the result is always non-negative, even if `self`
/// is negative.
///
/// - Parameter modulus: must be positive.
/// - Returns: the unique integer in `0 ..< modulus` that satisfies
///   `self = n*modulus + result` for some integer `n`.
///
/// See also `divided(by:, rounding:)`.
func mod(_ modulus: Self) -> Self

/// Shifts this value right by n, rounding according to the specified
/// rounding rule.
///
/// - Parameters:
///   - n: The number of bits to shift by. Must be non-negative.
///   - rule: The direction in which to round the result if it is not
///     exact.
/// - Returns: the pair `(rounded: Self, isExact: Bool)`, where `rounded`
///   is `self*2**(-n)` rounded to the nearest integer, and `isExact` is
///   true if and only if the result of the shift was an integer before
///   rounding.
///
/// See also `divided(by:, rounding:)`.
func shiftedRight<Count>(
  by: Count,
  rounding: RoundingRule = .down
) -> (result: Self, isExact: Bool) where Count : BinaryInteger
```
and deprecate the existing `quotientAndRemainder(dividingBy:)` function.

On the `FixedWidthInteger` protocol, add the following function:
```swift
func dividedReportingOverflow(by: Self, rounding: RoundingRule = .towardZero)
  -> (quotient: Self, remainder: Self, overflow: Bool)
```
add the `rounding:` param to `dividingFullWidth`:
```swift
func dividingFullWidth(
  _: (high: Self, low: Self.Magnitude),
  rounding: RoundingRule = .towardZero
) -> (quotient: Self, remainder: Self)
```
and deprecate the existing `dividedReportingOverflow(by:)` and `remainderReportingOverflow(dividingBy:)` functions.

Some notes:
`quotientAndRemainder` is less discoverable than `divded`--it requires knowing the semi-
arcane technical names for these things, and we want this operation to be easy to find.

There are two common things that people try to do with the `%` operator. One is test 
divisibility, which is already addressed by the new `isMultiple(of: )` function. The other
is getting the residue mod some positive value. The new `mod`  function exists to cover the
second use, so that users don't need to write out:
```swift
x.divided(by: 7, rounding: .down).remainder
```
and can instead use
```swift
x.mod(7)
```
The restriction that the modulus be positive avoids any confusion with rounding rules; the two
reasonable candidates, flooring and euclidean division, agree in this case.

## Source compatibility

Existing users of `quotientAndRemainder`, `dividedReportingOverflow`, and
`remainderReportingOverflow` will get deprecation warnings together with migration help.

The proposal currently would change the behavior of `dividingFullWidth` without a
rounding-mode specified to round *down* instead of *toward zero*. This is technically a
breaking change. Mitigating this: this function is rarely used, and even more rarely used
with negative numbers (which is when this change matters). For most uses, the new result
will be at least as useful--if not more useful--than the old result. But this is still something
to consider carefully, and from which we might want to back off.

## Effect on ABI stability

Deprecates and renames a few existing functions, and adds a parameter (with default value)
to some others.

## Alternatives considered

1. "Euclidean division" (remainder is always >= 0) has been requested by a few people on the 
forums threads. It does not map well to the proposed new interfaces because it cannot
really be described as a rounding rule on the quotient. I understand why people would like to
have it, but:

- Most people think of division primarily in terms of the quotient, and the remainder is a
secondary thing. Euclidean division is defined solely by the remainder, which makes the rules
for picking the quotient somewhat counter-intuitive.

- All of the examples that have been cited arguing for Euclidean division are also satisfied by
flooring division because the divisor is known to be positive.

2. Changing the behavior of the `/` and `%` operators to round `.down`, and using that as the
default rounding mode for these new functions as well.

- In a perfect world where this was  Swift 1.0 *and* most users were not migrating from
C-family languages, this would be almost a no-brainer. It really is a better definition of
division (largely because the sign of the dividend is changed much more often than the 
sign of the divisor in real use, and because it matches shifts for signed values which allows 
for better optimization with constant powers-of-two. (Note to future implementors of new
standard libraries and languages: adopt flooring division while you can)

- It's a tough sell for Swift today. That said, Python changed the behavior of `/` far more
dramatically in 3.0, and the sky did not fall. Furthermore, using these operators with negative
values and caring about the precise rounding turns out to be pretty rare, as evidenced by the
fact that most people are blissfully ignorant of the variantion between languages until this
bites them.

3. Naming `shiftedRight` something like `divided(byTwoToThe:)` and returning a
quotient and remainder instead. The different name is intended to aid discoverability, and to
help communicate that this is a much more efficient operation. In my use of this operation,
I've never needed the remainder, and simply returning `isExact` can be slightly more efficient
in bignum contexts.

4. Supporting negative shift counts. This could be easily added, at the cost of an extra branch
that the optimizer will need to strip away in most use cases. I think I would prefer to have code
explicitly add that branch where necessary, rather than the optimizer needing to do
range analysis to remove it all the time.
