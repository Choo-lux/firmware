#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

echo "WiFi Mesh Connection Checker"
echo "----------------------------------------------------------------"

# Test Global Internet Connectivity (connects to an HTTP server)
if [ "$(curl http://www.google.com/)" ]; then
	connected=1
else
	connected=0
fi

# If we are connected
if [ "$connected" = "1" ]; then
	log_message "check: We are connected to the Internet"
else
	log_message "check: We are NOT connected to the Internet"
fi