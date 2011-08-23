<cfoutput>
	<p>Hello #rc.data#!</p>
	<form action="" method="get">
		<input type="hidden" name="action" value="#getFullyQualifiedAction('main.default')#" />
		Name: <input type="text" name="name" /><br />
		<input type="submit" name="submit" value="Submit" />
	</form>
	<p>The following data was captured by the controller by running a view:</p>
	#rc.captured#
</cfoutput>