# 1.0.0 - Convert source code to ES2015
- Functionality should be the same as 0.4.3

## 0.4.3 - Escaped Single Quotes in a Triple-Quoted String
- Fix indentation behavior when there are odd numbers of escaped single quotes within a string. This fixed #22.
- Update some wording in the README.
- Clean up variable names.

## 0.4.2 - Errors on Malformed Code
- Don't throw error when source code is malformed. This fixed #17.

## 0.4.1 - Hanging Indent Continuation Fix
- Properly indent continuing lines in a hanging indent after closing a nested bracket pair. This fixed #15.
- Improve test coverage.

## 0.4.0 - Major Improvements and Fixes
##### All improvements for this release are thanks to the incredible work of @kbrose!
- Make indentation behave as expected in practically every scenario.

    Essentially, simple parsing is performed to keep a stack of the column-location of open brackets (one of [({). When an opening bracket
    is read, it adds to the stack indicating the column where the bracket is located, when a closing bracket (one of })]) is read, it pops
    the latest element (it does not do any checking to make sure the closing bracket matches the opening bracket - this is why it assumes
    the python source code is well-formed). If there is anything in the stack after parsing the python file up to the cursor location, then
    that means there is an open bracket. We can see what column the most recent addition to the stack was on, and then set the indent from that.

## 0.3.4 - Improve Hanging Indent Behavior
- Major refactor to better modularize components.
- Allow for whitespace after a comma in a list. This fixed #6.
- Remove fringe functionality introduced in `0.3.0` that caused newlines to not be created when text was on the next line.

## 0.3.3 - Support All Python-Based Grammars
- Search the `scopeName` of the current grammar rather than the `packageName`. This allows the package to scale better with all Python-based grammars. Thanks @alix-!

## 0.3.2 - Add Support for MagicPython
- Add MagicPython as a supported grammar.
- Tweak regex for hanging indent new lines.

## 0.3.1 - Tweak New Functionality
- Fix bug where hanging indents were deleting one non-newline characters when a new line is created directly after an opening parentheses, but with trailing characters.
- Make sure this package is only run with Python language files.

## 0.3.0 - Smart Decisions for Indentation Type
- Remove setting for __Continuation Indent Type__. This is now automatically detected based on syntax, allowing for both _aligned with opening delmiter_ and _hanging_ indent types at the same time.
- Add setting for __Hanging Indent Regex__.
- Rename settings that began with `fluid` to `opening delimiter`.

## 0.2.0 - New Indentation Options
- Add "hanging" indentation feature in Settings.
- For "hanging" indentation, add setting for number of tabs to indent.
- Add further examples and improve documentation.
- Fix potential bug for `:` character when ending a fluid indentation and the character exists somewhere else in the line (perhaps a string).

## 0.1.0 - Initial Release
- Fluid indent in tuples, lists, and parameters.
- Unindent to tab after fluid indented tuples, lists and parameters.
