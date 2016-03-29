# python-indent [![Build Status](https://travis-ci.org/DSpeckhals/python-indent.svg?branch=master)](https://travis-ci.org/DSpeckhals/python-indent)  

_Atom with easy PEP8 indentation...No more space bar mashing!_

![example of python-indent](https://raw.githubusercontent.com/DSpeckhals/python-indent/master/resources/img/python-indent-demonstration.gif)

__Python Indent__ is the indentation behavior you've been waiting for in Atom! You should no longer have to worry about mashing your tab/space/backspace key every time you press `enter` in the middle of coding. Also, compared to other editors, there is no need to change an app configuration if you want to have a mixture of different types of indents (namely hanging and opening-delimiter-aligned).

The main obstacle with Atom's native indentation behavior is that it doesn't yet have the necessary API's to do what Python's [PEP8 style guide](https://www.python.org/dev/peps/pep-0008/#indentation) suggests. Enhancement requests and issues have been opened in [Atom Core](https://github.com/atom/atom) on a few occasions, but none have been resolved yet.

- language-python - [Auto indent on line continuation with list/tuple](https://github.com/atom/language-python/issues/22)
- atom - [Autoindent not working properly](https://github.com/atom/atom/issues/6655)

This package was made to give you expected indentation behavior; __python-indent__ listens for `editor:newline` events in Python source files, and when triggered, adjusts the indentation to be lined up relative to the opening delimiter of the statement _or_ "hanging" (for parameters, tuples, or lists).

### Indent Types
Both indent types for continuing lines as described in [PEP 0008 -- Style Guide for Python Code](https://www.python.org/dev/peps/pep-0008/#indentation) are auto-detected and applied by this package.
  - Aligned with Opening Delimiter

    ```python
    def function_with_lots_of_params(param_1, param_2,
                                     param_3, param_4,
                                     very_long_parameter_name,
                                     param_6)
    ```
  - Hanging

      ```python
      def function_with_lots_of_params(
          param_1, param_2,
          param_3, param_4,
          very_long_parameter_name,
          param_6)
      ```

### Setting
- __Hanging Indent Tabs__: Number of tabs used for _hanging_ indents

### Examples

```python
def current_language_python_package(first_parameter, second_parameter,#<newline>
third_parameter):#<---default Atom language-python
    pass

def with_python_indent_package_added(first_parameter, second_parameter,
                                      third_parameter):
    #<--properly unindents to here
    pass

def with_hanging_indent(
    first_parameter, second_parameter, third_parameter):
    pass

also_works_with_lists = ["apples", "oranges", "pears", "peaches", "mangoes",
                         "clementines", "etc."]#<--PEP8 continued indentation
or_like_this = [
    "apples", "oranges", "pears",
    "peaches", "mangoes", "clementines",
    "etc."
]

```

There are plenty of other examples (ordinary and extraordinary) in the [test_file](https://github.com/DSpeckhals/python-indent/blob/master/spec/test_file.py).
