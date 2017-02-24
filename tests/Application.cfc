component{
	this.name = 'fw1 test';
  variables.here = getDirectoryFromPath(getCurrentTemplatePath());
	this.mappings['/mxunit'] = variables.here & "../testbox/system/compat";
	this.mappings['/framework'] = variables.here & "../framework";
	this.mappings['/tests'] = variables.here;
  this.mappings['/goldfish/trumpets'] = variables.here & "extrabeans";
}
