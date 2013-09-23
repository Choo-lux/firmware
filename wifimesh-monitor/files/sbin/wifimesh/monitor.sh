#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

echo "WiFi Mesh Monitor"
echo "----------------------------------------------------------------"
echo "Checking Monitor status"

# Check if the mon0 interface is up
if [ ! -f "/sys/class/net/mon0/dev_id" ]; then
	iw phy phy0 interface add mon0 type monitor
fi

# Check if airodump-ng is up and running
if [ ! "$(pidof airodump-ng)" ]; then
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
curl -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -k -s --data-binary @/tmp/airo-01.csv "http://${dashboard_server}checkin-wm.php?ip=${ip_lan}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&mac_mesh=${mac_mesh}&action=scanner" > /dev/null
