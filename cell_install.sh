#!/bin/bash

src=/media/cdrom/
sdkdir=/media/usb_disk/tim/data/sdk3.1/sdk3.1/CellSDK-Open-Fedora/ppc64
target=$(mktemp -d --tmpdir=/var/tmp)

echo "Will use $target"

# OpenCL on Cell/BE

cd $target
for r in $sdkdir/*ppc.rpm $src/opencl/*ppc.rpm; do
    echo $r
    fakeroot alien -k --to-deb $r
done

for r in $sdkdir/*ppc64.rpm $src/xlc/images-ppc/{runtime,rpms}/*ppc64.rpm; do
    echo $r
    d=$(rpm -qp --qf '%{SUMMARY}' $r 2>/dev/null)
    v=$(rpm -qp --qf '%{VERSION}' $r 2>/dev/null)
    n=$(rpm -qp --qf '%{NAME}' $r 2>/dev/null)
    echo $n,$v,$d
    fakeroot alien -k --scripts --to-tgz $r
    s=$n-$v.tgz
    t=$n-ppc64-$v.tgz
    echo "$s -> $t"
    mv $target/$s $target/$t
    fakeroot alien --description "$d" -k --to-deb $t --version $v
done


rm $target/*.tgz

echo "Please do:"
echo "dpkg -i $target/*.deb"
