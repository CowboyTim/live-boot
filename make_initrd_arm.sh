#!/bin/bash

squashfile="$1"
moddir="$2"

tmpscratchdir=/var/tmp
if [ -d /mnt/rootfs/var/tmp ]; then
    tmpscratchdir=/mnt/rootfs/var/tmp
fi
here=$(readlink -f -- "${0%/*}") 

export PATH=$PATH:/usr/sbin/:/sbin/

trap exit ERR
tmpdir=$(mktemp -d -p $tmpscratchdir initrd_XXXXXX)
echo "tempdir to use $tmpdir"
mkdir -p $tmpdir

echo "unsquashfs busybox stuff to $tmpdir"
unsquashfs -i -f -d $tmpdir $squashfile \
    /usr/lib/klibc/bin \
    /bin/busybox \
    /bin/mount \
    /sbin/blkid \
    /sbin/udevd \
    /sbin/udevadm \
    /sbin/mkfs.ext{2,3,4} \
    /sbin/mkfs.vfat \
    /sbin/mkdosfs \
    /sbin/fsck.vfat \
    /sbin/dosfsck \
    /sbin/fdisk \
    /sbin/{lsmod,rmmod,insmod,modprobe} \
    /bin/{lsmod,rmmod,kmod} \
    /lib/klibc-*.so \
    /lib/libselinux.so.1 \
    /lib/libsepol.so.1 \
    /lib/libext2fs.so.2 \
    /lib/libext2fs.so.2.4 \
    /lib/libcom_err.so.2 \
    /lib/libcom_err.so.2.1 \
    /lib/libpthread.so.0 \
    /lib/libpthread-2.11.3.so \
    /lib/libe2p.so.2 \
    /lib/libe2p.so.2.3 \
    /lib/libc.so.6 \
    /lib/libc-*.so \
    /lib/ld-linux.so.3 \
    /lib/ld-*.so \
    /lib/libselinux.so.1 \
    /lib/libm.so.6 \
    /lib/libm-*.so \
    /lib/libdl*.so* \
    /lib/libblkid.so.1* \
    /lib/libuuid.so.* \
    /lib/libgcc_s.so.1 \
    /lib/udev/{usb,scsi,path,edd,ata}_id \
    /lib/udev/rules.d/60-persistent-storage.rules \
    /lib/udev/rules.d/50-udev-default.rules \
    /lib/udev/rules.d/91-permissions.rules \
    || exit 1

echo "taking the kernel modules from $moddir"
mkdir -p $tmpdir/lib/modules/
kernelversion=$(basename $(ls $moddir/lib/modules/))
cp -a $moddir/lib/modules/* $tmpdir/lib/modules
depmod  -b $tmpdir -a $kernelversion

echo "making modules list"
mkdir $tmpdir/conf
cat >> $tmpdir/conf/modules <<EOconfmodules
aufs
xhci-hcd
ehci-hcd
uhci-hcd
ohci-hcd
libata
sg
scsi_mod
sd_mod
sr_mod
squashfs
loop
usbhid
hid
usb_storage
vfat
ext2
ext3
romfs
sdio_uart
sdhci
ushc
mmci
mmc_block
EOconfmodules

echo "copying fastboot and fastboot_init"
cp $here/fastboot $tmpdir/
cp $here/fastboot_init $tmpdir/init

echo "making the cpio"
targetinitrd=$tmpscratchdir/initrd-$kernelversion.cpio.gz
(
    cd $tmpdir
    #dd if=/dev/zero of=./empty_ext2_fs bs=1M count=32
    #mkfs.ext2 -O dir_index -F -F -L cow ./empty_ext2_fs
    #tune2fs -c -1 -i -1 ./empty_ext2_fs
    #gzip -9 ./empty_ext2_fs
    find . |cpio -ov -H newc|gzip -c -9 > $targetinitrd
)

echo "created $targetinitrd $tmpdir"
