#!/bin/bash
BASE=`dirname $0`
. $BASE/preamble.sh

# log activity
log "[failure-cond: $WHEN_COMMAND_CONDITION] TEST: `basename $0` $@"

case $1 in
  -l)
    echo_err "this is a long error message"
    ;;
  -o)
    echo "error"
    ;;
  -t)
    echo "this is a long error message"
    ;;
  -q)
    ;;
  *)
    echo_err "error"
    ;;
esac

exit 2
