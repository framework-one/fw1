component{
	this.name = 'fw1 test';

	this.mappings['/mxunit'] = getDirectoryFromPath(getCurrentTemplatePath()) & "../../mxunit";	
	this.mappings['/framework'] = getDirectoryFromPath(getCurrentTemplatePath()) & "../framework";
	this.mappings['/tests'] = getDirectoryFromPath(getCurrentTemplatePath());
    this.mappings['/goldfish/trumpets'] = expandPath( "/tests/extrabeans" );
}
