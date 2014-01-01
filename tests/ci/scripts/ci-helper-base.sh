#!/bin/bash
if [ ! -n "$WORK_DIR" ]; then
	echo "WORK_DIR must be set!"
	exit 1
fi

if [ ! -n "$BUILD_DIR" ]; then
	BUILD_DIR=`pwd`
fi

echo "Working directory: $WORK_DIR, Build directory: $BUILD_DIR"

if [ ! "$1" == "install" ]; then

	if [ ! -d $WORK_DIR ]; then
		echo "Working directory doesn't exist and this isn't an install!"
		exit 1
	else
		cd $WORK_DIR
	fi
else
	if [ ! -n "$2" ]; then
		echo "usage: $0 install PROJECTNAME";
		exit 1
	fi
fi

WGET_OPTS="-nv"

function download_and_extract {
	FILENAME=`echo $1|awk '{split($0,a,"/"); print a[length(a)]}'`
	if [[ "$1" == /* ]]; then
		echo "Copying $1 to $FILENAME"
		cp $1 $FILENAME
	else
		echo "Downloading $1 to $FILENAME"
		wget $WGET_OPTS $1 -O $FILENAME
	fi

	if [[ "$FILENAME" == *zip ]]; then
		unzip -q $FILENAME
	else
		tar -zxf $FILENAME
	fi
	rm $FILENAME
	result=$FILENAME
}


if [ ! -n "$SERVER_PORT" ]; then
	SERVER_PORT="8500"
fi

HEALTHCHECK_URL="http://localhost:$SERVER_PORT"


case $1 in
	install)
		if [ -d $WORK_DIR ]; then
			echo "Removing $WORK_DIR"
			rm -rf $WORK_DIR
		fi

		mkdir -p $WORK_DIR
		cd $WORK_DIR

		download_and_extract $PLATFORM_URL

		# assume platform dir is the only dir
		FIRST_DIR=`ls -b`
		if [ "$FIRST_DIR" != "$PLATFORM_DIR" ]; then
			mv $FIRST_DIR $PLATFORM_DIR
		fi
		download_and_extract $TESTFRAMEWORK_URL

		case $TESTFRAMEWORK in
			mxunit)
				mv mxunit* "$WEBROOT/$TESTFRAMEWORK"
				;;
			testbox)
				mv testbox "$WEBROOT/$TESTFRAMEWORK"
				;;
		esac
		ln -s $BUILD_DIR $WEBROOT/$2
		;;
	start)
		if [ ! -f $CONTROL_SCRIPT ]; then
			echo "Control script does not exist!"
			exit 1
		fi
		echo "Starting server... ($HEALTHCHECK_URL)"
		$CONTROL_SCRIPT start&
		until [ "`curl --connect-timeout 2 -m 2 -s -o /dev/null -w "%{http_code}" $HEALTHCHECK_URL`" == "200" ]
		do
			echo "Waiting for server to start..."
			sleep 2
		done
		;;
	stop)
		echo "Stopping server..."
		$CONTROL_SCRIPT stop
		while curl --connect-timeout 2 --max-time 2 -s $HEALTHCHECK_URL>/dev/null
		do
			echo "Waiting for server to stop..."
			sleep 1
		done
		;;
	*)
		echo "Usage: $0 {install|start|stop}"
		exit 1
		;;
esac