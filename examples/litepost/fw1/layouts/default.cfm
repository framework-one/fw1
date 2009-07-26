<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<cfparam name="rc.title" default="LitePost Blog" />
	<title><cfoutput>#rc.title#</cfoutput></title>
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">

	<style type="text/css" media="all">
	<!--
	@import url("../assets/css/lp_layout.css");
	@import url("../assets/css/lp_text.css");
	@import url("../assets/css/lp_forms.css");
	-->
	</style>

</head>

<body>

<!-- display divider-->
<div id="bar">&nbsp;</div>

<cfoutput>
<!-- main container -->
<div id="container">

	<!-- login/out button -->
	<cfif rc.isAdmin>
		<a href="?#framework.action#=blog.logout" id="loginbutton" class="adminbutton">Log Out</a>
	<cfelse>
		<a href="?#framework.action#=blog.login" id="loginbutton" class="adminbutton">Log In</a>
	</cfif>
	
	<!-- header block -->
	<div id="header"><a href="?#framework.action#=blog.main"><img src="../assets/images/litePost_logo.gif" alt="litePost" border="0" /></a></div>
	
	<!-- wrapper block to constrain widths -->
	<div id="wrapper">
		<!-- begin body content -->
		<div id="content">
			
			<!-- anchor to top of content, also used for skip to content links-->
			<a name="content"></a>
			
			<!-- content -->
			#body#
		
	  	</div>
		
	</div>
	<!-- navigation -->
	<div id="navigation">
		
		#view('blog/navigation')#
		
	</div>
	
	<!-- site footer-->
	<div id="footer"><p>LitePost is made under the Creative Commons license! (or something like that)</p></div>
	
</div>
</cfoutput>

</body>
</html>