var onLoadHasFired = false;
var bf = new framework.ioc("/tests/model").onLoad(function(beanFactory){
        onLoadHasFired = true;
    });
var q = bf.containsBean( "foo" );
assertTrue( onLoadHasFired ); 