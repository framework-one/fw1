component {

	function init(LogService){
		this.logService = logService;
		return this;
	}
	function before(methodname, args, target){
		this.logService.logMessage("Before:" & arguments.args.input);
		
	}
	function after(result, methodname, args, target){
		this.logService.logMessage("After:" & arguments.result);
	}
}