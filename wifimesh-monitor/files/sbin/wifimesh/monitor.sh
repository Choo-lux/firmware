#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

echo "WiFi Mesh Monitor"
echo "----------------------------------------------------------------"

# Check that we are allowed to use this
if [ "$(uci get wifimesh.monitor.enabled)" -eq 0 ]; then
	echo "This script is disabled, exiting..."
	exit
fi

# Check the status
echo "Checking Monitor status"

# Check if the mon0 interface is up
if [ ! -f "/sys/class/net/mon0/dev_id" ]; then
	iw phy phy0 interface add mon0 type monitor
fi

# Check if airodump-ng is up and running
if [ ! "$(pidof airodump-ng)" ]; then
	rm -R /tmp/airo-*
	airodump-ng -i mon0 --beacons --output-format csv --write /tmp/airo > /dev/null 2>&1 &
fi

echo "Collecting data for Monitor process"

# Check if the csv file exists
if [ ! -f "/tmp/airo-01.csv" ]; then
    logger "monitor: We have no data, exiting..."
    exit 0
fi

echo "----------------------------------------------------------------"
echo "Sending data"

url_data="ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&mac_mesh=${mac_mesh}&action=scanner"
if [ "$(uci get wifimesh.dashboard.https)" -eq 1 ]; then
	url="https://$(uci get wifimesh.dashboard.server)/checkin-wm.php?${url_data}"
else
	url="http://$(uci get wifimesh.dashboard.server)/checkin-wm.php?${url_data}"
fi

curl -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" -k -s --data-binary @/tmp/airo-01.csv "${url}" > /dev/null
