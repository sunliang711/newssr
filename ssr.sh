#!/bin/bash

rpath="$(readlink $BASH_SOURCE)"
if [ -z "$rpath" ];then
    rpath="$BASH_SOURCE"
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"
user=${SUDO_USER:-$(whoami)}
home=$(eval echo ~$user)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 5)
reset=$(tput sgr0)
runAsRoot(){
    cmd="$@"
    if [ -z "$cmd" ];then
        echo "${red}Need cmd${reset}"
        exit 1
    fi

    if (($EUID==0));then
        sh -c "$cmd"
    else
        if ! command -v sudo >/dev/null 2>&1;then
            echo "Need sudo cmd"
            exit 1
        fi
        sudo sh -c "$cmd"
    fi
}

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
     local name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo
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
             echo "Issus tail -f /tmp/${name%.json}.log to check log"
             ;;
         Linux)
             runAsRoot systemctl start ${name%.json}
             echo "Issus journalctl -u ${name%.json} to check log"
             ;;
     esac
     #only check client service
     if echo "$name" | grep -q "^C";then
        localPort="$(perl -ne 'print $2 if /(\"local_port\"\s*:\s*)(\d+)/' etc/${name%.json}.json)"
        # checkPort "$localPort"
        if ps aux | grep 'python' | grep -q "${name%.json}.json" ;then
            printf "%-20s %s " "${name%.json}.json" "${green}working on ${localPort}${reset}"
            checkPort $localPort || printf "\n"
        else
            printf "%-20s %s\n" "${name%.json}.json" "${blue}stopped on ${localPort}${reset}"
        fi
     fi
 }

 checkPort(){
     port=${1:?'missing port'}
     echo -n "${yellow}Check Proxy ... "
     sleep 1
     if curl -m 5 -x socks5://localhost:$port ifconfig.me >/dev/null 2>&1;then
            echo "${green}[OK]${reset}"
        else
            echo "${blue}[Failed]${reset}"
     fi
 }

 stop(){
     local name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo
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
         echo "No such config file: \"${red}${name%.json}.json${reset}\" in $root/etc"
         echo
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
                runAsRoot systemctl stop "${name%.json}"
             fi
             ;;
     esac
 }

 restart(){
     local name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo
        echo "Available file(s):"
        list
        exit 1
     fi
     stop $name
     start $name
 }

 status(){
     local name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo
        echo "Available file(s):"
        list
        exit 1
     fi
     if [ ! -e "etc/${name%.json}.json" ];then
         echo "No such config file: \"${red}${name%.json}.json${reset}\" in $root/etc"
         echo
         echo "Available config file(s):"
         list
         exit 1
     fi
     case $(uname) in
         Darwin)
             launchctl list | grep ${name%.json}
             ;;
         Linux)
             runAsRoot systemctl status ${name%.json}
             ;;
     esac

 }

log(){
    local name=${1}
    if [ -z "$name" ];then
       echo "Missing config file."
       echo
       echo "Available file(s):"
       list
       exit 1
    fi
    if [ ! -e "etc/${name%.json}.json" ];then
        echo "No such config file: \"${red}${name%.json}.json${reset}\" in $root/etc"
        echo
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
     local name=${1}
     if [ -z "$name" ];then
        echo "Missing config file."
        echo
        echo "Available file(s):"
        list
        exit 1
     fi
     if [ ! -e "etc/${name%.json}.json" ];then
         echo "No such config file: \"${red}${name%.json}.json${reset}\" in $root/etc"
         echo
         echo "Available config file(s):"
         list
         exit 1
     fi

     editor=vi
     if command -v vim >/dev/null 2>&1;then
         editor=vim
     fi
     configFile="etc/${name%.json}.json"
     oldmd5sum="$(python md5.py ${configFile})"
     # sha1sum "${configFile}" > "${configFile}.sha1"
     $editor "${configFile}"
     newmd5sum="$(python md5.py ${configFile})"
     # if ! sha1sum -c --status "${configFile}.sha1";then
     if [ "$oldmd5sum" != "$newmd5sum" ];then
         if ps aux | grep 'python' | grep -q "${name%.json}.json";then
             echo "${green}Config file: \"$configFile\" changed."
             echo "Restart service..."
             stop "$name"
             start "$name"
         fi
    else
        echo "${cyan}Config file not changed, do nothing."
     fi
     # rm "${configFile}.sha1"
 }

add(){
     local name=${1:?'missing new config name'}
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
     echo "config file is: ${red}$name${reset}"

     cp template/${typ}.json etc/$name

    if [ "$typ" = "server" ] && [ "$uname" = "Linux" ];then
        echo "Enable bbr? [y/N]" bbr
        if [[ "$bbr" =~ [yY] ]];then
            bash enableBBR.sh
        fi
    fi
    echo "Config $name? [y/N]"
    read edit
    if [[ "$edit" =~ [yY] ]];then
        config $name
    fi
 }

delete(){
    local name=${1}
    if [ -z "$name" ];then
       echo "Missing config file."
       echo
       echo "Available file(s):"
       list
       exit 1
    fi
    if [ ! -e "etc/${name%.json}.json" ];then
        echo "No such config file: \"${red}${name%.json}.json${reset}\" in $root/etc"
        echo
        echo "Available config file(s):"
        list
        exit 1
    fi
    stop $name

    rm etc/${name%.json}.json
    rm etc/${name%.json}.json.md5 2>/dev/null
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
LSOF(){
    case $(uname) in
        Linux)
            if (($EUID!=0));then
                sudo lsof "$@"
            else
                lsof "$@"
            fi
            ;;
        Darwin)
            lsof "$@"
            ;;
    esac
}

list(){
    check=${1}
    cd etc
    if ls *.json >/dev/null 2>&1;then
        for i in *.json;do
            if echo $i | grep -q '^C';then
                localPort="$(perl -ne 'print $2 if /(\"local_port\"\s*:\s*)(\d+)/' $i)"
                if ps aux | grep "$i" | grep -q 'python';then
                    printf "%-20s %s " "$i" "${green}working on ${localPort}${reset}"
                    [ -n "$check" ] && checkPort $localPort || printf "\n"
                else
                    printf "%-20s %s\n" "$i" "${blue}stopped on ${localPort}${reset}"
                fi
                # if LSOF -iTCP -sTCP:LISTEN -P | grep -q "\<${localPort}\>";then
                #     printf "%-20s %s  " "$i" "${green}working on ${localPort}${reset}"
                    # [ -n "$check" ] && checkPort $localPort || printf "\n"
                # else
                #     printf "%-20s %s\n" "$i" "${blue}stopped on ${localPort}${reset}"
                # fi
            else
                python $root/getServerPort.py "$i"
                for port in $(cat "${i}.ports");do
                    if LSOF -iTCP -sTCP:LISTEN -P | grep -q "\<${port}\>";then
                        printf "%-20s %s\n" "$i" "${green}working on ${port}${reset}"
                    else
                        printf "%-20s %s\n" "$i" "${blue}stopped on ${port}${reset}"
                    fi
                done
                rm "${i}.ports" 2>/dev/null
            fi
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
    em)
        em
        ;;
    list)
        list check
        ;;
    addServer)
        add "$1" server
        ;;
    *)
        usage
        ;;
esac
