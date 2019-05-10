"use babel";

import * as parser from "python-indent-parser";

export default class PythonIndent {
    constructor() {
        this.version = atom.getVersion().split(".").slice(0, 2).map(p => parseInt(p, 10));
    }

    indent() {
        this.editor = atom.workspace.getActiveTextEditor();

        // Make sure there's an active editor
        if (!this.editor) {
            return;
        }

        // Make sure this is a Python file
        const { scopeName } = this.editor.getGrammar();
        const validScopeName = scopeName === "python" // New grammar name
            || scopeName === "source.cython" // Cython grammar name
            || scopeName.substring(0, 13) === "source.python"; // Legacy grammar name;

        if (!validScopeName || !this.editor.getSoftTabs()) {
            return;
        }

        // Group operations together. Most noticeable for hanging
        // indents. Note this still does not group the original
        // newline call so there's two ctrl-z's needed.
        this.editor.transact(() => {
            const { row, column: col } = this.editor.getCursorBufferPosition();
            const tabSize = this.editor.getTabLength();
            const lines = this.editor.getTextInBufferRange([[0, 0], [row, col]]).split("\n");

            // The parser assumes not to have the line after the new line character.
            lines.pop();

            const { nextIndentationLevel, canHang } = parser.indentationInfo(lines, tabSize);
            if (canHang) {
                const indent = this.editor.indentationForBufferRow(row)
                    + atom.config.get("python-indent.hangingIndentTabs");

                this.editor.setIndentationForBufferRow(row, indent);
                return;
            }

            // Create the indentation string.
            const toInsert = `${" ".repeat(Math.max(nextIndentationLevel, 0))}`;
            const range = [[row, 0], [row, this.editor.indentationForBufferRow(row) * tabSize]];

            // Only set the new indent if it's different than what the editor chose.
            const currentIndent = this.editor.getTextInBufferRange(range);
            if (currentIndent !== toInsert) {
                this.editor.getBuffer().setTextInRange(range, toInsert);
            }
        });
    }
}
