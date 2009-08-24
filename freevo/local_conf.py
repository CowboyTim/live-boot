CONTROL_ALL_AUDIO   = 0
MAJOR_AUDIO_CTRL    = 'Master'
MAX_VOLUME          = 100
DEFAULT_VOLUME      = 100
CONFIG_VERSION      = 5.24

plugin.remove('mixer')
plugin.remove('tv')
plugin.remove('shutdown')
plugin.remove('xine')
plugin.remove('ossmixer')
plugin.remove('image.apod')
plugin.remove('headlines')
plugin.remove('image')
plugin.remove('usb')
plugin.remove('idlebar')
plugin.remove('idlebar.clock')
plugin.remove('idlebar.tc')
plugin.remove('idlebar.diskfree')
plugin.remove('idlebar.cdstatus')
plugin.remove('file_ops')
plugin.remove('rom_drives.rom_items')
plugin.remove('tiny_osd')

plugin.activate('alsamixer2')
plugin.activate('ps3_controller')
plugin.activate('shutdown')


SYS_SHUTDOWN_ENABLE  = True
SYS_SHUTDOWN_CONFIRM = True
SYS_SHUTDOWN_CMD     = '/sbin/shutdown -h now'
SYS_RESTART_CMD      = '/sbin/reboot' # aparently not needed/used when SYS_SHUTDOWN_ENABLE is True

START_FULLSCREEN_X  = 1

EVENTS['video']['r1']     = Event(VIDEO_SEND_MPLAYER_CMD, arg='seek +600')
EVENTS['video']['l1']     = Event(VIDEO_SEND_MPLAYER_CMD, arg='seek -600')
EVENTS['video']['SELECT'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='pause')
EVENTS['video']['UP']     = Event(VIDEO_SEND_MPLAYER_CMD, arg='sub_select')
EVENTS['video']['OSD']    = Event(VIDEO_SEND_MPLAYER_CMD, arg='osd')

MPLAYER_ARGS_DEF = '-nojoystick'
MPLAYER_VERSION = 0.9
MPLAYER_AO_DEV = 'alsa'
MPLAYER_ARGS = {
    'dvd'    : '-cache 8192 -monitoraspect 16:9 -af volnorm=2 -vf pp=fd',
    'vcd'    : '-cache 4096 -monitoraspect 16:9',
    'cd'     : '-cache 1024 -cdda speed=2',
    'mkv'    : '-cache 5000 -alang eng,en,En -monitoraspect 16:9 -ac hwdts,hwac3 -ass -ass-color ffffff00 -ass-font-scale 0.9 -fs',
    'ogm'    : '-cache 5000 -aid 1 -sid 0 -monitoraspect 16:9',
    'tv'     : '-nocache',
    'ivtv'   : '-cache 8192',
    'avi'    : '-cache 5000 -monitoraspect 16:9 -af volnorm=1',
    'mpg'    : '-cache 5000 -monitoraspect 16:9 -af volnorm=1 -vf pp=fd',
    'rm'     : '-cache 5000 -forceidx',
    'rmvb'   : '-cache 5000 -forceidx -monitoraspect 16:9',
    'webcam' : 'tv:// -tv driver=v4l:width=352:height=288:outfmt=yuy2:device=/dev/video2',
    'default': ''
}

SKIN_XML_FILE = 'Tux\'n Tosh TV'
JOY_CMDS = {
   'select' : 'HELP',
   'up'     : 'UP',
   'down'   : 'DOWN',
   'left'   : 'LEFT',
   'right'  : 'RIGHT',
   'cross'  : 'SELECT',
   'round'  : 'EXIT',
   'square' : 'OSD',
   'r1'     : 'r1',
   'l1'     : 'l1',
}


IMAGE_ITEMS = []
TV_CHANNELS = []
VIDEO_ITEMS = [ ('Video Archive', '/media') ]
AUDIO_ITEMS = [ ('MP3 Collection', '/media') ]
GAMES_ITEMS = [ ('MSX', '/media', ('GENERIC', 'openmsx', '', '', [ 'ROM', 'rom', 'zip', 'ZIP' ] )) ]

ROM_DRIVES  = []
VIDEO_SHOW_DATA_DIR  = '/media'

