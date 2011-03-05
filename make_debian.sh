#!/bin/bash

timezone_area="Europe"
timezone_city="Brussels"


tmp=/var/tmp
datestr=`date +%s`
tmpdir=$tmp/squeeze.$datestr
fn=$tmp/squashfs.$datestr
here=$(readlink -f -- "${0%/*}") 

debootstrap squeeze $tmpdir http://ftp.be.debian.org/debian

mount proc $tmpdir/proc -t proc
mount sysfs $tmpdir/sys -t sysfs

cat >> $tmpdir/usr/sbin/policy-rc.d <<EOh
exit 101
EOh
chmod +x $tmpdir/usr/sbin/policy-rc.d
cat >> $tmpdir/etc/apt/sources.list.d/ps3.extra.list <<Eol
deb http://ftp.be.debian.org/debian squeeze main contrib non-free
deb http://security.debian.org/ squeeze/updates main contrib non-free
deb-src http://security.debian.org/ squeeze/updates main contrib non-free
deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free
Eol
chroot $tmpdir /bin/bash -c "
aptitude update
apt-get update
apt-get -y install debconf-utils
debconf-set-selections <<EOc
tzdata  tzdata/Zones/$timezone_area     select  $timezone_city
tzdata  tzdata/Areas select  $timezone_area
keyboard-configuration  keyboard-configuration/ctrl_alt_bksp    boolean true
keyboard-configuration  keyboard-configuration/modelcode        string  pc105
keyboard-configuration  keyboard-configuration/unsupported_layout       boolean true
keyboard-configuration  keyboard-configuration/unsupported_config_options boolean true
keyboard-configuration  keyboard-configuration/variantcode      string  
keyboard-configuration  keyboard-configuration/unsupported_config_layout boolean true
keyboard-configuration  keyboard-configuration/toggle   select  No toggling
keyboard-configuration  keyboard-configuration/model    select  Generic 105-key (Intl) PC
keyboard-configuration  keyboard-configuration/compose  select  No compose key
keyboard-configuration  keyboard-configuration/layout   select  
keyboard-configuration  keyboard-configuration/xkb-keymap       select  us
keyboard-configuration  keyboard-configuration/layoutcode       string  us
keyboard-configuration  keyboard-configuration/variant  select  USA
keyboard-configuration  keyboard-configuration/switch   select  No temporary switch
keyboard-configuration  keyboard-configuration/unsupported_options      boolean true
keyboard-configuration  keyboard-configuration/store_defaults_in_debconf_db boolean true
keyboard-configuration  keyboard-configuration/altgr    select  The default for the keyboard layout
keyboard-configuration  keyboard-configuration/optionscode      string terminate:ctrl_alt_bksp
console-setup   console-setup/codeset47 select  # Latin1 and Latin5 - western Europe and Turkic languages
console-setup   console-setup/codesetcode       string  Lat15
console-setup   console-setup/fontface47        select  Fixed
console-setup   console-setup/fontsize-text47   select  16
console-setup   console-setup/store_defaults_in_debconf_db      boolean true
console-setup   console-setup/charmap47 select  UTF-8
console-setup   console-setup/fontsize-fb47     select  16
console-setup   console-setup/fontsize  string  16
EOc

echo 'console-setup hold' |dpkg --set-selections
"
chroot $tmpdir /bin/bash -c '
aptitude -y install \
    openbox obconf  \
    xserver-xorg-input-evdev xserver-xorg-input-mouse \
    xserver-xorg-video-fbdev \
    console-common console-data \
    dropbear \
    iceweasel gcc-4.4-spu lib64gcc1 gcc-spu gcc-avr spu-gcc spu-tools \
    avr-libc bc bzip2  \
    git zip p7zip unrar rxvt-unicode screen sudo xpdf \
    zlib1g-dev vim vim-runtime \
    lsof ltrace strace \
    colordiff wireless-tools wmctrl  uuid-runtime usbutils  \
    wpasupplicant time p7zip-full socat \
    nmap ntpdate lua5.1 lua5.1-doc lzma m4 make \
    luarocks luasocket luasocket-dev liblua5.1-posix-dev  \
    liblua5.1-posix1 liblua5.1-dev \
    tcpdump ttf-bitstream-vera xfonts-100dpi console-terminus \
    xfonts-terminus xinit rpm perltidy  netcat llvm llvm-dev \
    pwgen gtk2-engines-murrine gtk-chtheme luadoc numactl \
    fbpanel dnsutils device-tree-compiler deborphan debootstrap dzen2 ethtool \
    evtest exiv2 ftp g++-4.4  gcc-4.4-multilib gccxml genisoimage git-svn \
    curl dcraw dc bison flex autoconf automake bluez bluez-hcidump \
    build-essential dhcp3-client fakechroot fakeroot perl-doc \
    joystick oprofile mscompress cabextract xrestop squashfs-tools \
    fuse-utils python-fuse python2.6-fuse ruby libfuse2 libfuse-dev \
    libfuse-perl libfusefs-ruby1.8 fuse-utils  emesene \
    x11-utils x11-server-utils xserver-xorg-input-kbd mplayer ps3-utils \
    alsa-base alsa-utils linux-sound-base tint2 x11-xserver-utils \
    ttf-dejavu-core ttf-liberation ttf-mscorefonts-installer htop rox-filer xloadimage
'

chroot $tmpdir /bin/bash -c '
aptitude -y remove gconf2 gconf2-common libgconf2-4 console-setup \
    libcanberra-gtk-module libvorbisfile3 libtdb1 libwnck-common libwnck22 \
    libidl0 libcanberra-gtk0 libcanberra0 liborbit2 dbus-x11 \
    python-gst0.10 kbd libgstreamer0.10-0 libmimic0 libpython2.6 \
    python-libmimic iso-codes python2.5 python2.5-minimal \
    console-tools console-data libconsole  python3.1 python3.1-minimal \
    python3 python3-minimal yaboot  powerpc-utils powerpc-ibm-utils \
    console-common console-data
aptitude -y upgrade
aptitude -y `deborphan`
aptitude clean
dpkg -P `dpkg -l |grep ^rc|awk "{print $2}"`

for f in dropbear dbus; do
    update-rc.d $f disable
done
'

cp -a $here/ps3/package/etc/{skel,alsa,sysctl.d,init.d,X11,udev,kboot.*} $tmpdir/etc/
chroot $tmpdir /bin/bash -c '
useradd tim -g users -s /bin/bash -m -u 1000 -G audio,fuse,adm,cdrom,sudo -f -1
update-rc.d wm defaults
'

rm $tmpdir/usr/sbin/policy-rc.d

mkdir -p $tmpdir/cgroup

time nice -n 20 mksquashfs \
    $tmpdir/* \
    $fn.root \
    -e $tmpdir/{proc,tmp,sys,mnt,media,home,dev,boot,var}/*
time nice -n 20 mksquashfs \
    $tmpdir/var \
    $fn.var \
    -e $tmpdir/{var/run,var/lock,var/tmp}/*

echo
echo $fn
