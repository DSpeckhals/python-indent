{CompositeDisposable} = require 'atom'

supportedGrammars =
  'Python': true

module.exports = PythonIndent =
  config:
    fluidIndentRegex:
      type: 'string'
      default: "^.*(\\(|\\[).*,$"
      description: 'Regular Expression for fluid indenting'
    fluidUnindentRegex:
      type: 'string'
      default: "^\\s+\\S*(\\)|\\])\\:?$"
      description: 'Regular expression for fluid unindenting'

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'editor:newline': => @properlyIndent()

  deactivate: ->
    @subscriptions.dispose()

  properlyIndent: ->
    # Get configs
    fluidIndentRegex = new RegExp(atom.config.get 'python-indent.fluidIndentRegex')
    fluidUnindentRegex = new RegExp(atom.config.get 'python-indent.fluidUnindentRegex')
    return unless fluidIndentRegex and fluidUnindentRegex

    editor = atom.workspace.getActiveTextEditor()
    row = editor.getCursorBufferPosition().row
    previousLine = editor.buffer.lineForRow(row - 1)
    return unless row

    # Check if previous line should line up after opening delimiter
    if (match = fluidIndentRegex.exec previousLine) != null
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
          indent = editor.indentationForBufferRow(i)
          indent += 1 if line.lastIndexOf('[') is -1
          editor.setIndentationForBufferRow row, indent
          # Stop trying after success
          break
