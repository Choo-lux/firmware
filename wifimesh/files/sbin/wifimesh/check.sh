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

change_mesh_channel() {
	# Change channels to the one sent to this function
	uci set wireless.radio0.channel="$1"
	uci commit wireless
	/etc/init.d/network restart
	/etc/init.d/chilli stop && sleep 3 && /etc/init.d/chilli start
	sleep 1 && iw wlan0-4 set mesh_param mesh_rssi_threshold 80
	
	# Wait a little bit for the mesh to initialise
	sleep 9
	
	# Check if a ping will respond
	ping -c 2 $(route -n | grep 'UG' | awk '{ print $2 }') > /dev/null
	if [ $? -eq 1 ]; then
		# We couldn't ping the gateway, something is wrong with this route
		echo "false"
	elif [ "$(iw wlan0-4 mpath dump | grep '0x15')" ]; then
		# Say that all is well
		echo "true"
		if [ -f "/tmp/lock_check.tmp" ]; then rm "/tmp/lock_check.tmp"; fi
	elif [ "$(iw wlan0-4 mpath dump | grep '0x5')" ]; then
		# Say that all is well
		echo "true"
		if [ -f "/tmp/lock_check.tmp" ]; then rm "/tmp/lock_check.tmp"; fi
	else
		# Nope, it's not this channel
		echo "false"
	fi
}

echo "WiFi Mesh Connection Checker"
echo "----------------------------------------------------------------"

# Chucks out any bad mesh paths that may be added from time to time
if [ "$(iw wlan0-4 mpath dump | grep '00:00:00:00:00')" ]; then
	log_message "check: throwing out bad routes"
	/etc/init.d/network restart
	/etc/init.d/chilli stop && sleep 3 && /etc/init.d/chilli start
	iw wlan0-4 set mesh_param mesh_rssi_threshold 80 && sleep 10
fi

# Checks mesh connectivity if the node is a repeater (to make sure it hasn't been orphaned)
if [ "${role}" == "R" ]; then
	if [ -z "$(iw wlan0-4 mpath dump | grep '0x' | grep -v '00:00:00:00:00')" ]; then
		log_message "check: we have no routes, sleeping..."
		sleep 10
		if [ -z "$(iw wlan0-4 mpath dump | grep '0x')" ]; then
			log_message "check: we still have no routes, we have an orphaned node, checking channels!"
			
			if [ "$(change_mesh_channel 11)" == "true" ]; then
				log_message "check: orphan: found neighbours on channel 11"
			elif [ "$(change_mesh_channel 5)" == "true" ]; then
				log_message "check: orphan: found neighbours on channel 5"
			elif [ "$(change_mesh_channel 1)" == "true" ]; then
				log_message "check: orphan: found neighbours on channel 1"
			else
				log_message "check: orphan: WARNING: could not recover orphan node!"
			fi
			
			exit
		fi
	fi
fi

# Tests LAN Connectivity
if [ "$(ping -c 2 ${ip_gateway})" ]; then
	lan_status=1
else
	lan_status=0
	
	log_message "check: we have no connectivity to the gateway, we have an orphaned node, checking channels!"
	if [ "$(change_mesh_channel 11)" == "true" ]; then
		log_message "check: orphan: found neighbours on channel 11"
	elif [ "$(change_mesh_channel 5)" == "true" ]; then
		log_message "check: orphan: found neighbours on channel 5"
	elif [ "$(change_mesh_channel 1)" == "true" ]; then
		log_message "check: orphan: found neighbours on channel 1"
	else
		log_message "check: orphan: WARNING: could not recover orphan node!"
	fi
	
	exit
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
if [ -f "/tmp/lock_check.tmp" ]; then
    rm "/tmp/lock_check.tmp"
fi