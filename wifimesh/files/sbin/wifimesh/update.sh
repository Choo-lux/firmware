#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

temp_dir="/tmp/checkin"
status_file="$temp_dir/request.txt"
response_file="$temp_dir/response.txt"
temp_file="$temp_dir/tmp"

if [ -e $status_file ]; then rm $status_file; fi
if [ -e $response_file ]; then rm $response_file; fi
if [ -e $temp_file ]; then rm $temp_file; fi
if [ ! -d "$temp_dir" ]; then mkdir $temp_dir; fi


echo "WiFi Mesh Dashboard Checker"
echo "----------------------------------------------------------------"

# If the node has no configuration, say that we need it
if [ "$(uci get wireless.@wifi-iface[1].ssid)" = "${ssid}" ]; then
	RR=1

# If we have not passed in a variable then it is 0
elif [ "$1" = "" ]; then
	RR=0

# Otherwise, work with what we have on hand
else
	RR="$1"
fi

echo "Calculating memory and load averages"
memfree=$(free | grep 'Mem:' | awk '{print $4}')
memtotal=$(free | grep 'Mem:' | awk '{print $2}')
load=$(uptime | awk '{ print $8 $9 $10 }')

timeb=$(grep btime /proc/stat | awk '{print $2'})
timenow=$(date +"%s")

diff=$(expr $timenow - $timeb)
days=$(expr $diff / 86400)
diff=$(expr $diff \% 86400)
hours=$(expr $diff / 3600)
diff=$(expr $diff \% 3600)
min=$(expr $diff / 60)

uptime="${days}d:${hours}h:${min}m"

echo "Doing a ping test"
if [ ! -n "$ip_dhcp" ]; then
	rtt=$(ping -c 5 ${ip_gateway} | tail -1| awk '{print $4}' | cut -d '/' -f 2)
	role="R"
else
	rtt=$(ping -c 5 "www.google.com" | tail -1| awk '{print $4}' | cut -d '/' -f 2)
	role="G"
fi

