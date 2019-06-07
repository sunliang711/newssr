#!/bin/bash

rpath="$(readlink $BASH_SOURCE)"
if [ -z "$rpath" ];then
    rpath="$BASH_SOURCE"
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"

if ! command -v python >/dev/null 2>&1;then
    echo "Need python"
    exit 1
fi

bash installLibsodium.sh

if [ ! -d etc ];then
    mkdir etc
fi

if [ ! -d runtime ];then
    mkdir runtime
fi
sudo ln -sf $root/ssr.sh /usr/local/bin
