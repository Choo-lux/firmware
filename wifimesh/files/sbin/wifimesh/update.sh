#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
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

# For WiFiRUSH
if [ $(grep 'wificpa_enterprise' /etc/chilli/defaults) ]; then
	echo "Performing captive portal heartbeat"

	cpmac_lan=$(ifconfig br-lan | awk '/HWaddr/ {print $5}')
	cpmac_wlan=$(ifconfig wlan0 | awk '/HWaddr/ {print $5}')
	cpmac_wan=${mac_wan}
	cpip_wan=${ip_dhcp}
	machine=$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50 | awk '{ print $2 }')
	cpfw_ver=${package_version}
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
echo "" > /tmp/checkin/speed

iw ${if_mesh} mpath dump | tail -n +2 | while read line; do
	echo $(echo $line | awk '{ print $5 }' | sed 's/ /,/g')";" >> /tmp/checkin/rank
	echo $(echo $line | awk '{ print $1,$2 }' | sed 's/ /,/g')";" >> /tmp/checkin/nbs
	echo $(iw ${if_mesh} station get $(echo $line | awk '{ print $2 }') | grep 'signal:' | awk '{ print $2 }')";" >> /tmp/checkin/rssi
	echo $(iw ${if_mesh} station get $(echo $line | awk '{ print $2 }') | grep 'tx bitrate:' | awk '{ print $3 }')";" >> /tmp/checkin/speed
done

rank=$(cat /tmp/checkin/rank | tr '\n' ' ' | sed 's/ //g')
nbs=$(cat /tmp/checkin/nbs | tr '\n' ' ' | sed 's/ //g')
rssi=$(cat /tmp/checkin/rssi | tr '\n' ' ' | sed 's/ //g')
speed=$(cat /tmp/checkin/speed | tr '\n' ' ' | sed 's/ //g')

echo "Doing a ping test"
rtt_internal=$(ping -c 2 ${ip_gateway} | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
rtt_external=$(ping -c 2 "cdn.wifi-mesh.co.nz" | tail -1 | awk '{print $4}' | cut -d '/' -f 2)

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
model_cpu=$(cat /proc/cpuinfo | grep 'system type' | cut -f2 -d ":" | cut -b 2-50 | awk '{ print $2 }')
model_device=$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50 | tr ' ' '+')

# Saving Request Data
request_data="ip=${ip_lan}&ip_vpn=${ip_vpn}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&mac_mesh=${mac_mesh}&fw_ver=${package_version}&model_cpu=${model_cpu}&model_device=${model_device}&gateway=${ip_gateway}&ip_internal=${ip_dhcp}&memfree=${memfree}&memtotal=${memtotal}&load=${load}&uptime=${uptime}&rtt_internal=${rtt_internal}&rtt_external=${rtt_external}&rank=${rank}&nbs=${nbs}&rssi=${rssi}&NTR=${speed}&noise=${noise}&top_users=${top_users}&role=${role}&channel_client=${channel_client}&channel_mesh=${channel_mesh}&RR=${RR}"

dashboard_protocol="http"
dashboard_url="checkin-wm.php"
url="${dashboard_protocol}://${dashboard_server}${dashboard_url}?${request_data}"

echo "----------------------------------------------------------------"
echo "Sending data:"
echo "$url"

curl -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -k -s "${url}" > $response_file
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

# define the coova flag
echo "0" > /tmp/coova_flag
echo "0" > /tmp/reboot_flag
echo "0" > /tmp/lanifbr_flag

