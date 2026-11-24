component {

    // Hold the first construction before DI/1 can cache the instance.
    if ( structKeyExists( request, "singletonRace" ) &&
         request.singletonRace.constructions.incrementAndGet() == 1 ) {
        request.singletonRace.constructing.countDown();
        if ( !request.singletonRace.release.await( javaCast( "long", 15 ), request.singletonRace.seconds ) ) {
            throw "Timed out waiting to release singleton construction";
        }
    }

    function setDependency( any dependency ) {
        this.dependency = dependency;
    }

}
