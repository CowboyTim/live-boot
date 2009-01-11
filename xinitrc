#!/bin/bash
fbpanel &
gnome-settings-daemon &
xsetroot -solid DimGray
exec openbox
