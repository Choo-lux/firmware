#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# IP Hexor
hex_ip() {
	if [ -z "${mac_wlan}" ]; then
		let tmp1=0x$(echo $mac_lan | cut -c$1)
	else
		let tmp1=0x$(echo $mac_wlan | cut -c$1)
	fi
	echo $tmp1
}

# Logs messages to the devices flash
log_message() {
	logger "$1"
	echo $1
}

# Define some networking-related variables
if_mesh=$(ifconfig | grep 'wlan0' | sort -r | awk '{ print $1 }' | head -1)
if_lan="eth0"
if_wan="eth0"

mac_lan=$(ifconfig ${if_lan} | grep 'HWaddr' | awk '{ print $5 }')
mac_wan=$(ifconfig br-wan | grep 'HWaddr' | awk '{ print $5 }')
mac_wlan=$(cat /sys/class/ieee80211/phy0/macaddress)
mac_mesh=$(ifconfig ${if_mesh} | grep 'HWaddr' | awk '{ print $5 }')
ip_lan="10.$(hex_ip 13-14).$(hex_ip 16-17).1"
ip_lan_block="10.$(hex_ip 13-14).$(hex_ip 16-17).0"
ip_dhcp=$(ifconfig br-wan | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1 }')
ip_gateway=$(route -n | grep 'UG' | grep 'br-wan' | awk '{ print $2 }' | head -1)

if [ "$(cat /sys/class/net/${if_wan}/carrier)" -eq "1" ]; then
	role="G"
else
	role="R"
fi
