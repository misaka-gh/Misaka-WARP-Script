#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN='\033[0m'

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

# 判断系统及定义系统安装依赖方式
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ $EUID -ne 0 ]] && red "Note: Please run the script under the root user" && exit 1

archAffix(){
    case "$(uname -m)" in
        i686 | i386 ) echo '386' ;;
        x86_64 | amd64 ) echo 'amd64' ;;
        armv5tel ) echo 'armv5' ;;
        armv6l ) echo 'armv6' ;;
        armv7 | armv7l ) echo 'armv7' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        s390x ) echo 's390x' ;;
        * ) red "Unsupported CPU architectures!" && exit 1 ;;
    esac
}

check_status(){
    yellow "Checking the VPS system configuration environment, please wait..."
    if [[ -z $(type -P curl) ]]; then
        yellow "Detecting curl not installed, in the process of installation..."
        if [[ ! $SYSTEM == "CentOS" ]]; then
            ${PACKAGE_UPDATE[int]}
        fi
        ${PACKAGE_INSTALL[int]} curl
    fi
    
    IPv4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    IPv6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    Browser_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
    
    if [[ $IPv4Status =~ "on"|"plus" ]] || [[ $IPv6Status =~ "on"|"plus" ]]; then
        # 关闭Wgcf-WARP，以防识别有误
        wg-quick down wgcf >/dev/null 2>&1
        v66=`curl -s6m8 https://ip.gs -k`
        v44=`curl -s4m8 https://ip.gs -k`
        wg-quick up wgcf >/dev/null 2>&1
    else
        v66=`curl -s6m8 https://ip.gs -k`
        v44=`curl -s4m8 https://ip.gs -k`
    fi
    
    [[ $IPv4Status == "off" ]] && w4="${RED}WARP is not enabled${PLAIN}"
    [[ $IPv6Status == "off" ]] && w6="${RED}WARP is not enabled${PLAIN}"
    [[ $IPv4Status == "on" ]] && w4="${YELLOW}WARP Free Account${PLAIN}"
    [[ $IPv6Status == "on" ]] && w6="${YELLOW}WARP Free Account${PLAIN}"
    [[ $IPv4Status == "plus" ]] && w4="${GREEN}WARP+ / Teams${PLAIN}"
    [[ $IPv6Status == "plus" ]] && w6="${GREEN}WARP+ / Teams${PLAIN}"
    
    # VPSIP变量说明：0为纯IPv6 VPS、1为纯IPv4 VPS、2为原生双栈VPS
    [[ -n $v66 ]] && [[ -z $v44 ]] && VPSIP=0
    [[ -z $v66 ]] && [[ -n $v44 ]] && VPSIP=1
    [[ -n $v66 ]] && [[ -n $v44 ]] && VPSIP=2
    
    v4=$(curl -s4m8 https://ip.gs -k)
    v6=$(curl -s6m8 https://ip.gs -k)
    c4=$(curl -s4m8 https://ip.gs/country -k)
    c6=$(curl -s6m8 https://ip.gs/country -k)
    n4=$(curl -4 --user-agent "${Browser_UA}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
    n6=$(curl -6 --user-agent "${Browser_UA}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
    s5p=$(warp-cli --accept-tos settings 2>/dev/null | grep 'WarpProxy on port' | awk -F "port " '{print $2}')
    w5p=$(grep BindAddress /etc/wireguard/proxy.conf 2>/dev/null | sed "s/BindAddress = 127.0.0.1://g")
    if [[ -n $s5p ]]; then
        s5s=$(curl -sx socks5h://localhost:$s5p https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
        s5i=$(curl -sx socks5h://localhost:$s5p https://ip.gs -k --connect-timeout 8)
        s5c=$(curl -sx socks5h://localhost:$s5p https://ip.gs/country -k --connect-timeout 8)
        s5n=$(curl -sx socks5h://localhost:$s5p -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
    fi
    if [[ -n $w5p ]]; then
        w5s=$(curl -sx socks5h://localhost:$w5p https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
        w5i=$(curl -sx socks5h://localhost:$w5p https://ip.gs -k --connect-timeout 8)
        w5c=$(curl -sx socks5h://localhost:$w5p https://ip.gs/country -k --connect-timeout 8)
        w5n=$(curl -sx socks5h://localhost:$w5p -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
    fi
    
    [[ -z $s5s ]] || [[ $s5s == "off" ]] && s5="${RED}Not started${PLAIN}"
    [[ -z $w5s ]] || [[ $w5s == "off" ]] && w5="${RED}Not started${PLAIN}"
    [[ $s5s == "on" ]] && s5="${YELLOW}WARP Free Account${PLAIN}"
    [[ $w5s == "on" ]] && w5="${YELLOW}WARP Free Account${PLAIN}"
    [[ $s5s == "plus" ]] && s5="${GREEN}WARP+ / Teams${PLAIN}"
    [[ $w5s == "plus" ]] && w5="${GREEN}WARP+ / Teams${PLAIN}"
    
    [[ -z $n4 ]] || [[ $n4 == "000" ]] && n4="${RED}Unable to detect Netflix status${PLAIN}"
    [[ -z $n6 ]] || [[ $n6 == "000" ]] && n6="${RED}Unable to detect Netflix status${PLAIN}"
    [[ $n4 == "200" ]] && n4="${GREEN}Netflix Unlocked${PLAIN}"
    [[ $n6 == "200" ]] && n6="${GREEN}Netflix Unlocked${PLAIN}"
    [[ $s5n == "200" ]] && s5n="${GREEN}Netflix Unlocked${PLAIN}"
    [[ $w5n == "200" ]] && w5n="${GREEN}Netflix Unlocked${PLAIN}"
    [[ $n4 == "403" ]] && n4="${RED}Netflix country restrictions${PLAIN}"
    [[ $n6 == "403" ]] && n6="${RED}Netflix country restrictions${PLAIN}"
    [[ $s5n == "403" ]]&& s5n="${RED}Netflix country restrictions${PLAIN}"
    [[ $w5n == "403" ]]&& w5n="${RED}Netflix country restrictions${PLAIN}"
    [[ $n4 == "404" ]] && n4="${YELLOW}Netflix but only homemade${PLAIN}"
    [[ $n6 == "404" ]] && n6="${YELLOW}Netflix but only homemade${PLAIN}"
    [[ $s5n == "404" ]] && s5n="${YELLOW}Netflix but only homemade${PLAIN}"
    [[ $w5n == "404" ]] && w5n="${YELLOW}Netflix but only homemade${PLAIN}"
}

check_tun(){
    vpsvirt=$(systemd-detect-virt)
    main=`uname  -r | awk -F . '{print $1}'`
    minor=`uname -r | awk -F . '{print $2}'`
    TUN=$(cat /dev/net/tun 2>&1 | tr '[:upper:]' '[:lower:]')
    if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then
        if [[ $vpsvirt == lxc ]]; then
            if [[ $main -lt 5 ]] || [[ $minor -lt 6 ]]; then
                red "Detect that the TUN module is not enabled, please go to the VPS vendor's control panel to enable it."
                exit 1
            else
                yellow "Detecting that your VPS is LXC architecture and supports kernel-level Wireguard, continue"
            fi
            elif [[ $vpsvirt == "openvz" ]]; then
            wget -N --no-check-certificate https://gitlab.com/misaka-blog/tun-script/-/raw/master/tun.sh && bash tun.sh
        else
            red "Detect that the TUN module is not enabled, please go to the VPS vendor's control panel to enable it."
            exit 1
        fi
    fi
}

check_best_mtu(){
    yellow "MTU optimal value is being set, please wait..."
    v66=`curl -s6m8 https://ip.gs -k`
    v44=`curl -s4m8 https://ip.gs -k`
    MTUy=1500
    MTUc=10
    if [[ -n ${v66} && -z ${v44} ]]; then
        ping='ping6'
        IP1='2606:4700:4700::1001'
        IP2='2001:4860:4860::8888'
    else
        ping='ping'
        IP1='1.1.1.1'
        IP2='8.8.8.8'
    fi
    while true; do
        if ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP1} >/dev/null 2>&1 || ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP2} >/dev/null 2>&1; then
            MTUc=1
            MTUy=$((${MTUy} + ${MTUc}))
        else
            MTUy=$((${MTUy} - ${MTUc}))
            if [[ ${MTUc} = 1 ]]; then
                break
            fi
        fi
        if [[ ${MTUy} -le 1360 ]]; then
            MTUy='1360'
            break
        fi
    done
    MTU=$((${MTUy} - 80))
    green "MTU Optimal value = $MTU is set"
}

docker_warn(){
    if [[ -n $(type -P docker) ]]; then
        yellow "Docker is installed, if you continue to install Wgcf-WARP, it may affect your Docker container"
        read -rp "Do you want continue installation? [Y/N]：" yesno
        if [[ $yesno =~ "Y"|"y" ]]; then
            green "Continue installing Wgcf-WARP"
        else
            red "Cancel Wgcf-WARP installation"
            exit 1
        fi
    fi
}

wgcfFailAction(){
    red "Unable to start Wgcf-WARP, trying to reboot, number of retries: $retry_time"
    wg-quick down wgcf >/dev/null 2>&1
    wg-quick up wgcf >/dev/null 2>&1
    WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    sleep 8
    retry_time=$((${retry_time} + 1))
    if [[ $retry_time == 6 ]]; then
        uninstall_wgcf
        echo ""
        red "Wgcf-WARP has been automatically uninstalled due to too many Wgcf-WARP startup retries"
        green "Suggestions are as follows:"
        yellow "1. It is recommended to use the official system source to update the system and kernel acceleration! If you are using a third party source and kernel acceleration, please make sure to update to the latest version, or reset to the official system source!"
        yellow "2. Some VPS systems are too streamlined, so you need to install the dependencies yourself and try again"
        yellow "3. Check https://www.cloudflarestatus.com/ for the nearest area of the VPS. If it is in the [Re-routed] state, you cannot use Wgcf-WARP"
        yellow "4. Script may not be up to date, suggest screenshot to post to GitHub Issues, GitLab Issues, forum or Telegram group to ask"
        exit 1
    fi
}

wgcfconfig4(){
    sed -i '/\:\:\/0/d' wgcf.conf
}

wgcfconfig6(){
    sed -i '/0\.\0\/0/d' wgcf.conf
}

wgcfcheck4(){
    yellow "Wgcf-WARP is starting"
    wg-quick up wgcf >/dev/null 2>&1
    
    WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    retry_time=1
    until [[ $WgcfWARP4Status =~ "on"|"plus" ]]; do
        wgcfFailAction
    done
    systemctl enable wg-quick@wgcf >/dev/null 2>&1
    
    WgcfIPv4=$(curl -s4m8 https://ip.gs -k)
    green "Wgcf-WARP has been started successfully"
    yellow "Wgcf-WARP's IPv4 IP is: $WgcfIPv4"
}

wgcfcheck6(){
    yellow "Wgcf-WARP is starting"
    wg-quick up wgcf >/dev/null 2>&1
    
    WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    retry_time=1
    until [[ $WgcfWARP6Status =~ "on"|"plus" ]]; do
        wgcfFailAction
    done
    systemctl enable wg-quick@wgcf >/dev/null 2>&1
    
    WgcfIPv6=$(curl -s6m8 https://ip.gs -k)
    green "Wgcf-WARP has been started successfully"
    yellow "Wgcf-WARP's IPv6 IP is: $WgcfIPv6"
}

wgcfcheckd(){
    yellow "Wgcf-WARP is starting"
    wg-quick up wgcf >/dev/null 2>&1
    
    WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    retry_time=1
    until [[ $WgcfWARP4Status =~ on|plus ]] && [[ $WgcfWARP6Status =~ on|plus ]]; do
        wgcfFailAction
    done
    systemctl enable wg-quick@wgcf >/dev/null 2>&1
    
    WgcfIPv4=$(curl -s4m8 https://ip.gs -k)
    WgcfIPv6=$(curl -s6m8 https://ip.gs -k)
    green "Wgcf-WARP has been started successfully"
    yellow "Wgcf-WARP's IPv4 IP is: $WgcfIPv4"
    yellow "Wgcf-WARP's IPv6 IP is: $WgcfIPv6"
}

wgcfdns4(){
    sed -i 's/1.1.1.1/1.1.1.1,8.8.8.8,8.8.4.4,2606:4700:4700::1001,2606:4700:4700::1111,2001:4860:4860::8888,2001:4860:4860::8844/g' wgcf.conf
}

wgcfdns6(){
    sed -i 's/1.1.1.1/2606:4700:4700::1001,2606:4700:4700::1111,2001:4860:4860::8888,2001:4860:4860::8844,1.1.1.1,8.8.8.8,8.8.4.4/g' wgcf.conf
}

wgcfendpoint4(){
    sed -i 's/engage.cloudflareclient.com/162.159.193.10/g' wgcf.conf
}

wgcfendpoint6(){
    sed -i 's/engage.cloudflareclient.com/[2606:4700:d0::a29f:c001]/g' wgcf.conf
}

wgcfpost4(){
    sed -i "7 s/^/PostUp = ip -4 rule add from $(ip route get 114.114.114.114 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
    sed -i "8 s/^/PostDown = ip -4 rule delete from $(ip route get 114.114.114.114 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
}

wgcfpost6(){
    sed -i "7 s/^/PostUp = ip -6 rule add from $(ip route get 2400:3200::1 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
    sed -i "8 s/^/PostDown = ip -6 rule delete from $(ip route get 2400:3200::1 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
}

wgcfpostd(){
    sed -i "7 s/^/PostUp = ip -4 rule add from $(ip route get 114.114.114.114 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
    sed -i "8 s/^/PostDown = ip -4 rule delete from $(ip route get 114.114.114.114 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
    sed -i "9 s/^/PostUp = ip -6 rule add from $(ip route get 2400:3200::1 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
    sed -i "10 s/^/PostDown = ip -6 rule delete from $(ip route get 2400:3200::1 | grep -oP 'src \K\S+') lookup main\n/" wgcf.conf
}

install_wgcf(){
    main=`uname  -r | awk -F . '{print $1}'`
    minor=`uname -r | awk -F . '{print $2}'`
    vsid=`grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1`
    [[ $SYSTEM == "CentOS" ]] && [[ ! ${vsid} =~ 7|8 ]] && yellow "Current system version: CentOS $vsid \nWgcf-WARP only supported on CentOS 7-8" && exit 1
    [[ $SYSTEM == "Debian" ]] && [[ ! ${vsid} =~ 10|11 ]] && yellow "Current system version: Debian $vsid \nWgcf-WARP only supported on Debian 10-11 systems" && exit 1
    [[ $SYSTEM == "Ubuntu" ]] && [[ ! ${vsid} =~ 16|18|20|22 ]] && yellow "Current system version: Ubuntu $vsid \nWgcf-WARP only supported on Ubuntu 16.04/18.04/20.04/22.04 systems" && exit 1
    
    if [[ $c4 == "Hong Kong" || $c6 == "Hong Kong" ]]; then
        red "VPS with Hong Kong location is detected!"
        yellow "Wgcf-WARP is not available due to CloudFlare blocked Wgcf for Hong Kong. please use a VPS from another location"
        exit 1
    fi
    
    check_tun
    docker_warn
    
    if [[ $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_INSTALL[int]} epel-release
        ${PACKAGE_INSTALL[int]} sudo curl wget net-tools wireguard-tools iptables htop screen iputils
        if [[ $main -lt 5 ]] || [[ $minor -lt 6 ]]; then
            if [[ $vpsvirt =~ "kvm"|"xen"|"microsoft"|"vmware"|"qemu" ]]; then
                vsid=`grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1`
                curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-$vsid/jdoss-wireguard-epel-$vsid.repo
                ${PACKAGE_INSTALL[int]} wireguard-dkms
            fi
        fi
    fi
    if [[ $SYSTEM == "Debian" ]]; then
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} sudo wget curl lsb-release htop inetutils-ping
        echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | tee /etc/apt/sources.list.d/backports.list
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} --no-install-recommends net-tools iproute2 openresolv screen dnsutils wireguard-tools iptables
        if [[ $main -lt 5 ]] || [[ $minor -lt 6 ]]; then
            if [[ $vpsvirt =~ "kvm"|"xen"|"microsoft"|"vmware"|"qemu" ]]; then
                ${PACKAGE_INSTALL[int]} --no-install-recommends linux-headers-$(uname -r)
                ${PACKAGE_INSTALL[int]} --no-install-recommends wireguard-dkms
            fi
        fi
    fi
    if [[ $SYSTEM == "Ubuntu" ]]; then
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} sudo curl wget lsb-release htop inetutils-ping
        if [[ $vsid =~ 16 ]]; then
            add-apt-repository ppa:wireguard/wireguard
            ${PACKAGE_UPDATE[int]}
        fi
        ${PACKAGE_INSTALL[int]} --no-install-recommends net-tools iproute2 openresolv dnsutils screen wireguard-tools iptables
        if [[ $main -lt 5 ]] || [[ $minor -lt 6 ]]; then
            if [[ $vpsvirt =~ "kvm"|"xen"|"microsoft"|"vmware"|"qemu" ]]; then
                ${PACKAGE_INSTALL[int]} --no-install-recommends wireguard-dkms
            fi
        fi
    fi
    
    if [[ $vpsvirt =~ lxc|openvz ]]; then
        if [[ $main -lt 5 ]] || [[ $minor -lt 6 ]]; then
            wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/files/wireguard-go -O /usr/bin/wireguard-go
            chmod +x /usr/bin/wireguard-go
        fi
    fi
    if [[ $vpsvirt == zvm ]]; then
        wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/files/wireguard-go-s390x -O /usr/bin/wireguard-go
        chmod +x /usr/bin/wireguard-go
    fi
    
    wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/files/wgcf-latest-linux-$(archAffix) -O /usr/local/bin/wgcf
    chmod +x /usr/local/bin/wgcf
    
    if [[ -f /etc/wireguard/wgcf-account.toml ]]; then
        cp -f /etc/wireguard/wgcf-account.toml /root/wgcf-account.toml
        wgcfFile=1
    fi
    if [[ -f /root/wgcf-account.toml ]]; then
        wgcfFile=1
    fi
    
    until [[ -a wgcf-account.toml ]]; do
        yellow "We are applying for an account with CloudFlare WARP, please be patient if you are prompted with 429 Too Many Requests error."
        yes | wgcf register
        sleep 5
    done
    chmod +x wgcf-account.toml
    
    if [[ ! $wgcfFile == 1 ]]; then
        yellow "To use WARP free version account, please press Enter to skip \n to enable WARP+ account, please copy the license key of WARP+ (26 characters) and enter"
        read -rp "Enter the WARP account license key (26 characters):" WPPlusKey
        if [[ -n $WPPlusKey ]]; then
            sed -i "s/license_key.*/license_key = \"$WPPlusKey\"/g" wgcf-account.toml
            read -rp "Please enter a custom device name, or use the default random device name if not entered." WPPlusName
            green "In the registered WARP+ account, if the following party shows: 400 Bad Request, then use the free version of WARP account"
            if [[ -n $WPPlusName ]]; then
                wgcf update --name $(echo $WPPlusName | sed s/[[:space:]]/_/g)
            else
                wgcf update
            fi
        fi
    fi
    
    wgcf generate
    chmod +x wgcf-profile.conf
    
    check_best_mtu
    sed -i "s/MTU.*/MTU = $MTU/g" wgcf-profile.conf
    
    if [[ ! -d "/etc/wireguard" ]]; then
        mkdir /etc/wireguard
        chmod -R 777 /etc/wireguard
    fi
    
    mv -f wgcf-profile.conf /etc/wireguard/wgcf.conf
    mv -f wgcf-account.toml /etc/wireguard/wgcf-account.toml
    
    cd /etc/wireguard
    
    if [[ $VPSIP == 0 ]]; then
        [[ $wgcfmode == 0 ]] && wgcfdns6 && wgcfconfig4 && wgcfendpoint6 && wgcfcheck4
        [[ $wgcfmode == 1 ]] && wgcfdns6 && wgcfpost6 && wgcfconfig6 && wgcfendpoint6 && wgcfcheck6
        [[ $wgcfmode == 2 ]] && wgcfdns6 && wgcfpost6 && wgcfendpoint6 && wgcfcheckd
    fi
    if [[ $VPSIP == 1 ]]; then
        [[ $wgcfmode == 0 ]] && wgcfdns4 && wgcfpost4 && wgcfconfig4 && wgcfendpoint4 && wgcfcheck4
        [[ $wgcfmode == 1 ]] && wgcfdns4 && wgcfconfig6 && wgcfendpoint4 && wgcfcheck6
        [[ $wgcfmode == 2 ]] && wgcfdns4 && wgcfpost4 && wgcfendpoint4 && wgcfcheckd
    fi
    if [[ $VPSIP == 2 ]]; then
        [[ $wgcfmode == 0 ]] && wgcfdns4 && wgcfpost4 && wgcfconfig4 && wgcfcheck4
        [[ $wgcfmode == 1 ]] && wgcfdns4 && wgcfpost6 && wgcfconfig6 && wgcfcheck6
        [[ $wgcfmode == 2 ]] && wgcfdns4 && wgcfpostd && wgcfcheckd
    fi
}

wgcf_switch(){
    WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    
    if [[ $WgcfWARP4Status =~ on|plus ]] || [[ $WgcfWARP6Status =~ on|plus ]]; then
        wg-quick down wgcf >/dev/null 2>&1
        systemctl disable wg-quick@wgcf >/dev/null 2>&1
        green "Wgcf-WARP stop successfully!"
        exit 1
    fi
    
    if [[ $WgcfWARP4Status == off ]] || [[ $WgcfWARP6Status == off ]]; then
        wg-quick up wgcf >/dev/null 2>&1
        systemctl enable wg-quick@wgcf >/dev/null 2>&1
        green "Wgcf-WARP start successfully!"
        exit 1
    fi
}

uninstall_wgcf(){
    wg-quick down wgcf 2>/dev/null
    systemctl disable wg-quick@wgcf 2>/dev/null
    ${PACKAGE_UNINSTALL[int]} wireguard-tools wireguard-dkms
    if [[ -z $(type -P wireproxy) ]]; then
        rm -f /usr/local/bin/wgcf
        rm -f /etc/wireguard/wgcf-account.toml
    fi
    rm -f /etc/wireguard/wgcf.conf
    rm -f /usr/bin/wireguard-go
    if [[ -e /etc/gai.conf ]]; then
        sed -i '/^precedence[ ]*::ffff:0:0\/96[ ]*100/d' /etc/gai.conf
    fi
    green "Wgcf-WARP has been completely uninstalled successfully!"
}

install_warpcli(){
    main=`uname  -r | awk -F . '{print $1}'`
    minor=`uname -r | awk -F . '{print $2}'`
    vsid=`grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1`
    [[ $SYSTEM == "CentOS" ]] && [[ ! ${vsid} =~ 8 ]] && yellow "Current system version: CentOS $vsid \nWARP-Cli proxy mode is only supported on CentOS 8" && exit 1
    [[ $SYSTEM == "Debian" ]] && [[ ! ${vsid} =~ 9|10|11 ]] && yellow "Current system version: Debian $vsid \nWARP-Cli proxy mode is only supported on Debian 9-11" && exit 1
    [[ $SYSTEM == "Ubuntu" ]] && [[ ! ${vsid} =~ 16|18|20 ]] && yellow "Current system version: Ubuntu $vsid \nWARP-Cli proxy mode is only supported on Ubuntu 16.04/18.04/20.04 systems" && exit 1
    
    check_tun
    
    [[ ! $(archAffix) == "amd64" ]] && red "WARP-Cli temporarily does not support the current VPS CPU architecture, please use the CPU architecture of amd64 VPS" && exit 1
    
    v66=`curl -s6m8 https://ip.gs -k`
    v44=`curl -s4m8 https://ip.gs -k`
    WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    
    if [[ -n ${v66} && -z ${v44} ]]; then
        red "WARP-Cli proxy mode does not support pure IPv6 VPS!"
        exit 1
    fi
    
    if [[ $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_INSTALL[int]} epel-release
        ${PACKAGE_INSTALL[int]} sudo curl wget net-tools htop iputils screen
        rpm -ivh http://pkg.cloudflareclient.com/cloudflare-release-el8.rpm
        ${PACKAGE_INSTALL[int]} cloudflare-warp
    fi
    
    if [[ $SYSTEM == "Debian" ]]; then
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} sudo curl wget lsb-release htop inetutils-ping screen
        [[ -z $(type -P gpg 2>/dev/null) ]] && ${PACKAGE_INSTALL[int]} gnupg
        [[ -z $(apt list 2>/dev/null | grep apt-transport-https | grep installed) ]] && ${PACKAGE_INSTALL[int]} apt-transport-https
        curl https://pkg.cloudflareclient.com/pubkey.gpg | apt-key add -
        echo "deb http://pkg.cloudflareclient.com/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} cloudflare-warp
    fi
    
    if [[ $SYSTEM == "Ubuntu" ]]; then
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} sudo curl wget lsb-release htop inetutils-ping screen
        curl https://pkg.cloudflareclient.com/pubkey.gpg | apt-key add -
        echo "deb http://pkg.cloudflareclient.com/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} cloudflare-warp
    fi
    
    warp-cli --accept-tos register >/dev/null 2>&1
    yellow "To use WARP free version account, please press Enter to skip \n to enable WARP+ account, please copy the license key of WARP+ (26 characters) and enter"
    read -rp "Enter the WARP account license key (26 characters):" WPPlusKey
    if [[ -n $WPPlusKey ]]; then
        warp-cli --accept-tos set-license "$WPPlusKey" >/dev/null 2>&1 && sleep 1
        if [[ $(warp-cli --accept-tos account) =~ Limited ]]; then
            green "WARP+ account enabled successfully"
        else
            red "WARP+ account failed to enable, will use WARP free version account"
        fi
    fi
    warp-cli --accept-tos set-mode proxy >/dev/null 2>&1
    
    read -rp "Please enter the proxy port used by WARP-Cli (default 40000):" WARPCliPort
    [[ -z $WARPCliPort ]] && WARPCliPort=40000
    if [[ -n $(netstat -ntlp | grep "$WARPCliPort") ]]; then
        until [[ -z $(netstat -ntlp | grep "$WARPCliPort") ]]; do
            if [[ -n $(netstat -ntlp | grep "$WARPCliPort") ]]; then
                yellow "The port you set is currently occupied, please re-enter the port"
                read -rp "Please enter the proxy port used by WARP-Cli (default 40000):" WARPCliPort
            fi
        done
    fi
    warp-cli --accept-tos set-proxy-port "$WARPCliPort" >/dev/null 2>&1
    
    yellow "Warp-Cli proxy mode is starting"
    warp-cli --accept-tos connect >/dev/null 2>&1
    warp-cli --accept-tos enable-always-on >/dev/null 2>&1
    sleep 5
    socks5IP=$(curl -sx socks5h://localhost:$WARPCliPort ip.gs -k --connect-timeout 8)
    green "WARP-Cli proxy mode has started successfully!"
    yellow "Local Socks5 proxy is: 127.0.0.1:$WARPCliPort"
    yellow "The IP of WARP-Cli proxy mode is: $socks5IP"
}

change_warpcli_port() {
    if [[ $(warp-cli --accept-tos status) =~ Connected ]]; then
        warp-cli --accept-tos disconnect >/dev/null 2>&1
    fi
    read -rp "Please enter the proxy port used by WARP-Cli (default 40000):" WARPCliPort
    [[ -z $WARPCliPort ]] && WARPCliPort=40000
    if [[ -n $(netstat -ntlp | grep "$WARPCliPort") ]]; then
        until [[ -z $(netstat -ntlp | grep "$WARPCliPort") ]]; do
            if [[ -n $(netstat -ntlp | grep "$WARPCliPort") ]]; then
                yellow "The port you set is currently occupied, please re-enter the port"
                read -rp "Please enter the proxy port used by WARP-Cli (default 40000):" WARPCliPort
            fi
        done
    fi
    warp-cli --accept-tos set-proxy-port "$WARPCliPort" >/dev/null 2>&1
    yellow "Starting Warp-Cli proxy mode"
    warp-cli --accept-tos connect >/dev/null 2>&1
    warp-cli --accept-tos enable-always-on >/dev/null 2>&1
    socks5IP=$(curl -sx socks5h://localhost:$WARPCliPort ip.gs -k --connect-timeout 8)
    green "WARP-Cli proxy mode has been started successfully and the proxy port has been modified successfully!"
    yellow "Local Socks5 proxy is: 127.0.0.1:$WARPCliPort"
}

warpcli_switch(){
    if [[ $(warp-cli --accept-tos status) =~ Connected ]]; then
        warp-cli --accept-tos disconnect >/dev/null 2>&1
        green "WARP-Cli proxy mode stop successfully!"
        exit 1
    fi
    if [[ $(warp-cli --accept-tos status) =~ Disconnected ]]; then
        yellow "Starting Warp-Cli proxy mode"
        warp-cli --accept-tos connect >/dev/null 2>&1
        warp-cli --accept-tos enable-always-on >/dev/null 2>&1
        socks5IP=$(curl -sx socks5h://localhost:$w5p ip.gs -k --connect-timeout 8)
        green "WARP-Cli proxy mode has been started successfully and the proxy port has been modified successfully!"
        yellow "Local Socks5 proxy is: 127.0.0.1:$w5p"
        exit 1
    fi
}

uninstall_warpcli(){
    warp-cli --accept-tos disconnect >/dev/null 2>&1
    warp-cli --accept-tos disable-always-on >/dev/null 2>&1
    warp-cli --accept-tos delete >/dev/null 2>&1
    ${PACKAGE_UNINSTALL[int]} cloudflare-warp
    systemctl disable --now warp-svc >/dev/null 2>&1
    green "WARP-Cli proxy mode has been completely uninstalled successfully!"
}

wireproxyFailAction(){
    retry_time=$((${retry_time} + 1))
    red "Failed to start WireProxy-WARP proxy mode, trying to restart, number of retries: $retry_time"
    systemctl stop wireproxy-warp
    systemctl start wireproxy-warp
    WireProxyStatus=$(curl -sx socks5h://localhost:$WireProxyPort https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
    if [[ $retry_time == 6 ]]; then
        uninstall_wireproxy
        echo ""
        red "WireProxy-WARP proxy mode has been automatically uninstalled due to too many retry attempts to start the WireProxy-WARP proxy mode"
        green "The following is recommended:"
        yellow "1. It is recommended to use the official system source to upgrade the system and kernel acceleration! If you are using a third-party source and kernel acceleration, please be sure to update to the latest version, or reset to the official system source!"
        yellow "2. Some VPS systems are too streamlined, so you need to install the dependencies yourself and try again"
        yellow "3. Check https://www.cloudflarestatus.com/ for the nearest area of the VPS. If you are in [Re-routed] state, you can not use WireProxy-WARP proxy mode"
        yellow "4. Script may not be up to date, suggest screenshot to post to GitHub Issues, GitLab Issues, forum or Telegram group to ask"
        exit 1
    fi
    sleep 8
}

install_wireproxy(){
    if [[ $c4 == "Hong Kong" || $c6 == "Hong Kong" ]]; then
        red "VPS with Hong Kong location is detected!"
        yellow "WireProxy-WARP proxy mode is not available due to CloudFlare blocking Wgcf for Hong Kong. Please use a VPS from another region"
        exit 1
    fi
    
    if [[ $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_INSTALL[int]} sudo curl wget htop iputils screen
    else
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} sudo curl wget htop inetutils-ping screen
    fi
    
    wget -N https://gitlab.com/misaka-blog/warp-script/-/raw/master/files/wireproxy-$(archAffix) -O /usr/local/bin/wireproxy
    chmod +x /usr/local/bin/wireproxy
    
    wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/files/wgcf-latest-linux-$(archAffix) -O /usr/local/bin/wgcf
    chmod +x /usr/local/bin/wgcf
    
    if [[ -f /etc/wireguard/wgcf-account.toml ]]; then
        cp -f /etc/wireguard/wgcf-account.toml /root/wgcf-account.toml
        wgcfFile=1
    fi
    if [[ -f /root/wgcf-account.toml ]]; then
        wgcfFile=1
    fi
    
    until [[ -a wgcf-account.toml ]]; do
        yellow "We are applying for an account with CloudFlare WARP, please be patient if you are prompted with 429 Too Many Requests error."
        yes | wgcf register
        sleep 5
    done
    chmod +x wgcf-account.toml
    
    if [[ ! $wgcfFile == 1 ]]; then
        yellow "To use WARP free version account, please press Enter to skip \n to enable WARP+ account, please copy the license key of WARP+ (26 characters) and enter"
        read -rp "Enter the WARP account license key (26 characters):" WPPlusKey
        if [[ -n $WPPlusKey ]]; then
            sed -i "s/license_key.*/license_key = \"$WPPlusKey\"/g" wgcf-account.toml
            read -rp "Please enter a custom device name, or use the default random device name if not entered." WPPlusName
            green "In the registered WARP+ account, if the following party shows: 400 Bad Request, then use the free version of WARP account"
            if [[ -n $WPPlusName ]]; then
                wgcf update --name $(echo $WPPlusName | sed s/[[:space:]]/_/g)
            else
                wgcf update
            fi
        fi
    fi
    
    wgcf generate
    chmod +x wgcf-profile.conf
    
    IPv4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    IPv6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    
    if [[ $IPv4Status =~ "on"|"plus" ]] || [[ $IPv6Status =~ "on"|"plus" ]]; then
        wg-quick down wgcf >/dev/null 2>&1
        check_best_mtu
        wg-quick up wgcf >/dev/null 2>&1
    else
        check_best_mtu
    fi
    
    read -rp "Please enter the proxy port used by WireProxy-WARP (default 40000):" WireProxyPort
    [[ -z $WireProxyPort ]] && WireProxyPort=40000
    if [[ -n $(netstat -ntlp | grep "$WireProxyPort") ]]; then
        until [[ -z $(netstat -ntlp | grep "$WireProxyPort") ]]; do
            if [[ -n $(netstat -ntlp | grep "$WireProxyPort") ]]; then
                yellow "The port you set is currently occupied, please re-enter the port"
                read -rp "Please enter the proxy port used by WireProxy-WARP (default 40000):" WireProxyPort
            fi
        done
    fi
    
    WgcfPrivateKey=$(grep PrivateKey wgcf-profile.conf | sed "s/PrivateKey = //g")
    WgcfPublicKey=$(grep PublicKey wgcf-profile.conf | sed "s/PublicKey = //g")
    
    if [[ ! -d "/etc/wireguard" ]]; then
        mkdir /etc/wireguard
        chmod -R 777 /etc/wireguard
    fi
    
    [[ $VPSIP == 0 ]] && WireproxyEndpoint="[2606:4700:d0::a29f:c001]:2408"
    [[ $VPSIP == 1 || $VPSIP == 2 ]] && WireproxyEndpoint="162.159.193.10:2408"
    
    cat <<EOF > /etc/wireguard/proxy.conf
[Interface]
Address = 172.16.0.2/32
MTU = $MTU
PrivateKey = $WgcfPrivateKey
DNS = 1.1.1.1,8.8.8.8,8.8.4.4,2606:4700:4700::1001,2606:4700:4700::1111,2001:4860:4860::8888,2001:4860:4860::8844

[Peer]
PublicKey = $WgcfPublicKey
Endpoint = $WireproxyEndpoint

[Socks5]
BindAddress = 127.0.0.1:$WireProxyPort
EOF
    
    cat <<'TEXT' > /etc/systemd/system/wireproxy-warp.service
[Unit]
Description=CloudFlare WARP Socks5 proxy mode based for WireProxy, script by owo.misaka.rest
After=network.target
[Install]
WantedBy=multi-user.target
[Service]
Type=simple
WorkingDirectory=/root
ExecStart=/usr/local/bin/wireproxy -c /etc/wireguard/proxy.conf
Restart=always
TEXT
    
    rm -f wgcf-profile.conf
    mv wgcf-account.toml /etc/wireguard/wgcf-account.toml
    
    yellow "WireProxy-WARP proxy mode is starting"
    systemctl start wireproxy-warp
    WireProxyStatus=$(curl -sx socks5h://localhost:$WireProxyPort https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
    retry_time=1
    until [[ $WireProxyStatus =~ on|plus ]]; do
        wireproxyFailAction
    done
    sleep 5
    systemctl enable wireproxy-warp >/dev/null 2>&1
    socks5IP=$(curl -sx socks5h://localhost:$WireProxyPort https://ip.gs -k --connect-timeout 8)
    green "WireProxy-WARP proxy mode has started successfully!"
    yellow "Local Socks5 proxy is: 127.0.0.1:$WireProxyPort"
    yellow "IP of WireProxy-WARP proxy mode is: $socks5IP"
}

change_wireproxy_port(){
    systemctl stop wireproxy-warp
    read -rp "Please enter the proxy port used by WireProxy-WARP (default 40000):" WireProxyPort
    [[ -z $WireProxyPort ]] && WireProxyPort=40000
    if [[ -n $(netstat -ntlp | grep "$WireProxyPort") ]]; then
        until [[ -z $(netstat -ntlp | grep "$WireProxyPort") ]]; do
            if [[ -n $(netstat -ntlp | grep "$WireProxyPort") ]]; then
                yellow "The port you set is currently occupied, please re-enter the port"
                read -rp "Please enter the proxy port used by WireProxy-WARP (default 40000):" WireProxyPort
            fi
        done
    fi
    CurrentPort=$(grep BindAddress /etc/wireguard/proxy.conf)
    sed -i "s/$CurrentPort/BindAddress = 127.0.0.1:$WireProxyPort/g" /etc/wireguard/proxy.conf
    yellow "WireProxy-WARP proxy mode is starting"
    systemctl start wireproxy-warp
    WireProxyStatus=$(curl -sx socks5h://localhost:$WireProxyPort https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
    retry_time=1
    until [[ $WireProxyStatus =~ on|plus ]]; do
        wireproxyFailAction
    done
    systemctl enable wireproxy-warp
    green "WireProxy-WARP proxy mode has started successfully!"
    yellow "Local Socks5 proxy is: 127.0.0.1:$WireProxyPort"
}

wireproxy_switch(){
    w5p=$(grep BindAddress /etc/wireguard/proxy.conf 2>/dev/null | sed "s/BindAddress = 127.0.0.1://g")
    w5s=$(curl -sx socks5h://localhost:$w5p https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
    if [[ $w5s =~ "on"|"plus" ]]; then
        systemctl stop wireproxy-warp
        systemctl disable wireproxy-warp
        green "WireProxy-WARP proxy mode stopped successfully!"
    fi
    if [[ $w5s =~ "off" ]] || [[ -z $w5s ]]; then
        systemctl start wireproxy-warp
        systemctl enable wireproxy-warp
        green "WireProxy-WARP proxy mode has started successfully!"
    fi
}

uninstall_wireproxy(){
    systemctl stop wireproxy-warp
    systemctl disable wireproxy-warp
    rm -f /etc/systemd/system/wireproxy-warp.service /usr/local/bin/wireproxy /etc/wireguard/proxy.conf
    if [[ ! -f /etc/wireguard/wgcf.conf ]]; then
        rm -f /usr/local/bin/wgcf /etc/wireguard/wgcf-account.toml
    fi
    green "WireProxy-WARP proxy mode has been completely uninstalled successfully!"
}

warpup(){
    yellow "Get CloudFlare WARP account information method:"
    green "PC: Download and install CloudFlare WARP → Settings → Preferences → Copy Device ID to the script"
    green "Mobile: download and install 1.1.1.1 APP → Menu → Advanced → Diagnostics → Copy Device ID to script"
    echo ""
    yellow "Please follow the instructions below and enter your CloudFlare WARP account information:"
    read -rp "Please enter your WARP device ID (36 characters): " WarpDeviceID
    read -rp "Please enter the amount of traffic (in GB) you expect to be swiped: " WarpFlowLimit
    echo -e "The amount of traffic you expect to be flushed is set to: $WarpFlowLimit GB"
    for ((i = 0; i < ${WarpFlowLimit}; i++)); do
        if [[ $i == 0 ]]; then
            sleep_try=30
            sleep_min=20
            sleep_max=600
        fi
        
        install_id=$(tr -dc 'A-Za-z0-9' </dev/urandom >/dev/null 2>&1 | head -c 22)
        curl -X POST -m 10 -sA "okhttp/3.12.1" -H 'content-type: application/json' -H 'Host: api.cloudflareclient.com' --data "{\"key\": \"$(tr -dc 'A-Za-z0-9' </dev/urandom >/dev/null 2>&1 | head -c 43)=\",\"install_id\": \"$install_id\",\"fcm_token\": \"APA91b$install_id$(tr -dc 'A-Za-z0-9' </dev/urandom >/dev/null 2>&1 | head -c 134)\",\"referrer\": \"$WarpDeviceID\",\"warp_enabled\": false,\"tos\": \"$(date -u +%FT%T.$(tr -dc '0-9' </dev/urandom >/dev/null 2>&1 | head -c 3)Z)\",\"type\": \"Android\",\"locale\": \"en_US\"}"  --url "https://api.cloudflareclient.com/v0a$(shuf -i 100-999 -n 1)/reg" | grep -qE "referral_count\":1" && status=0 || status=1
        
        # cloudflare限制了请求频率,目前测试大概在20秒,失败时因延长sleep时间
        [[ $sleep_try > $sleep_max ]] && sleep_try=300
        [[ $sleep_try == $sleep_min ]] && sleep_try=$((sleep_try+1))
        
        if [[ $status == 0 ]]; then
            sleep_try=$((sleep_try-1))
            sleep $sleep_try
            rit[i]=$i
            echo -n $i-o-
            continue
        fi
        
        if [[ $status == 1 ]]; then
            sleep_try=$((sleep_try+2))
            sleep $sleep_try
            bad[i]=$i
            echo -n $i-x-
            continue
        fi
    done
    echo ""
    echo -e "This run successfully obtained a total of warp+ traffic ${GREEN} ${#rit[*]} ${PLAIN} GB"
}

warpsw1_freeplus(){
    warpPublicKey=$(grep PublicKey wgcf-profile.conf | sed "s/PublicKey = //g")
    warpPrivateKey=$(grep PrivateKey wgcf-profile.conf | sed "s/PrivateKey = //g")
    warpIPv4Address=$(grep "Address = 172" wgcf-profile.conf | sed "s/Address = //g")
    warpIPv6Address=$(grep "Address = fd01" wgcf-profile.conf | sed "s/Address = //g")
    sed -i "s#PublicKey.*#PublicKey = $warpPublicKey#g" /etc/wireguard/wgcf.conf;
    sed -i "s#PrivateKey.*#PrivateKey = $warpPrivateKey#g" /etc/wireguard/wgcf.conf;
    sed -i "s#Address.*32#Address = $warpIPv4Address/32#g" /etc/wireguard/wgcf.conf;
    sed -i "s#Address.*128#Address = $warpIPv6Address/128#g" /etc/wireguard/wgcf.conf;
    rm -f wgcf-profile.conf
}

warpsw3_freeplus(){
    warpIPv4Address=$(grep "Address = 172" wgcf-profile.conf | sed "s/Address = //g")
    warpPublicKey=$(grep PublicKey wgcf-profile.conf | sed "s/PublicKey = //g")
    warpPrivateKey=$(grep PrivateKey wgcf-profile.conf | sed "s/PrivateKey = //g")
    sed -i "s#PublicKey.*#PublicKey = $warpPublicKey#g" /etc/wireguard/wgcf.conf;
    sed -i "s#PrivateKey.*#PrivateKey = $warpPrivateKey#g" /etc/wireguard/proxy.conf;
    sed -i "s#Address.*32#Address = $warpIPv4Address/32#g" /etc/wireguard/proxy.conf;
    rm -f wgcf-profile.conf
}

warpsw_teams(){
    read -rp "Please copy and paste the WARP Teams account configuration file link: " teamconfigurl
    [[ -z $teamconfigurl ]] && red "Did not enter profile link, cannot upgrade!" && exit 1
    teamsconfig=$(curl -sSL "$teamconfigurl" | sed "s/\"/\&quot;/g")
    wpteampublickey=$(expr "$teamsconfig" : '.*public_key&quot;:&quot;\([^&]*\).*')
    wpteamprivatekey=$(expr "$teamsconfig" : '.*private_key&quot;>\([^<]*\).*')
    wpteamv6address=$(expr "$teamsconfig" : '.*v6&quot;:&quot;\([^[&]*\).*')
    wpteamv4address=$(expr "$teamsconfig" : '.*v4&quot;:&quot;\(172[^&]*\).*')
    green "Your WARP Teams profile information is as follows:"
    yellow "PublicKey: $wpteampublickey"
    yellow "PrivateKey: $wpteamprivatekey"
    yellow "IPv4 address: $wpteamv4address"
    yellow "IPv6 address: $wpteamv6address"
    read -rp "Please enter y to confirm that the configuration information is correct, other keys to exit the upgrade process:" wpteamconfirm
}

warpsw1(){
    yellow "Please select the type of account to switch"
    green "1. WARP Free Account"
    green "2. WARP+"
    green "3. WARP Teams"
    read -rp "Please select the account type [1-3]: " accountInput
    if [[ $accountInput == 1 ]]; then
        wg-quick down wgcf >/dev/null 2>&1
        
        cd /etc/wireguard
        rm -f wgcf-account.toml
        
        until [[ -a wgcf-account.toml ]]; do
            yes | wgcf register
            sleep 5
        done
        chmod +x wgcf-account.toml
        
        wgcf generate
        chmod +x wgcf-profile.conf
        
        warpsw1_freeplus
        
        wg-quick up wgcf >/dev/null 2>&1
        yellow "Checking WARP free account connectivity, please wait..."
        WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
        WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
        if [[ $WgcfWARP4Status == "on" || $WgcfWARP6Status == "on" ]]; then
            green "Wgcf-WARP account type switch to WARP free account Success!"
        else
            green "It seems like that CloudFlare has a bug and has automatically given you a WARP+ account for nothing!"
        fi
    fi
    if [[ $accountInput == 2 ]]; then
        cd /etc/wireguard
        if [[ ! -f wgcf-account.toml ]]; then
            until [[ -a wgcf-account.toml ]]; do
                yes | wgcf register
                sleep 5
            done
        fi
        chmod +x wgcf-account.toml
        
        read -rp "Enter the WARP account license key (26 characters):" WPPlusKey
        if [[ -n $WPPlusKey ]]; then
            read -rp "Please enter a custom device name, or use the default random device name if not entered: " WPPlusName
            green "In the registered WARP+ account, if the following party shows: 400 Bad Request, then use the free version of WARP account"
            if [[ -n $WPPlusName ]]; then
                wgcf update --name $(echo $WPPlusName | sed s/[[:space:]]/_/g)
            else
                wgcf update
            fi
            
            wgcf generate
            chmod +x wgcf-profile.conf
            
            wg-quick down wgcf >/dev/null 2>&1
            
            warpsw1_freeplus
            
            wg-quick up wgcf >/dev/null 2>&1
            yellow "Checking WARP+ account connectivity, please wait..."
            WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            if [[ $WgcfWARP4Status == "plus" || $WgcfWARP6Status == "plus" ]]; then
                green "Wgcf-WARP account type switch to WARP+ successful!"
            else
                red "WARP+ is misconfigured and has been automatically downgraded to a WARP free account!"
            fi
        else
            red "The WARP account license key was not entered and could not be upgraded!"
        fi
    fi
    if [[ $accountInput == 3 ]]; then
        warpsw_teams
        if [[ $wpteamconfirm =~ "y"|"Y" ]]; then
            wg-quick down wgcf >/dev/null 2>&1
            
            sed -i "s#PublicKey.*#PublicKey = $wpteampublickey#g" /etc/wireguard/wgcf.conf;
            sed -i "s#PrivateKey.*#PrivateKey = $wpteamprivatekey#g" /etc/wireguard/wgcf.conf;
            sed -i "s#Address.*32#Address = $wpteamv4address/32#g" /etc/wireguard/wgcf.conf;
            sed -i "s#Address.*128#Address = $wpteamv6address/128#g" /etc/wireguard/wgcf.conf;
            
            wg-quick up wgcf >/dev/null 2>&1
            yellow "Checking WARP Teams account connectivity, please wait..."
            WgcfWARP4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            WgcfWARP6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            retry_time=1
            until [[ $WgcfWARP4Status =~ on|plus || $WgcfWARP6Status =~ on|plus ]]; do
                red "Unable to connect to WARP Teams account, trying to restart, number of retries: $retry_time"
                retry_time=$((${retry_time} + 1))
                
                if [[ $retry_time == 4 ]]; then
                    wg-quick down wgcf >/dev/null 2>&1
                    
                    cd /etc/wireguard
                    wgcf generate
                    chmod +x wgcf-profile.conf
                    
                    warpsw1_freeplus
                    
                    wg-quick up wgcf >/dev/null 2>&1
                    red "WARP Teams is misconfigured and has been automatically downgraded to WARP Free Account / WARP+!"
                fi
            done
            green "Wgcf-WARP account type switch to WARP Teams successful!"
        else
            red "Exited WARP Teams account upgrade process!"
        fi
    fi
}

warpsw2(){
    warp-cli --accept-tos disconnect >/dev/null 2>&1
    warp-cli --accept-tos register >/dev/null 2>&1
    read -rp "Enter the WARP account license key (26 characters):" WPPlusKey
    if [[ -n $WPPlusKey ]]; then
        warp-cli --accept-tos set-license "$WPPlusKey" >/dev/null 2>&1 && sleep 1
    fi
    warp-cli --accept-tos set-mode proxy >/dev/null 2>&1
    warp-cli --accept-tos set-proxy-port "$s5p" >/dev/null 2>&1
    warp-cli --accept-tos connect >/dev/null 2>&1
    if [[ $(warp-cli --accept-tos account) =~ Limited ]]; then
        green "WARP-Cli account type switch to WARP+ successful!"
    else
        red "WARP+ account enable failed and has been automatically downgraded to a WARP free version account"
    fi
}

warpsw3(){
    yellow "Please select the type of account to switch"
    green "1. WARP Free Account"
    green "2. WARP+"
    green "3. WARP Teams"
    read -rp "Please select the account type [1-3]: " accountInput
    if [[ $accountInput == 1 ]]; then
        systemctl stop wireproxy-warp
        
        cd /etc/wireguard
        rm -f wgcf-account.toml
        
        until [[ -a wgcf-account.toml ]]; do
            yes | wgcf register
            sleep 5
        done
        chmod +x wgcf-account.toml
        
        wgcf generate
        chmod +x wgcf-profile.conf
        
        warpsw3_freeplus
        
        systemctl start wireproxy-warp
        yellow "Checking WARP free account connectivity, please wait..."
        WireProxyStatus=$(curl -sx socks5h://localhost:$w5p https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
        if [[ $WireProxyStatus == "on" ]]; then
            green "WireProxy-WARP proxy mode Account type switch to WARP free account Success!"
        else
            green "It seems like that CloudFlare has a bug and has automatically given you a WARP+ account for nothing!"
        fi
    fi
    if [[ $accountInput == 2 ]]; then
        cd /etc/wireguard
        if [[ ! -f wgcf-account.toml ]]; then
            until [[ -a wgcf-account.toml ]]; do
                yes | wgcf register
                sleep 5
            done
        fi
        chmod +x wgcf-account.toml
        
        read -rp "Enter the WARP account license key (26 characters):" WPPlusKey
        if [[ -n $WPPlusKey ]]; then
            read -rp "Please enter a custom device name, or use the default random device name if not entered: " WPPlusName
            green "In the registered WARP+ account, if the following party shows: 400 Bad Request, then use the free version of WARP account"
            if [[ -n $WPPlusName ]]; then
                wgcf update --name $(echo $WPPlusName | sed s/[[:space:]]/_/g)
            else
                wgcf update
            fi
            
            wgcf generate
            chmod +x wgcf-profile.conf
            
            systemctl stop wireproxy-warp
            
            warpsw3_freeplus
            
            systemctl start wireproxy-warp
            yellow "Checking WARP+ account connectivity, please wait..."
            WireProxyStatus=$(curl -sx socks5h://localhost:$w5p https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
            if [[ $WireProxyStatus == "plus" ]]; then
                green "WireProxy-WARP proxy mode Account type switch to WARP+ successful!"
            else
                red "WARP+ configuration error, has automatically downgraded to WARP free account!"
            fi
        else
            red "The WARP account license key was not entered and could not be upgraded!"
        fi
    fi
    if [[ $accountInput == 3 ]]; then
        warpsw_teams
        if [[ $wpteamconfirm =~ "y"|"Y" ]]; then
            systemctl stop wireproxy-warp
            
            sed -i "s#PublicKey.*#PublicKey = $wpteampublickey#g" /etc/wireguard/proxy.conf;
            sed -i "s#PrivateKey.*#PrivateKey = $wpteamprivatekey#g" /etc/wireguard/proxy.conf;
            sed -i "s#Address.*32#Address = $wpteamv4address/32#g" /etc/wireguard/proxy.conf;
            
            systemctl start wireproxy-warp
            yellow "Checking WARP Teams account connectivity, please wait..."
            WireProxyStatus=$(curl -sx socks5h://localhost:$w5p https://www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 8 | grep warp | cut -d= -f2)
            retry_time=1
            until [[ $WireProxyStatus == "plus" ]]; do
                red "Unable to connect to WARP Teams account, trying to restart, number of retries: $retry_time"
                retry_time=$((${retry_time} + 1))
                
                if [[ $retry_time == 4 ]]; then
                    systemctl stop wireproxy-warp
                    
                    cd /etc/wireguard
                    wgcf generate
                    chmod +x wgcf-profile.conf
                    
                    warpsw3_freeplus
                    
                    systemctl start wireproxy-warp
                    red "WARP Teams is misconfigured and has been automatically downgraded to WARP Free Account / WARP+!"
                fi
            done
            green "WireProxy-WARP proxy mode account type switched to WARP Teams successfully!"
        else
            red "Exited WARP Teams account upgrade process!"
        fi
    fi
}

warpsw(){
    yellow "Please select the WARP client that needs to switch WARP accounts:"
    echo -e " ${GREEN}1.${PLAIN} Wgcf-WARP"
    echo -e " ${GREEN}2.${PLAIN} WARP-Cli proxy mode ${RED}(currently only supports upgraded WARP+ accounts) ${PLAIN}"
    echo -e " ${GREEN}3.${PLAIN} WireProxy-WARP proxy mode"
    read -rp "Please select client [1-3]: " clientInput
    case "$clientInput" in
        1 ) warpsw1 ;;
        2 ) warpsw2 ;;
        3 ) warpsw3 ;;
        * ) exit 1 ;;
    esac
}

warpnf(){
    yellow "Please select the WARP client that needs to get the NetFilx IP:"
    green "1. Wgcf-WARP IPv4 mode"
    green "2. Wgcf-WARP IPv6 mode"
    green "3. WARP-Cli proxy mode"
    green "4. WireProxy-WARP proxy mode"
    read -rp "Please select client [1-4]: " clientInput
    case "$clientInput" in
        1 ) wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/wgcf-warp/netfilx4.sh && bash netfilx4.sh ;;
        2 ) wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/wgcf-warp/netfilx6.sh && bash netfilx6.sh ;;
        3 ) wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/warp-cli/netfilxcli.sh && bash netfilxcli.sh ;;
        4 ) wget -N --no-check-certificate https://gitlab.com/misaka-blog/warp-script/-/raw/master/wireproxy-warp/netfilx-wireproxy.sh && bash netfilx-wireproxy.sh ;;
    esac
}

menu(){
    check_status
    [[ $VPSIP == 0 ]] && menu0
    [[ $VPSIP == 1 ]] && menu1
    [[ $VPSIP == 2 ]] && menu2
}

info_bar(){
    echo "#############################################################"
    echo -e "#            ${RED} WARP One-click installation script${PLAIN}            #"
    echo -e "# ${GREEN}Author${PLAIN}: Misaka No                                         #"
    echo -e "# ${GREEN}Blog${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}Forum${PLAIN}: https://vpsgo.co                                   #"
    echo -e "# ${GREEN}Telegram Group${PLAIN}: https://t.me/misakanetcn                  #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo "#############################################################"
}

statustext(){
    if [[ -n $v4 ]]; then
        echo "-------------------------------------------------------------"
        echo -e "IPv4: $v4  Location: $c4"
        echo -e "WARP Status: $w4  Netfilx Status: $n4"
    fi
    if [[ -n $v6 ]]; then
        echo "-------------------------------------------------------------"
        echo -e "IPv6：$v6  Location：$c6"
        echo -e "WARP Status: $w6  Netfilx Status: $n6"
    fi
    if [[ -n $s5p ]]; then
        echo "-------------------------------------------------------------"
        echo -e "WARP-Cli Proxy Port: $s5p  WARP-Cli Status: $s5"
        if [[ -n $s5i ]]; then
            echo -e "IP: $s5i  Location: $s5c  Netfilx Status: $s5n"
        fi
    fi
    if [[ -n $w5p ]]; then
        echo "-------------------------------------------------------------"
        echo -e "WireProxy Proxy Port: $w5p  WireProxy Status: $w5"
        if [[ -n $w5i ]]; then
            echo -e "IP: $w5i  Location: $w5c  Netfilx Status: $w5n"
        fi
    fi
    echo "-------------------------------------------------------------"
    echo -e ""
}

choice4d(){
    read -rp " 请输入选项 [0-16]:" menuInput
    case "$menuInput" in
        1 ) wgcfmode=0 && install_wgcf ;;
        2 ) wgcfmode=1 && install_wgcf ;;
        3 ) wgcfmode=2 && install_wgcf ;;
        4 ) wgcf_switch ;;
        5 ) uninstall_wgcf ;;
        6 ) install_warpcli ;;
        7 ) change_warpcli_port ;;
        8 ) warpcli_switch ;;
        9 ) uninstall_warpcli ;;
        10 ) install_wireproxy ;;
        11 ) change_wireproxy_port ;;
        12 ) wireproxy_switch ;;
        13 ) uninstall_wireproxy ;;
        14 ) warpup ;;
        15 ) warpsw ;;
        16 ) warpnf ;;
        * ) exit 1 ;;
    esac
}

