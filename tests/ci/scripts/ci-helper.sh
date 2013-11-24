#!/bin/bash
WGET_OPTS="-nv"
if [ "$TRAVIS" == "true" ]; then
	WORKDIR="$HOME/work"
	RAILO_URL=http://getrailo.com/railo/remote/download/4.1.1.009/railix/linux/railo-express-4.1.1.009-nojre.tar.gz
	MXUNIT_URL="https://github.com/marcins/mxunit/archive/fix-railo-nulls.zip"
else
	# not TravisCI - local OSX testing
	WORKDIR=/tmp/work
	RAILO_URL="http://localhost/railo-express-4.1.1.009-macosx.zip"
	MXUNIT_URL="https://github.com/marcins/mxunit/archive/fix-railo-nulls.zip"
	TRAVIS_BUILD_DIR=`pwd`
fi

echo "Working directory: $WORKDIR"

if [ -d $WORKDIR -a "$1" == "install" ]; then
	rm -rf $WORKDIR
fi

mkdir -p $WORKDIR
cd $WORKDIR

case $1 in
	install)
		# Download Railo Express
		if [[ "$RAILO_URL" == *zip ]]; then
			wget $WGET_OPTS $RAILO_URL -O railo.zip
			unzip -q railo.zip
		else
			wget $WGET_OPTS $RAILO_URL -O railo.tar.gz
			tar -zxf railo.tar.gz
		fi
		mv railo-express* railo
		wget $WGET_OPTS $MXUNIT_URL -O mxunit.zip
		unzip -q mxunit.zip -d railo/webapps/www/
		mv railo/webapps/www/mxunit* railo/webapps/www/mxunit
		ln -s $TRAVIS_BUILD_DIR railo/webapps/www/fw1
		;;
	start)
		sh railo/start>/dev/null &
		until curl -s http://localhost:8888>/dev/null
		do
			echo "Waiting for Railo..."
			sleep 1
		done
		;;
	stop)
		sh railo/stop
		;;
esac

exit 0