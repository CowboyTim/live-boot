#!/bin/bash

tmpscratchdir=/var/tmp
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
    targetinitrd="$tmpdir/initrd.gz"
    mkdir -p $tmpinitramfs/scripts
    cp $here/fastboot_by_tim $tmpinitramfs/scripts
    cat > $tmpinitramfs/initramfs.conf <<EOinitramfsconf
MODULES=list
BUSYBOX=y
BOOT=local
DEVICE=eth0
NFSROOT=auto
EOinitramfsconf
    mkinitramfs \
        -v \
        -d $tmpinitramfs \
        -o $targetinitrd \
        $kernelversion || exit 1

    mkdir -p $tmpdir/initrd.hacks
    (
        cd $tmpdir/initrd.hacks
        gunzip -c $targetinitrd|cpio -i
        echo "Hacks in initramfs"
    )
    mkdir -p $tmpdir/initrd.hacks/etc/udev/rules.d
    cp $here/60-persistent-storage.rules \
        $tmpdir/initrd.hacks/etc/udev/rules.d/60-persistent-storage.rules
    cp /sbin/losetup $tmpdir/initrd.hacks/sbin
    depmod  -b $tmpdir/initrd.hacks -a $kernelversion
    (
        cd $tmpdir/initrd.hacks
        dd if=/dev/zero of=./empty_ext2_fs bs=1M count=32
        mkfs.ext3 -O dir_index -F -F -L cow ./empty_ext2_fs
        tune2fs -c -1 -i -1 ./empty_ext2_fs
        gzip ./empty_ext2_fs
        find . |cpio -ov -H newc|gzip > $tmpdir/initrd-$distro-$kernelversion.gz
    )
    rm -rf $tmpdir/initrd.{tmp,hacks,gz}
}


kernelversion=$1
if [ -z $kernelversion ]; then
    if [ -e /boot/vmlinux ]; then
        kernelfile=/boot/vmlinux
    else
        echo "No valid kernel found"
        exit 1
    fi
    kernelversion=$(basename $(readlink $kernelfile)|sed "s#$(basename $kernelfile)-##")
fi

make_initramfs "timsps3" $kernelversion
