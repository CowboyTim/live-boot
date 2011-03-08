#!/bin/bash

timezone_area="Europe"
timezone_city="Brussels"
username="tim"
password="xxx"
wireless_essid=""
hostname="wihiie"

tmp=/var/tmp
datestr=`date +%s`
tmpdir=$tmp/squeeze.$datestr
fn=$tmp/squashfs.$datestr
srcloc=$(readlink -f -- "${0%/*}") 

renice -n +20 -p $$

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
chroot $tmpdir /bin/bash <<EOinstallSetup
apt-get update
apt-get update
apt-get -y install debconf-utils
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
EOc

dpkg --set-selections <<EOhold
console-setup          hold 
console-data           hold 
console-common         hold 
console-tools          hold 
kbd                    hold 
python3                hold 
python3-minimal        hold 
python3.1              hold 
python3.1-minimal      hold 
python2.5              hold 
python2.5-minimal      hold 
python-gst0.10         hold 
python-dbus            hold 
python-notify          hold 
libmimic0              hold 
gconf2                 hold 
gconf2-common          hold 
dbus-x11               hold 
iso-codes              hold 
libgconf2-4            hold 
libcanberra-gtk-module hold 
libvorbisfile3         hold 
libtdb1                hold 
libwnck-common         hold 
libwnck22              hold 
libdbus-glib-1-2       hold 
libnotify1             hold 
libpython2.6           hold 
libidl0                hold 
libcanberra-gtk0       hold 
libcanberra0           hold 
liborbit2              hold 
libgstreamer0.10-0     hold
libconsole             hold
libpci3                hold
geoip-database         hold
dictionaries-common    hold
hunspell-en-us         hold
mac-fdisk              hold
xdg-utils              hold
zeroinstall-injector   hold
pciutils               hold
EOhold
EOinstallSetup
chroot $tmpdir /bin/bash <<EOinstall 
apt-get -y install \
    alsa-base \
    alsa-utils \
    autoconf \
    automake \
    avr-libc \
    bc \
    bison \
    bluez \
    bluez-hcidump \
    build-essential \
    bzip2 \
    cabextract \
    colordiff \
    console-terminus \
    curl \
    dc \
    dcraw \
    debootstrap \
    deborphan \
    device-tree-compiler \
    dhcp3-client \
    dnsutils \
    dropbear \
    dzen2 \
    emesene \
    ethtool \
    evtest \
    exiv2 \
    fakechroot \
    fakeroot \
    fbpanel \
    flex \
    ftp \
    fuse-utils \
    fuse-utils \
    g++-4.4 \
    gcc-4.4-multilib \
    gcc-4.4-spu \
    gcc-avr \
    gcc-spu \
    gccxml \
    genisoimage \
    git \
    git-svn \
    gtk-chtheme \
    gtk2-engines-murrine \
    htop \
    iceweasel \
    joystick \
    lib64gcc1 \
    libfuse-dev \
    libfuse-perl \
    libfuse2 \
    libfusefs-ruby1.8 \
    liblua5.1-dev \
    liblua5.1-posix-dev \
    liblua5.1-posix1 \
    linux-sound-base \
    llvm \
    llvm-dev \
    lsof \
    ltrace \
    lua5.1 \
    lua5.1-doc \
    luadoc \
    luarocks \
    luasocket \
    luasocket-dev \
    lzma \
    m4 \
    make \
    mplayer \
    mscompress \
    netcat \
    nmap \
    ntpdate \
    numactl \
    obconf \
    openbox \
    oprofile \
    p7zip \
    p7zip-full \
    perl-doc \
    perltidy \
    ps3-utils \
    psmisc \
    pwgen \
    python-fuse \
    python2.6-fuse \
    rox-filer \
    rpm \
    ruby \
    rxvt-unicode \
    screen \
    socat \
    spu-tools \
    squashfs-tools \
    strace \
    sudo \
    tcpdump \
    time \
    tint2 \
    ttf-bitstream-vera \
    ttf-dejavu-core \
    ttf-liberation \
    ttf-mscorefonts-installer \
    unrar \
    usbutils \
    uuid-runtime \
    vim \
    vim-runtime \
    wireless-tools \
    wmctrl \
    wpasupplicant \
    x11-utils \
    x11-xserver-utils \
    xfonts-100dpi \
    xfonts-terminus \
    xinit \
    xloadimage \
    xpdf \
    xrestop \
    xserver-xorg-input-evdev \
    xserver-xorg-input-kbd \
    xserver-xorg-input-mouse \
    xserver-xorg-video-fbdev \
    zip \
    zlib1g-dev
EOinstall
chroot $tmpdir /bin/bash <<'EOrm'
apt-get -y upgrade
apt-get -y remove yaboot powerpc-utils powerpc-ibm-utils aptitude mac-fdisk
l=`deborphan`
while [ "$l" ]; do
    apt-get -y remove $l
    echo $l
    l=`deborphan`
done
apt-get clean
dpkg -P `dpkg -l |grep ^rc|awk '{print $2}'`

for f in dropbear dbus; do
    update-rc.d -f $f remove
done
EOrm

cp -a $srcloc/ps3/package/etc/{skel,alsa,sysctl.d,init.d,X11,udev,kboot.*} $tmpdir/etc/
chroot $tmpdir /bin/bash <<EOpost
userdel tim
useradd tim -g users -s /bin/bash -m -u 1000 -G audio,fuse,adm,cdrom,sudo,bluetooth -f -1
passwd -e tim <<Eop
$password
$password
Eop
cat >/etc/default/wm <<Eou
WM_USER=$username
Eou
update-rc.d wm defaults
EOpost

cat >> $tmpdir/etc/network/interfaces <<EOnetwork

# The loopback network interface
auto lo
iface lo inet loopback

# WiFi om the PS3
auto wlan0
iface wlan0 inet dhcp
    wireless-essid $wireless_essid

# The primary network interface
auto eth0
iface eth0 inet dhcp
    metric 50
EOnetwork

cat >> $tmpdir/etc/hosts <<EOhosts
127.0.1.1     $hostname
EOhosts

cat >> $tmpdir/hostname <<EOhosts
$hostname
EOhosts

rm $tmpdir/usr/sbin/policy-rc.d

mkdir -p $tmpdir/cgroup

umount $tmpdir/proc
umount $tmpdir/sys

(
    cd $tmpdir
    tar cvf - * --exclude={dev,proc,sys,tmp,var}/* \
        |lzma > ../$(basename $tmpdir).tar.lzma
)

#time nice -n 20 mksquashfs \
#    $tmpdir/* \
#    $fn.root \
#    -e $tmpdir/{proc,tmp,sys,mnt,media,home,dev,boot,var}/*
#time nice -n 20 mksquashfs \
#    $tmpdir/var \
#    $fn.var \
#    -e $tmpdir/{var/run,var/lock,var/tmp}/*

echo
echo $fn
