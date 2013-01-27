#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Load in the OpenWrt version information
. /etc/openwrt_release

# Checks if a password exists before the page may be viewed
if [ -f "/etc/httpd.conf" ]; then
cat <<EOF_96
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<title>Loading..</title>
		<meta http-equiv="refresh" content="0; url=/cgi-bin/overview.cgi">
	</head>
</html>
EOF_96
exit
fi

# Load in any requested data too
get_parameter() {
	echo "$query" | tr '&' '\n' | grep "^$1=" | head -1 | sed "s/.*=//" 
}

if [ "$REQUEST_METHOD" = POST ]; then
	query=$(head --bytes="$CONTENT_LENGTH")
else
	query="$QUERY_STRING"
fi

if [ $(get_parameter action) == "configure" ]; then
# Authorise all of the connected clients
chilli_query list | while read device; do
	chilli_query authorize ip $(echo $device | awk '{ print $2 }')
	chilli_query login ip $(echo $device | awk '{ print $2 }')
done

# Redirect the currently connected client to the Dashboard to add the node
cat <<EOF_96
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<title>Redirecting...</title>
		<meta http-equiv="cache-control" content="no-cache" />
		<meta http-equiv="refresh" content="0;URL='http://
EOF_96
echo $(cat /sbin/wifimesh/dashboard_server.txt)
cat <<EOF_97
first_boot.php?url=
EOF_97
echo $(chilli_query list | grep '10.176.247.13' | awk '{ print $15 }')
cat <<EOF_98
&mac=
EOF_98
echo $mac_lan
cat <<EOF_99
'" />
	</head>
</html>
EOF_99
exit
elif [ $(get_parameter action) == "disable" ]; then
echo "/cgi-bin/:admin:w1f1m35h" > /etc/httpd.conf

/etc/init.d/chilli disable
/etc/init.d/chilli stop

uci set wireless.@wifi-iface[1].network="wan"
uci commit wireless

wifi

cat <<EOF_97
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<title>Redirecting...</title>
		<meta http-equiv="refresh" content="10;URL='/cgi-bin/overview.cgi'" />
		<meta http-equiv="cache-control" content="no-cache" />
	</head>
	<body>
		<h1>Please wait...</h1>
	</body>
</html>
EOF_97
exit
fi

# Start showing the page
cat <<EOF_01
Content-Type: text/html
Pragma: no-cache

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xthml1/DTD/xhtml1-transitional.dtd">
<html>
	<head>
		<title>Welcome to WiFi Mesh (mini)</title>
		<meta name="format-detection" content="telephone=no" />
		<meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no" />
		<link rel="stylesheet" type="text/css" href="/resources/style.css" />
		<script>var selected_tab = 'tab3';</script>
		<script type="text/javascript" src="/resources/script.js"></script>
	</head>
	<body>
		<table id="top">
			<tr>
				<td style="width:300px;"><a href="http://www.wifi-mesh.co.nz/" target="_new"><img src="/resources/logo.png" style="border:0;height:100px;width:300px;"></a></td>
				<td style="width:600px;">
					<table style="float:right;background-color:#303030;color:#fff;margin-right:2%;">
						<tr style="font-weight:bold;"><td colspan="2">System Information</td></tr>
						<tr>
							<td>Hardware:</td>
							<td>$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50) / $(cat /proc/cpuinfo | grep 'system type' | cut -f2 -d ":" | cut -b 2-50 | awk '{ print $2 }')</td>
						</tr>
						<tr>
							<td>Version:</td>
							<td>WiFi Mesh v$(cat /sbin/wifimesh/package_version.txt) / $(cat /etc/openwrt_version)</td>
						</tr>
						<tr>
							<td>Build Date:</td>
							<td>$(uname -v)</td>
						</tr>
						<tr>
							<td>Connectivity:</td>
							<td>LAN: <font color="grey" id="lan_status_top">n/a</font> | WAN: <font color="grey" id="wan_status_top">n/a</font> | DNS: <font color="grey" id="dns_status_top">n/a</font></td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
		<table id="bottom">
			<tr>
				<td colspan="2">
					<ul id="tabsF">
						<li><a id="tab1" href="#/cgi-bin/overview.cgi" onmouseover="our_onmouseover('tab1');" onmouseout="our_onmouseout('tab1');"><span id="tab1span" onclick="our_onclick('tab1');">Overview</span></a></li>
						<li><a id="tab2" href="#/cgi-bin/settings.cgi" onmouseover="our_onmouseover('tab2');" onmouseout="our_onmouseout('tab2');"><span id="tab2span" onclick="our_onclick('tab2');">Settings</span></a></li>
						<li><a id="tab3" href="#/cgi-bin/help.cgi" onmouseover="our_onmouseover('tab3');" onmouseout="our_onmouseout('tab3');"><span id="tab3span" onclick="our_onclick('tab3');">Help</span></a></li>
					</ul>
					<fieldset>
						<legend>Welcome to WiFi Mesh!</legend>
						<p>Before you can get started using WiFi Mesh you need to either configure your node at the dashboard or disable the Captive Portal.</p>
						<p><a href="/cgi-bin/first_boot.cgi?action=configure">Configure Node</a></p>
						<p><a href="/cgi-bin/first_boot.cgi?action=disable">Disable Captive Portal</a></p>
					</fieldset>
					<br />
				</td>
			</tr>
		</table>
	</body>
</html>
EOF_01
