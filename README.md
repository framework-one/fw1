[![Build Status](https://travis-ci.org/framework-one/fw1.png)](https://travis-ci.org/framework-one/fw1)

This FW/1 directory is a complete web application and expects to live in its own
webroot if you plan to run the applications within it. To use FW/1 in a separate
webroot you can either copy the `framework` directory to that webroot or add a mapping
for `/framework` to the `framework` folder inside this FW/1 directory. Note that since
your `Application.cfc` needs to extend `framework.one`, you have to add the mapping
in your admin - you can't just use a per-application mapping.

**Project home:** http://fw1.riaforge.org

**Documentation wiki:** http://github.com/framework-one/fw1/wiki

**Blog:** http://framework-one.github.io

**Support:** http://groups.google.com/group/framework-one/

**Running the tests:**

The Ant `build.xml` file is primarily designed to be used by Travis to run the tests automatically, but it is possible to run the tests locally, with some setup:

* This FW/1 directory needs to be a web root for some test domain on your local machine. I have `fw1.local` setup to resolve to this folder.
* You'll need MXUnit installed and accessible via `/mxunit` for the test domain you use for this project. You can install MXUnit into this FW/1 directory if you want - `mxunit/*` is on the `.gitignore` list.

You can run the build locally using a variant of this command (all on one line):

    ant -Dplatform=railo41 -Dtest.path.root=/Developer/workspace/fw1 \
        -Dcontext.root= -Dserver.name=fw1.local -Dserver.port=8080 \
        run-tests-mxunit

See the `run-tests-example.sh` file for a template (for Mac/Linux).

* `platform` needs to be set just to satisfy the build script it doesn't affect anything (so use `railo41` even if you're on ACF or a different version of Railo)
* `test.path.root` should be the filesystem path to this directory, i.e., the web root for the FW/1 project.
* `context.root` should probably be empty (unless you are using a named web application context)
* `server.name` should be the test domain you have configured
* `server.port` should be the port on which you access that test domain
* `run-tests-mxunit` is the actual Ant task that does the testing
