#!/bin/bash
rpath="$(readlink $BASH_SOURCE)"
if [ -z "$rpath" ];then
    rpath="$BASH_SOURCE"
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"

echo "installLibsodium()"
sodiumver=1.0.16
cd "$root"
if ! ls /usr/local/lib/libsodium* >/dev/null 2>&1;then
    cp libsodium-${sodiumver}.tar.gz /tmp
    cd /tmp
    tar xf libsodium-${sodiumver}.tar.gz && cd libsodium-${sodiumver}
    ./configure && make -j2 && sudo make install
    if [ "$(uname)" == "Linux" ];then
        sudo sh -c 'echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf'
        sudo ldconfig
        cmds=$(cat<<-EOF
        sh -c 'echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf'
        ldconfig
		EOF
)
        sudo sh -c "$cmds"
    fi
fi
