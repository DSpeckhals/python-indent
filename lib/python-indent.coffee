{CompositeDisposable} = require 'atom'

supportedGrammars =
  'Python': true

module.exports = PythonIndent =
  config:
    continuationIndentType:
      type: 'string'
      default: 'aligned with opening delimiter'
      description: 'Indent type for continuing lines as described in [PEP 0008 -- Style Guide for Python Code](https://www.python.org/dev/peps/pep-0008/#indentation)'
      enum: [
        'aligned with opening delimiter',
        'hanging'
      ]
    fluidIndentRegex:
      type: 'string'
      default: '^.*(\\(|\\[).*,$'
      description: 'Regular Expression for _aligned with opening delimiter_ __Continuation Indent Type__, and used for determining when this type of indent should be _started_.'
    fluidUnindentRegex:
      type: 'string'
      default: '^\\s+\\S*(\\)|\\]):?$'
      description: 'Regular Expression for _aligned with opening delimiter_ __Continuation Indent Type__, and used for determining when this type of indent should be _ended_.'
    hangingIndentTabs:
      type: 'number'
      default: 1
      description: 'If __Continuation Indent Type__ is set to _hanging_, how many tabs should be used? If __Continuation Indent Type__ is not _hanging_, this setting is ignored'
      enum: [
        1,
        2
      ]

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'editor:newline': => @properlyIndent()

  deactivate: ->
    @subscriptions.dispose()

  properlyIndent: ->
    # Get base variables
    editor = atom.workspace.getActiveTextEditor()
    row = editor.getCursorBufferPosition().row
    previousLine = editor.buffer.lineForRow(row - 1)
    return unless row

    # Get continuation indent type configuration
    indentType = atom.config.get 'python-indent.continuationIndentType'

    # Based on configuration, branch to corresponding logic
    if indentType is 'aligned with opening delimiter'
      PythonIndent.indentOnOpeningDelimiter(editor, row, previousLine)
    else if indentType is 'hanging'
      PythonIndent.indentHanging(editor, row, previousLine)

  indentOnOpeningDelimiter: (editor, row, previousLine) ->
    # Get regex settings
    fluidIndentRegex = new RegExp(atom.config.get 'python-indent.fluidIndentRegex')
    fluidUnindentRegex = new RegExp(atom.config.get 'python-indent.fluidUnindentRegex')
    return unless fluidIndentRegex and fluidUnindentRegex

    # Check if previous line should line up after opening delimiter
    if (match = fluidIndentRegex.exec previousLine) isnt null

      # Get index of opening delimiter.
      # The indent should be one whitespace character past this (sorry, no tabs)
      indentColumn = previousLine.lastIndexOf(match[1]) + 1

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

    # Check if previous line should indent into block normally
    else if fluidUnindentRegex.test previousLine

      # Get all preceding lines
      lines = if row > 0 then editor.buffer.lines[0..row - 1] else []

      # Loop in reverse through lines
      for line, i in lines by -1

        # Set indent for row after declaration of block
        if fluidIndentRegex.test line

          # Indent one tab-level past declaration
          indent = editor.indentationForBufferRow i
          indent += 1 if previousLine.slice(-1) is ':'
          editor.setIndentationForBufferRow row, indent

          # Stop trying after success
          break

  indentHanging: (editor, row, previousLine) ->
    # Stop if no match
    return unless (match = /^.*(\(|\[)$/.exec previousLine) isnt null

    # Indent at the current block level plus the setting amount (1 or 2)
    indent = (editor.indentationForBufferRow row) + (atom.config.get 'python-indent.hangingIndentTabs')

    # Set the indent
    editor.setIndentationForBufferRow row, indent
