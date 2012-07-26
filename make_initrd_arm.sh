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
targetinitrd=$tmpscratchdir/initrd-$kernelversion.cpio
# general stuff
mkdir -p $tmpdir/{sbin,lib/udev/rules.d}
(
    cd $sourcedirtmp;
    cp -a \
        ./usr/lib/klibc/bin/* \
        ./bin/busybox \
        ./sbin/blkid \
        ./sbin/udevd \
        ./sbin/udevadm \
        ./sbin/{lsmod,rmmod,modprobe} \
        $tmpdir/sbin/
    cp -a \
        ./lib/libc.so.6 \
        ./lib/ld-linux.so.3 \
        ./lib/libselinux.so.1 \
        ./lib/libm.so.6 \
        ./lib/libdl.so.2 \
        ./lib/libblkid.so.1 \
        ./lib/libuuid.so.1 \
        ./lib/libgcc_s.so.1 \
        $tmpdir/lib/
    cp -a \
        ./lib/udev/{usb,scsi,path,edd,ata}_id \
        $tmpdir/lib/udev/
    cp -a \
        ./lib/udev/rules.d/60-persistent-storage.rules \
        ./lib/udev/rules.d/50-udev-default.rules \
        ./lib/udev/rules.d/91-permissions.rules \
        $tmpdir/lib/udev/rules.d/
    ln -s ./sbin $tmpdir/bin
)
#depmod  -b $tmpdir -a $kernelversion

# my stuff + build
cp $here/fastboot $tmpdir
cp $here/fastboot_init $tmpdir/init
(
    cd $tmpdir
    dd if=/dev/zero of=./empty_ext2_fs bs=1M count=32
    mkfs.ext2 -O dir_index -F -F -L cow ./empty_ext2_fs
    tune2fs -c -1 -i -1 ./empty_ext2_fs
    gzip -9 ./empty_ext2_fs
    find . |cpio -ov -H newc > $targetinitrd
)

echo "Created $targetinitrd $tmpdir"
