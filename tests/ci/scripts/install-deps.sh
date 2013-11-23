#!/bin/bash
MXUNIT_FILE="mxunit-2.1.3.zip"
if [ "$TRAVIS" == "true" ]; then
	WORKDIR=$HOME
	RAILO_VER="railo-express-4.1.1.009-nojre"
	RAILO_FILE="$RAILO_VER.tar.gz"
	RAILO_URL=http://getrailo.com/railo/remote/download/4.1.1.009/railix/linux/$RAILO_FILE
	MXUNIT_URL=https://github.com/downloads/mxunit/mxunit/$MXUNIT_FILE
else
	# not TravisCI - local OSX testing
	WORKDIR=/tmp/work
	mkdir -p /tmp/work
	rm -rf /tmp/work/*
	RAILO_VER="railo-express-4.1.1.009-macosx"
	RAILO_FILE="$RAILO_VER.zip"
	RAILO_URL="http://localhost/$RAILO_FILE"
	MXUNIT_URL="http://localhost/$MXUNIT_FILE"
	TRAVIS_BUILD_DIR=`pwd`
fi
echo "Working directory: $WORKDIR"
cd $WORKDIR

# Download Railo Express
wget $RAILO_URL
if [[ "$RAILO_FILE" == *zip ]]; then
	unzip $RAILO_FILE
else
	tar -zxvf $RAILO_FILE
fi
wget $MXUNIT_URL
unzip $MXUNIT_FILE -d $RAILO_VER/webapps/www/
ln -s $TRAVIS_BUILD_DIR $RAILO_VER/webapps/www/fw1