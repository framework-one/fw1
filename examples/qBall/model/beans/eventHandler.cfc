component implements="CFIDE.orm.IEventHandler" {

	public void function preDelete(any entity) {
	 
	}

	public void function preInsert(any entity) {
		//only run if we have both audit cols
		if(structKeyExists(arguments.entity, "setCreated") && structKeyExists(arguments.entity, "setEdited")) {
			arguments.entity.setCreated(now());
			arguments.entity.setEdited(now());
		}
	}
	
	public void function preUpdate(any entity, struct oldData) {
		//only run if we have both audit cols
		if(structKeyExists(arguments.entity, "setCreated") && structKeyExists(arguments.entity, "setEdited")) {
			arguments.entity.setEdited(now());
		}
	}

	public void function preLoad( any entity) {
	
	}

	public void function postDelete( any entity) {
	
	}

	public void function postLoad( any entity) {
	
	}

	public void function postUpdate( any entity) {
	
	}

	public void function postInsert( any entity) {
	
	}

}