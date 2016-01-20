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
export WHEN_BASE=/usr/bin
# export WHEN_BASE=/opt/when-command
# export WHEN_BASE=$HOME/Applications/When

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

checkrec_task_condition () {
  local task=$1
  local condition=$2
  retval=`cat $SESSIONLOG | fgrep "task:" | fgrep "$task:$condition" | wc -l`
  if [ "$retval" -lt "2" ]; then
    errors=$(( $errors + 1 ))
    failed="$failed $task:$condition"
  fi
}


# variables for brief (machine readable) output or no-output at all
BRIEF=
QUIET=
case $1 in
  -b)
    BRIEF="true"
    QUIET="true"
    ;;
  -q)
    QUIET="true"
    ;;
esac


# banner
if [ -z "$QUIET" ]; then
  echo "Welcome to the When test suite!"
  echo "Please do not interact with the console or the desktop, unless this"
  echo "script instructs to do so: please refer to README.md for details. If"
  echo "the script is interrupted before end, you might need to restore both"
  echo "configuration and exported items stored in the 'save' subdirectory."
  echo
fi

# verify that When is installed, and if not bail out
if [ -z "$QUIET" ]; then
  echo_prompt "Verifying When installation... "
  if [ -f $WHEN -a -d $CONF_BASE -a -f $CONF_BASE/when-command.conf ]; then
    echo_ok
    echo_prompt "Testing `$WHEN --version`"
    echo
  else
    echo "not installed: please install it and run tests."
    exit_fail
  fi
