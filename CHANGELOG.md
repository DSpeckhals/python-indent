## 0.3.4 - Improve Hanging Indent Behavior
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