cat $response_file | while read line ; do
	one=$(echo $line | awk '{print $1}')
	two=$(echo $line | awk '{print $2}')
	
	echo "$one=$two"
	
	if [ "$one" = "system.ssh.key" ]; then
		curl -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -k -s -o /etc/dropbear/authorized_keys "$two"
	elif [ "$one" = "system.ssh.password" ]; then
		echo -e "$two\n$two" | passwd root
		echo "/cgi-bin/:admin:$two" > /etc/httpd.conf
	elif [ "$one" = "system.hostname" ]; then
		uci set system.@system[0].hostname="$two"
	elif [ "$one" = "system.reboot" ]; then
		echo $two > /tmp/reboot_flag
	elif [ "$one" = "system.firmware.branch" ]; then
		echo "$two" > /sbin/wifimesh/firmware_branch.txt
	elif [ "$one" = "servers.ntp.server" ]; then
		uci set system.ntp.server="$two"
	elif [ "$one" = "servers.ntp.timezone" ]; then
		uci set system.@system[0].timezone="$two"
	elif [ "$one" = "servers.dns.domain" ]; then
		uci set dhcp.@dnsmasq[0].domain="$two"
	elif [ "$one" = "servers.firmware.url" ]; then
		echo "$two" > /sbin/wifimesh/firmware_server.txt
	elif [ "$one" = "servers.firmware.branch" ]; then
		echo "$two" > /sbin/wifimesh/firmware_branch.txt
	elif [ "$one" = "servers.dashboard.url" ]; then
		echo "$two" > /sbin/wifimesh/dashboard_server.txt
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
			curl -s -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/defaults" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-config&$(sed ':a;N;$!ba;s/\n//g' /tmp/dns.tmp)&dnsname=$(cat /tmp/resolv.conf.auto | awk '/wan/ {seen = 1} seen {print}' | grep 'search' | awk '{ print $2 }')"
			
			# get the page to use as the splash page
			curl -s -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/www/coova.html" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-html"
			
			# get the logo to use on the splash page
			curl -s -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -o "/etc/chilli/www/coova.jpg" "${url}?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-logo"
			
			# restarts coovachilli
			/etc/init.d/chilli enable
			echo "1" > /tmp/coova_flag
			
			# forces DNS for coova clients
			uci set network.lan.dns="$(grep 'DNS1' /etc/chilli/defaults | cut -d = -f 2) $(grep 'DNS2' /etc/chilli/defaults | cut -d = -f 2)"
		else
			# change to use the LAN
			uci set wireless.@wifi-iface[1].network="wan"
			
			# stops coovachilli
			/etc/init.d/chilli disable
			echo "2" > /tmp/coova_flag
			
			# If there are more that one adapter, move any LAN bridged adpter to the WAN.
			if [ "$(ifconfig -a | grep 'eth1' | awk '{ print $1 }')" == "eth1" ]; then
				echo "2" > /tmp/lanifbr_flag
			fi
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
		uci set wireless.${radio_client}.channel=$two
	elif [ "$one" = "network.mesh.channel" ]; then
		uci set wireless.${radio_mesh}.channel=$two
	elif [ "$one" = "network.client.txpower" ]; then
		uci set wireless.${radio_client}.txpower=$two
	elif [ "$one" = "network.mesh.txpower" ]; then
		uci set wireless.${radio_mesh}.txpower=$two
	elif [ "$one" = "network.distance" ]; then
		uci set wireless.${radio_mesh}.distance=$two
	elif [ "$one" = "network.country" ]; then
		uci set wireless.${radio_client}.country=$two
		uci set wireless.${radio_mesh}.country=$two
	
	elif [ "$one" = "network.channel.client" ]; then
		uci set wireless.radio0.channel=$two
	
	elif [ "$one" = "network.vpn.enabled" ]; then
		uci set openvpn.sample_client.enabled=$two
	elif [ "$one" = "network.vpn.server" ]; then
		uci set openvpn.sample_client.remote=$two
	elif [ "$one" = "network.vpn.key" ]; then
		curl -s -k -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" $two > /etc/openvpn/client.key
	elif [ "$one" = "network.vpn.certificate" ]; then
		curl -s -k -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" $two > /etc/openvpn/client.crt
	elif [ "$one" = "network.vpn.ca" ]; then
		curl -s -k -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" $two > /etc/openvpn/ca.crt
	
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

# Restart all of the services
/etc/init.d/network restart
/etc/init.d/openvpn restart

if [ $(cat /tmp/coova_flag) -eq 1 ]; then
	echo "restarting coovachilli"
	/etc/init.d/chilli stop
	sleep 5
	/etc/init.d/chilli start
elif [ $(cat /tmp/coova_flag) -eq 2 ]; then
	echo "stopping coovachilli"
	/etc/init.d/chilli stop
fi

if [ $(cat /tmp/lanifbr_flag) -eq 2 ]; then
	echo "moving interface: $(uci get network.lan.ifname) to the WAN"
	brctl delif br-lan $(uci get network.lan.ifname) && brctl addif br-wan $(uci get network.lan.ifname)	
fi

if [ "$(brctl show | grep br-wan | awk '{print $3}')" = "no" ]; then
	echo "stp is is disabled on the WAN, enable stp"
	# Enable stp on the wan bridge
	sleep 1 && brctl stp br-wan on
fi

if [ $(cat /tmp/reboot_flag) -eq 1 ]; then
	echo "restarting the node"
	reboot
fi

# Clear out the old files
if [ -e $status_file ]; then rm $status_file; fi
if [ -e $response_file ]; then rm $response_file; fi
if [ -e $temp_file ]; then rm $temp_file; fi

echo "----------------------------------------------------------------"
echo "Successfully applied new settings"

log_message "update: Successfully applied new settings"
