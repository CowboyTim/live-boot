#!/bin/bash

# apt-get install debootstrap fakeroot fakechroot squashfs-tools genisoimage mcrypt


sourcecdrom="/media/cdrom"
version="hardy"
architecture="amd64"
isotarget="/var/tmp/test_live_cd.iso"
isoname="TIMUBUNTU"
passwd="tubuntu"
kernelversion="2.6.24-16-generic"
nvidia_driver_file=~/NVIDIA-Linux-x86_64-180.16-pkg2.run
flash_10_file=~/libflashplayer-10.0.d21.1.linux-x86_64.so.tar.gz
if [ -z $user_id ]; then
    user_id=$(id -u)
    user_name=$(id -nu)
    export user_id user_name
fi
here=$(readlink -f -- "${0%/*}") 
wm='startkde'

#------------------------------------------------------------------------------
if [ -z $1 ]; then
    exec fakechroot fakeroot $0 'ok'
fi
#------------------------------------------------------------------------------
#
# from here, we're fakechroot fakeroot
#

tmpdir=$(mktemp -d -p /var/tmp live_cd_build_XXXXXX)
tmptargetsquashdir="$tmpdir/squashfs"
tmptargetisodir="$tmpdir/iso"
mkdir -p $tmptargetsquashdir
mkdir -p $tmptargetisodir

exec > >(tee $tmpdir/build.log)
exec 2>&1

echo $tmptargetsquashdir
ls -l $(dirname $tmptargetsquashdir)

echo "Will bootstrap a debian $version ($architecture) in $tmptargetsquashdir"
debootstrap --variant=fakechroot \
    --arch $architecture \
    $version \
    $tmptargetsquashdir \
    file://$sourcecdrom

ln -s $sourcecdrom $tmptargetsquashdir

echo "Making preseed"
##cat > $tmpdir/installf.preseed <<EOpreseed
##EOpreseed
chroot $tmptargetsquashdir debconf-set-selections <<EOpreseed
# Only install the standard system and language packs.
#tasksel tasksel/first   multiselect
#d-i     pkgsel/language-pack-patterns   string
# No language support packages.
#d-i     pkgsel/install-language-support boolean false

dash                  dash/sh                                   boolean true
debconf               debconf/frontend                          string Noninteractive
debconf               debconf/priority                          string critical
ucf                   ucf/changeprompt_threeway                 string replace
adduser               adduser/homedir-permission                boolean true
fdutils               fdutils/fdmount_setuid                    boolean false
man-db                man-db/build-database                     boolean false
man-db                man-db/rebuild-database                   boolean false
man-db                man-db/install-setuid                     boolean false
popularity-contest    popularity-contest/participate            boolean false
x11-common            x11-common/xwrapper/allowed_users         string Anybody
x11-common            x11-common/xwrapper/actual_allowed_users  string anybody

EOpreseed

echo "Hacking update-notifier to no-op"
mkdir -p $tmptargetsquashdir/usr/share/update-notifier
cat > $tmptargetsquashdir/usr/share/update-notifier/notify-reboot-required <<EOnop
#!/bin/bash
exit 0
EOnop
chmod +x $tmptargetsquashdir/usr/share/update-notifier/notify-reboot-required

