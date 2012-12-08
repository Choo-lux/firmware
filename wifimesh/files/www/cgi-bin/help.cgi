#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# Load in the settings
. /sbin/wifimesh/settings.sh

# Load in the OpenWrt version information
. /etc/openwrt_release

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
						<li><a id="tab3" href="/cgi-bin/help.cgi" onmouseover="our_onmouseover('tab3');" onmouseout="our_onmouseout('tab3');"><span id="tab3span" onclick="our_onclick('tab3');">Help</span></a></li>
					</ul>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<fieldset>
						<legend>Contact Us</legend>
						You can contact us at <a href="mailto:support@wifi-mesh.com">support@wifi-mesh.com</a>.
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
		
		var selected_tab = 'tab3';
		window.onload = function() {our_onclick(selected_tab);}
		</script>
	</body>
</html>
EOF_03

