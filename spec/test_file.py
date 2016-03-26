# This file represents all known cases of special-case indentations


x = [0, 1, 2,
     3, 4, 5]

x = [0,
     1]

x = [0, 1, 2, [3, 4, 5,
               6, 7, 8]]

x = [[[0,1,2],
      3,4,5],
     6,7,8]

x = [0, 1, 2,
     [3, 4, 5,
      6, 7, 8]]

x = (0, 1, 2,
     3, 4, 5,
     6, 7, 8)

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

def test(param_a, param_b, param_c,
         param_d):
    pass

def test(param_a,
         param_b,
         param_c):
    pass

class TheClass(object):
    def test(param_a, param_b,
             param_c):
        a_list = ["1", "2", "3",
                  "4"]
x = [
    0, 1, 2,
    3, 4, 5
]

x = [  #
    0
]

# [

# (

# {

# def f():


def f(arg1, arg2, arg3,
      arg4, arg5, arg6=')\)',
      arg7=0):
    return 0


alpha = (
    epsilon(),
    gamma
)

alpha = (
    epsilon(arg1, arg2,
            arg3, arg4),
    gamma
)

for i in range(10):
    for j in range(20):
        def f(x=[0,1,2,
                 3,4,5]):
            return x * i * j


'''
Here is just one quote: '
'''
x = [0, 1, 2,
     4, 5, 6]


class DoesBadlyFormedCodeBreak )
