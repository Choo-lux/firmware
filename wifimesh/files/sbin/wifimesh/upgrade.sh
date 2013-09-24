#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Load in the OpenWrt release information
. /etc/openwrt_release
architecture=$(echo $DISTRIB_TARGET | cut -d = -f 2 | cut -d / -f 1)
device=$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50 | sed 's/ /_/g')

echo "WiFi Mesh Upgrade Checker"
echo "----------------------------------------------------------------"

log_message "Waiting a bit..."
sleep $[ ( $RANDOM % 10 )  + 1 ]s

if [ "${firmware_branch}" = "fixed" ]; then
	log_message "upgrade: We are locked on v${old_package_version}. Enable upgrades at the dashboard."
	exit
fi

log_message "upgrade: Checking for new upgrade package..."
old_package_version=$(cat /sbin/wifimesh/package_version.txt)
new_package_version=$(curl -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -k -s "http://${firmware_server}firmware/${firmware_branch}/full_package_version.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")

if [ "${new_package_version+x}" = x ] && [ -z "$new_package_version" ]; then
	log_message "upgrade: Could not connect to the upgrade server, aborting!"
elif [ "$old_package_version" != "$new_package_version" ]; then
	# Make sure the directory exists
	if [ ! -d "/sbin/wifimesh" ]; then mkdir /sbin/wifimesh > /dev/null; fi
	
	# Make sure no old upgrade exists
	if [ -e "/tmp/full_scripts.zip" ]; then rm "/tmp/full_scripts.zip"; fi
	
	echo "Downloading package upgrade"
	curl -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -k -s -o /tmp/full_scripts.zip "http://${firmware_server}firmware/${firmware_branch}/full_scripts.zip?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)" > /dev/null
	
	echo "Checking validity of the scripts archive"
	actual_hash=$(curl -A "WMF/v${package_version} (http://www.wifi-mesh.co.nz/)" -s "http://${firmware_server}firmware/${firmware_branch}/full_hash.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")
	local_hash=$(md5sum /tmp/full_scripts.zip | awk '{ print $1 }')
	
	if [ ! -e "/tmp/full_scripts.zip" ]; then
		log_message "upgrade: The scripts package upgrade download was not successful, upgrade cancelled."
	elif [ "${actual_hash}" = "${local_hash}" ]; then
		echo "Installing scripts upgrade"
		unzip -o /tmp/full_scripts.zip -d / > /dev/null
		
		# Move the startup file
		mv /sbin/wifimesh/startup.sh /etc/init.d/wifimesh > /dev/null
		
		# Fix the permissions
		chmod +x /etc/init.d/wifimesh > /dev/null
		
		# Make sure we are enabled
		/etc/init.d/wifimesh enable > /dev/null
		
		# Load in the cron jobs
		crontab /sbin/wifimesh/cron.txt
		
		echo "Saving the new WiFi Mesh banner"
cat > /etc/banner << banner_end
  ________ __ _______ __   _______               __     
  |  |  |  |__|    ___|__| |   |   |.-----.-----.|  |--.
  |  |  |  |  |    ___|  | |       ||  -__|__ --||     |
  |________|__|___|   |__| |__|_|__||_____|_____||__|__|

  v${new_package_version}       (c) 2011-2013 WiFi Mesh: New Zealand Ltd.
  ------------------------------------------------------
  Powered by:	
  http://www.wifi-mesh.co.nz     http://www.openwrt.org
  http://coova.org               http://www.wifirush.com
  ------------------------------------------------------
banner_end
		
		# Say about it
		log_message "upgrade: Upgraded the scripts package from ${old_package_version} to ${new_package_version} successfully, rebooting..."
		reboot
	else
		log_message "upgrade: The downloaded scripts package upgrade was not valid, upgrade cancelled."
	fi	
else
	log_message "upgrade: v${old_package_version} is the latest package version available."
fi
