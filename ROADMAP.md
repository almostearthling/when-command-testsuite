# Achievements and Roadmap

List of achievements and expectations for the When applet test suite.


## 1) Reached goals

* Self contained test environment:
  1. Dedicated **When** instance
  2. Save and restore current **When** instance status
  3. Consistent test-suite script
  4. Dedicated shell scripts for *tasks*
  5. Dedicated shell scripts for *command-based conditions*
  6. Relocatable template file for *items* (*tasks*, *conditions*, *signal handlers*)
* Shell based outcome tests:
  1. Check for *tasks* triggered by *conditions*
  2. Check for *tasks* **not** triggered by *conditions*
  3. Check for *task* success or failure
* Test *interval based conditions*
  1. Occurring
* Test *time based conditions*
  1. Occurring
* Test *command based conditions*
  1. Check exit status, positive
  2. Check exit status, negative
  3. Check stdout, positive
  4. Check stdout, positive substring
  5. Check stdout, positive match RE
  6. Check stdout, negative
  7. Check stderr, positive
  8. Check stderr, positive substring
  9. Check stderr, positive match RE
  10. Check stderr, negative
* Test *idle time based conditions*
  1. Occurring
* Test *event based conditions*
  13. Command line trigger
* Test *file change based conditions*
  1. Occurring for a directory
* Test *DBus custom event based conditions*
  1. Check signal alone
  2. Check signal arguments: number, equality, positive
  8. Check signal arguments: string, equality, positive
  14. Check signal arguments: string, RE match, positive
  22. Check signal multiple arguments, check all, positive
* Easy to understand test visualization
* Fancy output
* Progress bars for lengthy operations
* Documentation (`README.md`)


## 2) Goals for When 0.9.0-rc.1

* Test *interval based conditions*
  2. Not occurring
  3. Recurring
* Test *time based conditions*
  2. Not occurring
* Test *idle time based conditions*
  2. Not occurring
  3. Recurring
* Test *event based conditions*
  1. Startup
  2. Shutdown
  3. Suspend [*emulated or optional*]
  4. Resume [*emulated or optional*]
  5. Connect storage [*emulated or optional*]
  6. Disconnect storage [*emulated or optional*]
  7. Join network [*emulated or optional*]
  8. Leave network [*emulated or optional*]
  9. Start screensaver [*emulated or optional*]
  10. Exit screensaver [*emulated or optional*]
  11. Session lock [*emulated or optional*]
  12. Session unlock [*emulated or optional*]
* Test *file change based conditions*
  2. Not occurring for a directory
  3. Occurring for a single file
  4. Not occurring for a single file
* Test *DBus custom event based conditions* (*NOTE:* Multiple number/string tests can be combined into a single *multiple arguments* test.)
  3. Check signal arguments: number, equality, negative
  4. Check signal arguments: number, greater-than, positive
  5. Check signal arguments: number, greater-than, negative
  6. Check signal arguments: number, less-than, positive
  7. Check signal arguments: number, less-than, negative
  9. Check signal arguments: string, equality, negative
  10. Check signal arguments: string, greater-than, positive
  11. Check signal arguments: string, greater-than, negative
  12. Check signal arguments: string, less-than, positive
  13. Check signal arguments: string, less-than, negative
  15. Check signal arguments: string, RE match, negative
  16. Check signal arguments: string, substring (`contains`), positive
  17. Check signal arguments: string, substring (`contains`), negative
  18. Check signal arguments: list, subindex
  19. Check signal arguments: list, contains
  20. Check signal arguments: struct, subindex
  21. Check signal arguments: struct, contains
  23. Check signal multiple arguments, check all, negative
  24. Check signal multiple arguments, check any, positive
  25. Check signal multiple arguments, check any, negative
* Option for machine readable output


## 3) Goals for When 1.0.0

* Continuous Integration (optional)


## 4) Ongoing Actions

* Verify test correctness
