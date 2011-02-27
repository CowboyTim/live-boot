#!/bin/bash


tmp=/var/tmp
datestr=`date +%s`
tmpdir=$tmp/squeeze.$datestr

debootstrap squeeze $tmpdir http://ftp.be.debian.org/debian

mount proc $tmpdir/proc -t proc
mount sysfs $tmpdir/sys -t sysfs

cat >> $tmpdir/etc/apt/sources.list.d/ps3.extra.list <<Eol
deb http://security.debian.org/ squeeze/updates main
deb http://security.debian.org/ squeeze/updates main
deb-src http://security.debian.org/ squeeze/updates main
Eol
chroot $tmpdir /bin/bash -c <<EOc
dpkg -r yaboot powerpc-utils powerpc-ibm-utils
aptitude update
aptitude install \
    openbox obconf  \
    xserver-xorg-input-evdev xserver-xorg-input-mouse \
    xserver-xorg-video-fbdev \
    iceweasel python3 gcc-4.4-spu lib64gcc1 gcc-spu gcc-avr spu-gcc \
    avr-libc bc bzip2  \
    git zip p7zip rxvt-unicode screen sudo xpdf \
    zlib1g-dev vim vim-runtime \
    lsof ltrace strace \
    colordiff wireless-tools wmctrl  uuid-runtime usbutils  \
    wpasupplicant time p7zip-full socat \
    nmap ntpdate lua5.1 lua5.1-doc lzma m4 make \
    luarocks luasocket luasocket-dev liblua5.1-posix-dev  \
    liblua5.1-posix1 liblua5.1-dev
    tcpdump ttf-bitstream-vera xfonts-100dpi console-terminus \
    xfonts-terminus xinit rpm perltidy  netcat llvm llvm-dev \
    pwgen gtk2-engines-murrine gtk-chtheme luadoc numactl
    fbpanel dnsutils device-tree-compiler deborphan debootstrap dzen2 ethtool \
    evtest exiv2 ftp g++-4.4  gcc-4.4-multilib gccxml genisoimage git-svn \
    curl dcraw ddclient dc bison flex autoconf automake bluez bluez-hcidump \
    build-essential dhcp3-client fakechroot fakeroot perl-doc \
    joystick oprofile mscompress cabextract xrestop squashfs-tools \
    pike7.8-core ruby \
    fuse-utils python-fuse python2.6-fuse pike7.8-fuse libfuse2 libfuse-dev \
    libfuse-perl libfusefs-ruby1.8 fuse-utils 


aptitude upgrade
aptitude clean

groupadd users -g 1000
useradd tim -g users -s /bin/bash -m -u 1000 -G audio,fuse,adm,cdrom -f -1
EOc

fn=$tmp/root.squashfs.$datestr
time nice -n 20 mksquashfs $tmpdir/* $fn -e $tmpdir/{proc,tmp,var/tmp,sys,mnt,media,home,dev,boot}/*

echo
echo $fn
