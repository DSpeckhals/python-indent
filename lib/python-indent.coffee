module.exports =
class PythonIndent
  constructor: ->
    # Cache settings
    @openingDelimiterIndentRegex = new RegExp(atom.config.get 'python-indent.openingDelimiterIndentRegex')
    @openingDelimiterUnindentRegex = new RegExp(atom.config.get 'python-indent.openingDelimiterUnindentRegex')
    @hangingIndentRegex = new RegExp(atom.config.get 'python-indent.hangingIndentRegex')

  properlyIndent: (e) ->
    @editor = atom.workspace.getActiveTextEditor()
    # Make sure this is a Python file
    return unless @editor.getGrammar().scopeName.substring(0, 13) == 'source.python'

    # Get base variables
    row = @editor.getCursorBufferPosition().row
    previousLine = @editor.buffer.lineForRow(row - 1)
    return unless row

    # Based on configuration, branch to corresponding logic
    if (matchOpeningDelimiter = @openingDelimiterIndentRegex.exec previousLine) isnt null
      @indentOnOpeningDelimiter(row, previousLine, matchOpeningDelimiter)
    else if @hangingIndentRegex.test previousLine
      @indentHanging(row, previousLine)
    else if @openingDelimiterUnindentRegex.test previousLine
      @unindentOnOpeningDelimiter(row, previousLine)

  indentOnOpeningDelimiter: (row, previousLine, matchOpeningDelimiter) ->
    # Get index of opening delimiter.
    # The indent should be one whitespace character past this (sorry, no tabs)
    indentColumn = previousLine.lastIndexOf(matchOpeningDelimiter[1]) + 1

    # Get tab length for context
    tabLength = @editor.getTabLength()

    # Calculate soft-tabs from spaces (can have remainder)
    tabs = (indentColumn / tabLength) - @editor.indentationForBufferRow row
    rem = indentColumn % tabLength

    # If there's a remainder, `@editor.buildIndentString` requires the tab to
    # be set past the desired indentation level, thus the ceiling.
    tabs = if rem > 0 then Math.ceil tabs else tabs

    # Offset is the number of spaces to subtract from the soft-tabs if they
    # are past the desired indentation (not divisible by tab length).
    offset = if rem > 0 then tabLength - rem else 0

    # I'm glad Atom has an optional `column` param to subtract spaces from
    # soft-tabs, though I don't see it used anywhere in the core.
    indent = @editor.buildIndentString(tabs, column=offset)

    # Set the indent
    @editor.getBuffer().setTextInRange([[row, 0], [row, 0]], indent)

  getLastUnmatchedOpenDelimiter: (previousLine) ->


  unindentOnOpeningDelimiter: (row, previousLine) ->
    # Get all preceding lines
    lines = if row > 0 then @editor.buffer.lines[0..row - 1] else []

    # Loop in reverse through lines
    for line, i in lines by -1

      # Set indent for row after declaration of block
      if @openingDelimiterIndentRegex.test line

        # Indent one tab-level past declaration
        indent = @editor.indentationForBufferRow i
        indent += 1 if previousLine.slice(-1) is ':'
        @editor.setIndentationForBufferRow row, indent

        # Stop trying after success
        break

  indentHanging: (row, previousLine) ->
    # Indent at the current block level plus the setting amount (1 or 2)
    indent = (@editor.indentationForBufferRow row) + (atom.config.get 'python-indent.hangingIndentTabs')

    # Set the indent
    @editor.setIndentationForBufferRow row, indent
