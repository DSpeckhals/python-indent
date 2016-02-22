{CompositeDisposable} = require 'atom'

module.exports = PythonIndent =
  config:
    openingDelimiterIndentRegex:
      type: 'string'
      default: '^.*(\\(|\\[).*,\\s*$'
      description: 'Regular Expression for _aligned with opening delimiter_ continuation indent type, and used for determining when this type of indent should be _started_.'
    openingDelimiterUnindentRegex:
      type: 'string'
      default: '^\\s+\\S*(\\)|\\])\\s*:?\\s*$'
      description: 'Regular Expression for _aligned with opening delimiter_ continuation indent type, and used for determining when this type of indent should be _ended_.'
    hangingIndentRegex:
      type: 'string'
      default: '^.*(\\(|\\[)\\s*$'
      description: 'Regular Expression for _hanging indent_ used for determining when this type of indent should be _started_.'
    hangingIndentTabs:
      type: 'number'
      default: 1
      description: 'Number of tabs used for _hanging_ indents'
      enum: [
        1,
        2
      ]

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'editor:newline': => @properlyIndent(event)

    # Cache settings
    @openingDelimiterIndentRegex = new RegExp(atom.config.get 'python-indent.openingDelimiterIndentRegex')
    @openingDelimiterUnindentRegex = new RegExp(atom.config.get 'python-indent.openingDelimiterUnindentRegex')
    @hangingIndentRegex = new RegExp(atom.config.get 'python-indent.hangingIndentRegex')

  deactivate: ->
    @subscriptions.dispose()

  properlyIndent: (e) ->
    # Make sure this is a Python file
    editor = atom.workspace.getActiveTextEditor()
    return unless editor.getGrammar().scopeName.substring(0, 13) == 'source.python'

    # Get base variables
    row = editor.getCursorBufferPosition().row
    col = editor.getCursorBufferPosition().column

    # What does this line do?
    return unless row

    PythonIndent.indentCorrectly(editor, row, col)


  indentCorrectly: (editor, row, col) ->
    # Parse the entire file up to the current point, keeping track of brackets
    lines = editor.getTextInBufferRange([[0,0], [row, col]]).split('\n')

    stacks = PythonIndent.parseLines(lines)

    bracketStack = stacks[0]
    parenthesesStack = stacks[1]

    if not bracketStack.length and not parenthesesStack.length
        return

    # Get the indent column, need to check both bracket and parentheses locations
    if not bracketStack.length
        # Only have open parentheses to worry about
        [..., indentColumn] = parenthesesStack
        indentColumn = indentColumn[1]
    else if not parenthesesStack.length
        # Only have open brackets to worry about
        [..., indentColumn] = bracketStack
        indentColumn = indentColumn[1]
    else
        # Have both open brackets and open parentheses to worry about
        [..., bracketIndent] = bracketStack
        [..., parenthesesIndent] = parenthesesStack

        # Find out which came last, checking rows and then columns
        useBracket = true
        if bracketIndent[0] < parenthesesIndent[0]
            useBracket = false
        else if bracketIndent[0] == parenthesesIndent[0]
            if bracketIndent[1] < parenthesesIndent[1]
                useBracket = false

        if useBracket
            indentColumn = bracketIndent[1]
        else
            indentColumn = parenthesesIndent[1]

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


  parseLines: (lines) ->
    # initialize some empty stacks
    bracketStack = []
    parenthesesStack = []

    # loop over each line, adding to each stack
    for i in [0..lines.length-1]
        line = lines[i]
        stacks = PythonIndent.parseLine(bracketStack, parenthesesStack, [], i, 0, line)
        bracketStack.concat(stacks[0])
        parenthesesStack.concat(stacks[1])

    # return the stacks as an array
    return [bracketStack, parenthesesStack]


  parseLine: (bracketStack, parenthesesStack, stringDelimiter, row, col, line) ->
    # base case

    if not line.length or (not stringDelimiter.length and line[0] == '#')
        # stacks will be turned as array
        return [bracketStack, parenthesesStack]

    c = line[0]

    # if stringDelimiter is set, then we are in a string
    if stringDelimiter.length
        # if current character is same as string delimiter, then we have exited string
        if c == stringDelimiter
            stringDelimiter = []
    else
        switch c
            when '['
                bracketStack.push([row, col])
            when ']'
                bracketStack.pop()
            when '('
                parenthesesStack.push([row, col])
            when ')'
                parenthesesStack.pop()
            when '\''
                stringDelimiter = '\''
            when '"'
                stringDelimiter = '"'

    return PythonIndent.parseLine(bracketStack, parenthesesStack,
                                  stringDelimiter, row, col+1, line[1..])

  #
  # indentOnOpeningDelimiter: (editor, row, previousLine, matchOpeningDelimiter) ->
  #   # Get index of opening delimiter.
  #   # The indent should be one whitespace character past this (sorry, no tabs)
  #   indentColumn = previousLine.lastIndexOf(matchOpeningDelimiter[1]) + 1
  #
  #   # Get tab length for context
  #   tabLength = editor.getTabLength()
  #
  #   # Calculate soft-tabs from spaces (can have remainder)
  #   tabs = (indentColumn / tabLength) - editor.indentationForBufferRow row
  #   rem = indentColumn % tabLength
  #
  #   # If there's a remainder, `editor.buildIndentString` requires the tab to
  #   # be set past the desired indentation level, thus the ceiling.
  #   tabs = if rem > 0 then Math.ceil tabs else tabs
  #
  #   # Offset is the number of spaces to subtract from the soft-tabs if they
  #   # are past the desired indentation (not divisible by tab length).
  #   offset = if rem > 0 then tabLength - rem else 0
  #
  #   # I'm glad Atom has an optional `column` param to subtract spaces from
  #   # soft-tabs, though I don't see it used anywhere in the core.
  #   indent = editor.buildIndentString(tabs, column=offset)
  #
  #   # Set the indent
  #   editor.getBuffer().setTextInRange([[row, 0], [row, 0]], indent)
  #
  # unindentOnOpeningDelimiter: (editor, row, previousLine) ->
  #   # Get all preceding lines
  #   lines = if row > 0 then editor.buffer.lines[0..row - 1] else []
  #
  #   # Loop in reverse through lines
  #   for line, i in lines by -1
  #
  #     # Set indent for row after declaration of block
  #     if PythonIndent.openingDelimiterIndentRegex.test line
  #
  #       # Indent one tab-level past declaration
  #       indent = editor.indentationForBufferRow i
  #       indent += 1 if previousLine.slice(-1) is ':'
  #       editor.setIndentationForBufferRow row, indent
  #
  #       # Stop trying after success
  #       break
  #
  # indentHanging: (editor, row, previousLine) ->
  #   # Indent at the current block level plus the setting amount (1 or 2)
  #   indent = (editor.indentationForBufferRow row) + (atom.config.get 'python-indent.hangingIndentTabs')
  #
  #   # Set the indent
  #   editor.setIndentationForBufferRow row, indent
