#!/bin/bash

rpath="$(readlink $BASH_SOURCE)"
if [ -z "$rpath" ];then
    rpath="$BASH_SOURCE"
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"

bash installLibsodium.sh

if [ ! -d etc ];then
    mkdir etc
fi

if [ ! -d runtime ];then
    mkdir runtime
fi
sudo ln -sf $root/ssr.sh /usr/local/bin
