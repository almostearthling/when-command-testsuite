#!/bin/bash

# This script executes all the tests on a specifically launched instance of
# the When scheduler. To do so, it shuts down any existing instance, saves its
# configuration, imports a specific configuration and performs some dummy
# actions using dummy conditions. The configuration is prepared for the
# environment where this command is executed, and time base conditions are
# specifically created to occur in reasonable times, however this does not
# prevent the test to need several minutes to perform despite the actual
# lightness of both tests and tasks.

export GRACE_TIME_MINUTES=1   # grace time to take cursor off VM desktop
export SLEEP_TEST_MINUTES=5   # time for unattended tests
export SLEEP_DEFER_MINUTES=2  # time for deferred tasks to take place

export BASE=`dirname $0`
export WHEN_BASE=/opt/when-command

export CONF_BASE=$HOME/.config/when-command
export WHEN="$WHEN_BASE/when-command"
export TIMESTAMP=`date +%Y%m%d-%H%M`
export BAR_LENGTH=50
export LC_NUMERIC="en_US.UTF-8"
export SESSIONLOG=$BASE/log/when-test.log

# common functions
. $BASE/preamble.sh

# functions
sleep_minutes_progress () {
  local secs=$(( $1 * 60 ))
  local tick=`echo "100.0 / $BAR_LENGTH.0" | bc -l`
  local tick_secs=`echo "$secs.0 / $BAR_LENGTH" | bc -l`
  local progress=0
  local span=0
  echo -en "\e[s"
  for x in `seq -f '%.2f' 0.0 $tick 100.0` ; do
    echo -en "\e[2K\e[u"
    printf "%6s" $x
    echo -n "% ["
    for y in `seq 0 $BAR_LENGTH` ; do
      if (( $y < $progress )) ; then
        echo -n "#"
      else
        echo -n "."
      fi
    done
    echo -n "] (" ; printf "%.2f" "${span}" ; echo -n "s)"
    sleep $tick_secs
    span=`echo "$span + $tick_secs" | bc -l`
    progress=$(( $progress + 1 ))
  done
  echo -en "\e[2K\e[u"
  printf "%6s" "100.00"
  echo -n "% ["
  for x in `seq 0 $BAR_LENGTH` ; do
    echo -n "#"
  done
  echo "]"
}

check_task_condition () {
  local task=$1
  local condition=$2
  retval=`cat $SESSIONLOG | fgrep "task:" | fgrep "$task:$condition" | wc -l`
  if [ "$retval" = "0" ]; then
    errors=$(( $errors + 1 ))
    failed="$failed $task:$condition"
  fi
}

checkfail_task_condition () {
  local task=$1
  local condition=$2
  retval=`cat $SESSIONLOG | fgrep "task:" | fgrep "$task:$condition" | wc -l`
  if [ "$retval" -gt "0" ]; then
    errors=$(( $errors + 1 ))
    failed="$failed $task:$condition"
  fi
}


# banner
echo "Welcome to the When test suite!"
echo "Please do not interact with the console or the desktop, unless this"
echo "script instructs to do so: please refer to README.md for details. If"
echo "the script is interrupted before end, you might need to restore both"
echo "configuration and exported items stored in the 'save' subdirectory."
echo

# verify that When is installed, and if not bail out
echo_prompt "Verifying When installation... "
if [ -d $CONF_BASE -a -f $CONF_BASE/when-command.conf ] ; then
  echo_ok
else
  echo "not installed: please install it and run tests."
  exit_fail
fi

