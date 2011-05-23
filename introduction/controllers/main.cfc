component {

	public void function default( struct rc ) {
		rc.files = directoryList( expandPath(request.base) & "../examples/", false, "query" );
	}

}