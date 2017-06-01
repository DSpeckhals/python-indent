# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [1.0.3] - 2017-06-01
### Changed
- Update Travis CI configuration to latest [suggested](https://github.com/atom/ci/)) Atom package standard.
### Fixed
- Assure indentation is occurring in an editor pane. This fixed #39.

## [1.0.2] - 2017-03-15
### Fixed
- Fix scenario when an empty string is virtually anywhere in the markup and causes
any further indentation to be wrong. This fixed #35.

## [1.0.1] - 2017-03-10
### Changed
- Update name of `properlyIndent` function to just be `indent`.
- Conform to [Keep a Changelog](http://keepachangelog.com/)
- Update formatting and fixed indentation error in the README.
- Update example GIF.
- Fix test documentation formatting.
- Update license copyright.
- Update eslint, eslint-config-airbnb-base, and eslint-plugin-import to their latest versions.

### Fixed
- Fix broken package activation discovered by an Atom beta channel (1.16.0-beta0) user. This appears
to have been caused by an Atom core Babel upgrade and this package using the incorrect type of function
declaration.
- Fix incorrect indent in the rare case when an unterminated comment character occurs within a
triple-quoted string. Also add a spec that will catch any future regressions for this case. This
fixed #33.

## [1.0.0] - 2016-09-15
### Changed
- Update to ES6; functionality should be the same as 0.4.3

## [0.4.3] - 2016-03-26
### Fixed
- Fix indentation behavior when there are odd numbers of escaped single quotes within a string.
This fixed #22.

### Changed
- Update some wording in the README.
- Clean up variable names.

## [0.4.2] - 2016-03-15
### Fixed
- Don't throw error when source code is malformed. This fixed #17.

## [0.4.1] - 2016-03-01
### Fixed
- Properly indent continuing lines in a hanging indent after closing a nested bracket pair. This fixed #15.
- Improve test coverage.

## [0.4.0] - 2016-02-26
### Added
- Make indentation behave as expected in practically every scenario.

    Essentially, simple parsing is performed to keep a stack of the column-location of open brackets
    (one of [({). When an opening bracket is read, it adds to the stack indicating the column where
    the bracket is located, when a closing bracket (one of })]) is read, it pops the latest element
    (it does not do any checking to make sure the closing bracket matches the opening bracket - this
    is why it assumes the python source code is well-formed). If there is anything in the stack after
    parsing the python file up to the cursor location, then that means there is an open bracket. We can
    see what column the most recent addition to the stack was on, and then set the indent from that.

##### All improvements for this release are thanks to the incredible work of @kbrose!

## [0.3.4] - 2016-02-24
### Changed
- Major refactor to better modularize components.

### Fixed
- Whitespace after a comma in a list caused an exception. This fixed #6.

### Removed
- Fringe functionality introduced in `0.3.0` that caused newlines to not be created when text was on
the next line.

## [0.3.3] - 2016-02-11
### Changed
- Search the `scopeName` of the current grammar rather than the `packageName`. This allows the package
to scale better with all Python-based grammars. Thanks @alix-!

## [0.3.2] - 2016-02-03
### Added
- MagicPython as a supported grammar.

### Changed
- Regex for hanging indent new lines.

## [0.3.1] - 2016-02-012
### Fixed
- Bug where hanging indents were deleting one non-newline characters when a new line is created directly
after an opening parentheses, but with trailing characters.
- Make sure this package is only run with Python language files.

## [0.3.0] - 2016-02-01
### Added
- Setting for __Hanging Indent Regex__.

### Changed
- Settings that began with `fluid` to `opening delimiter`.

### Removed
- Setting for __Continuation Indent Type__. This is now automatically detected based on syntax, allowing
for both _aligned with opening delmiter_ and _hanging_ indent types at the same time.

## [0.2.0] - 2016-01-19
### Added
- Hanging indentation feature in Settings.
- Setting for number of tabs to indent.
- Further examples and improve documentation.

### Fixed
- Potential bug for `:` character when ending a fluid indentation and the character exists somewhere else
in the line (perhaps a string).

## 0.1.0 - 2016-01-18
### Added
- Fluid indent in tuples, lists, and parameters.
- Unindent to tab after fluid indented tuples, lists and parameters.

[Unreleased]: https://github.com/DSpeckhals/python-indent/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/DSpeckhals/python-indent/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/DSpeckhals/python-indent/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/DSpeckhals/python-indent/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/DSpeckhals/python-indent/compare/v0.4.3...v1.0.0
[0.4.3]: https://github.com/DSpeckhals/python-indent/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/DSpeckhals/python-indent/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/DSpeckhals/python-indent/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/DSpeckhals/python-indent/compare/v0.3.4...v0.4.0
[0.3.4]: https://github.com/DSpeckhals/python-indent/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/DSpeckhals/python-indent/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/DSpeckhals/python-indent/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/DSpeckhals/python-indent/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/DSpeckhals/python-indent/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/DSpeckhals/python-indent/compare/v0.1.0...v0.2.0
