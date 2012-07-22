#!/bin/bash

sourcedirtmp="$1"
kernelversion="$2"
if [ -z $kernelversion ]; then
    kernelversion=$(uname -r)
fi

tmpscratchdir=/var/tmp
if [ -d /mnt/rootfs/var/tmp ]; then
    tmpscratchdir=/mnt/rootfs/var/tmp
fi
here=$(readlink -f -- "${0%/*}") 

export PATH=$PATH:/usr/sbin/:/sbin/

trap exit ERR
tmpdir=$(mktemp -d -p $tmpscratchdir initrd_XXXXXX)
echo "tempdir to use $tmpdir"
exec > >(tee $tmpdir/build.log)
exec 2>&1
mkdir -p $tmpdir

echo "Making a new initramfs in $tmpdir"
tmpinitramfs="$tmpdir/initrd.tmp"
targetinitrd=$tmpdir/initrd-$kernelversion.cpio
# general stuff
mkdir -p $tmpinitramfs/{sbin,lib/udev/rules.d}
(
    cd $sourcedirtmp;
    cp -a \
        ./usr/lib/klibc/bin/* \
        ./bin/busybox \
        ./sbin/blkid \
        ./sbin/udevd \
        ./sbin/udevadm \
        $tmpinitramfs/sbin/
    cp -a \
        ./lib/libc.so.6 \
        ./lib/ld-linux.so.3 \
        ./lib/libselinux.so.1 \
        ./lib/libm.so.6 \
        ./lib/libdl.so.2 \
        ./lib/libblkid.so.1 \
        ./lib/libuuid.so.1 \
        ./lib/libgcc_s.so.1 \
        $tmpinitramfs/lib/
    cp -a \
        ./lib/udev/{usb,scsi,path,edd,ata}_id \
        $tmpinitramfs/lib/udev/
    cp -a \
        ./lib/udev/rules.d/60-persistent-storage.rules \
        ./lib/udev/rules.d/50-udev-default.rules \
        ./lib/udev/rules.d/91-permissions.rules \
        $tmpinitramfs/lib/udev/rules.d/
        
)
#depmod  -b $tmpinitramfs -a $kernelversion

# my stuff + build
cp $here/fastboot $tmpinitramfs
cp $here/fastboot_init $tmpinitramfs/init
(
    cd $tmpinitramfs
    dd if=/dev/zero of=./empty_ext2_fs bs=1M count=32
    mkfs.ext2 -O dir_index -F -F -L cow ./empty_ext2_fs
    tune2fs -c -1 -i -1 ./empty_ext2_fs
    gzip -9 ./empty_ext2_fs
    find . |cpio -ov -H newc > $targetinitrd
)

cp $targetinitrd $tmpscratchdir/
echo "Created $tmpscratchdir/$(basename $targetinitrd)"
rm -rf $tmpdir
