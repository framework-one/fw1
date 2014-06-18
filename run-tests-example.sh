#!/bin/sh
#
# DO NOT MODIFY THIS FILE!
#
# COPY IT TO run-tests.sh AND MODIFY IT TO MATCH YOUR LOCAL
# ENVIRONMENT: test.path.root should be the file system path to your
# local repo, which should be an active web root for your CFML engine;
# server.name should be the local DNS entry that points to this
# project; server.port should be the local port you use for this
# project; You will need MXUnit (and WireBox I think) installed in
# this project's webroot (they are ignored by Git).

ant -Dplatform=railo41 -Dtest.path.root=/Developer/workspace/fw1 \
    -Dcontext.root= -Dserver.name=fw1.local -Dserver.port=8080 \
    run-tests-mxunit
