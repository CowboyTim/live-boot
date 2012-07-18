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
deb http://security.debian.org/ squeeze/updates main contrib non-free
deb-src http://security.debian.org/ squeeze/updates main contrib non-free
deb $baseurl/debian-backports squeeze-backports main contrib non-free
Eol
cat > /etc/apt/sources.list <<Eoe
Eoe

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
apt-listchanges        hold
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
nano                   hold
EOhold

apt-get -y --force-yes install \
    alien \
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
    g++ \
    gcc \
    g++-multilib \
    gcc-multilib \
    gcc-avr \
    gcc-doc \
    gccxml \
    genisoimage \
    git \
    git-svn \
    gtk-chtheme \
    gtk2-engines-murrine \
    htop \
    iceweasel \
    joystick \
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
    squashfs-tools \
    strace \
    subversion \
    sudo \
    sysklogd \
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

apt-get -y --force-yes upgrade
apt-get -y --force-yes remove \
    nano whiptail xfonts-base xfonts-100dpi python-central python-fuse \
    dictionaries-common hunspell-en-us libgl1-mesa-dri \
    libatk1.0-data \
    libnewt0.52 \
    whiptail \
    openssh-blacklist-extra \
    openssh-blacklist \
    xfonts-base \
    xfonts-100dpi \
    poppler-data \
    sgml-base \
    xml-core
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

for f in dropbear dbus; do
    update-rc.d -f $f remove
done

tasksel install desktop
