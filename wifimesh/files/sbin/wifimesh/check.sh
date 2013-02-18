#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

change_mesh_channel() {
	# Change channels to the one sent to this function
	uci set wireless.radio0.channel="$1"
	uci commit wireless
	wifi
	
	# Wait a little bit for the mesh to initialise
	sleep 10
	
	if [ -z "$(iw wlan0-4 mpath dump | grep '0x')" == "true" ]; then
		# We have mesh routes now, we can connect to the dashboard to make sure that this is the correct channel
		curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.co.nz/)" -k -s "http://${dashboard_server}checkin-wm.php?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&mac_mesh=${mac_mesh}&action=channel-config" > /tmp/checkin/orphan_channel
		curl_result=$?
		curl_data=$(cat /tmp/checkin/orphan_channel)
		
		if [ "$curl_result" -eq "0" ]; then
			uci set wireless.radio0.channel="${curl_data}"
			uci commit wireless
			wifi
		fi
		
		# Say that all is well
		echo "true"
	else
		# Nope, it's not this channel
		echo "false"
	fi
}

echo "WiFi Mesh Connection Checker"
echo "----------------------------------------------------------------"

# Checks mesh connectivity if the node is a repeater (to make sure it hasn't been orphaned)
if [ "${role}" == "R" ]; then
	if [ -z "$(iw wlan0-4 mpath dump | grep '0x')" ]; then
		crontab -r
		log_message "check: orphan: we have an orphaned node, checking channels!"

		if [ "$(change_mesh_channel 1)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 1"
		elif [ "$(change_mesh_channel 5)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 5"
		elif [ "$(change_mesh_channel 6)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 6"
		elif [ "$(change_mesh_channel 11)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 11"
		elif [ "$(change_mesh_channel 2)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 2"
		elif [ "$(change_mesh_channel 3)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 3"
		elif [ "$(change_mesh_channel 4)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 4"
		elif [ "$(change_mesh_channel 7)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 7"
		elif [ "$(change_mesh_channel 8)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 8"
		elif [ "$(change_mesh_channel 9)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 9"
		elif [ "$(change_mesh_channel 10)" == "true" ]; then
			log_message "check: orphan: found neighbours on channel 10"
		else
			log_message "check: orphan: WARNING: could not recover orphan node!"
		fi
	fi
fi

# Chucks out any bad mesh paths that may be added from time to time
iw wlan0-4 mpath dump | grep '00:00:00:00:00:00' | while read line; do
	iw wlan0-4 mpath del $(echo $line | awk '{ print $1 }')
done

# Tests LAN Connectivity
if [ "$(ping -c 2 ${ip_gateway})" ]; then
	lan_status=1
else
	lan_status=0
fi

# Tests WAN Connectivity
if [ "$(ping -c 2 www.google.com)" ]; then
	wan_status=1
else
	wan_status=0
fi

# Tests DNS Connectivity
if [ "$(nslookup www.google.com)" ]; then
	dns_status=1
else
	dns_status=0
fi

# Log that result
log_message "check: LAN: ${lan_status} | WAN: ${wan_status} | DNS: ${dns_status}"