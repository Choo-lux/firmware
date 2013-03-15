#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Check if there is currently a check_lock in progress
if [ -e "/tmp/lock_check.tmp" ]; then
    log_message "check: already in progress (lock)"
    exit
fi
echo "locked" > /tmp/lock_check.tmp

echo "WiFi Mesh Connection Checker"
echo "----------------------------------------------------------------"

# Checks mesh connectivity if the node is a repeater (to make sure it hasn't been orphaned)
if [ "${role}" == "R" ]; then
	if [ -z "$(iw ${if_mesh} mpath dump | grep '0x' | grep -v '00:00:00:00:00')" ]; then
		log_message "check: we have no routes, sleeping..."
		sleep 10
		if [ -z "$(iw ${if_mesh} mpath dump | grep '0x' | grep -v '00:00:00:00:00')" ]; then
			log_message "check: we still have no routes, we have an orphaned node, checking channels!"
			
			log_message "check: searching for neighbours on channel 11"
			uci set wireless.radio0.channel="11" && uci commit wireless && wifi && sleep 10 && ping -c 2 8.8.8.8 > /dev/null
			if [ $? ]; then exit; fi
			
			log_message "check: searching for neighbours on channel 6"
			uci set wireless.radio0.channel="6" && uci commit wireless && wifi && sleep 10 && ping -c 2 8.8.8.8 > /dev/null
			if [ $? ]; then exit; fi
			
			log_message "check: searching for neighbours on channel 1"
			uci set wireless.radio0.channel="1" && uci commit wireless && wifi && sleep 10 && ping -c 2 8.8.8.8 > /dev/null
			if [ $? ]; then exit; fi
			
			log_message "check: WARNING: could not find any neighbours"
			if [ -e "/tmp/lock_check.tmp" ]; then rm "/tmp/lock_check.tmp"; fi
			
			exit
		fi
	fi
fi

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

# Check if there is currently a check_lock in progress
if [ -e "/tmp/lock_check.tmp" ]; then
    rm "/tmp/lock_check.tmp"
fi