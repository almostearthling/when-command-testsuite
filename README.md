# When Test Suite

This is a test suite for the **When** scheduler. Since **When** is an interactive, single instance application, it's almost impossible to automate everything, although nowadays we are comfortable with simulated user interaction especially in web applications. In this case automation is made more difficult due to the fact that **When** is more similar to a system application. The test suite tries to exploit the most automation by using simple commands for tasks that log well-identifiable strings to a session log file, that can be interpreted using simple scripts.

![Screenshot](https://raw.githubusercontent.com/almostearthling/when-command-testsuite/master/images/when-command-testsuite.png)

The test suite is now quite complete, and covers most use cases. Some of them are left as optional (although desirable, if I ever find a way to automate them without user interaction) but the surrounding condition types are tested anyway: see the *What can be tested* paragraph below for details. Also, since a large number of conditions is set up and a fairly big amount of DBus signals are watched, this test suite can be interpreted as a way to stress test the applet: I didn't think of **When** as something that should check a lot of conditions, instead I thought of it as a small utility that could perform five to ten tests, and that would defer the most intensive ones most of the times (once every minute by default). The test suite displays in this sense a quite unusual situation.


## Testing Process

To perform the test, the `run.sh` command must be executed at the shell prompt. This will do the following:

* verify whether or not **When** is running, and in this case shut it down
* create an appropriate *items* dump file (tasks, conditions, signal handlers) from a template
* dump the current *items* to a save file, and backup current configuration
* replace configuration and import the new *items* file into **When**
* launch the DBus test message server in a separate process
* start **When** in a separate process
* sleep a specified amount of time
* perform filesystem actions for filesystem changes based conditions
* sleep some minutes to let the deferred tasks finish
* export task history list to a text file
* shutdown current **When** instance
* restore configuration and import saved *items* file
* check test results and display outcome information.

The user can choose, then, to restart **When** which will work with its prior configuration. Nevertheless, since these operations are performed against a possibly working installation, it's strongly advised to use a specifically created environment: it can be either a virtual machine, or at least a different user possibly created for this purpose.

Before running `run.sh`, all shell scripts should be made executable: do a `chmod a+x *.sh` in the test suite directory.


## Warnings and Caveats

### Requirements

For the test suite to meaningfully function, the environment has to be specifically prepared: this means for example that all the dependencies (`xprintidle` and also the optional `python3-pyinotify`) must be installed. Also, **When** must be installed and configured for the user that will perform the test, that is `when-command --install` should have been run at the time of testing. The tests must be performed from a terminal window in a graphic environment, right on the machine where **When** is tested, thus it cannot be run in a remote (e.g. `ssh`) session. This is because **When** is a desktop application anyway, and the test instance must belong to a Gnome session desktop.

### Configuration

There is not much to be configured. However there are some parameters: the ones about times (`GRACE_TIME_MINUTES`, `SLEEP_TEST_MINUTES`, `SLEEP_DEFER_MINUTES`), for instance, can be modified. I tend to set them to something more than what is strictly needed, but not much more: it's safe to leave them alone. One parameter might need to be changed, that is the `WHEN_BASE` variable: if **When** was not installed using the preferred package (LSB based) or if a different setup (e.g. a repository clone) has to be used, it has to be set to the actual installation base directory. There are two commented out options in `run.sh`: one is for the `/opt` based installation and the other for a setup contained in `~/Applications/When` such as the one described in the [documentation](http://when-documentation.readthedocs.org/en/latest/install.html#install-from-the-source). If one of these methods was chosen, it's sufficient to uncomment the appropriate script line.

### What Can be Tested

This test suite will perform some tests about correct task execution after condition evaluation. In other words, only the *background* activity of **When** is tested. Of course some features that belong to the *interactive* side of **When** are hard to automatically check, and are left out. These aspects include:

* consistency of the UI/UX
* correct behavior of *item* definition dialog boxes
* behavior of some command line switches.

However many of these features can be actually verified through user interaction (I'd say "*empirically*") and in many cases their malfunctioning would directly affect the overall correctness of **When**: for instance, if dialog boxes would not correctly define *items*, the applet should not work at all -- and in this case the template file for *items* could not have been created at all, as it was generated using an interactive session and edited to become a template with substitutable parts.

There are also some *conditions* that are hard to test automatically, that is the ones that depend on events that require intervention from the user or anyway environmental changes. Some examples include

* conditions that arise when a device is plugged or unplugged
* conditions that depend on joining or leaving a network
* suspend based conditions.

The best way to test these conditions remains probably to interact with the applet and verify that certain events actually trigger certain tasks. Possibly in future versions of this test suite, the user will be asked to interact with the system, by enabling a network or plugging in a device.

Also, the *Note* in **When**'s documentation file [overview](http://when-documentation.readthedocs.org/en/latest/description.html#overview), should be taken into account: conditions occur at very close times should be avoided, because in case of two events at the same time only one of them will actually be enqueued for task execution.

### How to Recover

Hopefully nothing goes wrong and the test suite reaches the final part of the `run.sh` script, where original configuration and items are restored. In case of failures preventing a full restore, the test suite saves the important configuration parts of the existing **When** instance in the `save` subdirectory of the test suite tree. The following commands can be used to recover:

```
~$ cd <when_test_home>
~/<when_test_home>$ when-command --kill
~/<when_test_home>$ when-command --clear --reset
~/<when_test_home>$ cp save/when-command.conf $HOME/.config/when-command
~/<when_test_home>$ when-command --import save/when-items-saved.dump
```

After this **When** can be restarted using *Dash* or run at next login.


## How Tests are Performed

The test suite only relies on the recorded output of commands used for *tasks* and in some cases by *conditions*: the **When** log files are not analyzed. However they remain a valuable source of information in case something goes wrong, that is why the test configuration includes debug logging. Logs are appended to the normal logs, the logging system in **When** does not allow to use different files or locations. During the tests **When** uses the color icon set: I normally let the applet guess the icon set, which in my case means that it uses light icons on dark background and I can visually identify the fact that the running one is a test session.

Please note that, in order for *idle time based conditions* to occur properly, the testing session should be left alone without user interaction. For this reason the test script gives the user a grace time to unfocus a possible virtual desktop, so that the virtual machine can remain idle for the whole session letting the user do something else, such as checking the logs in a remote session.

Normally, if `run.sh` is launched from the command line with no arguments, it produces textual output to assist the user in determining what the test suite is doing at the moment. This includes simple descriptions of the ongoing operations, check marks (and other special characters) to show success or failure, and text-based progress bars when the script is waiting for **When** to do something in the background. This can be annoying, or even just useless, at least in two cases:

* when the test script is performed (possibly on "headless" machines or virtual machines) as part of a continuous integration system;
* when a script has to be used to verify the outcome of the test suite.

Two command-line switches have been provided for this purpose:

* `-b` just issues a *brief* output in case of failure, consisting of the word `FAIL` followed by a colon and an all-caps word describing the reason (`NO_WHEN` when the applet is not found, `NO_DUMP` and `NO_IMPORT` if there is trouble with the items file, and so on), or the word `ERR` followed by either `COND` or `TASK` and the name of the item that failed. In case of success it just displays the word `SUCCESS`. All output is written to *stderr*, and in case of failure the exit status is `1`;
* `-q` produces no output, the only way to check for outcome is to test the return value (`1` on failure, `0` on success).

The options cannot be combined, and either one must be the first and only argument to the `run.sh` script if present. Neither option prevents the green **When** icon to show on the top panel: if you don't want to show it for some reason, please modify the `<when_test_home>/conf/when-command.conf` file.

*NOTE:*  There is *no way* to run the test suite from a text session (or a remote terminal), even when `-b` or `-q` are set. It has to be launched from a terminal window in a graphical session in order to be able to launch an instance of **When** for testing purposes.


## Modifying the test suite

The test suite can be updated to add tests that were not considered at first: the possibilities of **When** are actually many, and it's virtually impossible to test really *every* single case -- although the suite tries to cover all areas and general features of the applet in terms of scheduling checks and running tasks. The files that can be modified when adding tests are the following:

```
<when_test_home>/run.sh
<when_test_home>/prepare_items.py
<when_test_home>/dbus_server.py
<when_test_home>/conf/when-items_TEMPLATE.dump
<when_test_home>/conf/when-command.conf
```

Probably `when-command.conf` and `prepare_items.py` are the least subject to changes in the bunch, and `dbus_server.py` should only be modified in order to emit more DBus signals. The other two should be edited whenever a new check is needed.

### The items template

The *items* template, that is `<when_test_home>/conf/when-items_TEMPLATE.dump`, can be modified to add conditions and therefore tasks to be run or not. It can be considered sort of an "augmented" JSON file, where some macros can be used and with comments. Comments are lines where the first non-space string is either `#` or `//`, and macros are all-caps strings surrounded by double brackets. To introduce a new test, my advice is to copy an existing condition and edit the entries accordingly. It might be a difficult operation, so please take a look at how the records are generated for the various parts in the applet code (the `Item_to_dict` functions) before modifying existing items: malformed item files will be rejected by the test instance and all the tests will fail.

Comments are discarded in the generated file, and macros are substituted with fixed values as shown in `<when_test_home>/prepare_items.py`. It's strongly suggested to use predefined tasks in new conditions, in order to be sure that failing task names end with `_taskFAIL` and succeeding task names end with `_taskOK`: this allows to check task outcome automatically in a simple way. Another reason for this is that the shell command used to testify task execution is the provided `taskcmd.sh`, which logs both the task name and the condition name, in a way that is easily recognizable by means of the provided verification functions in `run.sh`.

Also, *command based conditions* should only use `test_fail.sh` and `test_succeed.sh` as check commands, possibly followed by switches to determine their behavior: the scripts are very easy and only accept one single switch to either exit with a success/failure status, and printing out a short or a long message.

### The test launcher

Whenever a condition is created and tasks are supposed to be triggered or not triggered, the `run.sh` laucher *must* be modified accordingly. After the `# *** CHECK TEST LOG FILE ***` line, there must be a check for each task triggered (or not triggered) by a condition. The check line has the following form:

```
check[rec|fail]_task_condition Task_Name Condition_Name
```

where the first token is one of:

* `check_task_condition` when the condition is supposed to trigger a task
* `checkfail_task_condition` when the condition is supposed *not* to trigger a task
* `checkrec_task_condition` when the condition is supposed to trigger a task more than once

and `Task_Name` and `Condition_Name` are obviously the task and condition names as defined in the item template file.

Please note that if a condition is bound to more than a task (either to be run in sequence or concurrently), for each task there should be a different check line.

These are the only parts that should be modified in the launcher script, all other operations (such as verifying that the task outcome is the expected one, provided that tasks follow the naming scheme described above) are performed automatically.
