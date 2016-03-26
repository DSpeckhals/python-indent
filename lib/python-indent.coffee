# TODO: handle hard indents, which CAN also have spaces in them (!!!)
#       see "stopRange" in "properlyIndent"
# TODO: do we want to over-ride atom's default behavior inside multi-line strings?
# TODO: do we want to de-dent after a "return" statement? When would that be incorrect?

module.exports =
class PythonIndent

  properlyIndent: (e) ->
    @editor = atom.workspace.getActiveTextEditor()
    # Make sure this is a Python file
    return unless @editor.getGrammar().scopeName.substring(0, 13) == 'source.python'

    # Get base variables
    row = @editor.getCursorBufferPosition().row
    col = @editor.getCursorBufferPosition().column

    # Parse the entire file up to the current point, keeping track of brackets
    lines = @editor.getTextInBufferRange([[0,0], [row, col]]).split('\n')
    # at this point, the newline character has just been added,
    # so remove the last element of lines, which will be the empty line
    lines = lines.splice(0, lines.length - 1)

    parseOutput = @parseLines(lines)
    # A stack of [row, col] pairs describing where open brackets are
    openBracketStack = parseOutput.openBracketStack
    # Either empty, or an array [rowOpen, rowClose] describing the rows
    # where the last bracket to be closed was opened and closed.
    lastClosedRow = parseOutput.lastClosedRow
    # A stack containing the row number where each bracket was closed.
    shouldHang = parseOutput.shouldHang
    # The last row a def/for/if/elif/else/try/except etc. block started
    lastColonRow = parseOutput.lastColonRow

    if shouldHang
        @indentHanging(row, @editor.buffer.lineForRow(row - 1))
        return

    return unless openBracketStack.length or (lastClosedRow.length and openBracketStack)

    if not openBracketStack.length
        # can assume lastClosedRow is not empty
        if lastClosedRow[1] == row - 1
            # we just closed a bracket on the row, get indentation from the
            # row where it was opened
            indentLevel = @editor.indentationForBufferRow(lastClosedRow[0])

            if lastColonRow == row - 1
                # we just finished def/for/if/elif/else/try/except etc. block,
                # need to increase indent level by 1.
                indentLevel += 1

            @editor.setIndentationForBufferRow(row, indentLevel)
        return

     # Get tab length for context
    tabLength = @editor.getTabLength()

    lastOpenBracketLocations = openBracketStack.pop()

    # Get some booleans to help work through the cases

    # haveClosedBracket is true if we have ever closed a bracket
    haveClosedBracket = lastClosedRow.length
    # justOpenedBracket is true if we opened a bracket on the row we just finished
    justOpenedBracket = lastOpenBracketLocations[0] == row - 1
    # justClosedBracket is true if we closed a bracket on the row we just finished
    justClosedBracket = haveClosedBracket and lastClosedRow[1] == row - 1
    # closedBracketOpenedAfterLineWithCurrentOpen is an ***extremely*** long name, and
    # it is true if the most recently closed bracket pair was opened on
    # a line AFTER the line where the current open bracket
    closedBracketOpenedAfterLineWithCurrentOpen = haveClosedBracket and lastClosedRow[0] > lastOpenBracketLocations[0]

    if not justOpenedBracket and not justClosedBracket
        # The bracket was opened before the previous line,
        # and we did not close a bracket on the previous line.
        # Thus, nothing has happened that could have changed the
        # indentation level since the previous line, so
        # we should use whatever indent we are given.
        return
    else if justClosedBracket and closedBracketOpenedAfterLineWithCurrentOpen
        # A bracket that was opened after the most recent open
        # bracket was closed on the line we just finished typing.
        # We should use whatever indent was used on the row
        # where we opened the bracket we just closed. This needs
        # to be handled as a separate case from the last case below
        # in case the current bracket is using a hanging indent.
        # This handles cases such as
        # x = [0, 1, 2,
        #      [3, 4, 5,
        #       6, 7, 8],
        #      9, 10, 11]
        # which would be correctly handled by the case below, but it also correctly handles
        # x = [
        #     0, 1, 2, [3, 4, 5,
        #               6, 7, 8],
        #     9, 10, 11
        # ]
        # which the last case below would incorrectly indent an extra space
        # before the "9", because it would try to match it up with the
        # open bracket instead of using the hanging indent.
        previousIndent = @editor.indentationForBufferRow(lastClosedRow[0])
        indentColumn = previousIndent * tabLength
    else
        # lastOpenBracketLocations[1] is the column where the bracket was,
        # so need to bump up the indentation by one
        indentColumn = lastOpenBracketLocations[1] + 1

    # Calculate soft-tabs from spaces (can have remainder)
    tabs = (indentColumn / tabLength)
    rem = ((tabs - Math.floor(tabs)) * tabLength)

    # If there's a remainder, `@editor.buildIndentString` requires the tab to
    # be set past the desired indentation level, thus the ceiling.
    tabs = if rem > 0 then Math.ceil tabs else tabs

    # Offset is the number of spaces to subtract from the soft-tabs if they
    # are past the desired indentation (not divisible by tab length).
    offset = if rem > 0 then tabLength - rem else 0

    # I'm glad Atom has an optional `column` param to subtract spaces from
    # soft-tabs, though I don't see it used anywhere in the core.
    # It looks like for hard tabs, the "tabs" input can be fractional and
    # the "column" input is ignored...?
    indent = @editor.buildIndentString(tabs, column=offset)

    # The range of text to replace with our indent
    # will need to change this for hard tabs, especially tricky for when
    # hard tabs have mixture of tabs + spaces, which they can judging from
    # the editor.buildIndentString function
    startRange = [row, 0]
    stopRange = [row, @editor.indentationForBufferRow(row) * tabLength]
    @editor.getBuffer().setTextInRange([startRange, stopRange], indent)


  parseLines: (lines) ->
    # openBracketStack is an array of [row, col] indicating the location
    # of the opening bracket (square, curly, or parentheses)
    openBracketStack = []
    # lastClosedRow is either empty or [rowOpen, rowClose] describing the
    # rows where the latest closed bracket was opened and closed.
    lastClosedRow = []
    # if we are in a string, this tells us what character introduced the string
    # i.e., did this string start with ' or with "?
    stringDelimiter = []
    # this is the row of the last function definition
    lastColonRow = NaN

    # true if we are in a triple quoted string
    inTripleQuotedString = false

    # If we have seen two of the same string delimiters in a row,
    # then we have to check the next character to see if it matches
    # in order to correctly parse triple quoted strings.
    checkNextCharForString = false

    # keep track of the number of consecutive string delimiter's we've seen
    # used to tell if we are in a triple quoted string
    numConsecutiveStringDelimiters = 0

    # NOTE: this parsing will only be correct if the python code is well-formed
    #       statements like "[0, (1, 2])" might break the parsing

    # loop over each line
    for row in [0 .. lines.length - 1]
        line = lines[row]

        # boolean, whether or not the current character is being escaped
        # applicable when we are currently in a string
        isEscaped = false

        # true if we should have a hanging indent, false otherwise
        shouldHang = false

        # this is the last defined def/for/if/elif/else/try/except row
        lastlastColonRow = lastColonRow

        for col in [0 .. line.length - 1] by 1
            c = line[col]

            if c == stringDelimiter and not isEscaped
                numConsecutiveStringDelimiters += 1
            else if checkNextCharForString
                numConsecutiveStringDelimiters = 0
                stringDelimiter = []
            else
                numConsecutiveStringDelimiters = 0

            checkNextCharForString = false

            # if stringDelimiter is set, then we are in a string
            # Note that this works correctly even for triple quoted strings
            if stringDelimiter.length
                if isEscaped
                    # If current character is escaped, then we do not care what it was,
                    # but since it is impossible for the next character to be escaped as well,
                    # go ahead and set that to false
                    isEscaped = false
                else
                    if c == stringDelimiter
                        # We are seeing the same quote that started the string, i.e. ' or "
                        if inTripleQuotedString
                            if numConsecutiveStringDelimiters == 3
                                # breaking out of the triple quoted string...
                                numConsecutiveStringDelimiters = 0
                                stringDelimiter = []
                                inTripleQuotedString = false
                        else if numConsecutiveStringDelimiters == 3
                            # reset the count, correctly handles cases like ''''''
                            numConsecutiveStringDelimiters = 0
                            inTripleQuotedString = true
                        else if numConsecutiveStringDelimiters == 2
                            # we are not currently in a triple quoted string, and we've
                            # seen two of the same string delimiter in a row. This could
                            # either be an empty string, i.e. '' or "", or it could be
                            # the start of a triple quoted string. We will check the next
                            # character, and if it matches then we know we're in a triple
                            # quoted string, and if it does not match we know we're not
                            # in a string any more (i.e. it was the empty string).
                            checkNextCharForString = true
                        else if numConsecutiveStringDelimiters == 1
                            # We are not in a string that is not triple quoted, and we've
                            # just seen an un-escaped instance of that string delimiter.
                            # In other words, we've left the string.
                            # It is also worth noting that it is impossible for
                            # numConsecutiveStringDelimiters to be 0 at this point, so
                            # this set of if/else if statements covers all cases.
                            stringDelimiter = []
                    else if c == '\\'
                        # We are seeing an unescaped backslash, the next character is escaped.
                        # Note that this is not exactly true in raw strings, HOWEVER, in raw strings
                        # you can still escape the quote mark by using a backslash. Since that's all
                        # we really care about as far as escaped characters go, we can go ahead and
                        # assume we are now escaping the next character.
                        isEscaped = true
            else
                if c in '[({'
                    openBracketStack.push([row, col])
                    # If the only characters after this opening bracket are whitespace,
                    # then we should do a hanging indent. If there are other non-whitespace
                    # characters after this, then they will set the shouldHang boolean to false
                    shouldHang = true
                else if c in ' \t\r\n' # shouldn't see a newline in here, but just in case...
                    # if it's whitespace, we don't care at all
                    # this check is necessary so we don't set shouldHang to false even if someone
                    # e.g. just entered a space between the opening bracket and the newline.
                    continue
                else if c == '#'
                    # this check goes as well to make sure we don't set shouldHang
                    # to false in similar circumstances as described in the whitespace section.
                    break
                else
                    # we've already skipped if the character was white-space, an opening bracket,
                    # or a new line, so that means the current character is not whitespace and
                    # not an opening bracket, so shouldHang needs to get set to false.
                    shouldHang = false

                    # Similar to above, we've already skipped all irrelevant characters,
                    # so if we saw a colon earlier in this line, then we would have
                    # incorrectly thought it was the end of a def/for/if/elif/else/try/except
                    # block when it was actually a dictionary being defined, reset the
                    # lastColonRow variable to whatever it was when we started parsing this line.
                    lastColonRow = lastlastColonRow

                    if c == ':'
                        lastColonRow = row
                    else if c in '})]' and openBracketStack.length
                        # Note that the .pop() will take the element off of the openBracketStack
                        # as it adds it to the array for lastClosedRow.
                        lastClosedRow = [openBracketStack.pop()[0], row]
                    else if c in '\'"'
                        # starting a string, keep track of what quote was used to start it.
                        stringDelimiter = c
                        numConsecutiveStringDelimiters += 1

    return {} =
        openBracketStack: openBracketStack
        lastClosedRow: lastClosedRow
        shouldHang: shouldHang
        lastColonRow: lastColonRow

  indentHanging: (row, previousLine) ->
    # Indent at the current block level plus the setting amount (1 or 2)
    indent = (@editor.indentationForBufferRow row) + (atom.config.get 'python-indent.hangingIndentTabs')

    # Set the indent
    @editor.setIndentationForBufferRow row, indent