menu0(){
    clear
    info_bar
    echo -e ""
    echo -e " ${GREEN}1.${PLAIN} Install Wgcf-WARP single-stack mode ${YELLOW}(WARP IPv4 + native IPv6) ${PLAIN}"
    echo -e " ${GREEN}2.${PLAIN} Install Wgcf-WARP single-stack mode ${YELLOW}(WARP IPv6)${PLAIN}"
    echo -e " ${GREEN}3.${PLAIN} Install Wgcf-WARP dual stack mode ${YELLOW}(WARP IPV4 + WARP IPv6) ${PLAIN}"
    echo -e " ${GREEN}4.${PLAIN} Turning Wgcf-WARP on or off"
    echo -e " ${GREEN}5.${PLAIN} ${RED} uninstall Wgcf-WARP${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}6.${PLAIN} Install Wireproxy-WARP Proxy Mode ${YELLOW}(Socks5 WARP)${PLAIN}"
    echo -e " ${GREEN}7.${PLAIN} Modify Wireproxy-WARP proxy mode connection port"
    echo -e " ${GREEN}8.${PLAIN} Turn Wireproxy-WARP proxy mode on or off"
    echo -e " ${GREEN}9.${PLAIN} ${RED} uninstall Wireproxy-WARP proxy mode ${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}10.${PLAIN} Get WARP+ account traffic"
    echo -e " ${GREEN}11.${PLAIN} Switching WARP account types"
    echo -e " ${GREEN}12.${PLAIN} Get unlocked WARP IP for Netflix"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} Exit script"
    echo -e ""
    echo -e "VPS IP characteristics: ${RED} pure IPv6 VPS ${PLAIN}"
    statustext
    read -rp " Please enter options [0-12]:" menu0Input
    case "$menu0Input" in
        1 ) wgcfmode=0 && install_wgcf ;;
        2 ) wgcfmode=1 && install_wgcf ;;
        3 ) wgcfmode=2 && install_wgcf ;;
        4 ) wgcf_switch ;;
        5 ) uninstall_wgcf ;;
        6 ) install_wireproxy ;;
        7 ) change_wireproxy_port ;;
        8 ) wireproxy_switch ;;
        9 ) uninstall_wireproxy ;;
        10 ) warpup ;;
        11 ) warpsw ;;
        12 ) warpnf ;;
        * ) exit 1 ;;
    esac
}

