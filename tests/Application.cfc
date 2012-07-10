component{
	this.name = 'fw1 test';

	this.mappings['/mxunit'] = getDirectoryFromPath(getCurrentTemplatePath()) & "../../mxunit";	
	this.mappings['/org'] = getDirectoryFromPath(getCurrentTemplatePath()) & "../org";
}