else
  if [ ! -f $WHEN -o ! -d $CONF_BASE -o ! -f $CONF_BASE/when-command.conf ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:NO_WHEN"
    fi
    exit 1
  fi
fi

# prepare directories and files
if [ -z "$QUIET" ]; then
  echo_prompt "Preparing files."
fi
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
if [ -z "$QUIET" ]; then
  echo_ok
fi

# save config, test whether or not When is running, and possibly shut it down
if [ -z "$QUIET" ]; then
  echo_prompt "Shut down When and save configuration."
fi
if discard_out $WHEN --query ; then
  discard_out $WHEN --shutdown
  sleep 5
fi
discard_out cp $CONF_BASE/when-command.conf $BASE/save
if [ -f $CONF_BASE/when-command.pause ]; then
  discard_out mv $CONF_BASE/when-command.pause $BASE/save
fi
$WHEN --export $BASE/save/when-items-saved.dump
res=$?
if [ -z "$QUIET" ]; then
  if [ "$res" = "0" ]; then
    echo_ok
  else
    exit_fail
  fi
else
  if [ "$res" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:NO_DUMP"
    fi
    exit 1
  fi
fi

# prepare new configuration and install it
if [ -z "$QUIET" ]; then
  echo_prompt "Install test configuration."
fi
discard_out $WHEN --clear
discard_out cp $BASE/conf/when-command.conf $CONF_BASE
discard_out python3 prepare_items.py
discard_out $WHEN --import $BASE/conf/when-items.dump
res=$?
if [ -z "$QUIET" ]; then
  if [ "$res" = "0" ]; then
    echo_ok
  else
    exit_fail
  fi
else
  if [ "$res" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:NO_IMPORT"
    fi
    exit 1
  fi
fi

# start the DBus signal emitter
if [ -z "$QUIET" ]; then
  echo_prompt "Starting DBus signal emitter."
fi
nohup python3 $BASE/dbus_server.py > /dev/null 2>&1 &
if [ -z "$QUIET" ]; then
  echo_ok
fi

# wait for user to take the cursor off the screen in a VM
if [ -z "$QUIET" ]; then
  echo_prompt_nl "Waiting $GRACE_TIME_MINUTES minute(s) to start the test instance..."
  sleep_minutes_progress $GRACE_TIME_MINUTES
  echo_prompt "Done."
  echo_ok
else
  sleep $(( $GRACE_TIME_MINUTES * 60 ))
fi

# launch the new instance of When in a separate process
if [ -z "$QUIET" ]; then
  echo_prompt "Starting test instance of When."
fi
nohup $WHEN > /dev/null 2>&1 &
res=$?
if [ -z "$QUIET" ]; then
  if [ "$res" = "0" ]; then
    echo_ok
  else
    exit_fail
  fi
else
  if [ "$res" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:START_WHEN"
    fi
    exit 1
  fi
fi

# for now sleep some time
if [ -z "$QUIET" ]; then
  echo_prompt_nl "Sleeping $SLEEP_TEST_MINUTES minute(s) during unattended tests... "
  sleep_minutes_progress $SLEEP_TEST_MINUTES
  echo_prompt "Done."
  echo_ok
else
  sleep $(( $SLEEP_TEST_MINUTES * 60 ))
fi

# load items from item definition files
if [ -z "$QUIET" ]; then
  echo_prompt "Loading items from valid Item Definition File..."
fi
sed "s%xxBASE_DIRxx%`pwd`%g" $BASE/conf/itemdefs.when | discard_out $WHEN --item-add -
res=$?
if [ -z "$QUIET" ]; then
  if [ "$res" = "0" ]; then
    echo_ok
  else
    echo_fail
  fi
else
  if [ "$res" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:LOAD_VALID_IDF"
    fi
  fi
fi

if [ -z "$QUIET" ]; then
  echo_prompt "Discarding items from invalid Item Definition Files..."
fi
discard_out $WHEN --item-add $BASE/conf/itemdefs-fail01.when
res1=$?
discard_out $WHEN --item-add $BASE/conf/itemdefs-fail02.when
res2=$?
discard_out $WHEN --item-add $BASE/conf/itemdefs-fail03.when
res3=$?
if [ -z "$QUIET" ]; then
  if [ "$res1" != "0" -a "$res2" != "0" -a "$res3" != "0" ]; then
    echo_ok
  else
    echo_fail
  fi
else
  if [ "$res1" != "0" -a "$res2" != "0" -a "$res3" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:LOAD_INVALID_IDF"
    fi
  fi
fi

# small pause to ensure that item definition file has been loaded
if [ -z "$QUIET" ]; then
  echo_prompt_nl "Sleeping $GRACE_TIME_MINUTES minute(s) to wait for new items... "
  sleep_minutes_progress $GRACE_TIME_MINUTES
  echo_prompt "Done."
  echo_ok
else
  sleep $(( $GRACE_TIME_MINUTES * 60 ))
fi

# perform interactive-like tests
if [ -z "$QUIET" ]; then
  echo_prompt "Performing other automated tests."
fi
discard_out $WHEN --run-condition Cond08-CommandLine    # 1a. cmdline-activated
discard_out $WHEN --run-condition Cond_IDF05-Event      # 1b. cmdline-activated
discard_out touch $BASE/temp/file_notify_test           # 2. inotify
discard_out touch $BASE/temp/start_dbus.tmp             # 3. emit signals
# ...
if [ -z "$QUIET" ]; then
  echo_ok
fi

if [ -z "$QUIET" ]; then
  echo_prompt_nl "Sleeping $SLEEP_DEFER_MINUTES minute(s) for deferred tasks... "
  sleep_minutes_progress $SLEEP_DEFER_MINUTES
  echo_prompt "Done."
  echo_ok
else
  sleep $(( $SLEEP_DEFER_MINUTES * 60 ))
fi


# export task history to a text file
if [ -z "$QUIET" ]; then
  echo_prompt "Export task history to log directory..."
fi
discard_out $WHEN --export-history $BASE/log/when-task-history.csv
sleep 1
if [ -z "$QUIET" ]; then
  echo_ok
fi


# shut down current instance
if [ -z "$QUIET" ]; then
  echo_prompt "Shutting down test instance of When..."
fi
if discard_out $WHEN --query ; then
  discard_out $WHEN --shutdown
fi
res=$?
if [ -z "$QUIET" ]; then
  if [ "$res" = "0" ]; then
    echo_ok
  else
    exit_fail
  fi
else
  if [ "$res" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:START_WHEN"
    fi
    exit 1
  fi
fi

# ask DBus server to shut down asap
if [ -z "$QUIET" ]; then
  echo_prompt "Shutting down DBus signal emitter..."
fi
discard_out rm $BASE/temp/start_dbus.tmp
sleep 5
if [ -z "$QUIET" ]; then
  echo_ok
fi


# *** CHECK TEST LOG FILE ***
if [ -z "$QUIET" ]; then
  echo_prompt "Performing tests on log file."
fi
# do checks on log
errors=0
failed=""

# specific checks
check_task_condition T01-status-chkOK_taskOK Cond01-Time
check_task_condition T05-stderr-rjcRE_taskFAIL Cond02-Interval
check_task_condition T03-status-chkFAIL_taskOK Cond03-Idle
check_task_condition T01-status-chkOK_taskOK Cond04-Command_Status
check_task_condition T03-status-chkFAIL_taskOK Cond05-Command_Stderr
check_task_condition T06-stderr-chkRE_taskOK Cond06-Command_Stdout
check_task_condition T01-status-chkOK_taskOK Cond08-CommandLine
check_task_condition T03-status-chkFAIL_taskOK Cond08-CommandLine
check_task_condition T03-status-chkFAIL_taskOK Cond09-DBus
check_task_condition T01-status-chkOK_taskOK Cond10-FileNotify
check_task_condition T02-status-rjcOK_taskFAIL Cond20-FileNotify
check_task_condition T06-stderr-chkRE_taskOK Cond11-DBus_is
check_task_condition T05-stderr-rjcRE_taskFAIL Cond12-DBus_s
check_task_condition T06-stderr-chkRE_taskOK Cond85-Command_Stderr
check_task_condition T07-stderr-rjcSTR_taskFAIL Cond95-Command_Stderr
check_task_condition T09-stdout-rjcRE_taskFAIL Cond86-Command_Stdout
check_task_condition T10-stdout-chkRE_taskOK Cond96-Command_Stdout
check_task_condition T07-stderr-rjcSTR_taskFAIL Cond41-DBus_is
check_task_condition T12-stdout-chkSTR_taskOK Cond33-DBus_is
check_task_condition T11-stdout-rjcSTR_taskFAIL Cond34-DBus_is
check_task_condition T10-stdout-chkRE_taskOK Cond35-DBus_is
check_task_condition T09-stdout-rjcRE_taskFAIL Cond36-DBus_is
check_task_condition T08-stderr-chkSTR_taskOK Cond37-DBus_is
check_task_condition T01-status-chkOK_taskOK Cond13-Evt_startup
check_task_condition T01-status-chkOK_taskOK Cond14-Evt_shutdown
check_task_condition T07-stderr-rjcSTR_taskFAIL Cond15-DBus_is
check_task_condition T06-stderr-chkRE_taskOK Cond16-DBus_s
check_task_condition T05-stderr-rjcRE_taskFAIL Cond17-DBus_s
check_task_condition T01-status-chkOK_taskOK Cond25-DBus_iSsi
check_task_condition T02-status-rjcOK_taskFAIL Cond26-DBus_iSsi
check_task_condition T03-status-chkFAIL_taskOK Cond27-DBus_iDsi
check_task_condition T04-status-rjcFAIL_taskFAIL Cond28-DBus_iDsi

check_task_condition Task-IDF02_taskFAIL Cond_IDF01-Interval
check_task_condition Task-IDF02_taskFAIL Cond_IDF03-Command
check_task_condition Task-IDF01_taskOK Cond_IDF04-Idle
check_task_condition Task-IDF01_taskOK Cond_IDF05-Event
check_task_condition Task-IDF01_taskOK Cond_IDF06-FileChanges
check_task_condition Task-IDF01_taskOK Cond_IDF07-UserEvent

checkfail_task_condition T04-status-rjcFAIL_taskFAIL Cond74-Command_Status
checkfail_task_condition T05-stderr-rjcRE_taskFAIL Cond75-Command_Stderr
checkfail_task_condition T08-stderr-chkSTR_taskOK Cond76-Command_Stdout
checkfail_task_condition T01-status-chkOK_taskOK Cond32-nDBus
checkfail_task_condition T01-status-chkOK_taskOK Cond21-Time
checkfail_task_condition T05-stderr-rjcRE_taskFAIL Cond22-Interval
checkfail_task_condition T03-status-chkFAIL_taskOK Cond23-Idle

checkfail_task_condition Task-IDF01_taskOK Cond_IDF01-Interval
checkfail_task_condition Task-IDF01_taskOK Cond_IDF02-Time

checkrec_task_condition T10-stdout-chkRE_taskOK Cond42-Interval_Rec

# ... (more are to come)
if [ -z "$QUIET" ]; then
  if [ "$errors" -gt "0" ]; then
    echo_fail
  else
    echo_ok
  fi
fi

# *** CHECK TEST TASKS OUTCOME ***
if [ -z "$QUIET" ]; then
  echo_prompt "Performing tests on task history file..."
fi
# do checks on history
task_errors=0
task_failed=""

# spaces in the history file have to be removed
for x in `grep -v ^ITEM_ID $BASE/log/when-task-history.csv | sed "s/ /_/g"` ; do
  v_task=`echo $x | cut -d ";" -f 4`
  v_result=`echo $x | cut -d ";" -f 6`
  case $v_task in
    *_taskOK)
      if [ "$v_result" = "failure" ]; then
        task_errors=$(( $task_errors + 1 ))
        task_failed="$task_failed $v_task"
      fi
      ;;
    *_taskFAIL)
      if [ "$v_result" = "success" ]; then
        task_errors=$(( $task_errors + 1 ))
        task_failed="$task_failed $v_task"
      fi
      ;;
    *)
      task_errors=$(( $task_errors + 1 ))
      task_failed="$task_failed $v_task"
      ;;
  esac
done

if [ -z "$QUIET" ]; then
  if [ "$task_errors" -gt "0" ]; then
    echo_fail
  else
    echo_ok
  fi
fi

# *** END OF TESTS

# restore old When configuration
if [ -z "$QUIET" ]; then
  echo_prompt "Restoring configuration."
fi
discard_out $WHEN --clear
if [ -f $BASE/save/when-command.pause ]; then
  discard_out mv $BASE/save/when-command.pause $CONF_BASE
fi
discard_out cp $BASE/save/when-command.conf $CONF_BASE
discard_out $WHEN --import $BASE/save/when-items-saved.dump
res=$?
if [ -z "$QUIET" ]; then
  if [ "$res" = "0" ]; then
    echo_ok
  else
    exit_fail
  fi
else
  if [ "$res" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      echo_err "FAIL:START_WHEN"
    fi
    exit 1
  fi
fi

# clean up temporary files
if [ -z "$QUIET" ]; then
  echo_prompt "Cleaning up."
fi
discard_out rm $BASE/temp/*
if [ -z "$QUIET" ]; then
  echo_ok
fi

if [ -z "$QUIET" ]; then
  echo
  if [ "$errors" = "0" -a "$task_errors" = "0" ]; then
    echo "All tests succeeded! This release of When can be almost safely shipped."
  else
    if [ "$errors" -gt "0" ]; then
      echo "There are $errors failed tests:"
      for x in $failed; do
        echo_bullet $x
      done
    fi
    if [ "$task_errors" -gt "0" ]; then
      echo "There are $task_errors unexpected task results:"
      for x in $task_failed; do
        echo_bullet $x
      done
    fi
    echo
    echo "This release of When has to be reviewed before shipping."
    exit 1
  fi
else
  if [ "$errors" != "0" -o "$task_errors" != "0" ]; then
    if [ -n "$BRIEF" ]; then
      if [ "$errors" -gt "0" ]; then
        for x in $failed; do
          echo_err "ERR:COND:$x"
        done
      fi
      if [ "$task_errors" -gt "0" ]; then
        for x in $task_failed; do
          echo_err "ERR:TASK:$x"
        done
      fi
    fi
    exit 1
  else
    if [ -n "$BRIEF" ]; then
      echo_err "SUCCESS"
    fi
  fi
fi

# end.
