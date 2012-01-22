#!/bin/bash

## if [ -d /cgroup/cpu/user ]; then
##     mkdir -m 0700 /cgroup/cpu/user/wm
##     echo $$ > /cgroup/cpu/user/wm/tasks
##     echo 2048 > /cgroup/cpu/user/wm/cpu.shares
## fi
if [ -e /cgroup/blkio/tasks ]; then
    mkdir -m 0700 /cgroup/blkio/wm
    echo $$ > /cgroup/blkio/wm/tasks
    echo 1000 > /cgroup/blkio/wm/blkio.weight
fi

export MOZ_DISABLE_PANGO=1
xrdb -merge ~/.Xresources
xset m 1/1
xset b off
setxkbmap -option terminate:ctrl_alt_bksp
pkill -9 -f ssh-agent
eval `ssh-agent -s`
tint2 &
if [ ! -z "$WM_BACKDROP" -a -e "$WM_BACKDROP" ]; then
    xsetbg "$WM_BACKDROP" &
else
    xsetroot -solid DimGray
fi
if [ -x ~/dropbox.py ]; then
    (
        ~/dropbox.py running
        if [ $? = 0 ]; then
            ~/dropbox.py start
        fi
    )&
fi
exec openbox-session
