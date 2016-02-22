# This file represents all known cases of special-case indentations

x = [0, 1, 2,
     3, 4, 5]

x = [0,
     1]

x = [0, 1, 2, [3, 4, 5,
               6, 7, 8]]

x = [0, 1, 2,
     [3, 4, 5,
      6, 7, 8]]

x = (0, 1, 2,
     3, 4, 5)

x = (0,
     1)

x = (0, 1, 2, [3, 4, 5,
               6, 7, 8],
     9, 10, 11)

x = {0: 0, 1: 1,
     2: 2, 3: 3}

x = {0: 0, 1: 1,
     2: 2, 3: 3, 4: [4, 4,
                     4, 4]}

s = '[ will this \'break \( the parsing?'

x = ['here(\'(', 'is', 'a',
     'list', 'of', ['nested]',
                    'strings\\'],
     r'some \[\'[of which are raw',
     'and some of which are not']


def f(arg1, arg2, arg3,
      arg4, arg5, arg6=')\)',
      arg7=0):
    return 0
