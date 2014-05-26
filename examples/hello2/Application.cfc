component extends="framework.one" {
	// this demonstrates the global before/after methods:
	function before( rc ) {
		rc.information = "Powered by Framework One!";
	}
	function after( rc ) {
		rc.information = rc.information & " Copyright (c) 2011-2014 Sean Corfield, Marcin Szczepanski, Ryan Cogswell.";
	}
}
