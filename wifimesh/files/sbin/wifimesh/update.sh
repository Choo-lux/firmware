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


# fix up the passed in variable if there is none
if [ "$1" = "" ]; then
	RR=0
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


echo "Doing a speedtest to /NOWHERE/"
#ntr=$(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -o /dev/null -s -w "%{speed_download}\n" "http://svn.assembla.com/svn/RobinMesh/downloads/firmware/development/speed-test")
#ntr=$(echo $ntr | awk -F '.' '{ print $1 }')
#ntr=$((${ntr}/1024))
ntr="0"
ntr="${ntr}-KB/s"


echo "Doing a ping test"
if [ ! -n "$ip_dhcp" ]; then
	rtt=$(ping -c 5 ${gateway} | tail -1| awk '{print $4}' | cut -d '/' -f 2)
	role="R"
else
	rtt=$(ping -c 5 "www.google.com" | tail -1| awk '{print $4}' | cut -d '/' -f 2)
	role="G"
fi


# Saving Request Data
request_data="ip=${ip}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&fw_ver=${fw_ver}&mesh_ver=${mesh_ver}&gateway=${gateway}&ip_internal=${ip_dhcp}&memfree=${memfree}&memtotal=${memtotal}&load=${load}&uptime=${uptime}&NTR=${ntr}&RTT=${rtt}&role=${role}&hops=&nbs=&rssi=&RR=${RR}"

dashboard_protocol="http"
dashboard_server="www.wifi-mesh.com/dashboard/"
dashboard_url="checkin-wm.php"
url="${dashboard_protocol}://${dashboard_server}${dashboard_url}"

echo "----------------------------------------------------------------"
echo "Sending data:"
echo "$url?$request_data"

curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s "-d ${request_data}" "${url}" > $response_file

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
echo "${ip} my.wifi-mesh.com my.robin-mesh.com my.open-mesh.com node chilli" >> /etc/hosts

cat $response_file | while read line ; do
	one=$(echo $line | awk '{print $1}')
	two=$(echo $line | awk '{print $2}')
	
	echo "$one=$two"
	
	if [ "$one" = "system.ssh.key" ]; then
		curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s -o /etc/dropbear/authorized_keys "$two"
	elif [ "$one" = "system.ssh.password" ]; then
		(echo -n $two && sleep 1 && echo -n $two) | passwd root
	elif [ "$one" = "system.hostname" ]; then
		uci set system.@system[0].hostname="$two"
	elif [ "$one" = "system.command" ]; then
		curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s -o /tmp/command.sh "$two"
		chmod +x /tmp/command.sh
		/tmp/command.sh
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
			# configure the wifi interface to use the wan
			uci set wireless.@wifi-iface[1].network="lan"
			
			# get the page to use as the splash page
			curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -o "/etc/chilli/www/coova.html" "${url}?ip=${ip}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&action=coova-html"
			
			# get the logo to use on the splash page
			curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -o "/etc/chilli/www/coova.jpg" "${url}?ip=${ip}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&action=coova-logo"
			
			# do start coova on boot
			/etc/init.d/chilli enable
		else
			# configure the wifi interface to use the wan
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
	
	# Filtering
	elif [ "$one" = "system.filtering.ads" ]; then
		echo $(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k $two) >> /etc/hosts
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
logger "update: Successfully applied new settings, rebooting..."

reboot