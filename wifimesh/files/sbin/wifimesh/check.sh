#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

echo "WiFi Mesh Connection Checker"
echo "----------------------------------------------------------------"

# Check that we are allowed to use this
if [ "$(uci get wifimesh.check.enabled)" -eq 0 ]; then
	echo "This script is disabled, exiting..."
	exit
fi

# Deletes any bad mesh paths that may occur from time to time
iw ${if_mesh} mpath dump | grep '00:00:00:00:00:00' | while read line; do
	iw ${if_mesh} mpath del $(echo $line | awk '{ print $1 }')
done

# Tests LAN Connectivity
if [ "$(ping -c 2 ${ip_gateway})" ]; then
	lan_status=1
else
	lan_status=0
fi

# Tests WAN Connectivity
if [ "$(ping -c 2 $(uci get wifimesh.ping.server))" ]; then
	wan_status=1
else
	wan_status=0
fi

# Tests DNS Connectivity
if [ "$(nslookup $(uci get wifimesh.ping.server))" ]; then
	dns_status=1
else
	dns_status=0
fi

# Log that result
log_message "check: LAN: ${lan_status} | WAN: ${wan_status} | DNS: ${dns_status}"
