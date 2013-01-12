#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Start testing!
# Tests LAN Connectivity
if [ "$(ping -c 2 ${ip_gateway})" ]; then
	lan_status=1
	lan_ip="${ip_gateway}"
else
	lan_status=0
	lan_ip="n/a"
fi

# Tests WAN Connectivity
wan=$(curl http://maintenance.wifi-mesh.co.nz/check-ip.php?mac=${mac_lan})
if [ "${wan}" ]; then
	wan_status=1
	wan_ip="${wan}"
else
	wan_status=0
	wan_ip="n/a"
fi

# Tests DNS Connectivity
dns=$(nslookup www.google.com)
if [ "${dns}" ]; then
	dns_status=1
	dns_ip=$(echo $dns | grep 'Server:' | awk '{ print $2 }')
else
	dns_status=0
	dns_ip="n/a"
fi

# Start showing the page
cat <<EOF_01
Content-Type: application/json
Pragma: no-cache

{
	"lan": {
		"status": ${lan_status},
		"ip": "${lan_ip}"
	},
	"wan": {
		"status": ${wan_status},
		"ip": "${wan_ip}"
	},
	"dns": {
		"status": ${dns_status},
		"ip": "${dns_ip}"
	}
}
EOF_01

