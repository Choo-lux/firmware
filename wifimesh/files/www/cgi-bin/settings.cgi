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
						<legend>Wi-Fi</legend>
						<table>
							<tr>
								<td>Channel:</td>
								<td><input type="text" name="wifi_channel" value="$(uci get wireless.radio0.channel)" placeholder="$(uci get wireless.radio0.channel)" maxchars="2" style="width:200px;" /></td>
							</tr>
							<tr>
								<td>&nbsp;</td>
								<td><input type="submit" name="action" value="Save WiFi" disabled /></td>
							</tr>
						</table>
					</fieldset>
					<br />
					<fieldset>
						<legend>WAN Connectivity</legend>
						<table>
							<tr>
								<td>Type:</td>
								<td>
									<select name="wan_type" style="width:200px;">
EOF_01
if [ "$(uci get network.wan.proto)" == "static" ]; then
	echo "<option value='static' selected>Static"
else
	echo "<option value='static'>Static"
fi

if [ "$(uci get network.wan.proto)" == "dhcp" ]; then
	echo "<option value='dhcp' selected>DHCP Client"
else
	echo "<option value='dhcp'>DHCP Client"
fi

if [ "$(uci get network.wan.proto)" == "3g" ]; then
	echo "<option value='3g' selected>2G/3G/CDMA"
else
	echo "<option value='3g'>2G/3G/CDMA"
fi
cat <<EOF_02
									</select>
								</td>
							</tr>
EOF_02

if [ "$(uci get network.wan.proto)" == "dhcp" ]; then
	echo "<tr><td colspan='2'>DHCP does not need further configuration.</td></tr>"
elif [ "$(uci get network.wan.proto)" == "3g" ]; then
	echo "<tr>"
	echo "<td>Signal:</td>"
	echo "<td>$(comgt sig -d /dev/ttyACM1 | cut -d ":" -f 2 | cut -d ',' -f 1 | cut -b 2-50)</td>"
	echo "</tr>"
	
	echo "<tr>"
	echo "<td>Carrier:</td>"
	echo "<td>$(comgt reg -d /dev/ttyACM1 | grep 'Registered' | cut -d ":" -f 2 | cut -d ',' -f 1 | sed 's/"//g' | cut -b 2-50)</td>"
	echo "</tr>"
	
	echo "<tr>"
	echo "<td>Device:</td>"
	echo "<td><select name='wan_device' style='width:200px;'>"
	ls /dev | grep 'tty' | while read serial; do
		if [ "$(uci get network.wan.device)" == "/dev/${serial}" ]; then
			echo "<option value='${serial}' selected>${serial}"
		else
			echo "<option value='${serial}'>${serial}"
		fi
	done
	echo "</select>"
	echo "</td>"
	echo "</tr>"
	
	echo "<tr>"
	echo "<td>Mode:</td>"
	echo "<td><select name='wan_service' style='width:200px;'>"
	if [ "$(uci get network.wan.service)" == "umts" ]; then
		echo "<option value='umts' selected>2G &amp; 3G"
	else
		echo "<option value='umts'>2G &amp; 3G"
	fi
	
	if [ "$(uci get network.wan.service)" == "umts_only" ]; then
		echo "<option value='umts_only' selected>Only 3G"
	else
		echo "<option value='umts_only'>Only 3G"
	fi
	
	if [ "$(uci get network.wan.service)" == "gprs_only" ]; then
		echo "<option value='gprs_only' selected>Only 2G"
	else
		echo "<option value='gprs_only'>Only 2G"
	fi
	
	if [ "$(uci get network.wan.service)" == "evdo" ]; then
		echo "<option value='evdo' selected>CDMA"
	else
		echo "<option value='evdo'>CDMA"
	fi
	echo "</select>"
	echo "</td>"
	echo "</tr>"
	
	echo "<tr>"
	echo "<td>APN:</td>"
	echo "<td><input type='text' name='wan_apn' value='$(uci get network.wan.apn)' placeholder='$(uci get network.wan.apn)' style='width:200px;' /></td>"
	echo "</tr>"
	
	echo "<tr>"
	echo "<td>PIN:</td>"
	echo "<td><input type='text' name='wan_pin' value='$(uci get network.wan.pin)' placeholder='(optional) $(uci get network.wan.pin)' style='width:200px;' /></td>"
	echo "</tr>"
	
	echo "<tr>"
	echo "<td>Username:</td>"
	echo "<td><input type='text' name='wan_username' value='$(uci get network.wan.username)' placeholder='(optional) $(uci get network.wan.username)' style='width:200px;' /></td>"
	echo "</tr>"
	
	echo "<tr>"
	echo "<td>Password:</td>"
	echo "<td><input type='text' name='wan_password' value='$(uci get network.wan.password)' placeholder='(optional) $(uci get network.wan.password)' style='width:200px;' /></td>"
	echo "</tr>"
elif [ "$(uci get network.wan.proto)" == "static" ]; then
	echo "true"
else
	echo "<tr><td colspan='2'>You are using a custom WAN configuration.</td></tr>"
fi

cat <<EOF_03
							<tr>
								<td>&nbsp;</td>
								<td><input type="submit" name="action" value="Save WAN" disabled /></td>
							</tr>
						</table>
					</fieldset>
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
		
		var selected_tab = 'tab2';
		window.onload = function() {our_onclick(selected_tab);}
		</script>
	</body>
</html>
EOF_03
