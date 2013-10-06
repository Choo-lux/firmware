#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Creates temporary directory if it doesn't already exist
if [ ! -d "/tmp/checkin" ]; then mkdir /tmp/checkin; fi

# Wipes out previous configuration updates from dashboard
echo "" > /tmp/checkin_request.txt

echo "WiFi Mesh Dashboard Checker"
echo "----------------------------------------------------------------"

# Check that we are allowed to use this
if [ "$(uci get wifimesh.dashboard.enabled)" -eq 0 ]; then
	echo "This script is disabled, exiting..."
	exit
fi

log_message "Waiting a bit..."
sleep $(head -30 /dev/urandom | tr -dc "0123456789" | head -c1)

# If the node has no configuration, say that we need it
if [ "$(uci get wireless.@wifi-iface[1].ssid)" = "wifimesh" ]; then
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

# For WiFiRUSH
if [ $(grep 'wificpa_enterprise' /etc/chilli/defaults) ]; then
	echo "Performing captive portal heartbeat"

	cpmac_lan=$(ifconfig br-lan | awk '/HWaddr/ {print $5}')
	cpmac_wlan=$(ifconfig wlan0 | awk '/HWaddr/ {print $5}')
	cpmac_wan=${mac_wan}
	cpip_wan=${ip_dhcp}
	machine=$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50 | awk '{ print $2 }')
	cpfw_ver=$(uci get wifimesh.system.version)
	nasid=$(grep HS_RADIUSNASID /etc/chilli/defaults | awk -F'HS_RADIUSNASID=' '/HS_RADIUSNASID/ {print $2}' | sed s/\"//g)
	uamserver=$(grep HS_UAMSERVER= /etc/chilli/defaults | awk -F'HS_UAMSERVER=' '/HS_UAMSERVER/ {print $2}' | sed s/\"//g | sed '1!d')

	curl -s "http://"$uamserver"/WiFi-CPA/ControlPanel/heartbeat.php?router_name=$(uci get system.@system[0].hostname | sed "s/ /+/g")&nasid="$nasid"&wan_ip=$cpip_wan&wan_ssid="$(uci get wireless.@wifi-iface[1].ssid | sed "s/ /+/g")"&mac="$(echo $cpmac_wlan | sed "s/:/-/g")"&wanmac="$(echo $cpmac_wan | sed "s/:/-/g")"&lanmac="$(echo $cpmac_lan | sed "s/:/-/g")"&model="$machine"&ver="$cpfw_ver"&node_type=mesh" -o /dev/null
fi

echo "Obtaining CoovaChilli client data"
if [ -n "$(ps | grep '[c]hilli')" ]; then
	if [ -e "/tmp/chilli_clients" ]; then rm /tmp/chilli_clients; fi
	chilli_query list | while read record ; do
		mac_address=$(echo $record | awk '{print $1}'|sed y/-/:/ |tr A-Z a-z)
		ip_address=$(echo $record | awk '{print $2}')
		token=$(echo $record | awk '{print $4}')
		status=$(echo $record | awk '{print $5}')
		user_name=$(echo $record | awk '{print $6}')
		
		kb_down=$(echo $record | awk '{print $9}' |tr '/' ' ' |awk 'OFMT = "%.0f" {print ($1 / 1024)}')
		kb_up=$(echo $record | awk '{print $10}' |tr '/' ' ' |awk 'OFMT = "%.0f" {print ($1 / 1024)}')
		kb_total=$(echo $kb_up $kb_down |awk '{print ($1 + $2)}')
		
		record=";${kb_total},${kb_down},${kb_up},${mac_address},${user_name},${ip_address},${token},${status}"
		echo $record >> /tmp/chilli_clients
		
		tot_kb_up=$(echo $tot_kb_up $kb_up |awk '{print ($1 + $2)}')
		tot_kb_down=$(echo $tot_kb_down $kb_down |awk '{print ($1 + $2)}')
	done
fi
if [ -e "/tmp/chilli_clients" ]; then
	top_users=$(cat /tmp/chilli_clients)
	top_users=$(echo $top_users | sed 's/ //g')
else
	top_users=""
fi

echo "Acquiring routing information"
echo "" > /tmp/checkin/rank
echo "" > /tmp/checkin/nbs
echo "" > /tmp/checkin/rssi
echo "" > /tmp/checkin/ntr

iw ${if_mesh} mpath dump | grep -v '00:00:00:00:00:00' | tail -n +2 | while read line; do
	echo $(echo $line | awk '{ print $5 }' | sed 's/ /,/g')";" >> /tmp/checkin/rank
	echo $(echo $line | awk '{ print $1,$2 }' | sed 's/ /,/g')";" >> /tmp/checkin/nbs
	echo $(iw ${if_mesh} station get $(echo $line | awk '{ print $2 }') | grep 'signal:' | awk '{ print $2 }')";" >> /tmp/checkin/rssi
	echo $(iw ${if_mesh} station get $(echo $line | awk '{ print $2 }') | grep 'tx bitrate:' | awk '{ print $3 }')";" >> /tmp/checkin/ntr
done

rank=$(cat /tmp/checkin/rank | tr '\n' ' ' | sed 's/ //g')
nbs=$(cat /tmp/checkin/nbs | tr '\n' ' ' | sed 's/ //g')
rssi=$(cat /tmp/checkin/rssi | tr '\n' ' ' | sed 's/ //g')
ntr=$(cat /tmp/checkin/ntr | tr '\n' ' ' | sed 's/ //g')

radio_channel=$(uci get wireless.radio0.channel)

echo "Doing a ping test"
rtt_internal=$(ping -c 2 ${ip_gateway} | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
rtt_external=$(ping -c 2 $(uci get wifimesh.ping.server) | tail -1 | awk '{print $4}' | cut -d '/' -f 2)

echo "Checking the noise levels"
echo "" > /tmp/noise.tmp
iw wlan0 survey dump | while read line; do
	if [ "$(echo $line | grep 'frequency')" ]; then
		echo ";$(echo $line | awk '{ print $2 }')," >> /tmp/noise.tmp
	elif [ "$(echo $line | grep 'noise')" ]; then
		echo $(echo $line | awk '{ print $2 }') >> /tmp/noise.tmp
	fi
done
noise=$(cat /tmp/noise.tmp | tr '\n' ' ' | sed 's/ //g')

echo "Getting the model information"
model_cpu=$(uci get wifimesh.system.cpu)
model_device=$(uci get wifimesh.system.device)

# Saving Request Data
url_data="ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&mac_mesh=${mac_mesh}&fw_ver=$(uci get wifimesh.system.version)&model_cpu=${model_cpu}&model_device=${model_device}&gateway=${ip_gateway}&ip_internal=${ip_dhcp}&memfree=${memfree}&memtotal=${memtotal}&load=${load}&uptime=${uptime}&rtt_internal=${rtt_internal}&rtt_external=${rtt_external}&rank=${rank}&nbs=${nbs}&rssi=${rssi}&ntr=${ntr}&noise=${noise}&top_users=${top_users}&role=${role}&channel_client=${radio_channel}&RR=${RR}"

if [ "$(uci get wifimesh.dashboard.https)" -eq 1 ]; then
	url="https://$(uci get wifimesh.dashboard.server)/checkin-wm.php?${url_data}"
else
	url="http://$(uci get wifimesh.dashboard.server)/checkin-wm.php?${url_data}"
fi

echo "----------------------------------------------------------------"
echo "Sending data:"
echo "$url"

curl -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" -k -s -o /tmp/checkin_request.txt "${url}" > /dev/null
curl_result=$?

if [ "${curl_result}" -eq 0 ]; then
	echo "Checked in to the dashboard successfully,"
	
	if grep -q "." /tmp/checkin_request.txt; then
		echo "we have new settings to apply!"
	else
		echo "we will maintain the existing settings."
		exit
	fi
else
	log_message "WARNING: Could not checkin to the dashboard."
	exit
fi


echo "----------------------------------------------------------------"
echo "Applying settings"

cat /tmp/checkin_request.txt | while read line ; do
	one=$(echo $line | awk '{print $1}')
	two=$(echo $line | awk '{print $2}')
	
	echo "$one=$two"
	
	if [ "$one" = "system.ssh.key" ]; then
		curl -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" -k -s -o /etc/dropbear/authorized_keys "$two"
	elif [ "$one" = "system.ssh.password" ]; then
		echo -e "$two\n$two" | passwd root
	elif [ "$one" = "system.hostname" ]; then
		uci set system.@system[0].hostname="$two"
	elif [ "$one" = "servers.ntp.server" ]; then
		uci set system.ntp.server="$two"
	elif [ "$one" = "servers.ntp.timezone" ]; then
		uci set system.@system[0].timezone="$two"
	elif [ "$one" = "servers.firmware.url" ]; then
		uci set wifimesh.firmware.server="$two"
	elif [ "$one" = "servers.firmware.branch" ]; then
		uci set wifimesh.firmware.branch="$two"
	elif [ "$one" = "servers.dashboard.url" ]; then
		uci set wifimesh.dashboard.server="$two"
	elif [ "$one" = "servers.ping.url" ]; then
		uci set wifimesh.ping.server="$two"
	
	# SSID #1 (formerly Public SSID)
	elif [ "$one" = "network.ssid1.enabled" ]; then
		if [ "$two" == "1" ]; then
			if [ -z "$(uci get wireless.@wifi-iface[1])" ]; then uci add wireless wifi-iface; fi
			uci set wireless.@wifi-iface[1].network="wan"
			uci set wireless.@wifi-iface[1].mode="ap"
			uci set wireless.@wifi-iface[1].device="radio0"
		else
			uci delete wireless.@wifi-iface[1]
		fi
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
			uci set wifimesh.captive_portal.enabled_lan="1"
			uci set wifimesh.captive_portal.enabled_wlan="1"
			
			# change to use the LAN
			uci set wireless.@wifi-iface[1].network="lan"
			
			# get the config to use for chilli
			echo "" > /tmp/dns.tmp
			cat /tmp/resolv.conf.auto | awk '/wan/ {seen = 1} seen {print}' | grep 'nameserver' | while read line; do
				line=$(echo $line | awk '{ print $2 }')
				
				if [ -z $dns1 ] ; then
					echo "&dns1=${line}" >> /tmp/dns.tmp
					dns1=1
				elif [ -z $dns2 ]; then
					echo "&dns2=${line}" >> /tmp/dns.tmp
					dns2=1
				fi
			done
			curl -s -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/defaults" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-config&$(sed ':a;N;$!ba;s/\n//g' /tmp/dns.tmp)&dnsname=$(cat /tmp/resolv.conf.auto | awk '/wan/ {seen = 1} seen {print}' | grep 'search' | awk '{ print $2 }')"
			
			# get the page to use as the splash page
			curl -s -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/www/coova.html" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-html"
			
			# get the logo to use on the splash page
			curl -s -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/www/coova.jpg" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-logo"
			
			# start coovachilli at boot
			/etc/init.d/chilli enable
			
			# forces DNS for coova clients
			uci set network.lan.dns="$(grep 'DNS1' /etc/chilli/defaults | cut -d = -f 2) $(grep 'DNS2' /etc/chilli/defaults | cut -d = -f 2)"
		else
			uci set wifimesh.captive_portal.enabled_lan="0"
			uci set wifimesh.captive_portal.enabled_wlan="0"
			
			# change to use the LAN
			uci set wireless.@wifi-iface[1].network="wan"
			
			# stop coovachilli at boot
			/etc/init.d/chilli disable
		fi
	
	# SSID #2 (formerly Private SSID)
	elif [ "$one" = "network.ssid2.enabled" ]; then
		if [ "$two" == "1" ]; then
			if [ -z "$(uci get wireless.@wifi-iface[2])" ]; then uci add wireless wifi-iface; fi
			uci set wireless.@wifi-iface[2].network="wan"
			uci set wireless.@wifi-iface[2].mode="ap"
			uci set wireless.@wifi-iface[2].device="radio0"
		else
			uci delete wireless.@wifi-iface[2]
		fi
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
		if [ "$two" == "1" ]; then
			if [ -z "$(uci get wireless.@wifi-iface[3])" ]; then uci add wireless wifi-iface; fi
			uci set wireless.@wifi-iface[3].network="wan"
			uci set wireless.@wifi-iface[3].mode="ap"
			uci set wireless.@wifi-iface[3].device="radio0"
		else
			uci delete wireless.@wifi-iface[3]
		fi
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
		if [ "$two" == "1" ]; then
			if [ -z "$(uci get wireless.@wifi-iface[4])" ]; then uci add wireless wifi-iface; fi
			uci set wireless.@wifi-iface[4].network="wan"
			uci set wireless.@wifi-iface[4].mode="ap"
			uci set wireless.@wifi-iface[4].device="radio0"
		else
			uci delete wireless.@wifi-iface[4]
		fi
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
		uci set wireless.radio0.channel=$two
	elif [ "$one" = "network.client.txpower" ]; then
		uci set wireless.radio0.txpower=$two
	elif [ "$one" = "network.distance" ]; then
		uci set wireless.radio0.distance=$two
	elif [ "$one" = "network.country" ]; then
		uci set wireless.radio0.country=$two
	
	# LAN Block
	elif [ "$one" = "network.lan.block" ]; then
		if [ "$two" == "1" ]; then
			iptables -I FORWARD -s ${ip_lan_block}/24 -d 172.16.0.0/12 -j DROP
			iptables -I FORWARD -s ${ip_lan_block}/24 -d 192.168.0.0/16 -j DROP
			iptables -I FORWARD -s ${ip_lan_block}/24 -d ${ip_gateway} -j DROP
			
			iptables -I FORWARD -p tcp --source-port 22 -j ACCEPT
			iptables -I FORWARD -p udp --destination-port 67:68 --source-port 67:68 -j ACCEPT
			iptables -I FORWARD -p udp --destination-port 53 -j ACCEPT
			iptables -I FORWARD -p tcp --destination-port 53 -j ACCEPT
			
			iptables -I FORWARD -i br-wan -d ${ip_dhcp} -j ACCEPT
			iptables -I FORWARD -i br-wan -p udp --destination-port 53 -j ACCEPT
			iptables -I FORWARD -i br-wan -p tcp --destination-port 53 -j ACCEPT
			
			iptables-save
		else
			iptables -D FORWARD -s ${ip_lan_block}/24 -d 172.16.0.0/12 -j DROP
			iptables -D FORWARD -s ${ip_lan_block}/24 -d 192.168.0.0/16 -j DROP
			iptables -D FORWARD -s ${ip_lan_block}/24 -d ${ip_gateway} -j DROP
			
			iptables -D FORWARD -p tcp --source-port 22 -j ACCEPT
			iptables -D FORWARD -p udp --destination-port 67:68 --source-port 67:68 -j ACCEPT
			iptables -D FORWARD -p udp --destination-port 53 -j ACCEPT
			iptables -D FORWARD -p tcp --destination-port 53 -j ACCEPT
			
			iptables -D FORWARD -i br-wan -d ${ip_dhcp} -j ACCEPT
			iptables -D FORWARD -i br-wan -p udp --destination-port 53 -j ACCEPT
			iptables -D FORWARD -i br-wan -p tcp --destination-port 53 -j ACCEPT
			
			iptables-save
		fi
	fi
done

# Save all of that
uci commit

echo "----------------------------------------------------------------"
echo "Successfully applied new settings"

log_message "update: Successfully applied new settings, rebooting..."
sleep 1
reboot
