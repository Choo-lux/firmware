#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Load in the OpenWrt version information
. /etc/openwrt_release

# Load in any requested data too
get_parameter() {
	echo "$query" | tr '&' '\n' | grep "^$1=" | head -1 | sed "s/.*=//" 
}

if [ "$REQUEST_METHOD" = POST ]; then
	query=$(head --bytes="$CONTENT_LENGTH")
else
	query="$QUERY_STRING"
fi

if [ $(get_parameter action) == "logoff-client" ]; then
	cat <<EOF_97
Content-Type: text/html
Pragma: no-cache
Location: /cgi-bin/overview.cgi

$(chilli_query logoff $(get_parameter id))
$(chilli_query logout $(get_parameter id))
EOF_97
exit
elif [ $(get_parameter action) == "logon-client" ]; then
	cat <<EOF_97
Content-Type: text/html
Pragma: no-cache
Location: /cgi-bin/overview.cgi

$(chilli_query login $(get_parameter id))
$(chilli_query authorise $(get_parameter id))
EOF_97
exit
elif [ $(get_parameter action) == "block-client" ]; then
	cat <<EOF_97
Content-Type: text/html
Pragma: no-cache
Location: /cgi-bin/overview.cgi

$(chilli_query block $(get_parameter id))
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
		<link rel="stylesheet" type="text/css" href="/resources/style.css">
	</head>
	<body>
		<table id="top">
			<tr>
				<td style="width:300px;"><a href="http://www.wifi-mesh.com/" target="_new"><img src="/resources/logo.png" style="border:0;height:100px;width:300px;"></a></td>
				<td style="width:600px;">
					<table style="float:right;background-color:#303030;color:#fff;margin-right:2%;">
						<tr style="font-weight:bold;"><td colspan="2">System Information</td></tr>
						<tr>
							<td>Hardware:</td>
							<td>$(cat /proc/cpuinfo | grep 'machine' | cut -f2 -d ":" | cut -b 2-50)</td>
						</tr>
						<tr>
							<td>Version:</td>
							<td>WiFi Mesh v$(cat /sbin/wifimesh/version.txt) / $(cat /etc/openwrt_version)</td>
						</tr>
						<tr>
							<td>Build Date:</td>
							<td>$(uname -v)</td>
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
						<li><a id="tab3" href="/cgi-bin/support.cgi?" onmouseover="our_onmouseover('tab3');" onmouseout="our_onmouseout('tab3');"><span id="tab3span" onclick="our_onclick('tab3');">Support</span></a></li>
					</ul>
				</td>
			</tr>
			<tr>
				<td colspan="2">
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
								<td>${ip}</td>
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
								<th>MAC Address</th>
								<th>IP Address</th>
								<th>State</th>
								<th>Time</th>
								<th>Bytes Total</th>
								<th>Bytes Down</th>
								<th>Bytes Up</th>
								<th colspan="2">Maintenance</th>
							</tr>
EOF_01
chilli_query list | while read device; do
	state="$(echo $device | awk '{ print $3 }')"
	if [ "${state}" == "dnat" ]; then
		state="Pending"
	elif [ "${state}" == "pass" ]; then
		state="Online"
	else
		state="Unknown ${state}"
	fi
	
	echo "<tr>"
	echo "<td>$(echo $device | awk '{ print $6 }')</td>"
	echo "<td>$(echo $device | awk '{ print $1 }')</td>"
	echo "<td>$(echo $device | awk '{ print $2 }')</td>"
	echo "<td>${state}</td>"
	echo "<td>$(echo $device | awk '{ print $7 }')</td>"
	echo "<td>$(echo $device | awk '{ print $8 }')</td>"
	echo "<td>$(echo $device | awk '{ print $9 }')</td>"
	echo "<td>$(echo $device | awk '{ print $10 }')</td>"
	if [ "${state}" == "Online" ]; then 
		echo "<td><a href='overview.chi?action=logoff-client&id=$(echo $device | awk '{ print $6 }')'>Logoff</a></td>"
	else
		echo "<td><a href='overview.chi?action=logon-client&id=$(echo $device | awk '{ print $6 }')'>Logon</a></td>"
	fi
	echo "<td><a href='overview.chi?action=block-client&id=$(echo $device | awk '{ print $6 }')'>Block</a></td>"
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
					<!--
					<br />
					<fieldset>
						<legend>Nearby Routers</legend>
						<table border="0" width="100%">
							<tr>
								<th>MAC</th>
								<th>SSID</th>
								<th>Signal</th>
								<th>Encryption</th>
								<th>&nbsp;</th>
							</tr>
						</table>
					</fieldset>
					-->
					<br />
				</td>
			</tr>
		</table>
		<script>
		function our_onclick(tabname) {
			// Reset all of the other tabs back to normal
			document.getElementById('tab1').style.background = "#303030";
			document.getElementById('tab1span').style.color = "#4FA8FF";
			document.getElementById('tab2').style.background = "#303030";
			document.getElementById('tab2span').style.color = "#4FA8FF";
			document.getElementById('tab3').style.background = "#303030";
			document.getElementById('tab3span').style.color = "#4FA8FF";
			
			// and change this tab to be the nicer looking one
			selected_tab=tabname;
			
			document.getElementById(tabname).style.background = "#262626";
			document.getElementById(tabname + "span").style.color = "#FFFFFF";
		}

		function our_onmouseover(tabname) {
			// Reset all of the other tabs back to normal
			if(tabname != selected_tab) {document.getElementById(tabname).style.background = "#262626";}
			document.getElementById(tabname).style.color = "#FFFFFF";
		}
		
		function our_onmouseout(tabname) {
			// Reset all of the other tabs back to normal
			if(tabname != selected_tab) {document.getElementById(tabname).style.backgroundColor = "303030";}
		}
		
		var selected_tab = 'tab1';
		window.onload = function() {our_onclick(selected_tab);}
		</script>
	</body>
</html>
EOF_03
