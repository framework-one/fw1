component accessors="true" {
	property item;

	function init( product ) {
		variables.product = product;
	}

    function getProduct() {
        return variables.product;
    }

    function itemTest() {
        return structKeyExists( variables, "item" ) ? variables.item : "missing";
    }

}
