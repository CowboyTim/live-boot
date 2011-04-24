chroot $tmpdir /bin/bash <<EOinstall
apt-get -y --force-yes install \
    gcc-4.4-spu \
    gcc-spu \
    spu-tools \
    ps3-utils \
    lib64gcc1
apt-get -y --force-yes remove \
    yaboot powerpc-utils powerpc-ibm-utils mac-fdisk
chmod +s /usr/sbin/ps3-flash-util /sbin/reboot /sbin/shutdown

cat >> ./etc/network/interfaces <<EOwifi
# WiFi om the PS3
auto wlan0
iface wlan0 inet dhcp
    wireless-essid $wireless_essid
EOwifi
EOinstall
