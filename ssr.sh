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

usage(){
     cat<<-EOF
	Usage: $(basename $0) cmd

	cmd:
	    start       <config file>
	    stop        <config file>
	    restart     <config file>
	    status      <config file>
	    log         <config file>
	    config      <config file>
	    add         <new config name>
	    delete      <config file>
	    addServer   <new config name>
	    em
	EOF
 }

start(){
     name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo "Available file(s):"
        list
        exit 1
     fi
     if echo $name | grep -q '^S';then
         typ=server
     elif echo $name | grep -q "^C";then
         typ=client
     else
         echo 'config file name must begin with S or C!'
         exit 1
     fi
     #TODO check config file 'server' 'port' 'password' ... fields
     bash createService.sh "$name" $typ || { exit 1; }

     case $(uname) in
         Darwin)
             launchctl load -w "$home/Library/LaunchAgents/${name%.json}.plist"
             ;;
         Linux)
             systemctl start ${name%.json}
             ;;
     esac
 }

 stop(){
     name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo "Available file(s):"
        list
        exit 1
     fi
     if echo $name | grep -q '^S';then
         typ=server
     elif echo $name | grep -q "^C";then
         typ=client
     else
         echo 'config file name must begin with S or C!'
         exit 1
     fi
     if [ ! -e "etc/${name%.json}.json" ];then
         echo "No such config file: \"${RED}${name%.json}.json${RESET}\" in $root/etc"
         echo "Available config file(s):"
         list
         exit 1
     fi
     case $(uname) in
         Darwin)
             plistFile="$home/Library/LaunchAgents/${name%.json}.plist"
             if [ -e "$plistFile" ];then
                 launchctl unload -w "$plistFile"
             fi
             ;;
         Linux)
             serviceFile="/etc/systemd/system/${name%.json}.service"
             if [ -e "$serviceFile" ];then
                 systemctl stop "${name%.json}"
             fi
             ;;
     esac
 }

 restart(){
     name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo "Available file(s):"
        list
        exit 1
     fi
     stop $name
     start $name
 }

 status(){
     name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo "Available file(s):"
        list
        exit 1
     fi
     if [ ! -e "etc/${name%.json}.json" ];then
         echo "No such config file: \"${RED}${name%.json}.json${RESET}\" in $root/etc"
         echo "Available config file(s):"
         list
         exit 1
     fi
     case $(uname) in
         Darwin)
             launchctl list | grep ${name%.json}
             ;;
         Linux)
             systemctl status ${name%.json}
             ;;
     esac

 }

log(){
    name=${1}
    if [ -z "$name" ];then
       echo "Missing config file."
       echo "Available file(s):"
       list
       exit 1
    fi
    if [ ! -e "etc/${name%.json}.json" ];then
        echo "No such config file: \"${RED}${name%.json}.json${RESET}\" in $root/etc"
        echo "Available config file(s):"
        list
        exit 1
    fi
    case $(uname) in
        Darwin)
            tail -f /tmp/${name%.json}.log
            ;;
        Linux)
            #TODO
            ;;
    esac


}

config(){
     name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo "Available file(s):"
        list
        exit 1
     fi
     if [ ! -e "etc/${name%.json}.json" ];then
         echo "No such config file: \"${RED}${name%.json}.json${RESET}\" in $root/etc"
         echo "Available config file(s):"
         list
         exit 1
     fi

     editor=vi
     if command -v vim >/dev/null 2>&1;then
         editor=vim
     fi
     $editor etc/${name%.json}.json
 }

add(){
     name=${1:?'missing new config name'}
     typ=${2:-'client'}
     case $typ in
         client)
             name="C${name%.json}.json"
             ;;
         server)
             name="S${name%.json}.json"
             ;;
         *)
             echo "Type error,available type: client or server"
             exit 1
             ;;
     esac
     if [ -e "etc/${name}" ];then
         echo "Config file: ${name} already exists"
         exit 1
     fi
     echo "config file is: ${RED}$name${RESET}"

     cp template/${typ}.json etc/$name

    if [ "$typ" = "server" ] && [ "$uname" = "Linux" ];then
        echo "Enable bbr? [y/N]" bbr
        if [[ "$bbr" =~ [yY] ]];then
            bash enableBBR.sh
        fi
    fi
 }

delete(){
    name=${1}
    if [ -z "$name" ];then
       echo "Missing config file."
       echo "Available file(s):"
       list
       exit 1
    fi
    if [ ! -e "etc/${name%.json}.json" ];then
        echo "No such config file: \"${RED}${name%.json}.json${RESET}\" in $root/etc"
        echo "Available config file(s):"
        list
        exit 1
    fi
    stop $name

    rm etc/${name%.json}.json
    rm $home/Library/LaunchAgents/${name%.json}.plist 2>/dev/null
    rm runtime/${name%.json}.plist 2>/dev/null
    rm /etc/systemd/system/${name%.json}.service 2>/dev/null
    rm runtime/${name%.json}.service 2>/dev/null
}

em(){
    editor=vi
    if command -v vim >/dev/null 2>&1;then
        editor=vim
    fi
    $editor $rpath
}

list(){
    cd etc
    if ls *.json >/dev/null 2>&1;then
        for i in *.json;do
            echo $i
        done
    fi
}

cmd=$1
shift

case  $cmd in
    start)
        start "$@"
        ;;
    stop)
        stop "$@"
        ;;
    restart)
        restart "$@"
        ;;
    status)
        status "$@"
        ;;
    log)
        log "$@"
        ;;
    config)
        config "$@"
        ;;
    add)
        add "$1" client
        ;;
    del|delete|rm|remove)
        delete "$@"
        ;;
    addServer)
        addServer "$@"
        ;;
    em)
        em
        ;;
    list)
        list
        ;;
    addServer)
        add "$1" server
        ;;
    *)
        usage
        ;;
esac