# prepare directories and files
echo_prompt "Preparing files."
discard_out chmod a+x $BASE/*.sh
discard_out chmod a+x $BASE/*.py
if [ -d "$BASE/log" ]; then
  discard_out tar czvf logs_$TIMESTAMP.tar.gz $BASE/log
  discard_out rm $BASE/log/*
else
  mkdir $BASE/log
fi
if [ -d "$BASE/save" ]; then
  discard_out tar czvf save_$TIMESTAMP.tar.gz $BASE/save
  discard_out rm $BASE/save/*
else
  discard_out mkdir $BASE/save
fi
if [ ! -d "$BASE/conf" ]; then
  discard_out mkdir $BASE/conf
  discard_out mv when-command.conf $BASE/conf
  discard_out mv when-items_TEMPLATE.dump $BASE/conf
fi
if [ ! -d "$BASE/temp" ]; then
  discard_out mkdir $BASE/temp
fi
echo_ok

# prepare shell environment
echo_prompt "Preparing environment."
discard_out . $BASE/preamble.sh
echo_ok

# save config, test whether or not When is running, and possibly shut it down
echo_prompt "Shut down When and save configuration."
if discard_out $WHEN --query ; then
  discard_out $WHEN --shutdown
  sleep 5
fi
discard_out cp $CONF_BASE/when-command.conf $BASE/save
if [ -f $CONF_BASE/when-command.pause ] ; then
  discard_out mv $CONF_BASE/when-command.pause $BASE/save
fi
$WHEN --export $BASE/save/when-items-saved.dump
[ "$?" = "0" ] && echo_ok || echo_fail

# prepare new configuration and install it
echo_prompt "Install test configuration."
discard_out $WHEN --clear
discard_out cp $BASE/conf/when-command.conf $CONF_BASE
discard_out python3 prepare_items.py
discard_out $WHEN --import $BASE/conf/when-items.dump
if [ "$?" = "0" ] ; then
  echo_ok
else
  exit_fail
fi

# start the DBus signal emitter
echo_prompt "Starting DBus signal emitter."
nohup python3 $BASE/dbus_server.py > /dev/null 2>&1 &
echo_ok

# wait for user to take the cursor off the screen in a VM
echo_prompt_nl "Waiting $GRACE_TIME_MINUTES minute(s) to start the test instance..."
sleep_minutes_progress $GRACE_TIME_MINUTES
echo_prompt "Done."
echo_ok

# launch the new instance of When in a separate process
echo_prompt "Starting test instance of When."
nohup $WHEN > /dev/null 2>&1 &
if [ "$?" = "0" ] ; then
  echo_ok
else
  exit_fail
fi

# for now sleep some time
echo_prompt_nl "Sleeping $SLEEP_TEST_MINUTES minute(s) during unattended tests... "
sleep_minutes_progress $SLEEP_TEST_MINUTES
echo_prompt "Done."
echo_ok

# perform interactive-like tests
echo_prompt "Performing other automated tests."
discard_out $WHEN --run-condition Cond08-CommandLine    # 1. cmdline-activated
discard_out touch $BASE/temp/file_notify_test           # 2. inotify
discard_out touch $BASE/temp/start_dbus.tmp             # 3. emit signals
# ...
echo_ok

echo_prompt_nl "Sleeping $SLEEP_DEFER_MINUTES minute(s) for deferred tasks... "
sleep_minutes_progress $SLEEP_DEFER_MINUTES
echo_prompt "Done."
echo_ok


# shut down current instance
echo_prompt "Shutting down test instance of When..."
if discard_out $WHEN --query ; then
  discard_out $WHEN --shutdown
fi
if [ "$?" = "0" ] ; then
  sleep 5
  echo_ok
else
  exit_fail
fi

# ask DBus server to shut down asap
echo_prompt "Shutting down DBus signal emitter..."
discard_out rm $BASE/temp/start_dbus.tmp
echo_ok


# *** CHECK TEST LOG FILE ***
echo_prompt "Performing tests on log file..."
# do checks on log (and hope for the best)
errors=0
failed=""

# generated checks:
check_task_condition Task01-StatusOK Cond01-Time
check_task_condition Task02-StdErrKO_RE Cond02-Interval
check_task_condition Task03-StatusKO Cond03-Idle
check_task_condition Task01-StatusOK Cond04-Command_Status
check_task_condition Task03-StatusKO Cond05-Command_Stderr
check_task_condition Task04-StdErrOK_RE Cond06-Command_Stdout
check_task_condition Task01-StatusOK Cond08-CommandLine
check_task_condition Task03-StatusKO Cond08-CommandLine
check_task_condition Task03-StatusKO Cond09-DBus
check_task_condition Task01-StatusOK Cond10-FileNotify
check_task_condition Task04-StdErrOK_RE Cond11-DBus_is
check_task_condition Task02-StdErrKO_RE Cond12-DBus_s

# ... (more are to come)

if [ "$errors" -gt "0" ]; then
  echo_fail
else
  echo_ok
fi
# *** END OF TESTS

# restore old When configuration
echo_prompt "Restoring configuration..."
discard_out $WHEN --clear
if [ -f $BASE/save/when-command.pause ] ; then
  discard_out mv $BASE/save/when-command.pause $CONF_BASE
fi
discard_out cp $BASE/save/when-command.conf $CONF_BASE
discard_out $WHEN --import $BASE/save/when-items-saved.dump
if [ "$?" = "0" ] ; then
  echo_ok
else
  echo_fail
fi

# clean up temporary files
echo_prompt "Cleaning up."
discard_out rm $BASE/temp/*
echo_ok

echo
if [ "$errors" = "0" ]; then
  echo "All tests succeeded! This release of When can be almost safely shipped."
else
  echo "There are $errors failed tests:"
  for x in $failed; do
    echo "- $x"
  done
  echo
  echo "This release of When has to be reviewed before shipping."
fi

# end.
