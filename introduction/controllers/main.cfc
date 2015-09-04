component {

	public void function default( struct rc ) {
		rc.files = directoryList( expandPath(request.base) & "../examples/", false, "query" );
		rc.subsystems = directoryList( expandPath(request.base) & "../examples/subsystems/", false, "query" );
	}

}
