<p>FW/1 - Framework One - leverages Application.cfc and some simple conventions to provide a 'full' MVC framework in a single file.</p>
<p>Intended to require near-zero configuration, FW/1 lets you build your application without worrying about a framework getting in your way.</p>
<p>Controllers, Services (the gateway to your application's model), Views and Layouts are all 'discovered' using straightforward conventions.</p>
<p>Your controller and service CFCs don't need to extend anything.</p>
<p>Your views and layouts don't need to know about objects and method calls (a simple 'request context' structure - rc - is available containing URL and form scope data as well as data setup and passed by the framework and controllers).</p>
<p>Supports your choice of bean factory (as long as it offers containsBean(name) and getBean(name) methods) and autowiring of controllers and services. Your controller and service CFC instances can be managed by your bean factory instead if you prefer, again following a simple naming convention!</p>
