#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Creates temporary directory if it doesn't already exist
if [ ! -d "/tmp/upgrade" ]; then mkdir /tmp/upgrade; fi

# Wipes out previous upgrade information from dashboard
echo "" > /tmp/upgrade/version
echo "" > /tmp/upgrade/md5sums

echo "WiFi Mesh Upgrade Checker"
echo "----------------------------------------------------------------"

# Check that we are allowed to use this
if [ "$(uci get wifimesh.firmware.enabled)" -eq 0 ]; then
	echo "This script is disabled, exiting..."
	exit
fi

echo "Waiting a bit..."
sleep $(head -30 /dev/urandom | tr -dc "0123456789" | head -c1)

# Defines the URL to check the firmware at
if [ "$(uci get wifimesh.firmware.https)" -eq 1 ]; then
	url="https://$(uci get wifimesh.firmware.server)/firmware/$(uci get wifimesh.firmware.branch)/$(uci get wifimesh.system.architecture)/"
else
	url="http://$(uci get wifimesh.firmware.server)/firmware/$(uci get wifimesh.firmware.branch)/$(uci get wifimesh.system.architecture)/"
fi
echo "Checking latest version number"
curl -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" --cacert /etc/ssl-bundle.crt -s -o /tmp/upgrade/version "${url}version?r=$(head -30 /dev/urandom | tr -dc '0123456789' | head -c3)"
echo "Latest version number: v$(cat /tmp/upgrade/version)"

echo "Getting latest version hashes and filenames"
curl -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" --cacert /etc/ssl-bundle.crt -s -o /tmp/upgrade/md5sums "${url}md5sums?r=$(head -30 /dev/urandom | tr -dc '0123456789' | head -c3)"

if [ "${new_version+x}" = x ] && [ -z "$new_version" ]; then
	log_message "upgrade: Could not connect to the upgrade server, exiting..."
elif [ "$(uci get wifimesh.system.version)" != "$new_version" ]; then
	# Make sure no old firmware exists
	if [ -e "/tmp/firmware.bin" ]; then rm "/tmp/firmware.bin"; fi
	
	echo "Checking for upgrade binary"
	if grep -q "$(cat /tmp/sysinfo/board_name)-squashfs-sysupgrade" /tmp/md5sums; then
		echo "Downloading upgrade binary: $(grep $(cat /tmp/sysinfo/board_name)'-squashfs-sysupgrade' /tmp/md5sums | awk '{ print $2 }' | sed 's/*//')"
		curl -A "WMF/v$(uci get wifimesh.system.version) (http://www.wifi-mesh.co.nz/)" --cacert /etc/ssl-bundle.crt -s -o /tmp/firmware.bin "${url}$(grep $(cat /tmp/sysinfo/board_name)'-squashfs-sysupgrade' /tmp/md5sums | awk '{ print $2 }' | sed 's/*//')?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)" > /dev/null
		
		# Stop if the firmware file does not exist
		if [ ! -e "/tmp/firmware.bin" ]; then
			echo "The upgrade binary download was not successful, exiting..."
		
		# If the hash is correct: flash the firmware
		elif [ "$(grep $(cat /tmp/sysinfo/board_name)'-squashfs-sysupgrade' /tmp/md5sums | awk '{ print $1 }')" = "$(md5sum /tmp/firmware.bin | awk '{ print $1 }')" ]; then
			logger "Installing upgrade binary..."
			sysupgrade -c -d 600 /tmp/firmware.bin
			
		# The hash is invalid, stopping here
		else
			echo "The upgrade binary hash did not match, exiting..."
		fi	
	else
		echo "There is no upgrade binary for this device ($(cat /tmp/sysinfo/model)/$(cat /tmp/sysinfo/board_name)), exiting..."
	fi
else
	echo "v$(cat /tmp/upgrade/version) is the latest firmware version available."
fi
