#!/bin/bash

baseurl=$1
timezone_area="$2"
timezone_city="$3"

mount proc /proc -t proc
mount sysfs /sys -t sysfs

cat >> /usr/sbin/policy-rc.d <<EOh
exit 101
EOh
chmod +x /usr/sbin/policy-rc.d
cat >> /etc/apt/sources.list.d/extra.list <<Eol
deb $baseurl/debian squeeze main contrib non-free
#deb http://security.debian.org/ squeeze/updates main contrib non-free
#deb-src http://security.debian.org/ squeeze/updates main contrib non-free
Eol
cat > /etc/apt/sources.list <<Eoe
Eoe

gpg --keyserver keyserver.ubuntu.com --recv-key ABF5BD827BD9BF62

apt-get update
aptitude -y --allow-untrusted install desktop
apt-get clean
apt-get autoclean
