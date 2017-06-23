# FW/1 (Framework One) [![Build Status](https://travis-ci.org/framework-one/fw1.png)](https://travis-ci.org/framework-one/fw1) [![Stories in Ready](https://badge.waffle.io/framework-one/fw1.png?label=ready&title=Ready)](http://waffle.io/framework-one/fw1) [![Join the chat at https://gitter.im/framework-one/fw1](https://badges.gitter.im/framework-one/fw1.svg)](https://gitter.im/framework-one/fw1?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This FW/1 directory is a complete web application and expects to live in its own
webroot if you plan to run the applications within it. To use FW/1 in a separate
webroot you can either copy the `framework` directory to that webroot or add a mapping
for `/framework` to the `framework` folder inside this FW/1 directory. Note that since
your `Application.cfc` needs to extend `framework.one`, you have to add the mapping
in your admin - you can't just use a per-application mapping.

Please read the [Framework One Code of Conduct](CODE_OF_CONDUCT.md) - we want FW/1 to be a welcoming and supportive environment for everyone to feel comfortable contributing!

# Resources

**Project home:** https://github.com/framework-one/fw1

**Documentation / Wiki:** http://framework-one.github.io/documentation/ / http://github.com/framework-one/fw1/wiki

**Blog:** http://framework-one.github.io

**Support:** http://groups.google.com/group/framework-one/

**Chat:** The [CFML team Slack](http://cfml-slack.herokuapp.com) has a [dedicated #fw1 channel](https://cfml.slack.com/messages/fw1/).

# Running the Tests

FW/1 is setup to run tests on [Travis CI](https://travis-ci.org/framework-one/fw1) using the `.travis.yml` file.

To run tests manually, you'll need [CommandBox](https://www.ortussolutions.com/products/commandbox) installed.

Then run `box install` once to install the dependencies (TestBox is the only one currently).

Then start a server on port 8500 with your choice of CFML engine, e.g.,

    box server start cfengine=lucee@5 port=8500

This will open a browser, running the FW/1 "Introduction" app.

You can then run the tests:

    box testbox run reporter=mintext

# Copyright and License

Copyright (c) 2009-2017 Sean Corfield (and others -- see individual files for additional copyright holders). All rights reserved.
The use and distribution terms for this software are covered by the Apache Software License 2.0 (http://www.apache.org/licenses/LICENSE-2.0) which can also be found in the file LICENSE at the root of this distribution and in individual licensed files.
By using this software in any fashion, you are agreeing to be bound by the terms of this license. You must not remove this notice, or any other, from this software.
