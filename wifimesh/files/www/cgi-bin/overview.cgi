#!/bin/sh
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Load in the OpenWrt version information
. /etc/openwrt_release

# Checks if a password exists before the page may be viewed
if [ ! -f "/etc/httpd.conf" ]; then
cat <<EOF_96
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<title>403 Forbidden</title>
	</head>
	<body>
		<h1>403 Forbidden</h1>
		<p>You must configure a password on this node before this page may be viewed.</p>
	</body>
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

if [ $(get_parameter action) == "reboot" ]; then
cat <<EOF_97
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<title>Rebooting...</title>
		<meta http-equiv="refresh" content="0;URL='/cgi-bin/overview.cgi'" />
		<meta http-equiv="cache-control" content="no-cache" />
	</head>
</html>
EOF_97
reboot
exit
elif [ $(get_parameter action) == "logoff-client" ]; then
	$(chilli_query logoff ip $(get_parameter id))
	$(chilli_query logout ip $(get_parameter id))
	
	cat <<EOF_97
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<meta http-equiv="refresh" content="0;URL='/cgi-bin/overview.cgi'" />
		<meta http-equiv="cache-control" content="no-cache" />
	</head>
</html>
EOF_97
exit
elif [ $(get_parameter action) == "logon-client" ]; then
	$(chilli_query login ip $(get_parameter id))
	$(chilli_query authorize ip $(get_parameter id))
	
	cat <<EOF_97
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<meta http-equiv="refresh" content="0;URL='/cgi-bin/overview.cgi'" />
		<meta http-equiv="cache-control" content="no-cache" />
	</head>
</html>
EOF_97
exit
elif [ $(get_parameter action) == "block-client" ]; then
	$(chilli_query block ip $(get_parameter id))
	
	cat <<EOF_97
Content-Type: text/html
Pragma: no-cache

