# python-indent [![Build Status](https://travis-ci.org/DSpeckhals/python-indent.svg?branch=master)](https://travis-ci.org/DSpeckhals/python-indent)  

_Make Atom's Python auto-indentation behave in a truly PEP8 manner_

![example of python-indent](https://raw.githubusercontent.com/DSpeckhals/python-indent/master/resources/img/python-indent-demonstration.gif)

I love a lot about Atom, but when trying to write Python, I've often found myself frustrated with its indentation behavior in that language. The main problem I've found is that Atom's core indentation behavior doesn't have the necessary API's yet to do what Python's [PEP8 style guide](https://www.python.org/dev/peps/pep-0008/#indentation) suggests. Enhancement requests and issues have been opened in [Atom Core](https://github.com/atom/atom) on a few occasions, but none have been resolved yet.

- language-python - [Auto indent on line continuation with list/tuple](https://github.com/atom/language-python/issues/22)
- atom - [Autoindent not working properly](https://github.com/atom/atom/issues/6655)

This package is made to fill that gap; __python-indent__ listens for `editor:newline` events in Python source files, and when triggered, adjusts the indentation to be lined up relative to the opening delimiter of the statement _or_ "hanging" (for parameters, tuples, or lists). Also, when proper unindenting (back to normal) is necessary, this package assures that is done correctly.

### Settings

- __Continuation Indent Type__: Indent type for continuing lines as described in [PEP 0008 -- Style Guide for Python Code](https://www.python.org/dev/peps/pep-0008/#indentation).
  - aligned with opening delimiter

    ```python
    def function_with_lots_of_params(param_1, param_2,
                                     param_3, param_4,
                                     really_log_parameter_name,
                                     param_6)
    ```
  - hanging

      ```python
      def function_with_lots_of_params(
          param_1, param_2,
          param_3, param_4,
          really_log_parameter_name,
          param_6)
      ```
- __Fluid Indent Regex__: Regular expression string to find lines where the next line should be indented relative to the __opening delimiter__.
- __Fluid Unindent Regex__: Regular expression string to find lines where the next line should be indented relative to the current __block__.
- __Hanging Indent Tabs__: If __Continuation Indent Type__ is set to _hanging_, how many tabs should be used? If __Continuation Indent Type__ is not _hanging_, this setting is ignored

### Examples

```python
def current_language_python_package(first_parameter, second_parameter,#<newline>
third_parameter):#<---default Atom language-python
    pass

def with_python_indend_packgage_added(first_parameter, second_parameter,
                                      third_parameter):
    #<--properly unindents to here
    pass

def with_hanging_indent_option(first_parameter, second_parameter,
    third_parameter):
    pass

also_works_with_lists = ["apples", "oranges", "pears", "peaches", "mangoes",
                         "clementies", "etc."]#<--PEP8 continued indentation
or_like_this = [
    "apples", "oranges", "pears",
    "peaches", "mangoes", "clementines",
    "etc."
]

```
