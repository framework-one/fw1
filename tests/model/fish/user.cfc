component accessors="true" {
	property item;
    property string itemLamb; // do not inject this!

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
