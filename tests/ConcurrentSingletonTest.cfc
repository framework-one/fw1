component extends="mxunit.framework.TestCase" {

    function testConcurrentSingleton() {
        checkConcurrentLookups( "singleton", "singleton" );
    }

    function testConcurrentSingletonAlias() {
        checkConcurrentLookups( "singleton", "singletonAlias" );
    }

    function testConcurrentRootsSharingSingleton() {
        checkConcurrentLookups( "firstRoot", "secondRoot" );
    }

    private void function checkConcurrentLookups( string firstName, string secondName ) {
        var factory = new framework.ioc( "" );
        factory.declareBean( "singleton", "tests.concurrentSingleton.singleton" );
        factory.addAlias( "singletonAlias", "singleton" );
        factory.declareBean( "firstRoot", "tests.concurrentSingleton.root" );
        factory.declareBean( "secondRoot", "tests.concurrentSingleton.root", false );
        factory.addBean( "dependency", { } );
        var first = "iocFirst" & replace( createUUID(), "-", "", "all" );
        var second = "iocSecond" & replace( createUUID(), "-", "", "all" );
        var race = {
            factory = factory,
            constructions = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init( 0 ),
            constructing = newLatch(),
            release = newLatch(),
            lookingUp = newLatch(),
            finished = newLatch(),
            seconds = createObject( "java", "java.util.concurrent.TimeUnit" ).SECONDS
        };
        request.singletonRace = race;
        try {
            thread name=first beanName=firstName {
                thread.bean = request.singletonRace.factory.getBean( attributes.beanName );
            }
            try {
                assertTrue( race.constructing.await( javaCast( "long", 5 ), race.seconds ),
                            "The first lookup never entered singleton construction" );
                thread name=second beanName=secondName {
                    request.singletonRace.lookingUp.countDown();
                    try {
                        thread.bean = request.singletonRace.factory.getBean( attributes.beanName );
                    } finally {
                        request.singletonRace.finished.countDown();
                    }
                }
                assertTrue( race.lookingUp.await( javaCast( "long", 5 ), race.seconds ),
                            "The second lookup never started" );
                // On the old factory the second lookup completes, then the first
                // overwrites its cache entry. With the lock it waits for release.
                race.finished.await( javaCast( "long", 2 ), race.seconds );
            } finally {
                race.release.countDown();
                thread action="join" name=first timeout=10000;
                if ( structKeyExists( cfthread, second ) ) {
                    thread action="join" name=second timeout=10000;
                }
            }

            assertEquals( "COMPLETED", cfthread[ first ].status );
            assertEquals( "COMPLETED", cfthread[ second ].status );
            var firstBean = cfthread[ first ].bean;
            var secondBean = cfthread[ second ].bean;
            if ( firstName == "firstRoot" ) {
                firstBean = firstBean.singleton;
                secondBean = secondBean.singleton;
            }
            var cachedBean = factory.getBean( "singleton" );
            var dependency = factory.getBean( "dependency" );
            assertTrue( structKeyExists( cachedBean, "dependency" ), "The cached singleton is unwired" );
            assertSame( dependency, cachedBean.dependency );
            assertTrue( structKeyExists( firstBean, "dependency" ), "The first lookup returned an unwired singleton" );
            assertSame( dependency, firstBean.dependency );
            assertTrue( structKeyExists( secondBean, "dependency" ), "The second lookup returned an unwired singleton" );
            assertSame( dependency, secondBean.dependency );
            assertSame( firstBean, secondBean, "The lookups returned different singleton instances" );
            assertSame( firstBean, cachedBean, "The cached singleton differs from the first lookup" );
            assertEquals( 1, race.constructions.get() );
        } finally {
            structDelete( request, "singletonRace" );
        }
    }

    private any function newLatch() {
        return createObject( "java", "java.util.concurrent.CountDownLatch" ).init( 1 );
    }

}
