#!/usr/bin/env python3

import os
import sys
import time


# constants amd configuration
TIME_EVENT_AFTER_MINUTES = 2
IDLE_TIME_MINUTES = 3
INTERVAL_MINUTES = 5

# directories
BASE_DIR = os.path.dirname(sys.argv[0])
if BASE_DIR == "" or BASE_DIR == ".":
    BASE_DIR = os.getcwd()
SAVE_DIR = os.path.join(BASE_DIR, 'save')
CONF_DIR = os.path.join(BASE_DIR, 'conf')
TEMPLATE = os.path.join(CONF_DIR, 'when-items_TEMPLATE.dump')
OUT_FILE = os.path.join(CONF_DIR, 'when-items.dump')

# define current time
curtime = time.time()
time_event_secs = curtime + TIME_EVENT_AFTER_MINUTES * 60
time_event = time.localtime(time_event_secs)

to_replace = {
    'BASE_DIR': BASE_DIR,
    'TIMEOFDAY_HOUR': time_event.tm_hour,
    'TIMEOFDAY_MINUTE': time_event.tm_min,
    'IDLE_TIME': IDLE_TIME_MINUTES * 60,
    'INTERVAL_TIME': INTERVAL_MINUTES * 60,
}


def replace_in_text(s):
    for x in to_replace:
        s = s.replace("[[%s]]" % x, str(to_replace[x]))
    return s


# allow comments in templates: all lines that begin with '#' are discarded
output = open(OUT_FILE, 'w')
with open(TEMPLATE) as f:
    for line in f:
        valid_line = line.lstrip()
        if valid_line and valid_line[0] != '#':
            output.write(replace_in_text(line))
output.close()

# end.
