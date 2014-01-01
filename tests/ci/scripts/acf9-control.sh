pushd $WORK_DIR/jrun4/bin > /dev/null
case $1 in
	start)
		./jrun -start cfusion>/dev/null&
		;;
	stop)
		./jrun -stop cfusion>/dev/null&
		;;
esac
popd > /dev/null