This is a test for a issue which has been seen under heavy load where a
transient which has a dependancy on a singleton, doesn't always get wired up.

To run this test you will need to use jMeter (and optional commandbox).

The jMeter test expects the server to accessible at localhost:8765 but you change
port and hostname in the test. The expected response is 'Hello World'

Then run `tests/iocLoad/jmeter/TestPlan.jmx` in jMeter.
