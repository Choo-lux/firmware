#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

# general node stuff
node_ip=$(uci get node.general.IP_mesh)
node_name=$(cat /proc/sys/kernel/hostname)
node_version=$(cat /etc/robin_version)

# nds stuff
nds_conf="/etc/nodogsplash/nodogsplash.conf"
ad_url=$(uci show nodog)
limit_download=$(cat $nds_conf | awk '$1=="DownloadLimit" {print $2}')
limit_upload=$(cat $nds_conf | awk '$1=="UploadLimit" {print $2}')

# ssid stuff
ssid1_ssid=$(uci get mesh.ap.ssid |tr [*] [' '])

ssid2_ssid="$(uci get mesh.Myap.ssid |tr [*] [' '])"
ssid2_up=$(uci get mesh.Myap.up)
ssid2_pass=$(uci get mesh.Myap.key)

# static ip stuff
staticip=$(uci get installation.gw.ipaddr)
subnet=$(uci get installation.gw.netmask)
gateway=$(uci get installation.gw.defroute)

# port forwarding stuff
port_forwarding=$(uci get forwarder.general.enabled)

sp1=$(uci get forwarder.rule_1.IncomingPort)
dst1=$(uci get forwarder.rule_1.IPAddr)
dp1=$(uci get forwarder.rule_1.DstPort)

sp2=$(uci get forwarder.rule_2.IncomingPort)
dst2=$(uci get forwarder.rule_2.IPAddr)
dp2=$(uci get forwarder.rule_2.DstPort)

sp3=$(uci get forwarder.rule_3.IncomingPort)
dst3=$(uci get forwarder.rule_3.IPAddr)
dp3=$(uci get forwarder.rule_3.DstPort)

sp4=$(uci get forwarder.rule_4.IncomingPort)
dst4=$(uci get forwarder.rule_4.IPAddr)
dp4=$(uci get forwarder.rule_4.DstPort)

sp5=$(uci get forwarder.rule_5.IncomingPort)
dst5=$(uci get forwarder.rule_5.IPAddr)
dp5=$(uci get forwarder.rule_5.DstPort)

sp6=$(uci get forwarder.rule_6.IncomingPort)
dst6=$(uci get forwarder.rule_6.IPAddr)
dp6=$(uci get forwarder.rule_6.DstPort)


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

			<form method="GET" action="/cgi-bin/settings-set.cgi">
			<input type="hidden" name="submit_type">
			<table width="70%" border="0">
			
			<tr>
				<td height="25" colspan="2">
					<fieldset>
						<legend>SSID #1</legend>
						<table border="0" width="100%">
							<tr><td height="25" width="60%">SSID #1: Status</td><td><input name="ssid1" type="radio" value="1" checked disabled>&nbsp;Enabled&nbsp;&nbsp;&nbsp;<input name="ssid1" type="radio" value="0" disabled>&nbsp;Disabled</td></tr>
							<tr><td height="25" width="60%">SSID #1: Name</td><td><input maxlength="30" size="30" name="ssid1_ssid" value="$ssid1_ssid" readonly></td></tr>
							<tr><td colspan="2"><hr></td></tr>
							<tr><td height="25" width="60%">Advertisment URL</td><td><input maxlength="100" size="30" name="ad_url" value="$ad_url"></td></tr>
							<tr><td height="25" width="60%">Download Limit (kbps)</td><td><input maxlength="5" size="6" name="limit_download" value="$limit_download"></td></tr>
							<tr><td height="25" width="60%">Upload Limit (kbps)</td><td><input maxlength="5" size="6" name="limit_upload" value="$limit_upload"></td></tr>
						</table>
					</fieldset>
				</td>
			</tr>
			
			<tr><td colspan="2"><br></td></tr>
			
			<tr>
				<td height="25" colspan="2">
					<fieldset>
						<legend>SSID #2</legend>
						<table border="0" width="100%">
							<tr><td height="25" width="60%">SSID #2: Status</td><td>
EOF_01
case $ssid2_up in
	1) echo "<input name="ssid2" type="radio" value="1" checked>&nbsp;Enabled&nbsp;&nbsp;&nbsp;<input name="ssid2" type="radio" value="0">&nbsp;Disabled";;
	0) echo "<input name="ssid2" type="radio" value="1">&nbsp;Enabled&nbsp;&nbsp;&nbsp;<input name="ssid2" type="radio" value="0" checked>&nbsp;Disabled" ;;
