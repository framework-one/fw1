<h1>Welcome to the Framework One examples - with subsystems!</h1>
<p>This shows how individual FW/1 applications can be reused as 
	subsystems in a larger application with no code changes!</p>
<h2>Examples</h2>
<cfoutput>
<ul>
	<li><a href="#buildURL('errortest:')#">errortest subsystem</a></li>
	<li><a href="#buildURL('hello1:')#">hello1 subsystem</a></li>
	<li><a href="#buildURL('hello2:')#">hello2 subsystem</a></li>
	<li><a href="#buildURL('hello3:')#">hello3 subsystem</a></li>
	<li><a href="#buildURL('hello4:')#">hello4 subsystem</a></li>
	<li>hello5 - uses a custom base/cfcbase location so it cannot be reused as-is</li>
	<li><a href="#buildURL('hello6:')#">hello6 subsystem</a></li>
	<li><a href="#buildURL('hello7:')#">hello7 subsystem</a></li>
	<li><a href="#buildURL('hello8:')#">hello8 subsystem</a></li>
</ul>
</cfoutput>