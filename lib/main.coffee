{CompositeDisposable} = require 'atom'
PythonIndent = require './python-indent'

module.exports =
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
    @pythonIndent = new PythonIndent()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'editor:newline': => @pythonIndent.properlyIndent(event)

  deactivate: ->
    @subscriptions.dispose()
