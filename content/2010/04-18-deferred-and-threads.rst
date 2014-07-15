.. meta::
  tags: [python, twisted]

==========================
    Deferred + Threads 
==========================

В последнее время много знакомых пытаются писать какие-то сетевые вещи на twisted, и волей не волей все рано или поздно наталкиваются на такую вещь как Deferred. Deferred наверное самое сложное с чем стакливается новичек в twisted. Почти каждый человек открывая официальную документацию спрашивает себя (а то и меня) зачем же нужен Deferred если он сам по себе не делает код асинхронным. Вот здесь антипаттерн официальной документации twisted касаемо Deferred - попытка объяснить как работает Deferred совершенно забывая о потоках как таковых.  


Для примера рассмотрим реализацию сервиса-краулера предоставляющий доступ к своему API по протоколу xmlrpc.
Практический функционал краулера глубоко эзотерический, и я взял его для примера только потому что это была одна из первых моих программ на twisted с использованием Deferred и потоков. Краулер написан специально для сайта ozon.ru и предоставляет по id товара урл до изображения с обложкой этого товара. 

Для сервера используется `реализация xmlrpc в twisted`_.

.. _реализация xmlrpc в twisted: http://twistedmatrix.com/documents/current/web/howto/xmlrpc.html

Отбросим возможность использования twisted.web.client и html-парсеров, так будет более очевидна разница между блокируемым и неблокируемым кодом.


Начнем первый, очевидный вариант который думаю напишет каждый кто только начинает работать с twisted:

.. sourcecode:: python

    import re
    from urllib import urlopen

    from twisted.internet import reactor
    from twisted.web import xmlrpc, server
    # Объект регулярного выражения для поиска ссылки на обложку в пределах всей страницы.
    cover_regex = re.compile(r'(/multimedia/audio_cd_covers/(?:\d+)\.jpg)') 

    class CoverCrawler(xmlrpc.XMLRPC):
        
        def xmlrpc_get_cover(self, content_id): 
            """
            Метод XMLRPC который позволяет вытащить одну обложку.
            """
            # получаем контент страницы средствами urllib
            content = urlopen('http://www.ozon.ru/context/detail/id/%s' % content_id).read() 
            # ищем по regexp урл изображения и отправляем клиенту в xmlrpc
            return cover_regex.search(content).group()

    def main():
        crawler = CoverCrawler() 
        reactor.listenTCP(8080, server.Site(crawler))
        reactor.run()

    if __name__ == '__main__':
        main()


Вот пример краулера который вытаскивает один урл обложки с сайта. И он даже работает. Однако с точки зрения потоков этот код написан неправильно, ибо вызов функции urllib блокирует выполнение приложения и краулер будет ждать когда каждая из обложек будет скачана с сайта, естественно за это время не будет скачана никакая другая обложка, и никакой другой запрос от клиентов xmlrpc не будет обработан. Почему так получается, каждое приложение twisted работает в режиме глобального селектора, тоесть каждый из запросов серверу, ответов клиенту, запросов на сторонний ресурс или обращение к файлу фактически проходят через глобальную очередь которая называется reactor. Фактически все объекты Deferred, все их callback'ки выполняются тоже в реакторе. Для выхода из этой ситуации в twisted есть функционал для запуска опрпделенных функций в отдельном потоке, например для этого есть функция deferToThread которая тоже возвращает Deferred в котором будет результат выполнения переданной в него функции. По хорошему любую функцию которая будет блокировать выполнение программы можно и нужно оборачивать в deferToThread. Перепишем скачивание страницы с использованием deferToThread. 	    

.. sourcecode:: python

    import re
    from urllib import urlopen

    from twisted.internet import reactor, defer
    from twisted.internet.threads import deferToThread

    from twisted.web import xmlrpc, server

    cover_regex = re.compile(r'(/multimedia/audio_cd_covers/(?:\d+)\.jpg)')

    def getUrlContent(url): 
        """
        создаем отдельную функцию которая всегда будет неблокируемо получать 
        контент страницы и возвращать Deferred с ним
        """
        return deferToThread(lambda : urlopen(url).read())

    class CoverCrawler(xmlrpc.XMLRPC):
        
        def xmlrpc_get_cover(self, content_id):
            imageUrlDeferred = defer.Deferred()
            def _gotContent(content):           
                imageUrlDeferred.callback(cover_regex.search(content).group())
            getUrlContent('http://www.ozon.ru/context/detail/id/%s' % content_id
                         ).addCallbacks(_gotContent, imageUrlDeferred.errback)
            return imageUrlDeferred 
        
    def main():
        crawler = CoverCrawler() 
        reactor.listenTCP(8080, server.Site(crawler))
        reactor.run()

    if __name__ == '__main__':
        main()


Код выше работает неблокируемо. Однако вспоминая мои первые эксперементы, вспоминаю и момент, когда в процессе анализа логов обнаружилось что большинство id запрашиваемых через xmlrpc совпадают между собой. Тогда встал вопрос о кэшировании обложек по id-товара. 
Далеее реализация класса CoverCrawler с учетом кэширования:

.. sourcecode:: python

    class CoverCrawler(xmlrpc.XMLRPC):
        _linkCache = {} # dict в котором храним id_товара => url обложки
        
        def xmlrpc_get_cover(self, content_id):
            if content_id in self._linkCache:
                # Краткий reference:
                # twisted.internet.defer.succeed это шоткат, и код будет аналогичен
                # d = Deferred()
                # d.callback()
                # return d
                return succeed(self._linkCache[content_id])
            imageUrlDeferred = Deferred()

            def _gotContent(content): 
                image_link = cover_regex.search(content).group()
                self._linkCache[content_id] = image_link
                imageUrlDeferred.callback(image_link)
            
            getUrlContent('http://www.ozon.ru/context/detail/id/%s' % content_id
                    ).addCallback(_gotContent, imageUrlDeferred.errback)
            return imageUrlDeferred 
 
Теперь один не совсем очевидный момент. В самом первом варианте метод xmlrpc_get_cover возвращал строку, во втором и третьем варианте Deferred, при том первый и второй вариант остаются рабочими. Как это происходит, существует функция twisted.internet.defer.maybeDeferred, которая конвертирует результат выполнения функции в Deferred, если он таковым не является.


