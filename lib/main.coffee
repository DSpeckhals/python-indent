{CompositeDisposable} = require 'atom'
PythonIndent = require './python-indent'

module.exports =
  config:
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
