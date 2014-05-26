component {

	function before( rc ) {
		// change skin if specified:
		if ( structKeyExists( rc, 'skin' ) ) {
			session.skin = rc.skin;
		}
		// set skin for each request:
		if ( structKeyExists( session, 'skin' ) ) {
			rc.skin = session.skin;
		} else {
			rc.skin = 'default';
		}
	}

}
