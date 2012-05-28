#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

node_ip=$(uci get node.general.IP_mesh)
node_name=$(cat /proc/sys/kernel/hostname)
node_version=$(cat /etc/robin_version)


cat <<EOF_99
Content-Type: text/html
Pragma: no-cache

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xthml1/DTD/xhtml1-transitional.dtd">
<html>
	<head>
		<title>Support: WiFi Mesh (mini) beta</title>
		<link rel="stylesheet" type="text/css" href="/resources/style.css">
	</head>
	<body>
		<table width="70%" border="0">
			<tr>
				<td width="350"><a href="http://www.wifi-mesh.com/"><img src="/resources/logo.png" height="91" width="283" border="0"></a></td>
				<td align="left" style="color:#3cb83f;font-weight:bold;">$node_name<br>${node_ip}<br />${node_version}</td>
			</tr>

			<tr>
				<td colspan="2">
					<ul id="tabsF">
						<li><a href="/cgi-bin/overview.cgi"><span>Overview</span></a></li>
						<li><a href="/cgi-bin/settings.cgi"><span>Settings</span></a></li>
						<li><a href="/cgi-bin/support.cgi"><span>Support</span></a></li>
					</ul>
				</td>
			</tr>

			<tr>
				<td colspan="2">
					<fieldset>
						<legend>Contacting Support</legend>
						
						You can contact us at support@wifi-mesh.com
					</fieldset>
				</td>
			</tr>
		</table>
	</body>
</html>
EOF_99
