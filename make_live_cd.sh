#!/bin/bash

# apt-get install python-vm-builder



sourcecdrom="/media/cdrom"
version="intrepid"
architecture="amd64"
tmpscratchdir="/var/tmp"
isotarget="/home/tim/test_live_cd.iso"
isoname="TIMUBUNTU"
passwd="tubuntu"
#kernelversion=$(uname -r)
kernelversion='2.6.27-14-generic'
flash_10_file=~/libflashplayer-10.0.d21.1.linux-x86_64.so.tar.gz
if [ -z $user_id ]; then
    user_id=$(id -u)
    user_name=$(id -nu)
    export user_id user_name
fi
here=$(readlink -f -- "${0%/*}") 

trap exit ERR
if [ -z $1 ]; then
    tmpdir=$(mktemp -d -p $tmpscratchdir live_cd_build_XXXXXX)
else
    tmpdir=$1
fi
echo "tempdir to use $tmpdir"
exec > >(tee $tmpdir/build.log)
exec 2>&1
tmptargetsquashdir="$tmpdir/squashfs"
tmptargetisodir="$tmpdir/iso"
mkdir -p $tmptargetsquashdir
mkdir -p $tmptargetisodir

make_initramfs(){
    echo "Getting a kernel and an initrd"
    mkdir -p $tmptargetisodir/boot
    cp -f $tmptargetsquashdir/boot/vmlinuz-$kernelversion \
        $tmptargetisodir/boot/vmlinuz-$kernelversion-$isoname

    echo "Making a new initramfs in $tmptargetsquashdir"
    tmpinitramfs="$tmptargetsquashdir/tmp/initrd.tmp"
    targetinitrd="$tmptargetsquashdir/tmp/initrd.gz"
    rm -rf $tmpinitramfs
    mkdir -p $tmpinitramfs
    cat > $tmpinitramfs/initramfs.conf <<EOinitramfsconf
MODULES=most
BUSYBOX=y
BOOT=local
DEVICE=eth0
NFSROOT=auto
EOinitramfsconf
    mkdir -p $tmpinitramfs/scripts
    cp $here/fastboot_by_tim $tmpinitramfs/scripts
    chmod +x $tmptargetsquashdir/usr/share/initramfs-tools/init
    chroot $tmptargetsquashdir \
        mkinitramfs \
            -d /tmp/initrd.tmp  \
            -o /tmp/initrd.gz \
            $kernelversion || exit 1

    rm -rf $tmpdir/initrd.hacks
    mkdir -p $tmpdir/initrd.hacks
    (
        cd $tmpdir/initrd.hacks
        gunzip -c $targetinitrd|cpio -i
        echo "Hacks in initramfs"
        ln -s /lib lib64
    )
    cp $here/60-persistent-storage.rules \
        $tmpdir/initrd.hacks/etc/udev/rules.d/60-persistent-storage.rules
    cp $tmptargetsquashdir/sbin/losetup \
        $tmpdir/initrd.hacks/sbin
    cp -R $tmptargetsquashdir/lib/modules/$kernelversion/* \
        $tmpdir/initrd.hacks/lib/modules/$kernelversion
    depmod  -b $tmpdir/initrd.hacks -a $kernelversion
    (
        cd $tmpdir/initrd.hacks
        dd if=/dev/zero of=./empty_ext2_fs bs=1M count=512
        mkfs.ext3 -O dir_index -F -F -L cow ./empty_ext2_fs
        gzip ./empty_ext2_fs
        echo "Creating $tmptargetisodir/boot/initrd.gz"
        find . |cpio -ov -H newc|gzip > $tmptargetisodir/boot/$isoname-initrd.gz
    )
    rm -f $targetinitrd
}

make_iso() {
    echo "Making a syslinux/isolinux config in $tmptargetisodir"
    mkdir -p $tmptargetisodir/isolinux
    cp -f /usr/lib/syslinux/{isolinux.bin,vesamenu.c32,chain.c32} \
        $tmptargetisodir/isolinux
 
    append="boot=fastboot_by_tim root=LABEL=$isoname persistent initrd=/boot/$isoname-initrd.gz"

    cat > $tmptargetisodir/isolinux/isolinux.cfg <<EOisocfg
menu hshift 1
menu width 80
menu margin 3

menu title OleOla
menu color title    * #FFFFFFFF *
menu color border   * #00000000 #00000000 none
menu color sel      * #ffffffff #76a1d0ff *
menu color hotsel   1;7;37;40 #ffffffff #76a1d0ff *
menu color tabmsg   * #ffffffff #00000000 *
menu vshift 1
menu rows 10
menu tabmsgrow 16
menu timeoutrow 17
menu tabmsg Press ENTER to boot or TAB to edit a menu entry
label nothingpersistent
  menu label ^Tubuntu to ram + NOTHING persistent
  kernel /boot/vmlinuz-$kernelversion-$isoname
  append $append noquiet nosplash toram --
label allpersistent
  menu label ^Tubuntu to ram + persistent home + persistent root
  kernel /boot/vmlinuz-$kernelversion-$isoname
  append $append noquiet nosplash toram rootpersistent homepersistent --
label rootpersistent
  menu label ^Tubuntu to ram + persistent root, NOT persistent home
  kernel /boot/vmlinuz-$kernelversion-$isoname
  append $append noquiet nosplash toram rootpersistent --
label hd
  menu label ^Boot from first hard disk
  localboot 0x80

default vesamenu.c32
prompt 0
timeout 10
gfxboot bootlogo
EOisocfg

    echo "Making the iso from $tmptargetisodir to $isotarget"
    mkisofs \
        -V $isoname -o $isotarget \
        -iso-level 4 -no-emul-boot -boot-load-size 4 -boot-info-table \
        -b isolinux/isolinux.bin  \
        $tmptargetisodir
}

mount_vm_image (){
    echo "Mounting image $tmptargetsquashdir to $tmpdir/loop.raw"
    mount -o loop,offset=16384 $tmpdir/loop.raw $tmptargetsquashdir
}

make_squash (){

    tmptargetsquashfs="$tmpdir/core-$version-$architecture.squashfs"
    if [ -f $tmptargetsquashfs ]; then
        return
    fi

    cat >> $tmptargetsquashdir/etc/fstab <<EOfst
    /dev/shm	/tmp	tmpfs rw,exec,noatime,nodiratime	0	0
EOfst

    echo "Running depmod for squashfs"
    depmod -b $tmptargetsquashdir $kernelversion -a

    echo "Creating squashfs file $tmptargetsquashfs"
    rm -rf $tmptargetsquashdir/tmp
    rm -rf $tmptargetsquashdir/boot/*
    rm -f $tmptargetsquashdir/{vmlinuz,initrd.img,cdrom,dev,proc}
    rm -rf $tmptargetsquashdir/var/cache/apt/archives

    mkdir -p $tmptargetsquashdir/{proc,dev,tmp}
    mksquashfs $tmptargetsquashdir $tmptargetsquashfs  \
        -noappend \
        -always-use-fragments 

    mkdir -p $tmptargetisodir/modules
    cp -f $tmptargetsquashfs $tmptargetisodir/modules
}

various_hacks (){
    user_id=$(id -u)
    user_name=$(id -nu)
    if [ $user_id == '0' ]; then
        user_name=$passwd
        user_id=500
    fi
    my_crypt_p=$(openssl passwd -crypt -salt xx '')
    chroot $tmptargetsquashdir useradd -m -s /bin/bash \
        --uid $user_id -G admin,audio -p $passwd $user_name || exit 1
    chroot $tmptargetsquashdir passwd -d root || exit 1

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

}

if [ -z $1 ]; then
    echo "Making vmw6 image $version ($architecture) in $tmpdir/vmimage"
    vmbuilder vmw6 ubuntu \
        --suite $version \
        --flavour generic \
        --arch $architecture \
        -d $tmpdir/vmimage

    echo "Convert to something loop-mountable with qemu"
    qemu-img convert -f vmdk $tmpdir/vmimage/disk0.vmdk -O raw $tmpdir/loop.raw
fi

mount_vm_image
make_initramfs 
various_hacks
make_squash
make_iso 

umount $tmptargetsquashdir
