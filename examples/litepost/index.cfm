<html>
<head>
	<title>FW/1 - LitePost - README</title>
</head>
<body>
<p>To run the FW/1 LitePost example, you need to:</p>
<ol>
<li>Download LitePost by checking it out of SVN into your webroot:<br />
	svn checkout http://litepost.googlecode.com/svn/trunk/ litepost</li>
<li>Download ColdSpring from http://coldspringframework.org/ (and put it in your webroot or create a /coldspring mapping to it).</li>
<li>Create a MySQL database and run litepost/db/blogTables.sql to set up your tables.</li>
<li>Configure a datasource called litepost pointing to your new database.</li>
<li>Create a /net/litepost mapping pointing to litepost/cfc/net/litepost.</li>
<li>Copy examples/litepost/fw1 from FW/1 to the litepost folder (so that http://localhost/litepost/fw1/ will work).</li>
<li>Make sure FW/1 is accessible as org.corfield.framework either by placing the /org folder in your webroot or creating a mapping for /org/corfield pointing to FW/1's org/corfield folder.</li>
</ol>
<p>Already done all of that? Want to run the FW/1 LitePost example?</p>
<p>Yeah, take me to <a href="/litepost/fw1/">FW/1 LitePost</a>!</p>
<p>To save you the trouble of figuring it out, the blog admin login is: chris / asstro</p>
<p><strong>Note:</strong> this example will not run if you have a non-empty context root.</p>
</body>
</html>