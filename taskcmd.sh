#!/bin/bash
BASE=`dirname $0`
. $BASE/preamble.sh

# log activity
log "[task: $WHEN_COMMAND_TASK:$WHEN_COMMAND_CONDITION] COMMAND: `basename $0` $@"

if [ "$1" = "-e" ]; then
  echo_err "test script `basename $0` failed"
  exit 2
else
  echo "test script `basename $0` succeeded"
fi
