#!/bin/bash

tmpscratchdir=/var/tmp
if [ -d /mnt/rootfs/var/tmp ]; then
    tmpscratchdir=/mnt/rootfs/var/tmp
fi
here=$(readlink -f -- "${0%/*}") 

trap exit ERR
tmpdir=$(mktemp -d -p $tmpscratchdir live_cd_build_XXXXXX)
echo "tempdir to use $tmpdir"
exec > >(tee $tmpdir/build.log)
exec 2>&1
mkdir -p $tmpdir

export PATH=$PATH:/usr/sbin/:/sbin/

make_initramfs(){
    distro="$1"
    kernelversion="$2"

    echo "Making a new initramfs in $tmpdir"
    tmpinitramfs="$tmpdir/initrd.tmp"
    tmptargetinitrd="$tmpdir/initrd.gz"
    targetinitrd=$tmpdir/initrd-$distro-$kernelversion.gz
    mkdir -p $tmpinitramfs/hooks
    cat > $tmpinitramfs/initramfs.conf <<EOinitramfsconf
MODULES=list
BUSYBOX=y
BOOT=local
DEVICE=eth0
NFSROOT=auto
EOinitramfsconf
    cat > $tmpinitramfs/modules <<EOmodules
sg
sd_mod
sr_mod
aufs
squashfs
loop
rtc_ps3
ps3_lpm
usbhid
hid
usb_storage
ps3stor_lib
ps3disk
EOmodules
    mkinitramfs \
        -v -k \
        -d $tmpinitramfs \
        -o $tmptargetinitrd \
        $kernelversion || exit 1

    mkdir -p $tmpdir/initrd.hacks
    (
        cd $tmpdir/initrd.hacks
        gunzip -c $tmptargetinitrd|cpio -i
        echo "Hacks in initramfs"
    )
    rm -rf $tmpdir/initrd.hacks/{init,conf/conf.d,conf/arch.conf,conf/initramfs.conf}
    rm -rf $tmpdir/initrd.hacks/scripts
    rm -rf $tmpdir/initrd.hacks/lib/udev/{ata_id,firmware,edd_id}
    rm -rf $tmpdir/initrd.hacks/lib/udev/rules/{64-device-mapper,50-firmware,80-drivers,61-persistent-storage-edd}.rules
    rm -rf $tmpdir/initrd.hacks/lib/libntfs-3g.so*
    rm -rf $tmpdir/initrd.hacks/lib/librt*
    rm -rf $tmpdir/initrd.hacks/lib/libext2fs*
    rm -rf $tmpdir/initrd.hacks/lib/libcom_err*
    rm -rf $tmpdir/initrd.hacks/lib/libpthread*
    rm -rf $tmpdir/initrd.hacks/lib/libe2p*
    rm -rf $tmpdir/initrd.hacks/lib/libfuse.so*
    rm -rf $tmpdir/initrd.hacks/lib/modules/$kernelversion/kernel/fs/fuse
    rm -rf $tmpdir/initrd.hacks/sbin/{hwclock,dumpe2fs,mount.{fuse,ntfs-3g,ntfs},depmod,rmmod,wait-for-root}
    rm -rf $tmpdir/initrd.hacks/etc/{console-setup,default,modprobe.d}
    rm -rf $tmpdir/initrd.hacks/bin/{cpio,resume,loadkeys,kbd_mode,setfont,poweroff,halt,nfsmount,date,ipconfig,ntfs-3g,sh,dmesg,dd,sleep,mount,insmod}
    cp $here/fastboot_by_tim $tmpdir/initrd.hacks/
    cp $here/fastboot_by_tim_init $tmpdir/initrd.hacks/init
    cp /usr/lib/klibc/bin/losetup $tmpdir/initrd.hacks/sbin
    depmod  -b $tmpdir/initrd.hacks -a $kernelversion
    (
        cd $tmpdir/initrd.hacks
        dd if=/dev/zero of=./empty_ext2_fs bs=1M count=32
        mkfs.ext3 -O dir_index -F -F -L cow ./empty_ext2_fs
        tune2fs -c -1 -i -1 ./empty_ext2_fs
        gzip -9 ./empty_ext2_fs
        find . |cpio -ov -H newc|gzip -9 > $targetinitrd
    )
    rm -rf $tmpdir/initrd.{tmp,hacks,gz}

    echo "Created $targetinitrd"
    cp $targetinitrd $tmpscratchdir/
    rm -rf $tmpdir
}


kernelversion=$1
if [ -z $kernelversion ]; then
    kernelversion=$(uname -r)
fi

make_initramfs "timsps3" $kernelversion
