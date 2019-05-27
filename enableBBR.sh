#!/bin/bash
checkKernel(){
    major=$(uname -r | awk -F. '{print $1}')
    minor=$(uname -r | awk -F. '{print $2}')
    if (( $major ==4 && $minor >= 9 )) || (( $major > 4));then
        return 0
    fi
    return 1
}

enableBBR(){
    cat>/etc/sysctl.d/10-bbr.conf<<-EOF
		net.core.default_qdisc=fq
		net.ipv4.tcp_congestion_control=bbr
	EOF
    sysctl -p
}

checkBBR(){
    #check bbr
    sysctl net.ipv4.tcp_available_congestion_control
    sysctl net.ipv4.tcp_congestion_control
    lsmod | grep bbr
}

if checkKernel;then
    enableBBR
    checkBBR
else
    echo "Error: Linux Kernel must >= 4.9"
    exit 1
fi
