.. meta::
    tags: [python, django, i18n]

===============================
    Django - глубоко в i18n 
===============================

Казалось-бы обычная ситуация, есть поддержка 2 разных языков в проекте. Как получить перевод разных слов на разных языках в django. На первый взгляд звучит просто, но в официальной документации на этот счет не было ничего. Пришлось руками залесть в код (спасибо twisted за такой скилл), и найти нормальный способ сделать это. 

.. sourcecode:: python

    from django.utils.translation.trans_real import translation

    trans_en = translation('en') 
    trans_es = translation('es')

    print trans_en.ugettext('word') 
    print trans_es.ugettext('word')

Теперь в деталях. Функция-шоткат translation возвращает экземпляр объекта `DjangoTranslation` который в свою очередь является наследником объекта GNUTranslations. Чтоыб собрать нужный DjangoTranslation функция language собирает все django.mo файлы доступные в проекте. 

Единственный, на мой взгляд минус такого подхода - скорее всего не будет работать при USE_I18N=False, пока не проверял. 

.. _DjangoTranslation: http://code.djangoproject.com/browser/django/tags/releases/1.2.5/django/utils/translation/trans_real.py#L59

