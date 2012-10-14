#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

echo "WiFi Mesh Upgrade Checker"
echo "----------------------------------------------------------------"

old_version=$(cat /sbin/wifimesh/version.txt)
new_version=$(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s "http://s3.amazonaws.com/cdn.wifi-mesh.com/firmware/development/version.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")

if [ "${new_version+x}" = x ] && [ -z "$new_version" ]; then
	log_message "upgrade: Could not connect to the upgrade server, aborting..."
elif [ "$old_version" != "$new_version" ]; then
	# Make sure the directory exists
	if [ ! -d "/sbin/wifimesh" ]; then mkdir /sbin/wifimesh > /dev/null; fi
	
	# Make sure no old upgrade exists
	if [ -e "/tmp/scripts.zip" ]; then rm "/tmp/scripts.zip"; fi
	
	echo "Downloading upgrade"
	curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s -o /tmp/scripts.zip "http://s3.amazonaws.com/cdn.wifi-mesh.com/firmware/development/scripts.zip?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)" > /dev/null
	
	echo "Checking validity"
	actual_hash=$(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -s "http://s3.amazonaws.com/cdn.wifi-mesh.com/firmware/development/hash.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")
	local_hash=$(md5sum /tmp/scripts.zip | awk '{ print $1 }')
	
	echo "Installing unzip"
	if [ ! -e "/tmp/scripts.zip" ]; then
		log_message "upgrade: The upgrade download was not successful, upgrade cancelled."
	elif [ "${actual_hash}" = "${local_hash}" ]; then
		echo "Installing upgrade"
		unzip -o /tmp/scripts.zip -d /sbin/wifimesh > /dev/null
		
		# Move the startup file
		mv /sbin/wifimesh/startup.sh /etc/init.d/wifimesh > /dev/null
		
		# Fix permissions
		chmod -R +x /sbin/wifimesh > /dev/null
		chmod -R +x /etc/init.d > /dev/null
		chmod -R +x /etc/rc.d > /dev/null
		
		# Make sure we are enabled
		/etc/init.d/wifimesh enable > /dev/null
		
		echo "saving the new WiFi Mesh banner"
cat > /etc/banner << banner_end
  ________ __ _______ __   _______               __     
  |  |  |  |__|    ___|__| |   |   |.-----.-----.|  |--.
  |  |  |  |  |    ___|  | |       ||  -__|__ --||     |
  |________|__|___|   |__| |__|_|__||_____|_____||__|__|

  v${new_version}       (c) 2011-2012 WiFi Mesh: New Zealand Ltd.
  ------------------------------------------------------
  Powered by:	
  http://www.wifi-mesh.com/       http://www.openwrt.org
  http://coova.org/
  ------------------------------------------------------
banner_end
		
		# Say about it
		log_message "upgrade: Upgraded from ${old_version} to ${new_version} successfully, rebooting..."
		
		reboot
	else
		log_message "upgrade: The downloaded upgrade was not valid, upgrade cancelled."
	fi
else
	log_message "upgrade: v${old_version} is the latest version available."
fi