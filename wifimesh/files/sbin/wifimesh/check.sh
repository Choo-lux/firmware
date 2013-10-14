#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

echo "WiFi Mesh Connection Checker"
echo "----------------------------------------------------------------"

# Check that we are allowed to use this
if [ "$(uci get wifimesh.ping.enabled)" -eq 0 ]; then
	echo "This script is disabled, exiting..."
	exit
fi

# Define the default status
bad_status="0"

# Deletes any bad mesh paths that may occur from time to time
iw ${if_mesh} mpath dump | grep '00:00:00:00:00:00' | while read line; do
	iw ${if_mesh} mpath del $(echo $line | awk '{ print $1 }')
done

# Tests LAN Connectivity
if [ "$(ping -c 2 ${ip_gateway})" ]; then
	lan_status=1
else
	bad_status=1
	lan_status=0
fi

# Tests WAN Connectivity
if [ "$(ping -c 2 $(uci get wifimesh.ping.server))" ]; then
	wan_status=1
else
	bad_status=1
	wan_status=0
fi

# Tests DNS Connectivity
nslookup $(uci get wifimesh.ping.server) > /dev/null
dns_temp=$?

if [ "${dns_temp}" -eq 0 ]; then
	dns_status=1
else
	bad_status=1
	dns_status=0
fi

# Use the LEDs
if [ "${bad_status}" -eq 1 ]; then
	if [ "$(cat /tmp/sysinfo/board_name)" = "bullet-m" ]; then
		echo 0 > /sys/class/leds/ubnt:green:link4/brightness
		echo 0 > /sys/class/leds/ubnt:green:link3/brightness
		echo 0 > /sys/class/leds/ubnt:orange:link2/brightness
		echo 0 > /sys/class/leds/ubnt:red:link1/brightness
		echo "timer" > /sys/class/leds/ubnt:red:link1/trigger
		echo 5000 > /sys/class/leds/ubnt:red:link1/delay_on
		echo 1000 > /sys/class/leds/ubnt:red:link1/delay_off
	elif [ "$(cat /tmp/sysinfo/board_name)" = "om2p" ]; then
		echo 0 > /sys/class/leds/om2p:green:wifi/brightness
		echo 0 > /sys/class/leds/om2p:yellow:wifi/brightness
		echo 0 > /sys/class/leds/om2p:red:wifi/brightness
		echo "timer" > /sys/class/leds/om2p:red:wifi/trigger
		echo 5000 > /sys/class/leds/om2p:red:wifi/delay_on
		echo 1000 > /sys/class/leds/om2p:red:wifi/delay_off
	fi
else
	if [ "$(cat /tmp/sysinfo/board_name)" = "bullet-m" ]; then
		echo "none" > /sys/class/leds/ubnt:red:link1/trigger
		echo 1 > /sys/class/leds/ubnt:green:link4/brightness
		echo 1 > /sys/class/leds/ubnt:green:link3/brightness
		echo 1 > /sys/class/leds/ubnt:orange:link2/brightness
		echo 1 > /sys/class/leds/ubnt:red:link1/brightness
	elif [ "$(cat /tmp/sysinfo/board_name)" = "om2p" ]; then
		echo "none" > /sys/class/leds/om2p:red:wifi/trigger
		echo 1 > /sys/class/leds/om2p:green:wifi/brightness
		echo 0 > /sys/class/leds/om2p:yellow:wifi/brightness
		echo 0 > /sys/class/leds/om2p:red:wifi/brightness
	fi
fi

# Log that result
log_message "check: LAN: ${lan_status} | WAN: ${wan_status} | DNS: ${dns_status}"
