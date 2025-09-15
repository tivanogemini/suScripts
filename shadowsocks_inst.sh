#!/bin/bash

/*Scripts used to install shadowsocks automatically*/
based on https://gfw.report/blog/ss_tutorial/zh/ */

rootAuth() {
	if [ $(id -u) -eq 0]then
		echo "rootAuth passed, continue"
	else
		echo "Please run this script as root"
		exit
	fi
}

envSet(){
	if [ -f eflag]then
		echo "env set done,skip"
	else
		apt update -y && apt upgrade -y
		apt install snap -y 
		apt install jq -y
		snap install core
		snap install shadowsocks-libev --edge
		echo "shadowsocks has been installed\n"
		echo "Start to set ss config file!"
		touch eflag
	fi
}

constVar(){
	port=$(shuf -i 1024-65536 -n 1)
	passwd=$(openssl rand -base64 16)
	publicIP=$(curl ipinfo.io/ip -s)
	ipinfo_data=$(curl -s http://ipinfo.io/$public_ip/json)
	country=$(jq -r '.country' <<< "$ipinfo_data")
	isp=$(jq -r '.org' <<< "$ipinfo_data")
	
	if [[ "$isp" == *"Google"* ]]; then
		isp="GCP"
	elif [[ "$isp" == *"Oracle"* ]]; then
		isp="Oracle"
	elif [[ "$isp" == *"Linode"* ]]; then
		isp="Linode"
	elif [[ "$isp" == *"DigitalOcean"* ]]; then
		isp="DigitalOcean"
  	elif [[ "$isp" == *"Amazon"* ]]; then
		isp="AWS"
	elif [[ "$isp" == *"Alibaba"* ]]; then
		isp="Ali"
	else
		isp="Unknown"
	fi
}

genConf(){
sleep 5
cat<<EOF>/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json
{
	"server":["::0","0.0.0.0"],
	"server_port":$port,
	"password":"$passwd",
	"method":"chacha20-ietf-poly1305",
	"mode":"tcp_and_udp",
	"fast_open":false
}
EOF
}

startSS(){
	systemctl enable snap.shadowsocks-libev.ss-server-daemon.service
	systemctl start snap.shadowsocks-libev.ss-server-daemon.service
 	systemctl start snap.shadowsocks-libev.ss-server-daemon.service

	echo "service has been started."
	echo -e "Your IP Address:	$public_ip"
	echo -e "Your service port:	$port"
	echo -e "Your passwd:		$passwd"
	tmp=$(echo -n "chacha20-ietf-poly1305:${passwd}@${IPv4}:${port}" | base64 -w0)
	sslink="ss://${tmp}#${isp}_${country}"
	echo -e "Your ss link:	$sslink"
}

main(){
	rootAuth
	envSet
	constVar
	genConf
	startSS
}