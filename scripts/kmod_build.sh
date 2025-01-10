#! /bin/bash

apt-get update

apt-get install zlib1g-dev -y
apt-get install pkg-config -y
apt-get install build-essential liblzma-dev libzstd-dev -y

export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig


find /usr /bin /sbin -name "kmod" -o -name "depmod" -o -name "modprobe" -exec rm -f {} \;

mkdir ../download/

if [ -e ./kmod-29.tar.xz ]; then
	cp -a ./kmod-29.tar.xz ../download/
fi

cd ../download/
pwd
if [ ! -e ./kmod-29.tar.xz ]; then
	echo "get kmod source tar"
	wget --no-check-certificate  https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-29.tar.xz
fi

rm -rf kmod-29
tar -xf kmod-29.tar.xz
cd kmod-29/

./configure --prefix=/usr --with-zlib --with-xz  --with-zlib-include=/usr/include --with-zlib-lib=/usr/lib

make
make install

ldconfig




if [ -e /sbin/kmod  ]; then
	rm -rf /sbin/depmod
	ln -sf /sbin/kmod /sbin/depmod
fi

if [ -e /bin/kmod  ]; then
        rm -rf /sbin/depmod
        ln -sf /bin/kmod /sbin/depmod

fi


if [ -e /usr/bin/kmod  ]; then
        rm -rf /sbin/depmod
        ln -sf /usr/bin/kmod /sbin/depmod

fi


if [ -e /usr/sbin/kmod  ]; then
	rm -rf /sbin/depmod
        ln -sf /usr/sbin/kmod /sbin/depmod
fi

version_info=$(kmod --version)
echo -e "\033[33m[kmod] ${version_info} \033[0m"
version_info=$(depmod --version)
echo -e "\033[33m[depmod] ${version_info} \033[0m" 

