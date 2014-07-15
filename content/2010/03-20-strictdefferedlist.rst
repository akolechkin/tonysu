.. meta::
    tags: [python, twisted]

==========================
    StrictDeferredList
==========================    

Основное что меня раздражало при использовании DeferredList это list со статусом выполнения каждого вложенного Deferred. При условии что 90% всех DeferredList которые я использовал по логике вещей должны валиться при первой ошибке. Из коробки twisted дает возможность убрать статус завершения каждого вложенного Deferred путем использования twisted.internet.defer.gatherResults, но такой вариант мне не нравился, получается очень некрасивая запись и лишний import.

В итоге я сделал класс который имеет почти такой-же интерфейс как и у DeferredList, но автоматически закидывает в callback только результаты выполнения вложенных Deferred.

.. sourcecode:: python

	from twisted.internet.defer import DeferredList, _parseDListResult

	class StrictDeferredList(DeferredList):
	    def __init__(self, deferredList, fireOnOneCallback=0):
	        DeferredList.__init__(self, deferredList, fireOnOneCallback, 1, 1)

	    def callback(self, result):
	        return DeferredList.callback(self, _parseDListResult(result))

использование:


.. sourcecode:: python

	from lib.twstd import StrictDeferredList
	StrictDeferredList(deferreds)

против

.. sourcecode:: python

	from twisted.internet.defer import DeferredList, gatherResults
	gatherResults(DeferredList(deferreds, 0, 1, 1))

конечно можно было легко написать функцию-обертку которая использует gatherResults

.. sourcecode:: python

	from twisted.internet.defer import DeferredList, gatherResults

	def strictDeferredList(deferreds, fireOnOneCallback=0)
	    return gatherResults(DeferredList(deferreds, fireOnOneCallback, 1, 1))


Однако меня смутил тот факт что сам gatherResults оборачивает DeferredList в еще один DeferredList, что немного сказывается на производительности и немного ухудшает дебаг.



