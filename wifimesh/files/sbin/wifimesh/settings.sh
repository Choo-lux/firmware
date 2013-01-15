#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# IP Hexor
hex_ip() {
	if [ -z "${mac_wlan}" ]; then
		let tmp1=0x$(echo $mac_lan | cut $1)
	else
		let tmp1=0x$(echo $mac_wlan | cut $1)
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

# Define some networking-related variables
mac_lan=$(ifconfig eth0 | grep 'HWaddr' | awk '{ print $5 }')
mac_wan=$(ifconfig br-wan | grep 'HWaddr' | awk '{ print $5 }')
mac_wlan=$(cat /sys/class/ieee80211/phy0/macaddress)
ip_lan="10.$(hex_ip -c13-14).$(hex_ip -c16-17).1"
ip_dhcp=$(ifconfig br-wan | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1 }')
ip_gateway=$(route -n | grep 'UG' | awk '{ print $2 }')
ssid="wifimesh_$(hex_ip -c16-17)"

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