esac
cat <<EOF_02
							</td><tr>
							<tr><td height="25" width="60%">SSID #2: Name</td><td><input maxlength="30" size="30" name="ssid2_ssid" value="$ssid2_ssid"></td></tr>
							<tr><td height="25" width="60%">SSID #2: Password</td><td><input type="password" maxlength="30" size="30" name="ssid2_pass" value="$ssid2_pass"></td></tr>
						</table>
					</fieldset>
				</td>
			</tr>
			
			<tr><td colspan="2"><br></td></tr>
			
			<tr>
				<td height="25" colspan=2>
					<fieldset>
						<legend>Static IP</legend>
						<table border="0" width="100%">
							<tr>
								<td height="25" width="60%">IP Address:</td>
								<td><input type="text" name="ip" value="$staticip" maxlength="30" size="30"></td>
							</tr>
							<tr>
								<td height="25" width="60%">Subnet Mask</td>
								<td><input type="text" name="subnet" value="$subnet" maxlength="30" size="30"></td>
							</tr>
							<tr>
								<td height="25" width="60%">Default Gateway</td>
								<td><input type="text" name="gateway" value="$gateway" maxlength="30" size="30"></td>
							</tr>
						</table>
					</fieldset>
				</td>
			</tr>
			
			<tr><td colspan="2"><br></td></tr>
			
			<tr>
				<td height="25" colspan="2">
					<fieldset>
						<legend>Port Forwarding</legend>
						
						<table border="0" width="100%">
							<tr>
								<td height="25">Status:&nbsp;
EOF_02

case $port_forwarding in
	'1')
	echo "<input name="enabled" type="radio" value="1" checked="checked">&nbsp;Enabled&nbsp;&nbsp;&nbsp;<input name="enabled" type="radio" value="0">&nbsp;Disabled" 
	;;
	*)
	echo "<input name="enabled" type="radio" value="1">&nbsp;Enabled&nbsp;&nbsp;&nbsp;<input name="enabled" type="radio" value="0" checked="checked">&nbsp;Disabled"
	;;
esac

cat <<EOF_03
								</td>
							</tr>
							<tr><td height="2"><hr></td></tr>

							<tr>
								<td height="25">TCP Port&nbsp;<input maxlength="5" size="5" name="sp1" value=$sp1>&nbsp;&nbsp;&nbsp;redirects to&nbsp;<input maxlength="15" size="15" name="dst1" value=$dst1>:<input maxlength="5" size="5" name="dp1" value=$dp1></td>
							</tr>

							<tr>
								<td height="25">TCP Port&nbsp;<input maxlength="5" size="5" name="sp2" value=$sp2>&nbsp;&nbsp;&nbsp;redirects to&nbsp;<input maxlength="15" size="15" name="dst2" value=$dst2>:<input maxlength="5" size="5" name="dp2" value=$dp2></td>
							</tr>

							<tr>
								<td height="25">TCP Port&nbsp;<input maxlength="5" size="5" name="sp3" value=$sp3>&nbsp;&nbsp;&nbsp;redirects to&nbsp;<input maxlength="15" size="15" name="dst3" value=$dst3>:<input maxlength="5" size="5" name="dp3" value=$dp3></td>
							</tr>

							<tr><td height="2"><hr></td></tr>

							<tr>
								<td height="25">UDP Port&nbsp;<input maxlength="5" size="5" name="sp4" value=$sp4>&nbsp;&nbsp;&nbsp;redirects to&nbsp;<input maxlength="15" size="15" name="dst4" value=$dst4>:<input maxlength="5" size="5" name="dp4" value=$dp4></td>
							</tr>

							<tr>
								<td height="25">UDP Port&nbsp;<input maxlength="5" size="5" name="sp5" value=$sp5>&nbsp;&nbsp;&nbsp;redirects to&nbsp;<input maxlength="15" size="15" name="dst5" value=$dst5>:<input maxlength="5" size="5" name="dp5" value=$dp5></td>
							</tr>

							<tr>
								<td height="25">UDP Port&nbsp;<input maxlength="5" size="5" name="sp6" value=$sp6>&nbsp;&nbsp;&nbsp;redirects to&nbsp;<input maxlength="15" size="15" name="dst6" value=$dst6>:<input maxlength="5" size="5" name="dp6" value=$dp6></td>
							</tr>
						</table>
EOF_03

cat << EOF_99
					</td>
				</tr>

			<tr>
				<td colspan="2" align="right">    
					<input type= "submit" name="b1" value="Save Settings">&nbsp;<input type= "reset" name="b2" value="Reset Settings">
				</td>
			</tr>
		</table>
	</form>
</body>
</html>
EOF_99
