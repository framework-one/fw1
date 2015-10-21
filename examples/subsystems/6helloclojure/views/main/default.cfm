<cfoutput>
  <cfif getBeanFactory().getBean( "cfmljure" ).isAvailable()>
    <h1>Hello!</h1>
    <p>Clojure produced the greeting "#rc.greeting#"</p>
    <p>We can also get a greeterService in Clojure and use that:
        #getBeanFactory().getBean("greeterService").hello("Earthling")#<p>
    <p>Display this page with <a href="#buildURL( action = 'main', queryString = 'name=Clojure is alive' )#">a value specified for 'name'</a>.</p>
    <p>Try calling <a href="#buildURL('main.do_redirect')#">redirect()</a>. Name will be Mr. Redirect.</p>
    <p>Try calling <a href="#buildURL('main.stop_it')#">abortController()</a>. Also calls setView().</p>
    <p>Try calling <a href="#buildURL('main.json')#">renderData()</a>. You'll get a Clojure structure rendered as JSON!</p>
  <cfelse>
    <h1>Sorry!</h1>
    <p>Clojure is not loaded -- most likely due to Leiningen not being installed / found.</p>
  </cfif>
</cfoutput>
