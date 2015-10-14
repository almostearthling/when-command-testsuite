# When Test Suite

This is a test suite for the **When** scheduler. Since **When** is an interactive, single instance application, it's almost impossible to automate everything, although nowadays we are comfortable with simulated user interaction especially in web applications. In this case automation is made more difficult due to the fact that **When** is more similar to a system application. The test suite tries to exploit the most automation by using simple commands for tasks that log well-identifiable strings to a session log file, that can be identified by a machine.

*Note:* For the moment this test suite is not much more than a proof-of-concept: of course tests are incomplete, but this set of scripts and templates should provide a skeleton to add checks for specific features. Now the suite shows especially its structure, but its components can be amended to improve both readability and effectiveness.


## Testing Process

To perform the test, the `run.sh` command must be executed at the shell prompt. This will perform the following tasks:

* verify whether or not **When** is running, and in this case shut it down
* create an appropriate *items* dump file (tasks, conditions, signal handlers) from a template
* dump the current *items* to a save file, and backup current configuration
* replace configuration and import the new *items* file into **When**
* launch the DBus test message server in a separate process [TBD]
* start **When** in a separate process
* sleep a specified amount of time
* perform filesystem actions for filesystem changes based conditions
* sleep some minutes
* shutdown current **When** instance
* restore configuration and import saved *items* file.

The user can choose, then, to restart **When** which will work with its prior configuration. Nevertheless, since these operations are performed against a possibly working installation, it's strongly adviced to use a specifically created environment: it can be either a virtual machine, or at least a different user possibly created for this purpose.

Before running `run.sh`, all shell scripts should be made executable: do a `chmod a+x *.sh` in the test suite directory.


## Warnings and Caveats

### Requirements

For the test suite to meaningfully function, the environment has to be specifically prepared: this means for example that all the dependencies (`xprintidle` and also the optional `python3-pyinotify`) must be installed. Also, **When** must be installed and configured for the user that will perform the test, that is `<INSTALLDIR>/when-command --install` should have been run at the time of testing. The tests must be performed from a terminal window in a graphic environment, right on the machine where **When** is tested, thus it cannot be tested in a remote (e.g. `ssh`) session. This is because **When** is a desktop application anyway, and the test instance must belong to a Gnome session desktop.

### What Can be Tested

This test suite will perform some tests about correct task execution after condition evaluation. In other words, only the *background* activity of **When** is tested. Of course some features that belong to the *interactive* side of **When** are hard to automatically check, and are left out. These aspects include:

* consistency of the UI/UX
* correct behavior of *item* definition dialog boxes
* behavior of some command line switches.

However many of these features can be actually verified through user interaction (I'd say "*empirically*") and in many cases their malfunctioning would directly affect the overall correctness of **When**: for instance, if dialog boxes would not correctly define *items*, the applet should not work at all -- and in this case the template file for *items* could not have been created at all, as it was generated using an interactive session and edited to become a template with substitutable parts.

There are also some *conditions* that are hard to test automatically, that is the ones that depend on events that require intervention from the user or anyway environmental changes. Some examples include

* conditions that arise when a device is plugged or unplugged
* conditions that depend on joining or leaving a network
* startup, shutdown, login and suspend based conditions.

The best way to test these conditions remains probably to interact with the applet and verify that certain events actually trigger certain tasks. Possibly in future versions of this test suite, the user will be asked to interact with the system, by enabling a network or plugging in a device.

Also, the *Note* in **When**'s `README.md` file, *Conditions* paragraph, should be taken into account: conditions that trigger the same task at very close times should be avoided, because in case of two conditions triggering the same task at the same time only one of them will actually trigger it.

### How to Recover

Hopefully nothing goes wrong, but in case it does the test suite saves the important configuration parts of the existing **When** instance in the `save` subdirectory of the test suite tree. In case it does, the following commands can be used to recover:

```
~$ cd <when_test_home>
~/<when_test_home>$ /opt/when-command/when-command --kill
~/<when_test_home>$ /opt/when-command/when-command --clear --reset
~/<when_test_home>$ cp save/when-command.conf $HOME/.config/when-command
~/<when_test_home>$ /opt/when-command/when-command --import save/when-items-saved.dump
```

After this **When** can be restarted using *Dash* or run at next login.


## How Tests are Performed

The test suite only relies on the recorded output of commands used for *tasks* and in some cases by *conditions*: the **When** log files are not analyzed. However they remain a valuable source of information in case something goes wrong, that is why the test configuration includes debug logging. Logs are appended to the normal logs, the logging system in **When** does not allow to use different files or locations. During the tests **When** uses the color icon set: I normally let the applet guess the icon set, which in my case means that it uses light icons on dark background and I can visually identify the fact that the running one is a test session.

Please note that, in order for *idle time based conditions* to occur properly, the testing session should be left alone without user interaction. For this reason the test script gives the user a grace time to unfocus a possible virtual desktop, so that the virtual machine can remain idle for the whole session letting the user do something else, such as checking the logs in a remote session.
