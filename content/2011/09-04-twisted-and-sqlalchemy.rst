.. meta::
    tags: [python, twisted, sqlalchemy]

============================
    Twisted + SqlAlchemy
============================

Так уж получается, что пишу посты исключительно по просьбе знакомых, либо когда меня много раз просят объяснить или показать одну и ту же вещь.
На сей раз описываю вариант взаимодействия twisted и sqlalchemy. Сразу говорю что изначально авторство не моё, мне подсказали подобный вариант использования на IRC канале #python в сети freenode.net, к сожалению ника подсказавшего уже не помню.

Для начала немного теории, как можно использовать реляционную базу данных асинхронно с применением twisted:

 + Можно использовать `twisted.enterprise.adbapi`_ однако подружить с SqlAlchemy его достаточно сложно. Конечно, можно использовать только конструктор запросов из SqlAlchemy и запускать их напрямую в adbapi.
 + Драйвер psycopg2 поддерживает `неблокируемые запросы`_. 
 + Когда-то существовал проект `SaSync`_ который на данный момент находится в неживом состоянии.
 + Использовать свою обертку для SqlAlchemy и Twisted. 

.. _twisted.enterprise.adbapi: http://twistedmatrix.com/documents/current/core/howto/rdbms.html
.. _неблокируемые запросы: http://initd.org/psycopg/docs/advanced.html#support-to-coroutine-libraries
.. _SaSync: http://pypi.python.org/pypi/sAsync

Больше чем уверен, есть еще много других способов, но здесь я опишу последний.

Перед тем как начать, я опишу значение декоратора toThread, использование которого будет ниже: 

.. sourcecode:: python

    from twisted.internet import threads

    def toThread(f):
        def wrapper(*args, **kwargs):
            return threads.deferToThread(f, *args, **kwargs)
        return wrapper

Декоратор оборачивает функцию в deferToThread и делает её неблокируемой, соответственно возвращает Deferred.


Теперь сама функция-декоратор которая позволяет делать неблокируемые запросы к базе данных:

.. sourcecode:: python

    from sqlalchemy import create_engine, pool 
    from sqlalchemy.orm import sessionmaker

    from twisted_decorators import toThread

    class DBDefer(object):
        def __init__(self, dsn, poolclass=pool.SingletonThreadPool):
            self.engine = create_engine(dsn, poolclass=poolclass)
        
        def __call__(self, func):
            @toThread
            def wrapper(*args, **kwargs):
                session = sessionmaker(bind=self.engine)()
                try:
                    return func(session=session, *args, **kwargs)
                except:
                    session.rollback()
                    raise
                finally:
                    session.close()
            return wrapper


Пример использования:

.. sourcecode:: python

    from twisted.web import xmlrpc, server
    from twisted.internet import reactor
    from twisted.internet.defer import Deferred

    import sqlalchemy as sa

    from sa_decorators import DBDefer

    dbdefer = DBDefer('postgres://postgres@localhost/mytestdb')
    metadata = sa.MetaData(dbdefer.engine)

    userTable = sa.Table('user', metadata,
            sa.Column('user_id', sa.Integer(11), primary_key=True),
            sa.Column('login', sa.String(30), unique=True),
            sa.Column('first_name', sa.String(30), nullable=True),
            sa.Column('last_name', sa.String(30), nullable=True),
    )

    class User(object):
        def __init__(self, login, first_name, last_name):
            self.login = login
            self.first_name = first_name
            self.last_name = last_name

        def __iter__(self):
            return (t for t in self.__dict__.iteritems() if not t[0].startswith('_'))

    sa.orm.mapper(User, userTable)

    @dbdefer
    def createUser(login, first_name, last_name, session=None):
        user = User(login=login, first_name=first_name, last_name=last_name)
        session.add(user)
        session.commit()
        new_user = session.query(User).filter_by(user_id=user.user_id).first()
        session.flush()
        return new_user

    @dbdefer
    def getUser(user_id, session=None):
        return session.query(User).filter_by(user_id=user_id).first()

    class UserService(xmlrpc.XMLRPC):
        def xmlrpc_create_user(self, login, first_name, last_name):
            return createUser(login, first_name, last_name).addCallback(dict)
        
        def xmlrpc_get_user(self, user_id):
            d = Deferred()
            def _gotResult(_user):
                if _user is None:
                    d.errback('No such user')
                else:
                    d.callback(dict(_user))
                return _user
            getUser(user_id).addCallbacks(_gotResult, d.errback)
            return d
            
    def main():
        userService = UserService()
        reactor.listenTCP(8000, server.Site(userService))
        reactor.run()

    if __name__ == '__main__':
        main()


Исходные коды доступны в `репозитарии bitbucket`_.

.. _репозитарии bitbucket: https://bitbucket.org/tony/twisted_and_sqlalchemy_demo

