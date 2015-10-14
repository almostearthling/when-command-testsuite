#!/bin/bash
BASE=`dirname $0`
. $BASE/preamble.sh

# log activity
log "[success-cond: $WHEN_COMMAND_CONDITION] TEST: `basename $0` $@"

case $1 in
  -l)
    echo "this is a long output message"
    ;;
  -e)
    echo_err "success"
    ;;
  -t)
    echo_err "this is a long output message"
    ;;
  -q)
    ;;
  *)
    echo "success"
    ;;
esac

exit 0
