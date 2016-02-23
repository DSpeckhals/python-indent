{CompositeDisposable} = require 'atom'

# TODO: handle hanging indents
# TODO: handle hard indents, which CAN also have spaces in them (!!!)
#       see "stopRange" in "properlyIndent"
# TODO: unindent back to previous level after all brackets have been closed

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

    if row and PythonIndent.hangingIndentRegex.test(editor.buffer.lineForRow(row - 1))
        PythonIndent.indentHanging(editor, row, editor.buffer.lineForRow(row - 1))
        return

    # Parse the entire file up to the current point, keeping track of brackets
    lines = editor.getTextInBufferRange([[0,0], [row, col]]).split('\n')

    # A stack of [row, col] pairs describing where open brackets are
    bracketStack = PythonIndent.parseLines(lines)

    return unless bracketStack.length

    # bracketStack.pop()[1] is the column where the bracket was, so need to bump by one
    indentColumn = bracketStack.pop() + 1

    # Get tab length for context
    tabLength = editor.getTabLength()

    # Calculate soft-tabs from spaces (can have remainder)
    tabs = (indentColumn / tabLength)
    rem = ((tabs - Math.floor(tabs)) * tabLength)

    # If there's a remainder, `editor.buildIndentString` requires the tab to
    # be set past the desired indentation level, thus the ceiling.
    # TODO: is the conditional necessary? Maybe to avoid floating point errors?
    tabs = if rem > 0 then Math.ceil tabs else tabs

    # Offset is the number of spaces to subtract from the soft-tabs if they
    # are past the desired indentation (not divisible by tab length).
    offset = if rem > 0 then tabLength - rem else 0

    # I'm glad Atom has an optional `column` param to subtract spaces from
    # soft-tabs, though I don't see it used anywhere in the core.
    # It looks like for hard tabs, the "tabs" input can be fractional and
    # the "column" input is ignored...?
    indent = editor.buildIndentString(tabs, column=offset)

    # The range of text to replace with our indent
    # will need to change this for hard tabs, especially tricky for when
    # hard tabs have mixture of tabs + spaces, which they can judging from
    # the editor.buildIndentString function
    startRange = [row, 0]
    stopRange = [row, editor.indentationForBufferRow(row) * tabLength]
    editor.getBuffer().setTextInRange([startRange, stopRange], indent)


  parseLines: (lines) ->
    # bracketStack is an array of columns indicating the location
    # of the opening bracket (square, curly, or parentheses)
    bracketStack = []
    # if we are in a string, this tells us what character introduced the string
    # i.e., did this string start with ' or with "?
    stringDelimiter = []

    # NOTE: this parsing will only be correct if the python code is well-formed
    #       statements like "[0, (1, 2])" might break the parsing

    # loop over each line
    for row in [0 .. lines.length-1]
        line = lines[row]

        # boolean, whether or not the current character is being escaped
        isEscaped = false

        for col in [0 .. line.length-1]
            c = line[col]

            # if stringDelimiter is set, then we are in a string
            if stringDelimiter.length
                if isEscaped
                    isEscaped = false
                else
                    if c == stringDelimiter
                        stringDelimiter = []
                    if c == '\\'
                        isEscaped = true
            else
                if c == '#'
                    break
                if c in '[({'
                    bracketStack.push(col)
                if c in '})]'
                    bracketStack.pop()
                if c in '\'"'
                    stringDelimiter = c

    return bracketStack

  indentHanging: (editor, row, previousLine) ->
    # Indent at the current block level plus the setting amount (1 or 2)
    indent = (editor.indentationForBufferRow row) + (atom.config.get 'python-indent.hangingIndentTabs')

    # Set the indent
    editor.setIndentationForBufferRow row, indent
