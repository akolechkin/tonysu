.. meta::
    tags: [python, context-managers, with]


============================================================
    with - заблуждения об управлении контекстом в python
============================================================

Информация в этом посте быть может очевидна для многих, но все же может быть полезной тем, кто не уверен в знаниях об управлении контекстом.
Про управление контекстом и with написано очень много и с очень давних времен. Однако, почему-то не все понимают казалось-бы очевидные вещи, например за последний месяц мне пришлось двум разным людям объяснить элементарные вещи о работе с with. Во многих примерах есть уопмянание класса с методами __enter__ и __exit__ например `первая ссылка в гугле`_, или даже без примера, и так неплохо объяснено в `официальной документации`_. 

.. _первая ссылка в гугле: http://proft.me/2010/06/24/python-i-menedzher-konteksta/
.. _официальной документации: http://docs.python.org/reference/datamodel.html#with-statement-context-managers

Еще раз копирую пример здесь:

.. sourcecode:: python

    class Logger(object):
        def __init__(self, val):
            self.val = val 
            print "%d :: __init__" % self.val

        def __enter__(self):
            print "%d :: __enter__" % self.val

        def __exit__(self, exc_type, exc_val, exc_tb):
            print "%d :: __exit__ " % self.val

    for i in xrange(5):
        with  Logger(i) as log:
            pass    

Почти ни у кого не возникает вопросов в какой момент срабатывает __enter__, а в какой __exit__ однако, далеко не все понимают что эти два метода НЕ являются деструкторами и конструкторами класса (в данном случае Logger), и соответственно не являются заменой методов __new__ и __del__, а значит оператор with может быть применен к экземпляру класса Logger более одного раза. 

Вот так:

.. sourcecode:: python

    logger = Logger(0)

    for i in xrange(5):
        logger.val += 1
        with logger as log:
            pass


Есть еще одно заблуждение, и оно в принципе обосновано ибо тут уже начинают немного пудрить мозги примеры. Многие думают, что внутрь контекста идет обязательно инстанс того объекта, который был передан в with, то есть в переменной log обязательно будет инстанс класса Logger. Однако, это не так. В контекст попадает любой объект который возвращает __enter__, и в примере выше переменная log будет равна None, более подробный пример можете посмотреть по ссылке выше, хоть он и бесполезен в python 2.7.

Далее, где можно применить управление контекстом кроме банального открытия файлов:

 - Больше всего мне понравился пример с `concurrent`_
 - Отличный пример - `управление транзакциями в Django`_
 - `assertNumQueries в django.test`_
 - Давно валялся в закладках `пример отслеживания времени бенчмарков`_
 - `elementflow`_

.. _concurrent: http://docs.python.org/dev/library/concurrent.futures.html#threadpoolexecutor-example
.. _управление транзакциями в Django: https://docs.djangoproject.com/en/1.3/topics/db/transactions/#controlling-transaction-management-in-views
.. _assertNumQueries в django.test: https://docs.djangoproject.com/en/1.3/topics/testing/#django.test.TestCase.assertNumQueries
.. _пример отслеживания времени бенчмарков: http://dabeaz.blogspot.com/2010/02/context-manager-for-timing-benchmarks.html
.. _elementflow: http://softwaremaniacs.org/blog/2010/05/19/elementflow/ 


Примеров очень много, и применение зависит только от фантазии программиста.


