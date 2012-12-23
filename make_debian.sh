#!/bin/bash

# apt-get install fakeroot fakechroot qemu binfmt-support qemu-user \
#    qemu-user-static xz-utils squashfs-tools debootstrap

timezone_area="Europe"
timezone_city="Brussels"
username="tim"
password="xxx"
wireless_essid=""
wireless_psk=""
hostname="wihiie"
compresswith="xz"
what="ps3"
arch="armel"
baseurl="http://ftp.be.debian.org/"
debootstrapurl="file:///media/cdrom"

tmp=/var/tmp
datestr=`date +%s`
tmpdir=$tmp/squeeze.$datestr
srcloc=$(readlink -f -- "${0%/*}") 

echo "Using $tmpdir"
export LANG=C

renice -n +20 -p $$

qemu-debootstrap --arch=$arch squeeze --no-check-gpg $tmpdir $debootstrapurl/debian

cp $srcloc/install_packages.sh $tmpdir/
mkdir -p $tmpdir/media/cdrom
mount --bind /media/cdrom $tmpdir/media/cdrom
chroot $tmpdir /bin/bash ./install_packages.sh $debootstrapurl $timezone_area $timezone_city || exit 1
umount $tmpdir/media/cdrom
rm $tmpdir/install_packages.sh

cp -a $srcloc/$what/package/etc/{skel,sysctl.d,init.d,X11,udev,kboot.*} $tmpdir/etc/
chroot $tmpdir /bin/bash <<EOpost
userdel tim
useradd tim -g users -s /bin/bash -m -u 1000 -G video,audio,fuse,adm,cdrom,sudo,bluetooth -f -1
passwd -e tim <<Eop
$password
$password
Eop
cat >/etc/default/wm <<Eou
WM_USER=$username
Eou
update-rc.d wm defaults
EOpost

cat > $tmpdir/etc/timezone <<EOtz
$timezone_area/$timezone_city
EOtz

cat >> $tmpdir/etc/network/interfaces <<EOnetwork
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
    metric 50

auto wlan0
iface wlan0 inet dhcp
wpa-ssid $wireless_essid
wpa-psk $wireless_psk
wpa-ap-scan 1
wpa-scan-ssid 1
wpa-key-mgmt WPA-PSK
wpa-pairwise TKIP CCMP
wpa-group TKIP
wpa-proto RSN
EOnetwork

wpa_passphrase "$wireless_essid" "$wireless_psk" >> $tmpdir/etc/wpa_supplicant.conf

cat >> $tmpdir/etc/hosts <<EOhosts
127.0.1.1     $hostname
EOhosts

cat >> $tmpdir/etc/inittab <<EOinittab
# sgs2
T0:1235:respawn:/sbin/getty -L ttyGS0 115200 vt100
EOinittab

cat > $tmpdir/etc/hostname <<EOhosts
$hostname
EOhosts

rm $tmpdir/usr/sbin/policy-rc.d

mkdir -p $tmpdir/cgroup

if [ -e $srcloc/$what/post.sh ]; then
    . $srcloc/$what/post.sh
fi

umount -l $tmpdir/{proc,sys}

if [ ! -z "$compresswith" ]; then
(
    cd $tmpdir
    tar cvf - * --exclude={dev,proc,sys,tmp}/* \
        |$compresswith > $tmp/$(basename $tmpdir).tar.$compresswith
)
fi

fn=$tmp/$(basename $tmpdir).squashfs.$compresswith
time nice -n 20 mksquashfs \
    $tmpdir/* \
    $fn \
    -comp $compresswith \
    -e $tmpdir/{dev,proc,sys,tmp,var/run,var/lock,var/tmp}/*

echo
echo $fn