menu1(){
    clear
    info_bar
    echo -e ""
    echo -e " ${GREEN}1.${PLAIN} Install Wgcf-WARP single-stack mode ${YELLOW}(WARP IPv4) ${PLAIN}"
    echo -e " ${GREEN}2.${PLAIN} Install Wgcf-WARP single-stack mode ${YELLOW}(Native IPv4 + WARP IPv6) ${PLAIN}"
    echo -e " ${GREEN}3.${PLAIN} Install Wgcf-WARP Dual Stack mode ${YELLOW}(WARP IPV4 + WARP IPv6) ${PLAIN}"
    echo -e " ${GREEN}4.${PLAIN} Turning Wgcf-WARP on or off"
    echo -e " ${GREEN}5.${PLAIN} ${RED} uninstall Wgcf-WARP${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}6.${PLAIN} Install WARP-Cli proxy mode ${YELLOW}(Socks5 WARP)${PLAIN} ${RED}(only support VPS with AMD64 CPU architecture) ${PLAIN}"
    echo -e " ${GREEN}7.${PLAIN} Modify WARP-Cli proxy mode connection port"
    echo -e " ${GREEN}8.${PLAIN} Turn WARP-Cli proxy mode on or off"
    echo -e " ${GREEN}9.${PLAIN} ${RED} uninstall WARP-Cli proxy mode ${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}10.${PLAIN} Install Wireproxy-WARP proxy mode ${YELLOW}(Socks5 WARP)${PLAIN}"
    echo -e " ${GREEN}11.${PLAIN} Modify Wireproxy-WARP proxy mode connection port"
    echo -e " ${GREEN}12.${PLAIN} Turn Wireproxy-WARP proxy mode on or off"
    echo -e " ${GREEN}13.${PLAIN} ${RED} uninstall Wireproxy-WARP proxy mode ${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}14.${PLAIN} Get WARP+ account traffic"
    echo -e " ${GREEN}15.${PLAIN} Switching WARP account types"
    echo -e " ${GREEN}16.${PLAIN} Get unlocked WARP IP for Netflix"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} Exit script"
    echo -e ""
    echo -e "VPS IP characteristics: ${RED} pure IPv4 VPS ${PLAIN}"
    statustext
    choice4d
}

