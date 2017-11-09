"use babel";

import PythonIndent from "../lib/python-indent";

describe("python-indent", () => {
    const FILE_NAME = "../../fixture.py";
    let buffer = null;
    let editor = null;
    let pythonIndent = null;
    let makeNewline = null;
    let manualTabs = false;

    beforeEach(() => {
        waitsForPromise(() =>
            atom.workspace.open(FILE_NAME).then((ed) => {
                const tabLength = 4;
                editor = ed;
                makeNewline = (tabs = 0) => {
                    atom.commands.dispatch(
                        atom.views.getView(editor),
                        "editor:newline");
                    editor.insertText(" ".repeat((manualTabs ? tabs : 0) * tabLength));
                };
                editor.setSoftTabs(true);
                editor.setTabLength(tabLength);
                buffer = editor.buffer;
            }),
        );

        waitsForPromise(() => {
            const packages = atom.packages.getAvailablePackageNames();
            let languagePackage;

            if (packages.indexOf("language-python") > -1) {
                languagePackage = "language-python";
            } else if (packages.indexOf("MagicPython") > -1) {
                languagePackage = "MagicPython";
            }

            return atom.packages.activatePackage(languagePackage);
        });

        waitsForPromise(() =>
            atom.packages.activatePackage("python-indent").then(() => {
                pythonIndent = new PythonIndent();
                manualTabs = pythonIndent.version[1] > 22;
            }),
        );
    });

    describe("package", () =>
        it("loads python file and package", () => {
            expect(editor.getPath()).toContain("fixture.py");
            expect(atom.packages.isPackageActive("python-indent")).toBe(true);
        }),
    );

    // Aligned with opening delimiter
    describe("aligned with opening delimiter", () => {
        describe("when indenting after newline", () => {
            /*
            def test(param_a, param_b, param_c,
                             param_d):
                    pass
            */
            it("indents after open def params", () => {
                editor.insertText("def test(param_a, param_b, param_c,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(9));
            });

            /*
            x = [0, 1, 2,
                     3, 4, 5]
            */
            it("indents after open bracket with multiple values on the first line", () => {
                editor.insertText("x = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));
            });

            /*
            x = [0,
                     1]
            */
            it("indents after open bracket with one value on the first line", () => {
                editor.insertText("x = [0,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));
            });

            /*
            x = [0, 1, 2, [3, 4, 5,
                           6, 7, 8]]
            */
            it("indents in nested lists when inner list is on the same line", () => {
                editor.insertText("x = [0, 1, 2, [3, 4, 5,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(15));
            });

            /*
            x = [0, 1, 2,
                 [3, 4, 5,
                  6, 7, 8]]
            */
            it("indents in nested lists when inner list is on a new line", () => {
                editor.insertText("x = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));

                editor.insertText("[3, 4, 5,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(6));
            });

            /*
            x = (0, 1, 2,
                 3, 4, 5)
            */
            it("indents after open tuple with multiple values on the first line", () => {
                editor.insertText("x = (0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));
            });

            /*
            x = (0,
                 1)
            */
            it("indents after open tuple with one value on the first line", () => {
                editor.insertText("x = (0,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));
            });

            /*
            x = (0, 1, 2, [3, 4, 5,
                           6, 7, 8],
                 9, 10, 11)
            */
            it("indents in nested lists when inner list is on a new line", () => {
                editor.insertText("x = (0, 1, 2, [3, 4, 5,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(15));

                editor.insertText("6, 7, 8],\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(5));
            });

            /*
            x = {0: 0, 1: 1,
                 2: 2, 3: 3}
            */
            it("indents dictionaries when multiple pairs are on the same line", () => {
                editor.insertText("x = {0: 0, 1: 1,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));
            });

            /*
            x = {0: 0, 1: 1,
                 2: 2, 3: 3, 4: [4, 4,
                                 4, 4]}
            */
            it("indents dictionaries with a list as a value", () => {
                editor.insertText("x = {0: 0, 1: 1,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));

                editor.insertText("2: 2, 3: 3, 4: [4, 4,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(21));
            });

            /*
            s = "[ will this \"break ( the parsing?"
            */
            it("does not indent with delimiters that are quoted", () => {
                editor.insertText("s = \"[ will this \\\"break ( the parsing?\"\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe("");
            });

            /*
            x = ["here(\"(", "is", "a",
                     "list", "of", ["nested]",
                                    "strings\\"],
                     r"some \[\"[of which are raw",
                     "and some of which are not"]
            */
            it("knows when to indent when some delimiters are literal, and some are not", () => {
                editor.insertText("x = [\"here(\\\"(\", \"is\", \"a\",\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(5));

                editor.insertText("\"list\", \"of\", [\"nested]\",\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(20));

                editor.insertText("\"strings\\\\\"],\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(3)).toBe(" ".repeat(5));

                editor.insertText("r\"some \\[\\\"[of which are raw\",\n");
                editor.autoIndentSelectedRows(4);
                expect(buffer.lineForRow(4)).toBe(" ".repeat(5));
            });

            /*
            def test(param_a, param_b, param_c):
                    pass
            */
            it("indents normally when delimiter is closed", () => {
                editor.insertText("def test(param_a, param_b, param_c):");
                makeNewline(1);
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));
            });

            /*
            def test(param_a,
                     param_b,
                     param_c):
                    pass
            */
            it("keeps indentation on succeding open lines", () => {
                editor.insertText("def test(param_a,\n");
                pythonIndent.indent();
                editor.insertText("param_b,\n");
                editor.autoIndentSelectedRows(2);
                expect(buffer.lineForRow(2)).toBe(" ".repeat(9));
            });

            /*
            class TheClass(object):
                    def test(param_a, param_b,
                             param_c):
                        a_list = [1, 2, 3,
                                  4]
            */
            it("allows for fluid indent in multi-level situations", () => {
                editor.insertText("class TheClass(object):\n");
                editor.autoIndentSelectedRows(1);
                editor.insertText("def test(param_a, param_b,\n");
                pythonIndent.indent();
                editor.insertText("param_c):\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(3)).toBe(" ".repeat(8));

                editor.insertText("a_list = [1, 2, 3,\n");
                pythonIndent.indent();
                editor.insertText("4]\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(5)).toBe(" ".repeat(8));
            });

            /*
            def f(arg1, arg2, arg3,
                  arg4, arg5, arg6=")\)",
                  arg7=0):
                return 0
            */
            it("indents properly when delimiters are an argument default string", () => {
                editor.insertText("def f(arg1, arg2, arg3,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(6));

                editor.insertText("arg4, arg5, arg6=\")\\)\",\n");
                editor.autoIndentSelectedRows(2);
                expect(buffer.lineForRow(2)).toBe(" ".repeat(6));

                editor.insertText("arg7=0):\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(3)).toBe(" ".repeat(4));
            });

            /*
            for i in range(10):
                for j in range(20):
                    def f(x=[0,1,2,
                             3,4,5]):
                        return x * i * j
            */
            it("indents properly when blocks and lists are deeply nested", () => {
                editor.insertText("for i in range(10):");
                makeNewline(1);
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));

                editor.insertText("for j in range(20):");
                makeNewline(2);
                expect(buffer.lineForRow(2)).toBe(" ".repeat(8));

                editor.insertText("def f(x=[0,1,2,");
                makeNewline();
                expect(buffer.lineForRow(3)).toBe(" ".repeat(17));

                editor.insertText("3,4,5]):");
                makeNewline();
                expect(buffer.lineForRow(4)).toBe(" ".repeat(12));
            });

            /*
            """ quote with a single string delimiter: " """
            var_name = [0, 1, 2,
            */
            it("handles odd number of string delimiters inside triple quoted string", () => {
                editor.insertText("\"\"\" quote with a single string delimiter: \" \"\"\"\n");
                editor.insertText("var_name = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(12));
            });

            /*
            """ here is a triple quote with a two string delimiters: "" """
            var_name = [0, 1, 2,
            */
            it("handles even number of string delimiters inside triple quoted string", () => {
                editor.insertText("\"\"\" a quote with two string delimiters: \"\" \"\"\"\n");
                editor.insertText("var_name = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(12));
            });

            /*
            """
            Here is just one quote: "
            """
            x = [0, 1, 2,
                 4, 5, 6]
            */
            it("handles a single delimiter inside a triple quoted string of the same char", () => {
                editor.insertText("\"\"\"\n");
                editor.insertText("Here is just one quote: \"\n");
                editor.insertText("\"\"\"\n");
                editor.insertText("x = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(4)).toBe(" ".repeat(5));
            });

            /*
            x = ""
            a = [b]
            */
            it("does not break formatting when an empty string is in the editor", () => {
                editor.insertText("x = \"\"\n");
                editor.insertText("a = [b,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(5));
            });

            /*
            ### here is "a triple quote" with three extra" string delimiters" ###
            var_name = [0, 1, 2,
            */
            it("handles three string delimiters spaced out inside triple quoted string", () => {
                editor.insertText("### here is \"a quote\" with extra\" string delimiters\" ###\n");
                editor.insertText("var_name = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(12));
            });

            /*
            ### string with an \\"escaped delimiter in the middle###
            var_name = [0, 1, 2,;
            */
            it("correctly handles escaped delimieters at the end of a triple quoted string", () => {
                editor.insertText("### string with an \\\"escaped delimiter in the middle###\n");
                editor.insertText("var_name = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(12));
            });

            /*
            ### here is a string with an escaped delimiter ending\\###"
            var_name = [0, 1, 2,;
            */
            it("correctly handles escaped delimiters at the end of a quoted string", () => {
                editor.insertText("### here is a string with an escaped delimiter ending\\###\"\n");
                editor.insertText("var_name = [0, 1, 2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(12));
            });
        });

        describe("when unindenting after newline :: aligned with opening delimiter", () => {
            /*
            def test(param_a,
                     param_b):
                pass
            */
            it("unindents after close def params", () => {
                editor.insertText("def test(param_a,\n");
                pythonIndent.indent();
                editor.insertText("param_b):\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(4));
            });

            /*
            tup = (True, False,
                   False)
            */
            it("unindents after close tuple", () => {
                editor.insertText("tup = (True, False,\n");
                pythonIndent.indent();
                editor.insertText("False)\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe("");
            });

            /*
            a_list = [1, 2,
                      3]
            */
            it("unindents after close bracket", () => {
                editor.insertText("a_list = [1, 2,\n");
                pythonIndent.indent();
                editor.insertText("3]\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe("");
            });

            /*
            a_dict = {0: 0}
            */
            it("unindents after close curly brace", () => {
                editor.insertText("a_dict = {0: 0}\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe("");
            });

            /*
            def test(x):
                return [x[0], x[-1]]
            */
            it("unindents after return statement with same-line opened/closed brackets", () => {
                editor.insertText("def test(x):");
                makeNewline();
                editor.insertText("return [x[0], x[-1]]");
                makeNewline();
                expect(buffer.lineForRow(2)).toBe("");
            });

            /*
            def f(api):
                (api
                 .doSomething()
                 .anotherThing()
                 ).finish()
                print('Correctly indented!')
            */
            it("unindents correctly with same-line opened/closed brackets", () => {
                editor.insertText("def f(api):");
                makeNewline();
                editor.insertText("(api");
                makeNewline();
                editor.insertText(".doSomething()");
                makeNewline();
                editor.insertText(".anotherThing()");
                makeNewline();
                editor.insertText(").finish()");
                makeNewline(1);
                expect(buffer.lineForRow(5)).toBe(" ".repeat(4));
            });
        });
    });

    // Hanging
    describe("hanging", () => {
        describe("when indenting after newline", () => {
            /*
            def test(
                param_a
            )
            */
            it("hanging indents after open def params", () => {
                editor.insertText("def test(\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));
            });

            /*
            tup = (
                "elem"
            )
            */
            it("indents after open tuple", () => {
                editor.insertText("tup = (\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));
            });

            /*
            a_list = [
                "elem"
            ]
            */
            it("indents after open bracket", () => {
                editor.insertText("a_list = [\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));
            });

            /*
            def test(
                param_a,
                param_b,
                param_c
            )
            */
            it("indents on succeding open lines", () => {
                editor.insertText("def test(\n");
                pythonIndent.indent();
                editor.insertText("param_a,\n");
                editor.autoIndentSelectedRows(2);
                editor.insertText("param_b,\n");
                editor.autoIndentSelectedRows(3);
                expect(buffer.lineForRow(3)).toBe(" ".repeat(4));
            });

            /*
            def test(x):
                return (
                    x
                )
            */
            it("does not dedent too much when doing hanging indent w/ return", () => {
                editor.insertText("def test(x):");
                makeNewline(1);
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));
                editor.insertText("return (");
                makeNewline(1);
                expect(buffer.lineForRow(2)).toBe(" ".repeat(8));
            });

            /*
            def test(x):
                return (
                    x
                )
            */
            xit("correctly hanging indents return w/ newline between parentheses", () => {
                // This test is skipped because it does not work for unknown
                // reasons. The second makeNewline() call behaves differently
                // during test running than when I call the exact same steps
                // in the dev tools.
                editor.insertText("def test(x):");
                makeNewline();
                editor.insertText("return ()");
                editor.setCursorBufferPosition([1, editor.buffer.lineForRow(1).length - 1]);
                makeNewline();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(8));
                expect(buffer.lineForRow(3)).toBe(" ".repeat(4).concat(")"));
            });

            /*
            def test(x):
                yield (
                    x
                )
            */
            it("does not dedent too much when doing hanging indent w/ return", () => {
                editor.insertText("def test(x):");
                makeNewline(1);
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));
                editor.insertText("yield (");
                makeNewline(1);
                expect(buffer.lineForRow(2)).toBe(" ".repeat(8));
            });

            /*
            class TheClass(object):
                def test(
                        param_a, param_b,
                        param_c):
                            a_list = [
                                "1", "2", "3",
                                "4"
                            ]
            */
            it("allows for indent in multi-level situations", () => {
                editor.insertText("class TheClass(object):\n");
                editor.autoIndentSelectedRows(1);
                editor.insertText("def test(\n");
                pythonIndent.indent();
                editor.insertText("param_a, param_b,\n");
                editor.autoIndentSelectedRows(3);
                editor.insertText("param_c):\n");
                editor.autoIndentSelectedRows(4);
                expect(buffer.lineForRow(4)).toBe(" ".repeat(4));

                editor.insertText("a_list = [\n");
                pythonIndent.indent();
                editor.insertText("\"1\", \"2\", \"3\",\n");
                editor.autoIndentSelectedRows(6);
                editor.insertText("\"4\"]\n");
                editor.autoIndentSelectedRows(7);
                expect(buffer.lineForRow(7)).toBe(" ".repeat(4));
            });
        });

        describe("when newline is in a comment", () => {
            /*
            x = [    #
                0
            ]
            */
            it("indents when delimiter is not commented, but other characters are", () => {
                editor.insertText("x = [ #\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe(" ".repeat(4));
            });

            /*
             * [
             */
            it("does not indent when bracket delimiter is commented", () => {
                editor.insertText("# [\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe("");
            });

            /*
             * (
             */
            it("does not indent when parentheses delimiter is commented", () => {
                editor.insertText("# (\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe("");
            });

            /*
             * {
             */
            it("does not indent when brace delimiter is commented", () => {
                editor.insertText("# {\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe("");
            });

            /*
             * def f():
             */
            it("does not indent when function def is commented", () => {
                editor.insertText("# def f():\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(1)).toBe("");
            });
        });

        describe("when continuing a hanging indent after opening/closing bracket(s)", () => {
            /*
            alpha = (
                epsilon(),
                gamma
            )
            */
            it("continues correctly after bracket is opened and closed on same line", () => {
                editor.insertText("alpha = (");
                makeNewline();
                editor.insertText("epsilon(),");
                makeNewline(1);
                expect(buffer.lineForRow(2)).toBe(" ".repeat(4));
            });

            /*
            alpha = (
                    epsilon(arg1, arg2,
                            arg3, arg4),
                    gamma
            )
            */
            it("continues after bracket is opened/closed on different lines", () => {
                editor.insertText("alpha = (\n");
                pythonIndent.indent();

                editor.insertText("epsilon(arg1, arg2,\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(2)).toBe(" ".repeat(12));

                editor.insertText("arg3, arg4),\n");
                pythonIndent.indent();
                expect(buffer.lineForRow(3)).toBe(" ".repeat(4));
            });
        });
    });

    describe("when source is malformed", () =>

        /*
        class DoesBadlyFormedCodeBreak )
        */
        it("does not throw error or indent when code is malformed", () => {
            editor.insertText("class DoesBadlyFormedCodeBreak )\n");
            expect(() => pythonIndent.indent())
            .not.toThrow();
            expect(buffer.lineForRow(1)).toBe("");
        }),
    );
});
