{CompositeDisposable} = require 'atom'

supportedGrammars =
  'Python': true

module.exports = PythonIndent =
  config:
    openingDelimiterIndentRegex:
      type: 'string'
      default: '^.*(\\(|\\[).*,$'
      description: 'Regular Expression for _aligned with opening delimiter_ continuation indent type, and used for determining when this type of indent should be _started_.'
    openingDelimiterUnindentRegex:
      type: 'string'
      default: '^\\s+\\S*(\\)|\\]):?$'
      description: 'Regular Expression for _aligned with opening delimiter_ continuation indent type, and used for determining when this type of indent should be _ended_.'
    hangingIndentRegex:
      type: 'string'
      default: '^.*(\\(|\\[)$'
      description: 'Regular Expression for _hanging indent_ used for determining when this type of indent should be _started_.'
    hangingIndentTabs:
      type: 'number'
      default: 1
      description: 'Number of tabs used for _hanging_ indents'
      enum: [
        1,
        2
      ]

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'editor:newline': => @properlyIndent()

    # Cache regular expressions
    @openingDelimiterIndentRegex = new RegExp(atom.config.get 'python-indent.openingDelimiterIndentRegex')
    @openingDelimiterUnindentRegex = new RegExp(atom.config.get 'python-indent.openingDelimiterUnindentRegex')
    @hangingIndentRegex = new RegExp(atom.config.get 'python-indent.hangingIndentRegex')

  deactivate: ->
    @subscriptions.dispose()

  properlyIndent: ->
    # Make sure this is a Python file
    editor = atom.workspace.getActiveTextEditor()
    return unless editor.getGrammar().name == 'Python'

    # Get base variables
    row = editor.getCursorBufferPosition().row
    previousLine = editor.buffer.lineForRow(row - 1)
    return unless row

    # Based on configuration, branch to corresponding logic
    if (matchOpeningDelimiter = PythonIndent.openingDelimiterIndentRegex.exec previousLine) isnt null
      PythonIndent.indentOnOpeningDelimiter(editor, row, previousLine, matchOpeningDelimiter)
    else if PythonIndent.hangingIndentRegex.test previousLine
      PythonIndent.indentHanging(editor, row, previousLine)
    else if PythonIndent.openingDelimiterUnindentRegex.test previousLine
      PythonIndent.unindentOnOpeningDelimiter(editor, row, previousLine)

  indentOnOpeningDelimiter: (editor, row, previousLine, matchOpeningDelimiter) ->
    # Get index of opening delimiter.
    # The indent should be one whitespace character past this (sorry, no tabs)
    indentColumn = previousLine.lastIndexOf(matchOpeningDelimiter[1]) + 1

    # Get tab length for context
    tabLength = editor.getTabLength()

    # Calculate soft-tabs from spaces (can have remainder)
    tabs = (indentColumn / tabLength) - editor.indentationForBufferRow row
    rem = indentColumn % tabLength

    # If there's a remainder, `editor.buildIndentString` requires the tab to
    # be set past the desired indentation level, thus the ceiling.
    tabs = if rem > 0 then Math.ceil tabs else tabs

    # Offset is the number of spaces to subtract from the soft-tabs if they
    # are past the desired indentation (not divisible by tab length).
    offset = if rem > 0 then tabLength - rem else 0

    # I'm glad Atom has an optional `column` param to subtract spaces from
    # soft-tabs, though I don't see it used anywhere in the core.
    indent = editor.buildIndentString(tabs, column=offset)

    # Set the indent
    editor.getBuffer().setTextInRange([[row, 0], [row, 0]], indent)

  unindentOnOpeningDelimiter: (editor, row, previousLine) ->
    # Get all preceding lines
    lines = if row > 0 then editor.buffer.lines[0..row - 1] else []

    # Loop in reverse through lines
    for line, i in lines by -1

      # Set indent for row after declaration of block
      if PythonIndent.openingDelimiterIndentRegex.test line

        # Indent one tab-level past declaration
        indent = editor.indentationForBufferRow i
        indent += 1 if previousLine.slice(-1) is ':'
        editor.setIndentationForBufferRow row, indent

        # Stop trying after success
        break

  indentHanging: (editor, row, previousLine) ->
    # Indent at the current block level plus the setting amount (1 or 2)
    indent = (editor.indentationForBufferRow row) + (atom.config.get 'python-indent.hangingIndentTabs')

    # Set the indent
    editor.transact =>
      editor.delete() if /^\s*\n$/.test editor.buffer.lineForRow(row)
      editor.setIndentationForBufferRow row, indent
