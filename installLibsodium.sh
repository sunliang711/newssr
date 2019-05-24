#!/bin/bash
rpath="$(readlink $BASH_SOURCE)"
if [ -z "$rpath" ];then
    rpath="$BASH_SOURCE"
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"
user=${SUDO_USER:-(whoami)}

echo "installLibsodium()"

runAsRoot(){
    cmd="$@"
    if [ -z "$cmd" ];then
        echo "${red}Need cmd${reset}"
        exit 1
    fi

    if (($EUID==0));then
        eval "$cmd"
    else
        if ! command -v sudo >/dev/null 2>&1;then
            echo "Need sudo cmd"
            exit 1
        fi
        eval "sudo $cmd"
    fi
}

sodiumver=1.0.16
if ! ls /usr/local/lib/libsodium* >/dev/null 2>&1;then

    if command -v apt-get >/dev/null 2>&1;then
        runAsRoot apt-get install build-essential -y
    elif command -v yum >/dev/null 2>&1;then
        runAsRoot yum -y groupinstall "Development Tools"
    elif command -v pacman >/dev/null 2>&1;then
        runAsRoot pacman -S libsodium --noconfirm --needed
        exit 0
    fi
    cp libsodium-${sodiumver}.tar.gz /tmp
    cd /tmp
    tar xf libsodium-${sodiumver}.tar.gz && cd libsodium-${sodiumver}
    ./configure && make -j2 
    runAsRoot make install
    if [ "$(uname)" = "Linux" ];then
        cmds=$(cat<<-EOF
			sh -c 'echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf'
			ldconfig
		EOF
)
        runAsRoot sh -c "$cmds"
    fi
fi
