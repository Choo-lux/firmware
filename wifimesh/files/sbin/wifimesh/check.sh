#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

echo "WiFi Mesh Connection Checker"
echo "----------------------------------------------------------------"

# Test Global Internet Connectivity (traceroutes the DNS Root Servers)
#test_root=( "198.41.0.4" "192.228.79.201" "192.33.4.12" "128.8.10.90" "192.203.230.10" "192.5.5.241" "192.112.36.4" "128.63.2.53" "192.36.148.17" "192.58.128.30" "193.0.14.129" "199.7.83.42" "202.12.27.33" )
#test_root_num=${#test_root[@]}
#rand=${test_root[$((RANDOM%test_root_num))]}
rand="202.12.27.33"

# If we can traceroute, we are connected
if [ "$(traceroute -n -w 1 -q 1 -m 20 $rand)" ]; then
	connected=1
else
	# Test Internet Connectivity (curl GETs a popular webpage)
	#test_popular=(
		#"http://www.google.com/"
		#"http://www.youtube.com/"
		#"http://search.yahoo.com/"
		#"http://www.wikipedia.org/"
	#)
	#test_popular_num=${#test_popular[@]}
	#site=${test_popular[$((RANDOM%test_popular_num))]}
	site="http://www.google.com/"
	
	# If we can get a html page back, we are connected
	if [ "$(curl -A 'WMF/v${fw_ver} (http://www.wifi-mesh.com/)' -s $site | grep -i -c '<html')" -eq "1" ]; then
		connected=1
	
	# Or else we must not be
	else
		connected=0
	fi
fi

# If we are connected
if [ "$connected" = "1" ]; then
	logger "check: We are connected to the Internet"
	echo "We are connected to the Internet"
else
	logger "check: We are NOT connected to the Internet"
	echo "We are NOT connected to the Internet"
fi