echo "Performing captive portal heartbeat"
# For WiFiRUSH
if [ $(grep 'wificpa_enterprise' /etc/chilli/defaults) ]; then
	nasid=$(grep HS_RADIUSNASID /etc/chilli/defaults | awk -F'HS_RADIUSNASID=' '/HS_RADIUSNASID/ {print $2}' | sed s/\"//g)
	uamserver=$(grep HS_UAMSERVER= /etc/chilli/defaults | awk -F'HS_UAMSERVER=' '/HS_UAMSERVER/ {print $2}' | sed s/\"//g | sed '1!d')
	
	curl -s "http://"$uamserver"/WiFi-CPA/ControlPanel/heartbeat.php?router_name=$(uci get system.@system[0].hostname | sed "s/ /+/g")&nasid="$nasid"&wan_ip=ToBeDetermined&wan_ssid="$(uci get wireless.@wifi-iface[1].ssid | sed "s/ /+/g")"&mac="$(echo $mac_wlan | sed "s/:/-/g")"&wanmac="$(echo $mac_wan | sed "s/:/-/g")"&lanmac="$(echo $mac_lan | sed "s/:/-/g")"&model=WiFi%20Mesh&ver="$fw_ver"&node_type=G" -o /dev/null
fi

echo "Acquiring link speed"
ntr=$(iw wlan0-4 station get $(iw wlan0-4 mpath dump | grep '0x15' | awk '{ print $1 }') | grep 'tx bit' | awk '{ print $3 }')

# Saving Request Data
request_data="ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&fw_ver=${firmware_version}&mesh_ver=${mesh_version}&gateway=${ip_gateway}&ip_internal=${ip_dhcp}&memfree=${memfree}&memtotal=${memtotal}&load=${load}&uptime=${uptime}&NTR=${ntr}&RTT=${rtt}&role=${role}&hops=&nbs=&rssi=&RR=${RR}"

dashboard_protocol="http"
dashboard_url="checkin-wm.php"
url="${dashboard_protocol}://${dashboard_server}${dashboard_url}"

echo "----------------------------------------------------------------"
echo "Sending data:"
echo "$url?$request_data"

curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -k -s "-d ${request_data}" "${url}" > $response_file

curl_result=$?
curl_data=$(cat $response_file)

if [ "$curl_result" -eq "0" ]; then
	echo "Checked in to the dashboard successfully,"
	
	if grep -q "." $response_file; then
		echo "we have new settings to apply!"
	else
		echo "we will maintain the existing settings."
		exit
	fi
else
	logger "WARNING: Could not checkin to the dashboard."
	echo "WARNING: Could not checkin to the dashboard."
	
	exit
fi


echo "----------------------------------------------------------------"
echo "Applying settings"

# define the hosts file
echo "127.0.0.1 localhost" > /etc/hosts
echo "${ip_lan} my.wifi-mesh.co.nz my.robin-mesh.com my.open-mesh.com node chilli" >> /etc/hosts

cat $response_file | while read line ; do
	one=$(echo $line | awk '{print $1}')
	two=$(echo $line | awk '{print $2}')
	
	echo "$one=$two"
	
	if [ "$one" = "system.ssh.key" ]; then
		curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -k -s -o /etc/dropbear/authorized_keys "$two"
	elif [ "$one" = "system.ssh.password" ]; then
		echo -e "$two\n$two" | passwd root
		echo "/cgi-bin/:admin:$two" > /etc/httpd.conf
	elif [ "$one" = "system.hostname" ]; then
		uci set system.@system[0].hostname="$two"
	elif [ "$one" = "system.firmware.branch" ]; then
		echo "$two" > /sbin/wifimesh/firmware_branch.txt
	elif [ "$one" = "system.command" ]; then
		curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -k -s -o /tmp/command.sh "$two"
		chmod +x /tmp/command.sh
		. /tmp/command.sh
		rm /tmp/command.sh
	elif [ "$one" = "servers.ntp.server" ]; then
		uci set system.ntp.server="$two"
	elif [ "$one" = "servers.ntp.timezone" ]; then
		uci set system.@system[0].timezone="$two"
	elif [ "$one" = "servers.dns.domain" ]; then
		uci set dhcp.@dnsmasq[0].domain="$two"
	
	# SSID #1 (formerly Public SSID)
	elif [ "$one" = "network.ssid1.enabled" ]; then
		uci set wireless.@wifi-iface[1].enabled="$two"
	elif [ "$one" = "network.ssid1.hide" ]; then
		uci set wireless.@wifi-iface[1].hidden="$two"
	elif [ "$one" = "network.ssid1.ssid" ]; then
		two=$(echo $two | sed 's/*/ /g')
		uci set wireless.@wifi-iface[1].ssid="$two"
	elif [ "$one" = "network.ssid1.key" ]; then
		if [ "$two" = "" ]; then
			uci set wireless.@wifi-iface[1].encryption="none"
			uci set wireless.@wifi-iface[1].key=""
		else
			uci set wireless.@wifi-iface[1].encryption="mixed-psk"
			uci set wireless.@wifi-iface[1].key="$two"
		fi
	elif [ "$one" = "network.ssid1.isolate" ]; then
		uci set wireless.@wifi-iface[1].isolate="$two"
	elif [ "$one" = "network.ssid1.captive_portal" ]; then
		if [ "$two" = "1" ]; then
			# change to use the LAN
			uci set wireless.@wifi-iface[1].network="lan"
			
			# get the config to use for chilli
			echo "" > /tmp/dns.tmp
			cat /tmp/resolv.conf.auto | grep 'nameserver' | while read line; do
				line=$(echo $line | awk '{ print $2 }')
				
				if [ -z $dns1 ] ; then
					echo "&dns1=${line}" >> /tmp/dns.tmp
					dns1=1
				elif [ -z $dns2 ]; then
					echo "&dns2=${line}" >> /tmp/dns.tmp
					dns2=1
				fi
			done
			curl -s -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/defaults" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-config&$(sed ':a;N;$!ba;s/\n//g' /tmp/dns.tmp)"
			
			# get the page to use as the splash page
			curl -s -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/www/coova.html" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-html"
			
			# get the logo to use on the splash page
			curl -s -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/www/coova.jpg" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-logo"
			
			# do start coova on boot
			/etc/init.d/chilli enable
		else
			# change to use the LAN
			uci set wireless.@wifi-iface[1].network="wan"
			
			# don't start coova on boot
			/etc/init.d/chilli disable
		fi
	
	# SSID #2 (formerly Private SSID)
	elif [ "$one" = "network.ssid2.enabled" ]; then
		uci set wireless.@wifi-iface[2].enabled="$two"
	elif [ "$one" = "network.ssid2.hide" ]; then
		uci set wireless.@wifi-iface[2].hidden="$two"
	elif [ "$one" = "network.ssid2.ssid" ]; then
		two=$(echo $two | sed 's/*/ /g')
		uci set wireless.@wifi-iface[2].ssid="$two"
	elif [ "$one" = "network.ssid2.key" ]; then
		if [ "$two" = "" ]; then
			uci set wireless.@wifi-iface[2].encryption="none"
			uci set wireless.@wifi-iface[2].key=""
		else
			uci set wireless.@wifi-iface[2].encryption="mixed-psk"
			uci set wireless.@wifi-iface[2].key="$two"
		fi
	elif [ "$one" = "network.ssid2.isolate" ]; then
		uci set wireless.@wifi-iface[2].isolate="$two"
	
	# SSID #3
	elif [ "$one" = "network.ssid3.enabled" ]; then
		uci set wireless.@wifi-iface[3].enabled="$two"
	elif [ "$one" = "network.ssid3.hide" ]; then
		uci set wireless.@wifi-iface[3].hidden="$two"
	elif [ "$one" = "network.ssid3.ssid" ]; then
		two=$(echo $two | sed 's/*/ /g')
		uci set wireless.@wifi-iface[3].ssid="$two"
	elif [ "$one" = "network.ssid3.key" ]; then
		if [ "$two" = "" ]; then
			uci set wireless.@wifi-iface[3].encryption="none"
			uci set wireless.@wifi-iface[3].key=""
		else
			uci set wireless.@wifi-iface[3].encryption="mixed-psk"
			uci set wireless.@wifi-iface[3].key="$two"
		fi
	elif [ "$one" = "network.ssid3.isolate" ]; then
		uci set wireless.@wifi-iface[3].isolate="$two"
	
	# SSID #4
	elif [ "$one" = "network.ssid4.enabled" ]; then
		uci set wireless.@wifi-iface[4].enabled="$two"
	elif [ "$one" = "network.ssid4.hide" ]; then
		uci set wireless.@wifi-iface[4].hidden="$two"
	elif [ "$one" = "network.ssid4.ssid" ]; then
		two=$(echo $two | sed 's/*/ /g')
		uci set wireless.@wifi-iface[4].ssid="$two"
	elif [ "$one" = "network.ssid4.key" ]; then
		if [ "$two" = "" ]; then
			uci set wireless.@wifi-iface[4].encryption="none"
			uci set wireless.@wifi-iface[4].key=""
		else
			uci set wireless.@wifi-iface[4].encryption="mixed-psk"
			uci set wireless.@wifi-iface[4].key="$two"
		fi
	elif [ "$one" = "network.ssid4.isolate" ]; then
		uci set wireless.@wifi-iface[4].isolate="$two"
	
	# Radios
	elif [ "$one" = "network.client.channel" ]; then
		uci set wireless.${radio_client}.channel=$two
	elif [ "$one" = "network.mesh.channel" ]; then
		uci set wireless.${radio_mesh}.channel=$two
	elif [ "$one" = "network.distance" ]; then
		uci set wireless.${radio_mesh}.distance=$two
	elif [ "$one" = "network.country" ]; then
		uci set wireless.${radio_client}.country=$two
		uci set wireless.${radio_mesh}.country=$two

	# WAN configuration
	elif [ "$one" = "network.wan.type" ]; then
		if [ "$two" = "dhcp" ]; then
			uci set network.wan.proto="dhcp"
			uci set network.wan.ipaddr=""
			uci set network.wan.netmask=""
			uci set network.wan.dns=""
			uci set network.wan.gateway=""
		else
			uci set network.wan.proto="static"
		fi
	elif [ "$one" = "network.wan.ip" ]; then
		uci set network.wan.ipaddr=$two
	elif [ "$one" = "network.wan.subnet" ]; then
		uci set network.wan.netmask=$two
	elif [ "$one" = "network.wan.gateway" ]; then
		uci set network.wan.gateway=$two
	elif [ "$one" = "network.wan.dns" ]; then
		uci set network.wan.dns=$two
	
	# Filtering
	elif [ "$one" = "system.filtering.ads" ]; then
		echo $(curl -s -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -k $two) >> /etc/hosts
	#elif [ "$one" = "system.filtering.torrents" ]; then
		#
	elif [ "$one" = "system.filtering.dns" ]; then
		echo "${two} guide.opendns.com" >> /etc/hosts
		echo "${two} hit-nxdomain.opendns.com" >> /etc/hosts
		echo "${two} block.opendns.com" >> /etc/hosts
		echo "${two} block.a.opendns.com" >> /etc/hosts
	fi
done

# Save all of that
uci commit

# Clear out the old files
if [ -e $status_file ]; then rm $status_file; fi
if [ -e $response_file ]; then rm $response_file; fi
if [ -e $temp_file ]; then rm $temp_file; fi

echo "----------------------------------------------------------------"
echo "Successfully applied new settings, rebooting..."

log_message "update: Successfully applied new settings, rebooting..."

reboot