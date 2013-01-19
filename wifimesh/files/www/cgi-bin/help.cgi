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

# Start showing the page
cat <<EOF_01
Content-Type: text/html
Pragma: no-cache

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xthml1/DTD/xhtml1-transitional.dtd">
<html>
	<head>
		<title>WiFi Mesh (mini): Support</title>
		<meta name="format-detection" content="telephone=no" />
		<meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no" />
		<link rel="stylesheet" type="text/css" href="/resources/style.css">
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
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<fieldset>
						<legend>Contact Us</legend>
						You can contact us at <a href="mailto:support@wifi-mesh.co.nz">support@wifi-mesh.co.nz</a>.
					</fieldset>
					<br />
					<fieldset>
						<legend>Support File</legend>
						You can <a href="#/cgi-bin/support.cgi?action=get-support_file">generate a support file</a> to send to the support team.<br />
						The support file will enable the support team to be able to assist you quicker.
					</fieldset>
					<br />
				</td>
			</tr>
		</table>
	</body>
</html>
EOF_03

