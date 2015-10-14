#!/bin/bash
export LOGFILE=`dirname $0`/log/when-test.log

log () {
  echo "`date -R`: $*" >> $LOGFILE
}

echo_ok () {
  echo -e " \e[32m\xE2\x9C\x94\e[0m"
}

echo_prompt () {
  echo -en "\e[33m[`date +%H:%M:%S`]\e[0m" "$@"
}

echo_prompt_nl () {
  echo -e "\e[33m[`date +%H:%M:%S`]\e[0m" "$@"
}

echo_fail () {
  echo -e " \e[31m\xE2\x9C\x96\e[0m"
}

exit_fail () {
  echo -e " \e[31m\xE2\x9C\x96\e[0m"
  exit 1
}

echo_err () {
  echo "$@" 1>&2
}

discard_out () {
  $@ > /dev/null 2>&1
}
