#!/bin/bash

baseurl=$1
timezone_area="$2"
timezone_city="$3"

mount proc /proc -t proc
mount sysfs /sys -t sysfs

cat >> /usr/sbin/policy-rc.d <<EOh
exit 101
EOh
chmod +x /usr/sbin/policy-rc.d
cat >> /etc/apt/sources.list.d/extra.list <<Eol
deb $baseurl/debian squeeze main contrib non-free
#deb http://security.debian.org/ squeeze/updates main contrib non-free
#deb-src http://security.debian.org/ squeeze/updates main contrib non-free
Eol
cat > /etc/apt/sources.list <<Eoe
Eoe

gpg --keyserver keyserver.ubuntu.com --recv-key ABF5BD827BD9BF62

apt-get update
debconf-set-selections <<EOc
tzdata	tzdata/Zones/$timezone_area	select	$timezone_city
tzdata	tzdata/Areas	select	$timezone_area
keyboard-configuration	keyboard-configuration/ctrl_alt_bksp	boolean	true
keyboard-configuration	keyboard-configuration/modelcode	string	pc105
keyboard-configuration	keyboard-configuration/unsupported_layout	boolean	true
keyboard-configuration	keyboard-configuration/unsupported_config_options	boolean	true
keyboard-configuration	keyboard-configuration/variantcode	string
keyboard-configuration	keyboard-configuration/unsupported_config_layout	boolean	true
keyboard-configuration	keyboard-configuration/toggle	select	No toggling
keyboard-configuration	keyboard-configuration/model	select	Generic 105-key (Intl) PC
keyboard-configuration	keyboard-configuration/compose	select	No compose key
keyboard-configuration	keyboard-configuration/layout	select
keyboard-configuration	keyboard-configuration/xkb-keymap	select	us
keyboard-configuration	keyboard-configuration/layoutcode	string	us
keyboard-configuration	keyboard-configuration/variant	select	USA
keyboard-configuration	keyboard-configuration/switch	select	No temporary switch
keyboard-configuration	keyboard-configuration/unsupported_options	boolean	true
keyboard-configuration	keyboard-configuration/store_defaults_in_debconf_db boolean	true
keyboard-configuration	keyboard-configuration/altgr	select	The default for the keyboard layout
keyboard-configuration	keyboard-configuration/optionscode	string	terminate:ctrl_alt_bksp
console-setup	console-setup/codeset47	select	# Latin1 and Latin5 - western Europe and Turkic languages
console-setup	console-setup/codesetcode	string	Lat15
console-setup	console-setup/fontface47	select	Fixed
console-setup	console-setup/fontsize-text47	select	16
console-setup	console-setup/store_defaults_in_debconf_db	boolean	true
console-setup	console-setup/charmap47	select	UTF-8
console-setup	console-setup/fontsize-fb47	select	16
console-setup	console-setup/fontsize	string	16
localepurge     localepurge/remove_no   note       
localepurge     localepurge/verbose     boolean true
localepurge     localepurge/dontbothernew       boolean false
localepurge     localepurge/nopurge     multiselect     
localepurge     localepurge/quickndirtycalc     boolean true
localepurge     localepurge/mandelete   boolean true
localepurge     localepurge/showfreedspace      boolean true
localepurge     localepurge/none_selected       boolean true
EOc

#tasksel install desktop
aptitude -y --allow-untrusted install desktop