echo "CDROM Setup for apt and hacks for ucf"
chroot $tmptargetsquashdir bash -c "
    :> /etc/apt/sources.list
    echo 'deb http://archive.ubuntu.com/ubuntu/ hardy main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ hardy main restricted universe multiverse' \
        >> /etc/apt/sources.list

    rm -f /var/lib/apt/lists/*

    apt-cdrom -mf add
    apt-get -y --force-yes --allow-unauthenticated install gnupg
    apt-get update --allow-unauthenticated
    apt-get -y --force-yes --allow-unauthenticated install ucf
    apt-get -y --force-yes --allow-unauthenticated install module-init-tools
"

echo "Hacking ucf, fakeroot has a bug with -w check?"
cp -f $tmptargetsquashdir/usr/bin/ucf $tmptargetsquashdir/usr/bin/ucf.REAL
cp $here/ucf $tmptargetsquashdir/usr/bin/ucf
cp -f $tmptargetsquashdir/usr/bin/ucfr $tmptargetsquashdir/usr/bin/ucfr.REAL
cp $here/ucfr $tmptargetsquashdir/usr/bin/ucfr

echo "Hacking GConf shit, actually only needed for ubuntu-desktop probably..."
chroot $tmptargetsquashdir bash -c "
    dpkg-divert --rename --add /usr/bin/gconf-merge-tree
    dpkg-divert --rename --add /usr/sbin/gconf-schemas
    dpkg-divert --rename --add /usr/sbin/update-gconf-defaults
    dpkg-divert --rename --add /usr/bin/update-desktop-database
    dpkg-divert --rename --add /usr/sbin/invoke-rc.d
    dpkg-divert --rename --add /usr/bin/polkit-auth
    dpkg-divert --rename --add /sbin/start-stop-daemon
    dpkg-divert --rename --add /usr/bin/touch

    cp /bin/true /usr/sbin/gconf-schemas
    cp /bin/true /usr/sbin/update-gconf-defaults
    cp /bin/true /usr/bin/update-desktop-database
    cp /bin/true /usr/sbin/invoke-rc.d
    cp /bin/true /usr/bin/polkit-auth
    cp /bin/true /sbin/start-stop-daemon

cat > /usr/bin/touch <<EOt
#!/bin/bash
if [ ! -z \\\$1 -a "\\\$1" != '-m' ]; then
    exec /usr/bin/touch.distrib \\\$*
fi
EOt
chmod +x /usr/bin/touch

cat > /usr/bin/gconf-merge-tree <<EOgc
#!/bin/bash
mkdir -p \\\$1
touch \\\$1/%gconf-tree.xml
exit 0
EOgc
    apt-get -y --force-yes --allow-unauthenticated install gconf2
"

echo "Installing extra packages"
chroot $tmptargetsquashdir bash -c "
    apt-get -y --force-yes --allow-unauthenticated install ubuntu-minimal
    apt-get -y --force-yes --allow-unauthenticated install ubuntu-standard
    apt-get -y --force-yes --allow-unauthenticated install \
        xinit xorg openbox fbpanel rxvt-unicode firefox pidgin vim-gtk vim-gui-common \
        mplayer obconf screen xterm
    apt-get -y --force-yes --allow-unauthenticated install language-pack-en
    apt-get -y --force-yes --allow-unauthenticated install ntfsprogs xfsprogs jfsutils
    apt-get -y --force-yes --allow-unauthenticated install xresprobe gparted gawk
    apt-get -y --force-yes --allow-unauthenticated install kubuntu-desktop
#    apt-get -y --force-yes --allow-unauthenticated install ubiquity
#    apt-get -y --force-yes --allow-unauthenticated install \
#        user-setup \
#        aspell ispell hspell gij \
#        openoffice.org-base \
#        openoffice.org-math   \
#        scim-pinyin scim-chewing scim-hangul

    # mainly for the NVIDIA driver compile:
    apt-get -y --force-yes --allow-unauthenticated install \
        vim-gui-common \
        linux-headers-generic \
        linux-image \
        linux-restricted-modules-common \
        libc6-dev \
        make \
        gcc \
        binutils \
        initramfs-tools \
        dmsetup \
        usplash \
        brltty \
        #linux-source

    apt-get -y --force-yes --allow-unauthenticated install \
        linux-restricted-modules
"

cp $nvidia_driver_file $tmptargetsquashdir
NV=$(basename $nvidia_driver_file)
chroot $tmptargetsquashdir bash -c "
    rm -rf ./${NV%.run}
    sh ./$NV -x
    cd ${NV%.run}/usr/src/nv
    mkdir -p /tmp/ii
    make SYSSRC=/usr/src/linux-headers-$kernelversion module
	install -m 0664 -o root -g root nvidia.ko /lib/modules/$kernelversion/kernel/drivers/video
    cd /
    cp -fR ${NV%.run}/usr/X11R6/lib/modules/* /usr/lib/xorg/modules
    cp -fR ${NV%.run}/usr/X11R6/lib/lib* /usr/lib
    ln -s /usr/lib/libXvMCNVIDIA.so.180.16 /usr/lib/libXvMCNVIDIA_dynamic.so.1
    ln -s /usr/lib/libXvMCNVIDIA_dynamic.so.1 /usr/lib/libXvMCNVIDIA_dynamic.so
    ln -s /usr/lib/xorg/modules/libnvidia-wfb.so.180.16 /usr/lib/xorg/modules/libnvidia-wfb.so.1 
    rm -f /usr/lib/xorg/modules/libwfb.so
    ln -s /usr/lib/xorg/modules/libnvidia-wfb.so.1 /usr/lib/xorg/modules/libwfb.so
    rm -f /usr/lib/xorg/modules/extensions/libglx.so
    ln -s /usr/lib/xorg/modules/extensions/libglx.so.180.16 /usr/lib/xorg/modules/extensions/libglx.so
    rm -f /usr/lib/xorg/modules/extensions/libGLcore.so
    rm -rf ${NV%.run}/usr/X11R6
    mkdir -p /usr/share/doc/NVIDIA_GLX-1.0
    cp -fR ${NV%.run}/usr/share/doc/* /usr/share/doc/NVIDIA_GLX-1.0
    cp -fR ${NV%.run}/LICENSE /usr/share/doc/NVIDIA_GLX-1.0
    mkdir -p /usr/share/doc/NVIDIA_GLX-1.0/include
    cp -fR ${NV%.run}/usr/include/GL /usr/share/doc/NVIDIA_GLX-1.0/include
    cp -fR ${NV%.run}/usr/share/pixmaps/nvidia-settings.png /usr/share/doc/NVIDIA_GLX-1.0
    rm -rf ${NV%.run}/usr/share/doc
    cp -fR ${NV%.run}/usr/* /usr
    cp -fR ${NV%.run}/nvidia-installer /usr/bin
    ln -s ${NV%.run}/nvidia-installer /usr/bin/nvidia-uninstall
    #nvidia-xconfig --logo

"
for i in `find $tmptargetsquashdir/${NV%.run} -name 'lib*.so*'|grep -v X11R6`; do 
    b=$(basename $i)
    d=$(dirname $i)
    f=${d#$tmptargetsquashdir/${NV%.run}}
    echo rm -f $f/${b%.180.16} $f/${b%.180.16}.1
    echo ln -s $f/$b $f/${b%.180.16}
    echo ln -s $f/$b $f/${b%.180.16}.1
    chroot $tmptargetsquashdir bash -c "
        rm -f $f/${b%.180.16} $f/${b%.180.16}.1
        ln -s $f/$b $f/${b%.180.16}
        ln -s $f/$b $f/${b%.180.16}.1
"
done
rm -rf $tmptargetsquashdir/${NV%.run}

#fakechroot chroot $tmptargetsquashdir NVIDIA-Linux-x86_64-180.16-pkg2.run \
    #-a --no-cc-version-check --run-nvidia-xconfig --no-rpms \
    #-b --no-x-check --no-network --no-recursion --no-precompiled-interface \
    #--no-runlevel-check -k $kernelversion

echo "Running the gconf2 schema imports ourselves"
if [ -d $tmptargetsquashdir/usr/share/gconf/schemas ]; then
    export GCONF_CONFIG_SOURCE=xml:readwrite:$tmptargetsquashdir/var/lib/gconf/defaults
    gconftool-2 --makefile-install-rule \
        $tmptargetsquashdir/usr/share/gconf/schemas/*.schemas
    if [ -d $tmptargetsquashdir/usr/share/gconf/defaults ]; then
        ./update-gconf-defaults \
            --defaults-dir $tmptargetsquashdir/usr/share/gconf/defaults \
            --outdir $tmptargetsquashdir/var/lib/gconf/debian.defaults
    fi
fi

echo "Install good flash from $flash_10_file"
(
    mkdir -p $tmptargetsquashdir/usr/lib/firefox-addons/plugins
    cd $tmptargetsquashdir/usr/lib/firefox-addons/plugins
    tar xvzf $flash_10_file
)

chroot $tmptargetsquashdir bash -c "
    #update-rc.d -f gdm remove
    update-rc.d -f kdm remove
    update-rc.d -f cupsys remove
    update-rc.d -f readahead remove
    update-rc.d -f sshd remove
    update-rc.d -f avahi-daemon remove
    update-rc.d -f pcmciautils remove
    update-rc.d -f samba remove
    update-rc.d -f sysstat remove
    update-rc.d -f openbsd-inetd remove
"

my_crypt_p=$(openssl passwd -crypt -salt xx '')
chroot $tmptargetsquashdir useradd -m -s /bin/bash --uid $user_id -G admin -p $passwd $user_name
#chroot $tmptargetsquashdir passwd -e $user_name

mkdir -p $tmptargetsquashdir/home/tim/Desktop

cp $here/kdmrc $tmptargetsquashdir/etc/kde3/kdm

#cat > $tmptargetsquashdir/home/$user_name/.xserverrc <<EOxserverrc
##!/bin/bash
#exec X -nolisten tcp vt7
#EOxserverrc
#chmod +x $tmptargetsquashdir/home/$user_name/.xserverrc

#cat > $tmptargetsquashdir/home/$user_name/.xinitrc <<EOxserverrc
##!/bin/bash
#fbpanel &
#gnome-settings-daemon &
#xsetroot -solid DimGray
#xset m 1 4
#exec openbox
#EOxserverrc
#
#chmod +x $tmptargetsquashdir/home/$user_name/.xinitrc
chown -R $user_name:$user_name $tmptargetsquashdir/home/$user_name

#cat > $tmptargetsquashdir/etc/event.d/tty7 <<EOtty
#start on runlevel 2
#
#stop on runlevel 0
#stop on runlevel 1
#stop on runlevel 3
#stop on runlevel 4
#stop on runlevel 5
#stop on runlevel 6
#
#respawn
#exec su - $user_name -c bash --login -c 'exec startx /usr/bin/$wm -- :0 >> /tmp/xinit.log 2>&1'
#EOtty

cat > $tmptargetsquashdir/etc/network/interfaces <<EOif
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp

# The secondary network interface
auto eth1
iface eth1 inet dhcp
EOif

cat > $tmptargetsquashdir/etc/default/locale <<EOift
LANG="en_US.UTF-8"
LANGUAGE="en_US:en"
EOift

cat > $tmptargetsquashdir/etc/hosts <<EOh
127.0.0.1 localhost oleeeh

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
EOh

cat > $tmptargetsquashdir/etc/sudoers <<EOs
# /etc/sudoers
#
# This file MUST be edited with the 'visudo' command as root.
#
# See the man page for details on how to write a sudoers file.
# Host alias specification

# User alias specification

# Cmnd alias specification

# Defaults

Defaults        !lecture,tty_tickets,!fqdn

# User privilege specification
root    ALL=(ALL) ALL

# Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL
%admin ALL=NOPASSWD: ALL
EOs
chmod 0400 $tmptargetsquashdir/etc/sudoers


echo "Removing all the dpkg-divert's"
chroot $tmptargetsquashdir bash -c "
    rm -f /usr/bin/gconf-merge-tree        && dpkg-divert --remove /usr/bin/gconf-merge-tree
    rm -f /usr/sbin/gconf-schemas          && dpkg-divert --remove /usr/sbin/gconf-schemas
    rm -f /usr/sbin/update-gconf-defaults  && dpkg-divert --remove /usr/sbin/update-gconf-defaults
    rm -f /usr/bin/update-desktop-database && dpkg-divert --remove /usr/bin/update-desktop-database
    rm -f /usr/sbin/invoke-rc.d            && dpkg-divert --remove /usr/sbin/invoke-rc.d
    rm -f /usr/bin/polkit-auth             && dpkg-divert --remove /usr/bin/polkit-auth
    rm -f /sbin/start-stop-daemon          && dpkg-divert --remove /sbin/start-stop-daemon
    rm -f /usr/bin/touch                   && dpkg-divert --remove /usr/bin/touch

    # 2 REAL's, the 'real' is the good one.. done by debootstrap?!
    rm -f /sbin/ldconfig /sbin/ldconfig.REAL
    mv /sbin/ldconfig.real /sbin/ldconfig
"


#echo "running dpkg-reconfigure -a -u"
#chroot $tmptargetsquashdir bash -c "
#    dpkg-reconfigure -plow -a -u
#"

echo "Cleaning the cache of apt-get"
chroot $tmptargetsquashdir apt-get clean

echo "Humpf, sometimes I wonder.. maybe this is in fact a compat package!?"
chroot $tmptargetsquashdir ln -s /usr/lib/libnspr4.so.0d /usr/lib/libnspr4.so
chroot $tmptargetsquashdir ln -s /usr/lib/libssl3.so.1d /usr/lib/libssl3.so
chroot $tmptargetsquashdir ln -s /usr/lib/libsmime3.so.1d /usr/lib/libsmime3.so
chroot $tmptargetsquashdir ln -s /usr/lib/libnss3.so.1d /usr/lib/libnss3.so
chroot $tmptargetsquashdir ln -s /usr/lib/libplc4.so.0d /usr/lib/libplc4.so
chroot $tmptargetsquashdir ln -s /usr/lib/libplds4.so.0d /usr/lib/libplds4.so

echo "Fix all symlinks, debootstrap sucks a bit on it"
(
    cd $tmptargetsquashdir
    for s in `find . -type l|grep -v '/proc'|grep -v '/dev'`; do
        orig_source=$(readlink $s);
        new_source=$(echo $orig_source|sed "s|^$tmptargetsquashdir||")
        if [ x"$orig_source" != x"$new_source" ]; then
            echo chroot $tmptargetsquashdir ln -s /$new_source $s
            chroot $tmptargetsquashdir rm -f $s && ln -s $new_source $s
        fi
    done
)

echo "Making ucf the original again"
rm -f $tmptargetsquashdir/usr/bin/ucf
mv $tmptargetsquashdir/usr/bin/ucf.REAL $tmptargetsquashdir/usr/bin/ucf
rm -f $tmptargetsquashdir/usr/bin/ucfr
mv $tmptargetsquashdir/usr/bin/ucfr.REAL $tmptargetsquashdir/usr/bin/ucfr

cat >> $tmptargetsquashdir/etc/fstab <<EOfst
/dev/shm	/tmp	tmpfs rw,exec,noatime,nodiratime	0	0
EOfst

echo "Running depmod for squashfs"
depmod -b $tmptargetsquashdir $kernelversion -a

echo "Creating squashfs file in $tmptargetsquashfs"
rm -rf $tmptargetsquashdir/tmp
rm -f $tmptargetsquashdir/{vmlinuz,initrd.img,cdrom,dev,proc}
mkdir -p $tmptargetsquashdir/{proc,dev,tmp}
tmptargetsquashfs="$tmpdir.squashfs"
mksquashfs $tmptargetsquashdir $tmptargetsquashfs  \
    -noappend \
    -always-use-fragments

mkdir -p $tmptargetisodir/modules
cp -f $tmptargetsquashfs $tmptargetisodir/modules

echo "Making a syslinux/isolinux config in $tmptargetisodir"
mkdir -p $tmptargetisodir/isolinux
cp -f /usr/lib/syslinux/{isolinux.bin,vesamenu.c32,chain.c32} \
    $tmptargetisodir/isolinux

cat > $tmptargetisodir/isolinux/isolinux.cfg <<EOisocfg
menu hshift 13
menu width 49
menu margin 8

menu title OleOla
menu color title    * #FFFFFFFF *
menu color border   * #00000000 #00000000 none
menu color sel      * #ffffffff #76a1d0ff *
menu color hotsel   1;7;37;40 #ffffffff #76a1d0ff *
menu color tabmsg   * #ffffffff #00000000 *
menu vshift 12
menu rows 10
menu tabmsgrow 16
menu timeoutrow 17
menu tabmsg Press ENTER to boot or TAB to edit a menu entry
default live
label live
  menu label ^Try running
  kernel /boot/vmlinuz
  append boot=fastboot_by_tim root=LABEL=$isoname initrd=/boot/initrd.gz noquiet nosplash toram --
label hd
  menu label ^Boot from first hard disk
  localboot 0x80

default vesamenu.c32
prompt 0
timeout 3
gfxboot bootlogo
EOisocfg

echo "Getting a kernel and an initrd"
mkdir -p $tmptargetisodir/boot
cp -f $tmptargetsquashdir/boot/vmlinuz-$kernelversion $tmptargetisodir/boot/vmlinuz

echo "Making a new initramfs"
tmpinitramfs="$tmptargetsquashdir/tmp/initrd.tmp"
mkdir -p $tmpinitramfs
cat > $tmpinitramfs/initramfs.conf <<EOinitramfsconf
MODULES=most
BUSYBOX=y
BOOT=local
DEVICE=eth0
NFSROOT=auto
EOinitramfsconf
mkdir -p $tmpinitramfs/scripts
cp ./fastboot_by_tim $tmpinitramfs/scripts
chmod +x $tmptargetsquashdir/usr/share/initramfs-tools/init
chroot $tmptargetsquashdir \
    mkinitramfs \
        -d /tmp/initrd.tmp  \
        -o /tmp/n.gz \
        $kernelversion

mkdir -p $tmpdir/initrd.hacks
(
    cd $tmpdir/initrd.hacks
    gunzip -c $tmptargetsquashdir/tmp/n.gz|cpio -i
    echo "Hacks in initramfs"
    ln -s /lib lib64
)
cp ./60-persistent-storage.rules $tmpdir/initrd.hacks/etc/udev/rules.d/60-persistent-storage.rules
cp $tmptargetsquashdir/sbin/losetup $tmpdir/initrd.hacks/sbin
cp -R $tmptargetsquashdir/lib/modules/$kernelversion/* $tmpdir/initrd.hacks/lib/modules/$kernelversion
depmod  -b $tmpdir/initrd.hacks -a $kernelversion
(
    cd $tmpdir/initrd.hacks
    echo "Creating $tmptargetisodir/boot/initrd.gz"
    find . |cpio -ov -H newc|gzip > $tmptargetisodir/boot/initrd.gz
)



echo "Making the iso from $tmptargetisodir to $isotarget"
mkisofs \
    -V $isoname -o $isotarget \
    -iso-level 4 -no-emul-boot -boot-load-size 4 -boot-info-table \
    -b isolinux/isolinux.bin  \
    $tmptargetisodir