<html>
	<head>
		<meta http-equiv="refresh" content="0;URL='/cgi-bin/overview.cgi'" />
		<meta http-equiv="cache-control" content="no-cache" />
	</head>
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
		<title>WiFi Mesh (mini): Overview</title>
		<meta name="format-detection" content="telephone=no" />
		<meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no" />
		<link rel="stylesheet" type="text/css" href="/resources/style.css" />
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
							<td>$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50)</td>
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
						<li><a id="tab1" href="/cgi-bin/overview.cgi" onmouseover="our_onmouseover('tab1');" onmouseout="our_onmouseout('tab1');"><span id="tab1span" onclick="our_onclick('tab1');">Overview</span></a></li>
						<li><a id="tab2" href="/cgi-bin/settings.cgi" onmouseover="our_onmouseover('tab2');" onmouseout="our_onmouseout('tab2');"><span id="tab2span" onclick="our_onclick('tab2');">Settings</span></a></li>
						<li><a id="tab3" href="/cgi-bin/help.cgi" onmouseover="our_onmouseover('tab3');" onmouseout="our_onmouseout('tab3');"><span id="tab3span" onclick="our_onclick('tab3');">Help</span></a></li>
					</ul>
					<fieldset>
						<legend>Network Connectivity</legend>
						<table>
							<tr>
								<th>Kind</th>
								<th>Status</th>
								<th>IP Address</th>
							</tr>
							<tr>
								<td>LAN</td>
								<td id="lan_status">n/a</td>
								<td id="lan_ip">n/a</td>
							</tr>
							<tr>
								<td>WAN</td>
								<td id="wan_status">n/a</td>
								<td id="wan_ip">n/a</td>
							</tr>
							<tr>
								<td>DNS</td>
								<td id="dns_status">n/a</td>
								<td id="dns_ip">n/a</td>
							</tr>
						</table>
					</fieldset>
					<br />
					<fieldset>
						<legend>Network Connections</legend>
						<table>
							<tr>
								<th>Interface Name</th>
								<th>IP address or SSID</th>
								<th>MAC Address</th>
							</tr>
							<tr>
								<td>br-lan (LAN bridge)</td>
								<td>${ip_lan}</td>
								<td>$(ifconfig br-lan | grep 'HWaddr' | awk '{ print $5 }')</td>
							</tr>
							<tr>
								<td>br-wan (WAN bridge)</td>
								<td>${ip_dhcp}</td>
								<td>$(ifconfig br-wan | grep 'HWaddr' | awk '{ print $5 }')</td>
							</tr>
							<tr>
								<td>&nbsp;</td>
								<td>$(route -n | grep 'UG' | awk '{ print $2 }')</td>
								<td>$()</td>
							</tr>
							<tr>
								<td>wlan0&nbsp;&nbsp;&nbsp;(SSID #1)</td>
								<td>$(uci get wireless.@wifi-iface[1].ssid)</td>
								<td>$(ifconfig wlan0 | grep 'HWaddr' | awk '{ print $5 }')</td>
							</tr>
							<tr>
								<td>wlan0-1 (SSID #2)</td>
								<td>$(uci get wireless.@wifi-iface[2].ssid)</td>
								<td>$(ifconfig wlan0-1 | grep 'HWaddr' | awk '{ print $5 }')</td>
							</tr>
							<tr>
								<td>wlan0-2 (SSID #3)</td>
								<td>$(uci get wireless.@wifi-iface[3].ssid)</td>
								<td>$(ifconfig wlan0-2 | grep 'HWaddr' | awk '{ print $5 }')</td>
							</tr>
							<tr>
								<td>wlan0-3 (SSID #4)</td>
								<td>$(uci get wireless.@wifi-iface[4].ssid)</td>
								<td>$(ifconfig wlan0-3 | grep 'HWaddr' | awk '{ print $5 }')</td>
							</tr>
							<tr>
								<td>wlan0-4 (802.11s)</td>
								<td>$(uci get wireless.@wifi-iface[0].mesh_id)</td>
								<td>$(ifconfig wlan0-4 | grep 'HWaddr' | awk '{ print $5 }')</td>
							</tr>
						</table>
					</fieldset>
					<br />
					<fieldset>
						<legend>Active Sessions</legend>
						<table>
							<tr>
								<th>Session Name</th>
								<th>IP/MAC Address</th>
								<th>State</th>
								<th>Time</th>
								<th>Bytes Down</th>
								<th>Bytes Up</th>
								<th colspan="2">Maintenance</th>
							</tr>
EOF_01
chilli_query list | while read device; do
	state="$(echo $device | awk '{ print $5 }')"
	if [ "${state}" == "0" ]; then
		state="Offline"
	elif [ "${state}" == "1" ]; then
		state="Online"
	else
		state="Unknown (${state})"
	fi
	
	echo "<tr>"
	echo "<td>$(echo $device | awk '{ print $6 }')</td>"
	echo "<td>$(echo $device | awk '{ print $2 }')<br />$(echo $device | awk '{ print $1 }' | sed 's/-/:/g')</td>"
	echo "<td>${state}</td>"
	echo "<td>$(echo $device | awk '{ print $7 }')</td>"
	echo "<td>$(echo $device | awk '{ print $9 }')</td>"
	echo "<td>$(echo $device | awk '{ print $10 }')</td>"
	if [ "${state}" == "Online" ]; then 
		echo "<td><a href='overview.cgi?action=logoff-client&id=$(echo $device | awk '{ print $2 }')'>Logoff</a></td>"
	else
		echo "<td><a href='overview.cgi?action=logon-client&id=$(echo $device | awk '{ print $2 }')'>Logon</a></td>"
	fi
	echo "<td><a href='overview.cgi?action=block-client&id=$(echo $device | awk '{ print $2 }')'>Block</a></td>"
	echo "</tr>"
done
cat <<EOF_02
						</table>
					</fieldset>
					<br />
					<fieldset>
						<legend>Mesh Neighbours</legend>
						<table>
							<tr>
								<th>MAC</th>
								<th>Role</th>
								<th>Signal</th>
								<th>Data Rate</th>
							</tr>
EOF_02
iw wlan0-4 mpath dump | grep '0x' | while read device; do
	if [ $(echo $device | awk '{ print $10 }') == "0x14" ]; then
		role="Repeater"
	elif [ $(echo $device | awk '{ print $10 }') == "0x15" ]; then
		role="Repeater"
	
	elif [ $(echo $device | awk '{ print $10 }') == "0x5" ]; then
		role="Gateway"
	
	elif [ $(echo $device | awk '{ print $10 }') == "0x0" ]; then
		role="Offline"
	elif [ $(echo $device | awk '{ print $10 }') == "0x2" ]; then
		role="Offline"
	
	else
		role="Unknown ($(echo $device | awk '{ print $10 }'))"
	fi
	
	dbm_rate="$(iw wlan0-4 station get $(echo $device | awk '{ print $1 }') | grep 'signal:' | awk '{ print $2 }')"
	if [ "${dbm_rate}" == "" ]; then
		dbm_rate="n/a"
	else
		dbm_rate="${dbm_rate} dBm"
	fi
	
	data_rate=$(iw wlan0-4 station get $(echo $device | awk '{ print $1 }') | grep 'rx bitrate:' | awk '{ print $3 }')
	if [ "${data_rate}" == "" ]; then
		data_rate="n/a"
	else
		data_rate="${data_rate} Mbps"
	fi

	echo "<tr>"
	echo "<td>$(echo $device | awk '{ print $1 }')</td>"
	echo "<td>${role}</td>"
	echo "<td>${dbm_rate}</td>"
	echo "<td>${data_rate}</td>"
	echo "</tr>"
done
cat <<EOF_03
						</table>
					</fieldset>
				</td>
			</tr>
		</table>
	</body>
</html>
EOF_03
