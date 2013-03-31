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

log_message() {
	#echo "$(date) $1" >> /etc/perma.log
	echo $1
}

# Radio Detection
radio_client="radio0"
radio_mesh="radio0"

channel_client=$(uci get wireless.${radio_client}.channel)
channel_mesh=$(uci get wireless.${radio_mesh}.channel)

# Define some networking-related variables
if_mesh=$(ifconfig | grep 'wlan0' | sort -r | awk '{ print $1 }' | head -1)

if [ "$(ifconfig -a | grep 'eth1' | awk '{ print $1 }')" == "eth1" ]; then
	if [ -n "$(grep -F $(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50 | awk '{ print $2 }') "/sbin/wifimesh/flipETH.list")" ]; then
		mac_lan=$(ifconfig eth1 | grep 'HWaddr' | awk '{ print $5 }')
	else
		mac_lan=$(ifconfig eth0 | grep 'HWaddr' | awk '{ print $5 }')
	fi
else
	mac_lan=$(ifconfig eth0 | grep 'HWaddr' | awk '{ print $5 }')
fi

mac_wan=$(ifconfig br-wan | grep 'HWaddr' | awk '{ print $5 }')
mac_wlan=$(cat /sys/class/ieee80211/phy0/macaddress)
mac_mesh=$(ifconfig ${if_mesh} | grep 'HWaddr' | awk '{ print $5 }')
ip_lan="10.$(hex_ip 13-14).$(hex_ip 16-17).1"
ip_lan_block="10.$(hex_ip 13-14).$(hex_ip 16-17).0"
ip_vpn=$(ifconfig | grep 'inet addr:172.16.' | cut -d: -f2 | awk '{ print $1 }')
ip_dhcp=$(ifconfig br-wan | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1 }')
ip_gateway=$(route -n | grep 'UG' | grep 'br-wan' | awk '{ print $2 }')
ssid="wifimesh_$(hex_ip 16-17)"

if [ "$(cat /sys/class/net/$(uci get network.wan.ifname)/carrier)" -eq "1" ]; then
	role="G"
else
	role="R"
fi

# Get the dashboard and upgrade server urls
dashboard_server=$(cat /sbin/wifimesh/dashboard_server.txt)
firmware_server=$(cat /sbin/wifimesh/firmware_server.txt)
firmware_branch=$(cat /sbin/wifimesh/firmware_branch.txt)

# Replace them with the defaults if they are not defined by text files in /sbin/wifimesh
if [ -z "${dashboard_server}" ]; then dashboard_server="dashboard.wifi-mesh.co.nz/"; fi
if [ -z "${firmware_server}" ]; then firmware_server="cdn.wifi-mesh.co.nz/"; fi
if [ -z "${firmware_branch}" ]; then firmware_branch="stable"; fi

# Define version information
package_version=$(cat /sbin/wifimesh/package_version.txt)
kernel_version=$(cat /sbin/wifimesh/kernel_version.txt)
mesh_version=$(opkg list_installed | grep 'ath9k - ' | awk '{ print $3 }' |cut -d + -f 2)