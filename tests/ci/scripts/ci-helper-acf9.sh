#!/bin/bash
PLATFORM_DIR="jrun4"
WEBROOT="jrun4/servers/cfusion/cfusion-ear/cfusion-war"

MY_DIR=`dirname $0`
CONTROL_SCRIPT="`pwd`/$MY_DIR/acf9-control.sh"

source $MY_DIR/ci-helper-base.sh $1 $2

case $1 in
	install)
		echo "Fixing ACF install directory..."
		grep -rl "/opt/jrun4/" --exclude-dir=$WEBROOT . | xargs -n 1 sed -i "s#/opt/jrun4/#$WORK_DIR/jrun4/#g"

		sed -i "s/8300/$SERVER_PORT/g" jrun4/servers/cfusion/SERVER-INF/jrun.xml
		;;
	start|stop)
		;;
	*)
		echo "Usage: $0 {install|start|stop}"
		exit 1
		;;
esac

exit 0