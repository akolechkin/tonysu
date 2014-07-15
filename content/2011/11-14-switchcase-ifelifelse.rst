.. meta::
    tags: [python]


===========================================
    switch-case и if-elif-else в python
===========================================

Многие кидают камень в огород python за то, что там нет полноценного блока switch-case. 
Некоторые из огорода python кидают ответный камень говоря про замену в виду if-elif-else

Я не одобряю не тех не других и матерю оба лагеря, ибо считаю что блоки подобные switch-case просто не нужны в большинстве случаев. И в свою очередь if-elif-else как эмуляция именно switch-case тоже бесполезна.  

Типичный блок кода с if-elif-else и эмуляцией switch-case:

.. sourcecode:: python

    if token == 1:
        do_something1()
    elif token == 2:
        do_something2()
    elif token == 3:
        do_something3()
    elif token == 4:
        do_something4()
    elif token == 5:
        do_something5()
    else:
        raise ValueError('unknown token %s' % token)

Это убого и некрасиво. 

Теперь красиво:

.. sourcecode:: python

    tokens = (do_something1, do_something2, do_something3,
              do_something4, do_something5) 
    if token < 1 or token > len(tokens):
        raise ValueError('unkown token %s' % token)

    tokens[int(token)-1]()


Аналогично с dict, в случае если token может быть произвольной строкой.
Пример сложнее, если в do_something[0-9] передаются произвольные аргументы.

.. sourcecode:: python

    from functools import partial as p
    tokens = (p(do_something1, 123), p(do_something2, mykwarg=666), 
              p(do_something3, 'arg', mykwarg=777, mykwarg2=888), 
              do_something4, p(do_something5, args),)

Далее в точности как в примере выше.
Можно обойтись и без functools, и сделать все руками, никаких проблем. 

Однако, if-elif-else может быть полезен, но только в том случае, когда он не используется как замена для swtich-case.
Пример из cyrax:

.. sourcecode:: python

    def parse_line(line):
        key, value = strip(line.split(':', 1))
        s, e = value.startswith, value.endswith
        if s('[') and e(']'):
            value = strip(value[1:-1].split(','))
        elif s('{') and e('}'):
            value = dict(strip(x.split(':')) for x in value[1:-1].split(','))
        elif s('date:'):
            value = parse_date(value[len('date:'):].strip())
        elif key.strip() == 'date':
            try:
                value = parse_date(value)
            except ValueError:
                pass
        elif value.lower() in 'true yes on'.split():
            value = True
        elif value.lower() in 'false no off'.split():
            value = False
        return key, value
   

