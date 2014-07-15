.. meta::
    tags: [java, solr]

========================================  
    Как поменять bind address в solr
========================================  

Для меня, как для человека не из мира Java, такой вопрос достоин отдельного поста. И так, как же сменить bind address в solr. 

Открываем /etc/jetty.xml, ищем ноду &lt;Call name="addConnector"&gt;&lt;/Call&gt;, и добавляем в Arg &gt; New такую строку:

.. sourcecode:: xml

	<Set name="host">
	    <SystemProperty name="jetty.host" default="127.0.0.1"/>
	</Set>
	

В итоге, вся нода Call у меня выглядит так:

.. sourcecode:: xml

	<Call name="addConnector">
	<Arg>
	    <New class="org.mortbay.jetty.bio.SocketConnector">
	        <Set name="port"><SystemProperty name="jetty.port" default="8983"/></Set>
	        <Set name="host"><SystemProperty name="jetty.host" default="127.0.0.1"/></Set>
	        <Set name="maxIdleTime">50000</Set>
	        <Set name="lowResourceMaxIdleTime">1500</Set>
	    </New>
	</Arg>
	</Call>

