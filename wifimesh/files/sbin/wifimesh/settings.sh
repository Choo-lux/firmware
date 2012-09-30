#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# IP Hexor
hex_ip() {
	let ip=0x$(echo $mac_wan | cut $1)
	echo $ip
}

log_message() {
	echo "$(date) $1" >> /etc/perma.log
	echo $1
}

# Radio Detection
# Client
if [ "$(uci get wireless.radio0.hwmode)" = "11ng" ]; then
	# 2.4 GHz Clients on radio0
	radio_client="radio0"
	radio_client_freq="24"
elif [ "$(uci get wireless.radio1.hwmode)" = "11ng" ]; then
	# 2.4 GHz Clients on radio1
	radio_client="radio1"
	radio_client_freq="24"
elif [ "$(uci get wireless.radio2.hwmode)" = "11ng" ]; then
	# 2.4 GHz Clients on radio2
	radio_client="radio2"
	radio_client_freq="24"
else
	log_message "No Client radio detected."
fi

# note:
# we only support single radio devices for the moment so the next part is commented out

# Mesh
#if [ "$(uci get wireless.radio0.hwmode)" = "11na" ]; then
#	# 5.X GHz Mesh on radio0
#	radio_mesh="radio0"
#	radio_mesh_freq="58"
#elif [ "$(uci get wireless.radio1.hwmode)" = "11na" ]; then
#	# 5.X GHz Mesh on radio1
#	radio_mesh="radio1"
#	radio_mesh_freq="58"
#elif [ "$(uci get wireless.radio2.hwmode)" = "11na" ]; then
#	# 5.X GHz Mesh on radio2
#	radio_mesh="radio2"
#	radio_mesh_freq="58"
#else
#	# No Mesh radio
#	if [ -n "${radio_client}" ]; then
#		# 2.4 GHz Mesh using $radio_client
		radio_mesh="${radio_client}"
		radio_mesh_freq="${radio_client_freq}"
#	else
#		# No radios at all
#		log_message "No Mesh radio detected."
#		echo "No Mesh radio detected."
#	fi
#fi


# Define some networking-related variables
mac_lan=$(ifconfig br-lan | grep 'HWaddr' | awk '{ print $5 }')
mac_wan=$(ifconfig br-wan | grep 'HWaddr' | awk '{ print $5 }')
mac_wlan=$(uci get wireless.radio0.macaddr)
ip="10.$(hex_ip -c13-14).$(hex_ip -c16-17).1"
ip_lan="10.$(hex_ip -c13-14).$(hex_ip -c16-17).1"
ip_dhcp=$(ifconfig br-wan | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1 }')
gateway=$(route -n | grep 'UG' | awk '{ print $2 }')
ssid="wifimesh_$(hex_ip -c16-17)"

# Define version information
fw_ver=$(cat /sbin/wifimesh/version.txt)

mesh_ver=$(opkg list_installed | grep 'ath9k' | awk '{ print $3 }')
temp=$(echo $mesh_ver | tr "+" "\n")
for mesh_ver in $temp; do
	break
done