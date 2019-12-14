


## TODO

* Clarify the role is formatted output for developer-or-machine reading purposes
  * Not for numbers presented to an end-user in a UI context
  * E.g. log messages, tabular data files, etc.
  * Clarify we're not doing everthing one can with ICU or number formatter
* Make sure this is extensible for other specifiers, like format-as-percentage
* Float formatting
* Consider keeping default argument values off of `SwiftyStringFormatting`
  * Or, likely, even dropping the protocol altogether
* Consider making String.Alignment something for RRC
  * Does this require the notion of a default value? String wants `" "`
  * Plays better with count being element count rather than render width
  * What about SeparatorFormatting?
* Consider consolidating the formatting options structs with String.Alignment
* Add a StringFormatting+Foundation
  * Conform NumberFormatter to `FixedWidthIntegerFormatter` and `FloatingPointFormatter`
* Consider adding a notion of bidirectionality
  * Reading from formatting options
* Consider how to spin off `CollectionBound` APIs, `replaceSubrange() -> Range<Index>`, etc.
