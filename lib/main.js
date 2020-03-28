"use babel";

import * as parser from "python-indent-parser";

import { CompositeDisposable } from "atom"; // eslint-disable-line

function indent() {
    const editor = atom.workspace.getActiveTextEditor();

    // Make sure there's an active editor
    if (!editor) {
        return;
    }

    // Get buffer after we know there's an active editor.
    const buffer = editor.getBuffer();

    // Make sure this is a Python file
    const { scopeName } = editor.getGrammar();
    const validScopeName = scopeName === "python" // New grammar name
        || scopeName === "source.cython" // Cython grammar name
        || scopeName.substring(0, 13) === "source.python"; // Legacy grammar name;

    if (!validScopeName || !editor.getSoftTabs()) {
        return;
    }

    // Group operations together. Most noticeable for hanging
    // indents. Note this still does not group the original
    // newline call so there's two ctrl-z's needed.
    editor.transact(() => {
        // Loop through cursor positions to allow for multiple cursors.
        editor.getCursorBufferPositions().forEach(({ row, column: col }) => {
            const tabSize = editor.getTabLength();
            const lineEnding = buffer.getPreferredLineEnding() || "\n";
            let lines = editor.getTextInBufferRange([[0, 0], [row, col]]).split(lineEnding);

            // At this point, the newline character has just been added,
            // so remove the last element of lines, which will be the empty line
            lines = lines.splice(0, lines.length - 1);

            // Use hanging indentation if it's needed.
            const { nextIndentationLevel, parseOutput } = parser.indentationInfo(lines, tabSize);
            const {
                canHang, dedentNext, lastClosedRow, lastColonRow, openBracketStack,
            } = parseOutput;

            // Use hanging indentation
            const previousLine = lines[row - 1];
            const hangType = parser.shouldHang(previousLine, previousLine.length);
            if (canHang && hangType !== parser.Hanging.None) {
                const indentation = editor.indentationForBufferRow(row)
                    + atom.config.get("python-indent.hangingIndentTabs");

                editor.setIndentationForBufferRow(row, indentation);
                buffer.groupLastChanges();

            // Account for Atom's auto-indentation in some cases (don't try to add to it)
            } else if (!openBracketStack.length && !dedentNext) {
                // Can assume lastClosedRow is not empty
                if (lastClosedRow[1] === row - 1) {
                    // We just closed a bracket on the row, get indentation from the
                    // row where it was opened
                    let indentLevel = editor.indentationForBufferRow(lastClosedRow[0]);

                    if (lastColonRow === row - 1) {
                        // We just finished def/for/if/elif/else/try/except etc. block,
                        // need to increase indent level by 1.
                        indentLevel += 1;
                    }
                    editor.setIndentationForBufferRow(row, indentLevel);
                }

            // Add to indentation (continuation)
            } else {
                // Otherwise create the indentation string.
                const toInsert = `${" ".repeat(Math.max(nextIndentationLevel, 0))}`;

                // The following range is zero-indexed (row and column)
                const range = [
                    [row, 0],
                    [row, editor.indentationForBufferRow(row - 1) * tabSize],
                ];

                // Only set the new indent if it's different than what the editor chose.
                const currentIndent = editor.getTextInBufferRange(range);
                if (currentIndent !== toInsert) {
                    buffer.setTextInRange(range, toInsert);
                    buffer.groupLastChanges();
                }
            }
        });
    });
}

export default {
    config: {
        hangingIndentTabs: {
            type: "number",
            default: 1,
            description: "Number of tabs used for _hanging_ indents",
            enum: [
                1,
                2,
            ],
        },
    },

    activate() {
        this.subscriptions = new CompositeDisposable();
        this.subscriptions.add(atom.commands.add("atom-text-editor",
            { "editor:newline": indent }));
    },
};
