#!/bin/bash
if (($EUID!=0));then
    echo "Need run as root."
    exit 1
fi
user=${SUDO_USER:-(whoami)}
if ! ls /usr/local/lib/libsodium* >/dev/null 2>&1;then
    if command -v apt-get >/dev/null 2>&1;then
        apt-get install build-essential -y
        cd /tmp
        wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
        tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
        ./configure && make -j2 && make install
        ldconfig
        rm -rf /tmp/libsodium-1.0.16
    elif command -v yum >/dev/null 2>&1;then
        yum -y groupinstall "Development Tools"
        cd /tmp
        wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
        tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
        ./configure && make -j2 && make install
        echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
        ldconfig
        rm -rf /tmp/libsodium-1.0.16
    elif command -v pacman >/dev/null 2>&1;then
        pacman -S libsodium --noconfirm
    fi
fi
