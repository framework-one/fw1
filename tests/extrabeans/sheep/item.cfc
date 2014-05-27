component accessors="true" {
	property beanfactory;

    function init( numeric start = 0 ) {
	    param name="application.itemCount" default="#start#";
	    this.itemNumber = ++application.itemCount;
    }

	function getNewItem() {
		return variables.beanfactory.getBean( "item" );
	}

}
