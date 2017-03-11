"use babel";

import { CompositeDisposable } from "atom"; // eslint-disable-line
import PythonIndent from "./python-indent";

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
        this.pythonIndent = new PythonIndent();
        this.subscriptions = new CompositeDisposable();
        this.subscriptions.add(atom.commands.add("atom-text-editor",
            { "editor:newline": () => this.pythonIndent.indent() }));
    },
};
