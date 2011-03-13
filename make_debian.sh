#!/bin/bash

timezone_area="Europe"
timezone_city="Brussels"
username="tim"
password="xxx"
wireless_essid=""
hostname="wihiie"
compresswith="gzip"

tmp=/var/tmp
datestr=`date +%s`
tmpdir=$tmp/squeeze.$datestr
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
localepurge     localepurge/remove_no   note       
localepurge     localepurge/verbose     boolean true
localepurge     localepurge/dontbothernew       boolean false
localepurge     localepurge/nopurge     multiselect     
localepurge     localepurge/quickndirtycalc     boolean true
localepurge     localepurge/mandelete   boolean true
localepurge     localepurge/showfreedspace      boolean true
localepurge     localepurge/none_selected       boolean true
EOc

dpkg --set-selections <<EOhold
libatk1.0-data         hold
libnewt0.52            holf
whiptail               hold
openssh-blacklist-extra     hold
openssh-blacklist      hold
xfonts-base            hold
xfonts-100dpi          hold
console-setup          hold 
console-data           hold 
console-common         hold 
console-tools          hold 
gsfonts                hold
gsfonts-x11            hold
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
libdrm-radeon1         hold
libgl1-mesa-dri        hold
libcupsimage2          hold
geoip-database         hold
dictionaries-common    hold
hunspell-en-us         hold
xdg-utils              hold
zeroinstall-injector   hold
pciutils               hold
poppler-data           hold
sgml-base              hold
xml-core               hold
nano                   hold
EOhold
EOinstallSetup
chroot $tmpdir /bin/bash <<EOinstall 
apt-get -y --force-yes install \
    alsa-base \
    alsa-utils \
    autoconf \
    automake \
    avr-libc \
    bc \
    binfmt-support \
    bison \
    bluez \
    bluez-hcidump \
    build-essential \
    bzip2 \
    cabextract \
    colordiff \
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
    fbset \
    flex \
    ftp \
    fuse-utils \
    fuse-utils \
    g++-4.4 \
    gcc-4.4-multilib \
    gcc-4.4-spu \
    gcc-avr \
    gcc-doc \
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
    libvpx-dev \
    linux-sound-base \
    lsof \
    ltrace \
    lua5.1 \
    lua5.1-doc \
    luadoc \
    luarocks \
    luasocket \
    luasocket-dev \
    libx11-dev \
    libxext-dev \
    libxv-dev \
    libxvmc-dev \
    lzma \
    m4 \
    manpages-posix-dev \
    manpages-posix \
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
    python2.6-fuse \
    rox-filer \
    rpm \
    ruby \
    rtorrent \
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
    x11proto-xext-dev \
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
    zlib1g-dev \
    localepurge \
    debconf-english
EOinstall
chroot $tmpdir /bin/bash <<'EOrm'
apt-get -y --force-yes upgrade
apt-get -y --force-yes remove \
    yaboot powerpc-utils powerpc-ibm-utils aptitude mac-fdisk
apt-get -y --force-yes remove \
    nano whiptail xfonts-base xfonts-100dpi python-central python-fuse \
    dictionaries-common hunspell-en-us libgl1-mesa-dri
apt-get -y --force-yes autoremove
l=`deborphan`
while [ "$l" ]; do
    apt-get -y --force-yes remove $l
    echo $l
    l=`deborphan`
done
apt-get clean
dpkg -P `dpkg -l |grep ^rc|awk '{print $2}'`

localepurge

chmod +s /usr/sbin/ps3-flash-util /sbin/reboot /sbin/shutdown

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

cat > $tmpdir/etc/timezone <<EOtz
$timezone_area/$timezone_city
EOtz

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

cat > $tmpdir/etc/hostname <<EOhosts
$hostname
EOhosts

rm $tmpdir/usr/sbin/policy-rc.d

mkdir -p $tmpdir/cgroup

umount -l $tmpdir/{proc,sys}

if [ ! -z "$compresswith" ]; then
(
    cd $tmpdir
    tar cvf - * --exclude={dev,proc,sys,tmp}/* \
        |$compresswith > $tmp/$(basename $tmpdir).tar.$compresswith
)
fi

#fn=$tmp/$(basename $tmpdir).squashfs.gzip
#time nice -n 20 mksquashfs \
#    $tmpdir/* \
#    $fn.root \
#    -e $tmpdir/{dev,proc,sys,tmp,var}/*
#time nice -n 20 mksquashfs \
#    $tmpdir/var \
#    $fn.var \
#    -e $tmpdir/{var/run,var/lock,var/tmp}/*

echo
echo $fn
