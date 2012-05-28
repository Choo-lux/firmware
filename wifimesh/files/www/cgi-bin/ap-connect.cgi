#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# general node stuff
node_ip=$(uci get node.general.IP_mesh)
node_name=$(cat /proc/sys/kernel/hostname)
node_version=$(cat /etc/robin_version)

cat <<EOF_01
Content-Type: text/html
Pragma: no-cache

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xthml1/DTD/xhtml1-transitional.dtd">
<html>
	<head>
		<title>Settings: WiFi Mesh (mini) beta</title>
		<link rel="stylesheet" type="text/css" href="/resources/style.css">
	</head>
	<body>
		<table width="70%" border="0">
			<tr>
				<td width="350"><a href="http://www.wifi-mesh.com/"><img src="/resources/logo.png" height="91" width="283" border="0"></a></td>
				<td align="left" style="color:#3cb83f;font-weight:bold;">$node_name<br>${node_ip}<br>${node_version}</td>
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

			<form method="GET" action="/cgi-bin/ap-connect.cgi">
			<input type="hidden" name="submit_type">
			<table width="70%" border="0">
				<tr>
					<td height="25" colspan="2">
						<fieldset>
							<legend>Nearby AP's</legend>
							<table border="0" width="100%">
								<tr>
									<th>MAC</th>
									<th>SSID</th>
									<th>Signal</th>
									<th>Encryption</th>
									<th>&nbsp;</th>
								</tr>
EOF_01
iwlist ath0 scanning | awk -F '[ :=]+' '/(ESS|Qual)/{ printf "<td>"$3"</td>" } /Encr/{ print "<td>"$4"</td><td><a href=''>Connect</a></td></tr>" } /Cell/{ printf "<tr><td>"$6":"$7":"$8":"$9":"$10":"$11"</td>" }' | tr -d '"'
cat <<EOF_99
							</table>
						</fieldset>
					</td>
				</tr>
				<tr>
					<td colspan="2" align="right">    
						<input type= "submit" name="b1" value="Connect to AP">&nbsp;<input type= "reset" name="b2" value="Reset Settings">
					</td>
				</tr>
			</table>
		</form>
	</body>
</html>
EOF_99
