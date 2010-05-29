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
    tmptargetinitrd="$tmpdir/initrd.gz"
    targetinitrd=$tmpdir/initrd-$distro-$kernelversion.gz
    mkdir -p $tmpinitramfs/scripts
    cp $here/fastboot_by_tim $tmpinitramfs/scripts
    cat > $tmpinitramfs/initramfs.conf <<EOinitramfsconf
MODULES=list
BUSYBOX=y
BOOT=local
DEVICE=eth0
NFSROOT=auto
EOinitramfsconf
    cat > $tmpinitramfs/modules <<EOmodules
snd_pcm_oss
snd_mixer_oss
snd_pcm
snd_seq_dummy
snd_page_alloc
snd_seq_oss
snd_seq_midi
snd_rawmidi
snd_seq_midi_event
snd_seq
snd_timer
snd_seq_device
snd
soundcore
btusb
sg
sd_mod
sr_mod
aufs
squashfs
loop
binfmt_misc
evdev
snd_ps3
bluetooth
spufs
ps3flash
rtc_ps3
ps3_lpm
usbhid
hid
usb_storage
ps3_gelic
ps3stor_lib
ps3rom
ps3vram
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
    cp /sbin/losetup $tmpdir/initrd.hacks/sbin
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
}


kernelversion=$1
if [ -z $kernelversion ]; then
    kernelversion=$(uname -r)
fi

make_initramfs "timsps3" $kernelversion