menu2(){
    clear
    info_bar
    echo -e ""
    echo -e " ${GREEN}1.${PLAIN} Install Wgcf-WARP single-stack mode ${YELLOW}(WARP IPv4 + native IPv6) ${PLAIN}"
    echo -e " ${GREEN}2.${PLAIN} Install Wgcf-WARP Single Stack Mode ${YELLOW}(Native IPv4 + WARP IPv6)${PLAIN}"
    echo -e " ${GREEN}3.${PLAIN} Install Wgcf-WARP Dual Stack mode ${YELLOW}(WARP IPV4 + WARP IPv6) ${PLAIN}"
    echo -e " ${GREEN}4.${PLAIN} Turning Wgcf-WARP on or off"
    echo -e " ${GREEN}5.${PLAIN} ${RED} uninstall Wgcf-WARP${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}6.${PLAIN} Install WARP-Cli proxy mode ${YELLOW}(Socks5 WARP)${PLAIN} ${RED}(only support VPS with AMD64 CPU architecture) ${PLAIN}"
    echo -e " ${GREEN}7.${PLAIN} Modify WARP-Cli proxy mode connection port"
    echo -e " ${GREEN}8.${PLAIN} Turn WARP-Cli proxy mode on or off"
    echo -e " ${GREEN}9.${PLAIN} ${RED} uninstall WARP-Cli proxy mode ${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}10.${PLAIN} Install Wireproxy-WARP proxy mode ${YELLOW}(Socks5 WARP)${PLAIN}"
    echo -e " ${GREEN}11.${PLAIN} Modify Wireproxy-WARP proxy mode connection port"
    echo -e " ${GREEN}12.${PLAIN} Turn Wireproxy-WARP proxy mode on or off"
    echo -e " ${GREEN}13.${PLAIN} ${RED} uninstall Wireproxy-WARP proxy mode ${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}14.${PLAIN} Get WARP+ account traffic"
    echo -e " ${GREEN}15.${PLAIN} Switching WARP account types"
    echo -e " ${GREEN}16.${PLAIN} Get unlocked WARP IP for Netflix"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} Exit script"
    echo -e ""
    echo -e "VPS IP feature: ${RED} native IP dual stack for VPS ${PLAIN}"
    statustext
    choice4d
}

if [[ $# > 0 ]]; then
    # 暂时没开发、以后再说
    case "$1" in
        * ) menu ;;
    esac
else
    menu
fi
