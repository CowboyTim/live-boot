#!/bin/bash

# apt-get install debootstrap fakeroot fakechroot squashfs-tools genisoimage 


sourcecdrom="/media/cdrom"
version="hardy"
architecture="amd64"
isotarget="/var/tmp/test_live_cd.iso"
isoname="TIMUBUNTU"
kernelversion="2.6.24-16-generic"
nvidia_driver_file=~/NVIDIA-Linux-x86_64-180.16-pkg2.run

tmpdir=$(mktemp -d -p /var/tmp live_cd_build_XXXXXX)
tmptargetsquashdir="$tmpdir/squashfs"
tmptargetisodir="$tmpdir/iso"
mkdir -p $tmptargetsquashdir
mkdir -p $tmptargetisodir

exec > >(tee $tmpdir/build.log)
exec 2>&1

echo "Will bootstrap a debian $version ($architecture) in $tmptargetsquashdir"
fakechroot fakeroot debootstrap --variant=fakechroot \
    --arch $architecture \
    $version \
    $tmptargetsquashdir \
    file://$sourcecdrom


ln -s $sourcecdrom $tmptargetsquashdir


echo "Making preseed"
##cat > $tmpdir/installf.preseed <<EOpreseed
##EOpreseed
fakechroot fakeroot chroot $tmptargetsquashdir debconf-set-selections <<EOpreseed
# Only install the standard system and language packs.
#tasksel tasksel/first   multiselect
#d-i     pkgsel/language-pack-patterns   string
# No language support packages.
#d-i     pkgsel/install-language-support boolean false

dash                  dash/sh                            boolean true
debconf               debconf/frontend                   string Noninteractive
debconf               debconf/priority                   string critical
ucf                   ucf/changeprompt_threeway          string replace
adduser               adduser/homedir-permission         boolean true
fdutils               fdutils/fdmount_setuid             boolean false
man-db                man-db/build-database              boolean false
man-db                man-db/rebuild-database            boolean false
man-db                man-db/install-setuid              boolean false
popularity-contest    popularity-contest/participate     boolean false

EOpreseed

echo "Hacking update-notifier to no-op"
mkdir -p $tmptargetsquashdir/usr/share/update-notifier
cat > $tmptargetsquashdir/usr/share/update-notifier/notify-reboot-required <<EOnop
#!/bin/bash
exit 0
EOnop
chmod +x $tmptargetsquashdir/usr/share/update-notifier/notify-reboot-required

echo "CDROM Setup for apt and hacks for ucf"
fakechroot fakeroot chroot $tmptargetsquashdir bash -c "
    :> /etc/apt/sources.list
    mkdir -p /etc/apt/sources.list.d
    echo 'deb http://archive.ubuntu.com/ubuntu/ hardy main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ hardy main restricted universe multiverse' \
        > /etc/apt/sources.list.d/extra_ubuntu

    apt-cdrom -mf add
    apt-get update --allow-unauthenticated
    apt-get -y --force-yes --allow-unauthenticated install ucf
    apt-get -y --force-yes --allow-unauthenticated install module-init-tools
"

echo "Hacking ucf, fakeroot has a bug with -w check?"
cp -f $tmptargetsquashdir/usr/bin/ucf $tmptargetsquashdir/usr/bin/ucf.REAL
cp ./ucf $tmptargetsquashdir/usr/bin/ucf
cp -f $tmptargetsquashdir/usr/bin/ucfr $tmptargetsquashdir/usr/bin/ucfr.REAL
cp ./ucfr $tmptargetsquashdir/usr/bin/ucfr

echo "Hacking GConf shit"
fakechroot fakeroot chroot $tmptargetsquashdir bash -c "
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
fakechroot fakeroot chroot $tmptargetsquashdir bash -c "
    apt-get -y --force-yes --allow-unauthenticated install ubuntu-minimal
    apt-get -y --force-yes --allow-unauthenticated install ubuntu-standard
    apt-get -y --force-yes --allow-unauthenticated install xorg
    #apt-get -y --force-yes --allow-unauthenticated install ubuntu-desktop

    apt-get -y --force-yes --allow-unauthenticated install \
        vim-gui-common \
        linux-headers-generic \
        linux-source \
        linux-image \
        linux-restricted-modules-common \
        libc6-dev \
        make \
        gcc \
        binutils \
        initramfs-tools \
        dmsetup \
        usplash \
        brltty
"

cp $nvidia_driver_file $tmptargetsquashdir
NV=$(basename $nvidia_driver_file)
fakechroot chroot $tmptargetsquashdir bash -c "
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
    nvidia-xconfig --logo

"
for i in `find $tmptargetsquashdir/${NV%.run} -name 'lib*.so*'|grep -v X11R6`; do 
    b=$(basename $i)
    d=$(dirname $i)
    f=${d#$tmptargetsquashdir/${NV%.run}}
    echo ln -s $f/$b $f/${b%.180.16}
    echo ln -s $f/$b $f/${b%.180.16}.1
    fakeroot fakechroot chroot $tmptargetsquashdir ln -s $f/$b $f/${b%.180.16}
    fakeroot fakechroot chroot $tmptargetsquashdir ln -s $f/$b $f/${b%.180.16}.1
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


echo "Removing all the dpkg-divert's"
fakechroot fakeroot chroot $tmptargetsquashdir bash -c "
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
#fakechroot fakeroot chroot $tmptargetsquashdir bash -c "
#    dpkg-reconfigure -plow -a -u
#"

echo "Cleaning the cache of apt-get"
fakechroot chroot $tmptargetsquashdir apt-get clean

echo "Fix all symlinks, debootstrap sucks a bit on it"
(
    cd $tmptargetsquashdir
    for s in `find . -type l`; do
        orig_source=$(readlink $s);
        new_source=$(echo $orig_source|sed "s|^$tmptargetsquashdir||")
        if [ x"$orig_source" != x"$new_source" ]; then
            echo chroot $tmptargetsquashdir ln -s /$new_source $s
            fakechroot fakeroot chroot $tmptargetsquashdir rm -f $s && ln -s $new_source $s
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
fakechroot fakeroot mksquashfs $tmptargetsquashdir $tmptargetsquashfs  \
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
fakeroot fakechroot chroot $tmptargetsquashdir \
    mkinitramfs \
        -d /tmp/initrd.tmp  \
        -o /tmp/n.gz \
        $kernelversion
mv $tmptargetsquashdir/tmp/n.gz $tmptargetisodir/boot/initrd.gz

mkdir -p $tmpdir/initrd.hacks
(
    cd $tmpdir/initrd.hacks
    gunzip -c $tmptargetisodir/boot/initrd.gz|cpio -i
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
