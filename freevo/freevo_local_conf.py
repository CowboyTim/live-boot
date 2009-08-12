CONTROL_ALL_AUDIO   = 0
MAJOR_AUDIO_CTRL    = 'PCM'
MAX_VOLUME          = 100
DEFAULT_VOLUME      = 60
CONFIG_VERSION      = 5.24

plugin.remove('mixer')
plugin.remove('tv')
plugin.remove('shutdown')
plugin.remove('xine')
plugin.remove('ossmixer')
plugin.remove('image.apod')
plugin.remove('headlines')
plugin.remove('image')

plugin.activate('usb')
plugin.activate('idlebar')
plugin.activate('idlebar.clock',   level=50)
plugin.activate('alsamixer2')


START_FULLSCREEN_X  = 1

EVENTS['video']['1'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='switch_audio')
EVENTS['video']['4'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='sub_select')
EVENTS['video']['7'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='sub_remove')

EVENTS['video']['2'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='speed_incr +.10')
EVENTS['video']['5'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='speed_incr -.10')
EVENTS['video']['0'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='frame_step')

EVENTS['video']['3'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='panscan +.05')
EVENTS['video']['6'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='panscan -.05')

EVENTS['video']['8'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='switch_ratio 1.33334')
EVENTS['video']['9'] = Event(VIDEO_SEND_MPLAYER_CMD, arg='switch_ratio 1.77778')

MPLAYER_ARGS_DEF = ''
MPLAYER_VERSION = 0.9
MPLAYER_AO_DEV = 'alsa'
MPLAYER_ARGS = {
    'dvd'    : '-cache 8192 -monitoraspect 16:9 -af volnorm=2 -vf pp=fd',
    'vcd'    : '-cache 4096 -monitoraspect 16:9',
    'cd'     : '-cache 1024 -cdda speed=2',
    'mkv'    : '-cache 5000 -slang eng,en,En -monitoraspect 16:9 -ac hwdts,hwac3 -utf8 -ass -ass-color ffffff00 -fs',
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

SKIN_XML_FILE = 'dark'

IMAGE_ITEMS = []
TV_CHANNELS = []
VIDEO_ITEMS = [ ('Video Archive', '/media') ]
AUDIO_ITEMS = [ ('MP3 Collection', '/media') ]
GAMES_ITEMS = [ ('MSX', '/media', ('GENERIC', 'openmsx', '', '', [ 'ROM', 'rom', 'zip', 'ZIP' ] )) ]

