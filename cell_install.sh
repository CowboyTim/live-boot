#!/bin/bash

src=/media/cdrom/
target=$(mktemp -d)

echo "Will use $target"

# OpenCL on Cell/BE

cd $target
for r in $src/opencl/*ppc.rpm; do
    echo $r
    fakeroot alien -k --to-deb $r
done

for r in $src/xlc/images-ppc/{runtime,rpms}/*ppc64.rpm; do
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
