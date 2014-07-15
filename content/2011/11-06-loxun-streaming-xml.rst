.. meta:: 

    tags: [python, xml, loxun]


================================================
    Loxun - потоковая генерация xml в python
================================================


`Loxun`_ - отличная замена для XMLGenerator из xml.sax. В чем его плюсы перед последним:

.. _`Loxun`: https://github.com/roskakori/loxun

SAX:

.. sourcecode:: python

    xml = XMLGenerator(out)
    xml.startDocument()
    xml.startElement('root')
    xml.startElement('body')
    xml.startElement('item')
    xml.characters('some data')
    xml.endElement('item')
    xml.endElement('body')
    xml.endElement('root')
    xml.endDocument()

Loxun:

.. sourcecode:: python

    xml = XmlWriter(out)
    xml.startTag('root')
    xml.startTag('body')
    xml.startTag('item')
    xml.text('somedata')
    xml.endTag()
    xml.endTag()
    xml.endTag()

Либо еще короче вместо трех вызовов endTag можно сделать xml.endTags() и все открытые элементы закроются автоматически.


Пойдем далее, необходимо добавить элемент вида:

.. sourcecode:: xml

    <addr host="127.0.0.1" port="8080" />


SAX:

.. sourcecode:: python

    xml.startElement('addr', {'host': '127.0.0.1', 'port': 8000})
    xml.endElement('addr')

Loxun:

.. sourcecode:: python

    xml.tag('addr', {'host': '127.0.0.1', 'port': 8080})


Работа с xmlns

SAX:

.. sourcecode:: python

    xml = XMLGenerator(out)
    xml.startDocument()
    xml.startElement('root', {'xmlns:g': '/some/url/to/xmlns'})
    xml.startElement('item')
    xml.startElementNS('image', 'g')
    xml.characters('some data')
    xml.endElementNS('image', 'g')
    # .... 

Loxun:

.. sourcecode:: python    

    xml = XmlWriter(out)
    xml.addNamespace('xmlns:g', '/some/url/to/xmlns')
    xml.startTag('root')
    xml.startTag('item')
    xml.startTag('g:image')
    xml.text('somedata')
    xml.endTags()


Преимущество такого подхода в том, что значительно упрощается автоматизация, ниже будет пример. Но есть и другие полезные вещи loxun которых нет в SAX:    

 - Никаких UnicodeDecodeError loxun конвертирует в unicode сам.
 - XmlWriter сам по себе является context-manager'ом, а значит можно использовать with.
 - Полезная функция сделанная мной - возможно использовать method chaining.
 - pretty-print из коробки.

И так, пример генерации google merchant feed.

.. sourcecode:: python

    from loxun import ChainXmlWriter

    SITE_TITLE = 'tony.su'
    SITE_LINK = 'tony.su'
    SITE_DESCRIPTION = "tony's blog"

    def export_merchant_xml(file, products):
        with ChainXmlWriter(file) as xml:
            xml.addNamespace('g', 'http://base.google.com/ns/1.0')
            xml.startTag('rss', {'version': '2.0'}).startTag('channel')
            xml.startTag('title').text(SITE_TITLE).endTag()
            xml.startTag('link').text(SITE_LINK).endTag()
            xml.startTag('description').cdata(SITE_DESCRIPTION).endTag()
            xml_fields = (
                        ('title', 'title'),
                        ('link', 'get_absolute_url'),
                        ('description', 'descr_short'),
                        ('g:image_link', 'get_pic_url'),
                        ('g:price', 'price'),
                        ('g:condition', 'condition'),
                        ('g:id', 'get_merchant_id'),
                    )

            for product in products:
                xml.startTag('item')        
                for xml_field, attr_name in xml_fields:
                    xml.startTag(xml_field)
                    attr = getattr(product, attr_name)
                    xml.text(unicode(attr if not callable(attr) else attr()))
                    xml.endTag()
                xml.endTag()
            xml.endTags()

    def main():
        with open('merchant.xml', 'w') as f:
            products = [] # итератор с объектами загруженными из базы данных 
            export_merchant_xml(f, products)

    if __name__ == '__main__':
        main()


