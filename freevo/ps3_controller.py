#!/usr/bin/python
# -*- coding: iso-8859-1 -*-


from threading import Thread
from Queue import Queue
from Queue import Empty

import struct
import select
import time

import config
import plugin
import rc

q = Queue(1000)

button_to_axis = {
     4 :  8,   # up
     5 :  9,   # right
     6 : 10,   # down
     7 : 11,   # left
     8 : 12,   # l2
     9 : 13,   # r2
    10 : 14,   # l1
    11 : 15,   # r1
    12 : 16,   # triangle
    13 : 17,   # round
    14 : 18,   # cross
    15 : 19,   # square
}

button_to_abbreviation = {
     0 : 'select',
     1 : 'l3',
     2 : 'r3',
     3 : 'start',
     4 : 'up',
     5 : 'right',
     6 : 'down',
     7 : 'left',
     8 : 'l2',
     9 : 'r2',
    10 : 'l1',
    11 : 'r1',
    12 : 'triangle',
    13 : 'round',
    14 : 'cross',
    15 : 'square',
    16 : 'ps',
}

class JoyImp(Thread):
    def init_dev(self):
        print("Trying opening /dev/input/js0")
        fd = open('/dev/input/js0')
        p = select.poll()
        p.register(fd, select.POLLIN)
        return (p, fd)

    def run(self):

        JS_EVENT_BUTTON = 0x01  #/* button pressed/released */
        JS_EVENT_AXIS   = 0x02  #/* joystick moved */
        JS_EVENT_INIT   = 0x80  #/* initial state of device */
        JS_EVENT        = "IhBB"
        JS_EVENT_SIZE   = struct.calcsize(JS_EVENT)

        dt = 0.5
        RC = 1.8

        y = {}
        a = dt /(RC - dt)

        p = None
        fd = None
        while True:
            try:
                # get events
                if not p:
                    p, fd = self.init_dev()
                e = p.poll()
                evt = fd.read(JS_EVENT_SIZE)
                ts, value, type, number = struct.unpack(JS_EVENT, evt)
                evt = type & ~JS_EVENT_INIT
                if evt == JS_EVENT_AXIS:
                    # lowpass filter: http://en.wikipedia.org/wiki/Low-pass_filter
                    if number not in y:
                        y[number] = value
                        last_k = y[number]
                        q.put(['axis', number, value])
                    else:
                        last_k = y[number]
                        y[number] = y[number] + a * (value - y[number])
                        
                    # push to queue
                    if int(last_k) != int(y[number]):
                        q.put(['axis', number, int(y[number])])

                elif evt == JS_EVENT_BUTTON:
                    q.put(['button', number, value])
                else:
                    print('unknown')

            except IOError as (errno, strerror):
                print("I/O error({0}): {1}".format(errno, strerror))
                if fd: fd.close()
                p = None
                time.sleep(1)
            except e:
                print(e)
                

class PluginInterface(plugin.DaemonPlugin):
    """
    A control plugin for freevo with PS3 wireless bluetooth controller

    To use this plugin make sure that your joystick is already working properly and
    then configure JOY_CMDS in your local_conf.py.  You will also need to have 
    plugin.activate('ps3_controller') in your config as well.
    """

    def __init__(self):
        self.plugin_name = 'PS3_CONTROLLER'
        #self.poll_interval  = 1
        self.poll_menu_only = False
        self.enabled = True
        self.w = JoyImp()
        self.state = {
            'axis'   : {},
            'button' : {}
        }
        self.w.start()
        plugin.DaemonPlugin.__init__(self)

    def config(self):
        return [
            ('JOY_CMDS', {
               'select' : 'HELP',
               'up'     : 'UP',
               'down'   : 'DOWN',
               'left'   : 'LEFT',
               'right'  : 'RIGHT',
               'cross'  : 'ENTER',
               'round'  : 'EXIT',
            }, 'Mapping of controller buttons to actions')
        ]

    def poll(self):
        if not self.enabled:
            return
        
        _debug_('poll called')

        value_has_been = {
            'axis'   : {},
            'button' : {} 
        }

        try:
            while True:
                action = q.get_nowait()
                self.state[action[0]][action[1]] = action[2]
                if action[0] == 'button':
                    if action[2] == 1:
                        value_has_been['button'][action[1]] = 1
                    if action[2] == 0 and action[1] in button_to_axis:
                        self.state['axis'][button_to_axis[action[1]]] = 0
            print('state:'+str(self.state))
        except Empty, e:
            pass
        except:
            raise
        _debug_(str(self.state))
        _debug_(str(value_has_been))

        for button, value in self.state['button'].iteritems():
            if button in button_to_abbreviation:
                abbr_button = button_to_abbreviation[button]
                if abbr_button in config.JOY_CMDS:
                    command = config.JOY_CMDS[abbr_button]
                    if value == 1 or button in value_has_been['button']:
                        print('command:'+str(command))
                        handler = rc.get_singleton()
                        handler.post_event(handler.key_event_mapper(command))

    def enable(self, enable_joy=True):
        self.enabled = enable_joy
        return