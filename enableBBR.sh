#!/bin/bash
checkKernel(){
    major=$(uname -r | awk -F. '{print $1}')
    minor=$(uname -r | awk -F. '{print $2}')
    if (( $major >=4 && $minor >= 9 ));then
        return 0
    fi
    return 1
}

installKernel(){
echo NOthing
}

enableBBR(){
    #echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    #echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    cat>/etc/sysctl.d/10-bbr.conf<<EOF
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

if ! checkKernel;then
    installKernel
fi

if checkKernel;then
    enableBBR
    checkBBR
fi
