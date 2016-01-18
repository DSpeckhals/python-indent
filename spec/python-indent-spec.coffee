describe 'python-indent', ->
  {properlyIndent} = require '../lib/python-indent'
  grammar = 'Python'
  FILE_NAME = 'fixture.py'
  editor = null
  buffer = null

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open(FILE_NAME).then (ed) ->
        editor = ed
        editor.setSoftTabs true
        editor.setTabLength 4

        buffer = editor.buffer
    waitsForPromise ->
      atom.packages.activatePackage 'python-indent'

    waitsForPromise ->
        atom.packages.activatePackage 'language-python'

  describe 'package', ->
    it 'loads python file and package', ->
      expect(editor.getPath()).toContain FILE_NAME
      expect(atom.packages.isPackageActive('python-indent')).toBe true

  describe 'when indenting after newline', ->
    it 'fluid indents after open def params', ->
      editor.insertText 'def test(param_a, param_b, param_c,\n'
      properlyIndent()
      expect(buffer.lineForRow(1)).toBe ' '.repeat 9

    it 'fluid indents after open tuple', ->
      editor.insertText 'tup = (True, False,\n'
      properlyIndent()
      expect(buffer.lineForRow(1)).toBe ' '.repeat 7

    it 'fluid indents after open bracket', ->
      editor.insertText 'a_list = ["1", "2",\n'
      properlyIndent()
      expect(buffer.lineForRow(1)).toBe ' '.repeat 10

    it 'does not do any special indentation when delimiter is closed', ->
      editor.insertText 'def test(param_a, param_b, param_c):\n'
      properlyIndent()
      expect(buffer.lineForRow(1)).toBe ' '.repeat 0

    it 'keeps fluid indentation on succeding open lines', ->
      editor.insertText 'def test(param_a,\n'
      properlyIndent()
      editor.insertText 'param_b,\n'
      editor.autoIndentSelectedRows(2)
      expect(buffer.lineForRow(2)).toBe ' '.repeat 9

    it 'allows for fluid indent in multi-level situations', ->
      editor.insertText 'class TheClass(object):\n'
      editor.autoIndentSelectedRows(1)
      editor.insertText 'def test(param_a, param_b,\n'
      properlyIndent()
      editor.insertText 'param_c):\n'
      properlyIndent()
      expect(buffer.lineForRow(3)).toBe ' '.repeat 8

      editor.insertText 'a_list = ["1", "2", "3",\n'
      properlyIndent()
      editor.insertText('"4"]\n')
      properlyIndent()
      expect(buffer.lineForRow(5)).toBe ' '.repeat 8

  describe 'when unindenting after newline', ->
    it 'fluid unindents after close def params', ->
      editor.insertText 'def test(param_a,\n'
      properlyIndent()
      editor.insertText 'param_b):\n'
      properlyIndent()
      expect(buffer.lineForRow(2)).toBe ' '.repeat 4

    it 'fluid unindents after close tuple', ->
      editor.insertText 'tup = (True, False,\n'
      properlyIndent()
      editor.insertText 'False)\n'
      properlyIndent()
      console.log editor.getText()
      expect(buffer.lineForRow(2)).toBe ''

    it 'fluid unindents after close bracket', ->
      editor.insertText 'a_list = ["1", "2",\n'
      properlyIndent()
      editor.insertText '"3"]\n'
      properlyIndent()
      expect(buffer.lineForRow(2)).toBe ''
