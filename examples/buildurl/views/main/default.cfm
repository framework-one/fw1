<cfoutput>
	<h1>Testbed for buildURL()</h1>
	<p><a href="#buildURL('')#">buildURL('')</a></p>
	<p><a href="#buildURL('.')#">buildURL('.')</a></p>
	<p><a href="#buildURL(':')#">buildURL(':') -- only valid in a subsystem-based app</a></p>
	<p><a href="#buildURL('main.default')#">buildURL('main.default')</a></p>
	<p><a href="#buildURL('main.default##anchor')#">buildURL('main.default##anchor')</a></p>
	<p><a href="#buildURL('main.default?##anchor')#">buildURL('main.default?##anchor')</a></p>
	<p><a href="#buildURL('main.default??##anchor')#">buildURL('main.default??##anchor')</a></p>
	<p><a href="#buildURL('main.default?test=1')#">buildURL('main.default?test=1')</a></p>
	<p><a href="#buildURL('main.default?test=1##anchor')#">buildURL('main.default?test=1##anchor')</a></p>
	<p><a href="#buildURL('main.default??test=2')#">buildURL('main.default??test=2')</a></p>
	<p><a href="#buildURL('main.default??test=2##anchor')#">buildURL('main.default??test=2##anchor')</a></p>
	<p><a href="#buildURL(action='main.default',queryString='##anchor')#">buildURL(action='main.default',queryString='##anchor')</a></p>
	<p><a href="#buildURL(action='main.default',queryString='?##anchor')#">buildURL(action='main.default',queryString='?##anchor')</a></p>
	<p><a href="#buildURL(action='main.default',queryString='test=1')#">buildURL(action='main.default',queryString='test=1')</a></p>
	<p><a href="#buildURL(action='main.default',queryString='test=1##anchor')#">buildURL(action='main.default',queryString='test=1##anchor')</a></p>
	<p><a href="#buildURL(action='main.default',queryString='?test=2')#">buildURL(action='main.default',queryString='?test=2')</a></p>
	<p><a href="#buildURL(action='main.default',queryString='?test=2##anchor')#">buildURL(action='main.default',queryString='?test=2##anchor')</a></p>
</cfoutput>
