#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Load in the OpenWrt release information
. /etc/openwrt_release
architecture=$(echo $DISTRIB_TARGET | cut -d = -f 2 | cut -d / -f 1)

echo "WiFi Mesh Upgrade Checker"
echo "----------------------------------------------------------------"

old_package_version=$(cat /sbin/wifimesh/package_version.txt)
new_package_version=$(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s "http://${firmware_server}firmware/${firmware_branch}/package_version.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")

if [ "${new_package_version+x}" = x ] && [ -z "$new_package_version" ]; then
	log_message "upgrade: Could not connect to the upgrade server, aborting..."
elif [ "$old_package_version" != "$new_package_version" ]; then
	# Make sure the directory exists
	if [ ! -d "/sbin/wifimesh" ]; then mkdir /sbin/wifimesh > /dev/null; fi
	
	# Make sure no old upgrade exists
	if [ -e "/tmp/scripts.zip" ]; then rm "/tmp/scripts.zip"; fi
	
	echo "Downloading package upgrade"
	curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s -o /tmp/scripts.zip "http://${firmware_server}firmware/${firmware_branch}/scripts.zip?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)" > /dev/null
	
	echo "Checking validity"
	actual_hash=$(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -s "http://${firmware_server}firmware/${firmware_branch}/hash.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")
	local_hash=$(md5sum /tmp/scripts.zip | awk '{ print $1 }')
	
	if [ ! -e "/tmp/scripts.zip" ]; then
		log_message "upgrade: The package upgrade download was not successful, upgrade cancelled."
	elif [ "${actual_hash}" = "${local_hash}" ]; then
		echo "Installing upgrade"
		unzip -o /tmp/scripts.zip -d /sbin/wifimesh > /dev/null
		
		# Move the startup file
		mv /sbin/wifimesh/startup.sh /etc/init.d/wifimesh > /dev/null
		
		# Fix permissions
		chmod +x /etc/init.d/wifimesh > /dev/null
		chmod +x /sbin/wifimesh/check.sh > /dev/null
		chmod +x /sbin/wifimesh/settings.sh > /dev/null
		chmod +x /sbin/wifimesh/startup.sh > /dev/null
		chmod +x /sbin/wifimesh/update.sh > /dev/null
		chmod +x /sbin/wifimesh/upgrade.sh > /dev/null
		
		# Make sure we are enabled
		/etc/init.d/wifimesh enable > /dev/null
		
		echo "saving the new WiFi Mesh banner"
cat > /etc/banner << banner_end
  ________ __ _______ __   _______               __     
  |  |  |  |__|    ___|__| |   |   |.-----.-----.|  |--.
  |  |  |  |  |    ___|  | |       ||  -__|__ --||     |
  |________|__|___|   |__| |__|_|__||_____|_____||__|__|

  v${new_package_version}       (c) 2011-2012 WiFi Mesh: New Zealand Ltd.
  ------------------------------------------------------
  Powered by:	
  http://www.wifi-mesh.com/       http://www.openwrt.org
  http://coova.org/
  ------------------------------------------------------
banner_end
		
		# Say about it
		log_message "upgrade: Upgraded package from ${old_package_version} to ${new_package_version} successfully, rebooting..."
		
		reboot
	else
		log_message "upgrade: The downloaded package upgrade was not valid, upgrade cancelled."
	fi
else
	log_message "upgrade: v${old_package_version} is the latest package version available."
fi
exit


old_kernel_version=$(cat /sbin/wifimesh/kernel_version.txt)
new_kernel_version=$(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s "http://${firmware_server}firmware/${firmware_branch}/${architecture}/kernel_version.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")

#device=$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50 | sed 's/ /_/g')
#new_kernel_version=$(cat /tmp/kernel_version.txt)
#echo $(echo $new_kernel_version | grep $device)

if [ "${new_kernel_version+x}" = x ] && [ -z "$new_kernel_version" ]; then
	log_message "upgrade: Could not connect to the upgrade server, aborting..."
elif [ "$old_kernel_version" != "$new_kernel_version" ]; then
	# Make sure the directory exists
	if [ ! -d "/sbin/wifimesh" ]; then mkdir /sbin/wifimesh > /dev/null; fi
	
	# Make sure no old upgrade exists
	if [ -e "/tmp/scripts.zip" ]; then rm "/tmp/scripts.zip"; fi
	
	echo "Downloading kernel upgrade"
	curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -s -o /tmp/scripts.zip "http://${firmware_server}firmware/${firmware_branch}/${architecture}/scripts.zip?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)" > /dev/null
	
	echo "Checking validity"
	actual_hash=$(curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -s "http://${firmware_server}firmware/${firmware_branch}/${architecture}/hash.txt?r=$(head -30 /dev/urandom | tr -dc "0123456789" | head -c3)")
	local_hash=$(md5sum /tmp/scripts.zip | awk '{ print $1 }')
	
	if [ "${actual_hash}" = "${local_hash}" ]; then
		echo "Installing upgrade"
		# Say about it
		log_message "upgrade: Upgraded kernel from ${old_kernel_version} to ${new_kernel_version} successfully, rebooting..."
		
		reboot
	else
		log_message "upgrade: The downloaded kernel upgrade was not valid, upgrade cancelled."
	fi
else
	log_message "upgrade: v${old_kernel_version} is the latest kernel version available."
fi