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

if ! command -v sha1sum >/dev/null 2>&1;then
    echo "Install sha1sum with \"brew install md5sha1sum\" on MacOS."
fi
