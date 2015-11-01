#!/usr/bin/env python3
#
# dbus_server.py
# emit DBus signals


import os
import sys
import time

from gi.repository import GLib, Gio, Gtk
from gi.repository import GObject

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop

import threading

UNIQUE_BUS_NAME = 'it.jks.EventEmitter'
INTERFACE_NAME = '/it/jks/EventEmitter'
WAIT_DELTA = 3
LONG_WAIT_DELTA = 15

base_dir = os.path.dirname(sys.argv[0])
wait_file = os.path.join(base_dir, 'temp', 'start_dbus.tmp')
main_loop = None
emitter = None


class SignalEmitter(dbus.service.Object):

    def __init__(self):
        bus_name = dbus.service.BusName(UNIQUE_BUS_NAME, bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, INTERFACE_NAME)

    @dbus.service.signal(UNIQUE_BUS_NAME, signature='')
    def PushSignal(self):           # no parameters
        pass

    @dbus.service.signal(UNIQUE_BUS_NAME, signature='s')
    def PushSignal_s(self, s):      # single str parameter
        pass

    @dbus.service.signal(UNIQUE_BUS_NAME, signature='is')
    def PushSignal_is(self, i, s):  # int and str parameters
        pass

    @dbus.service.signal(UNIQUE_BUS_NAME, signature='ia{si}')
    def PushSignal_iDsi(self, i, s):  # int and dict{str:int}
        pass

    @dbus.service.signal(UNIQUE_BUS_NAME, signature='i(si)')
    def PushSignal_iSsi(self, i, s):  # int and struct(str, int)
        pass


def thread_target():
    while not os.path.exists(wait_file):
        time.sleep(WAIT_DELTA)
    emitter.PushSignal()
    time.sleep(LONG_WAIT_DELTA)
    emitter.PushSignal_s("BoZo")
    time.sleep(LONG_WAIT_DELTA)
    emitter.PushSignal_is(42, "BoZo")
    time.sleep(LONG_WAIT_DELTA)
    emitter.PushSignal_iSsi(3, ("BoZo", 42))
    time.sleep(LONG_WAIT_DELTA)
    emitter.PushSignal_iDsi(3, {"BoZo": 42, "AnZo": 43})
    time.sleep(LONG_WAIT_DELTA)
    while os.path.exists(wait_file):
        time.sleep(WAIT_DELTA)
    main_loop.quit()


if __name__ == '__main__':
    DBusGMainLoop(set_as_default=True)
    main_loop = GObject.MainLoop()
    emitter = SignalEmitter()
    t = threading.Thread(target=thread_target)
    t.start()
    main_loop.run()


# end.
