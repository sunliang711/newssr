#!/bin/bash

rpath="$(readlink $BASH_SOURCE)"
if [ -z "$rpath" ];then
    rpath="$BASH_SOURCE"
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"
user=${SUDO_USER:-$(whoami)}
home=$(eval echo ~$user)
RED=$(tput setaf 1)
RESET=$(tput sgr 0)

name=${1:?'missing config file'}
typ=${2:?'missing type (client or server)'}

name="${name%.json}.json"


#check if config file exists
if [ ! -e etc/$name ];then
    echo "No such config file: \"${RED}$name${RESET}\" in $root/etc"
    exit 1
fi

#check if md5 file exists
if [ ! -e etc/${name}.md5 ];then
    echo "No ${name}.md5 file,create it..."
    python md5.py etc/${name} > etc/${name}.md5
else
    oldMd5="$(cat etc/${name}.md5)"
    newMd5="$(python md5.py etc/${name})"
    if [ "$oldMd5" != "$newMd5" ];then
        echo "Config file ${name} changed."
        python md5.py etc/${name} > etc/${name}.md5
    else
        echo "Config file not change.Don't need to create service file."
        exit 0
    fi
fi

case $typ in
    client)
        exe=local
        ;;
    server)
        exe=server
        ;;
    *)
        echo "Type error,available type: client, server"
        exit 1
esac

case $(uname) in
    Darwin)
        sed -e "s|NAME|${name%.json}|g" -e "s|ROOT|$root|g" \
            -e "s|EXE|$exe|g" -e "s|CONFIG|$name|g" \
            -e "s|PYTHON|$(which python)|g" \
            template/ssr.plist > runtime/${name%.json}.plist
        ln -sf "$root/runtime/${name%.json}.plist" $home/Library/LaunchAgents
        ;;
    Linux)
        sed -e "s|NAME|${name%.json}|g" -e "s|ROOT|$root|g" \
            -e "s|EXE|$exe|g" -e "s|CONFIG|$name|g" \
            -e "s|PYTHON|$(which python)|g" \
            template/ssr.service > runtime/${name%.json}.service
        sudo ln -sf "$root/runtime/${name%.json}.service" /etc/systemd/system
        sudo systemctl daemon-reload
        sudo systemctl enable ${name%.json}
        ;;
esac
