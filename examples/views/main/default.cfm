<h1>Welcome to the Framework One examples - with subsystems!</h1>
<p>This shows how individual FW/1 applications can be reused as
	subsystems in a larger application with no code changes!</p>
<h2>Examples</h2>
<cfoutput>
<ul>
	<li><a href="#buildURL('errortest:')#">errortest subsystem</a></li>
	<li><a href="#buildURL('1helloworld:')#">basic hello world subsystem</a></li>
	<li><a href="#buildURL('2hellolinked:')#">linked hello world subsystem</a></li>
	<li><a href="#buildURL('3hellolayout:')#">hello world with layout subsystem</a></li>
	<li><a href="#buildURL('4hellocontroller:')#">hello world controller subsystem</a></li>
	<li><a href="#buildURL('5helloservice:')#">hello world service subsystem</a></li>
	<li>
      <cfif getBeanFactory().containsBean( "cfmljure" ) and
            getBeanFactory().getBean( "cfmljure" ).isAvailable()>
        <a href="#buildURL('6helloclojure:')#">hello world clojure subsystem</a>
      <cfelse>
        hello world clojure subsystem not available: clojure is not loaded --
        most likely due to leiningen not being installed / found
      </cfif>
    </li>
</ul>
</cfoutput>
