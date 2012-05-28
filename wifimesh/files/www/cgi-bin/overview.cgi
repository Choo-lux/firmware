#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.
#
# Load in the settings
. /sbin/wifi-mesh/settings.sh

cat <<EOF_01
Content-Type: text/html
Pragma: no-cache

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xthml1/DTD/xhtml1-transitional.dtd">
<html>
	<head>
		<title>Overview: WiFi Mesh (mini) beta</title>
		<link rel="stylesheet" type="text/css" href="/resources/style.css">
	</head>
	<body>
		<table width="70%" border="0">
			<tr>
				<td width="350"><a href="http://www.wifi-mesh.com/"><img src="/resources/logo.png" height="91" width="283" border="0"></a></td>
				<td align="left" style="color:#3cb83f;font-weight:bold;">$(uci get wireless.@wifi-iface[0].ssid)<br>${ip}<br />v$(cat /etc/openwrt_version)</td>
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
						<legend>Connection</legend>
							<table>
EOF_01

echo "<tr><td>Connection Type:</td><td>Internet</td></tr>"
echo "<tr><td>Connection Speed:</td><td>$ntr</td></tr>"

if [ "$node_role" -eq 0 ] ; then
	echo "<tr><td>Device Role:</td><td>Repeater</td></tr>"
else
	echo "<tr><td>Device Role:</td><td>Gateway</td></tr>"
fi

cat <<EOF_02
						</table>
					</fieldset>
					<br>
					<fieldset>
						<legend>Active Users</legend>
						<table>
							<tr>
								<th>Name</th>
								<th>MAC</th>
								<th>IP</th>
								<th>KB Total</th>
								<th>KB Down</th>
								<th>KB Up</th>
								<th>Blocked?</th>
							</tr>
EOF_02

cat /tmp/dhcp.leases |tr [*] ['U'] > /tmp/dhcpd.clients.tmp 
sort -u < /tmp/dhcpd.clients.tmp > /tmp/dhcpd.clients 

#rows to columns
rm -f /tmp/nds_clients_h
while read riga ; do #rows to columns
	case $(echo $riga |awk -F = '{print $1}') in
		ip|state|downloaded|uploaded) 
			value=$(echo $riga |awk -F = '{print $2}')
			record="${record} $value" 
			;;
		token) 
			tok=$(echo $riga |awk -F = '{print $2}')
			;;
		mac) 
			value=$(echo $riga |awk -F = '{print $2}' |tr A-Z a-z)
			record="${record} $value" 
			;;
		avg_up_speed) 
			record="${record} $tok"
			echo $record >> /tmp/nds_clients_h 
			record= 
			;;
	esac
done < /tmp/nds_clients
 
#find authenticated users
while read riga ; do
	[ "$(echo $riga |awk '{print $3}')" == "Authenticated" ] && {
		NDS_IP=$(echo $riga |awk '{print $1}')
		NDS_MAC=$(echo $riga |awk '{print $2}')

		#look up hostname for the given authetnticated IP
		while read lease ; do
			LEASE_IP=$(echo $lease |awk '{print $3}')
			client_mac=$(echo $lease |awk '{print $2}' |tr A-Z a-z)

			if [ "$NDS_IP" == "$LEASE_IP" -a "$NDS_MAC" == "$client_mac" ]; then 	
				client_ip=$(echo $riga |awk '{print $1}')   
				KB_d=$(echo $riga |awk '{print $4}')
				KB_u=$(echo $riga |awk '{print $5}')
				KB_t=$(($KB_d+$KB_u))
				hostname=$(echo $lease |awk '{print $4}') 
				[ "$hostname" == "$is_unknown" ] && client_hostname="unknown" || client_hostname=$hostname

				echo "<tr>"
				echo "<td>${client_hostname}</td>"
				echo "<td>${client_mac}</td>"
				echo "<td>${client_ip}</td>"
				echo "<td>${KB_t}</td>"
				echo "<td>${KB_d}</td>"
				echo "<td>${KB_u}</td>"
				
				if [ -e "/tmp/$client_mac" ]; then
					echo "<td><a href='users.cgi?action=unblock&mac=${client_mac}'>Unblock</a></td>"
				else
					echo "<td><a href='users.cgi?action=block&mac=${client_mac}'>Block</a></td>"
				fi
				
				echo "</tr>";
			fi
		done < /tmp/dhcpd.clients
	}
done < /tmp/nds_clients_h

cat <<EOF_02
						</table>
					</fieldset>
					<br>
					<fieldset>
						<legend>Nearby Nodes</legend>
						<table>
							<tr>
								<th>Name</th>
								<th>IP</th>
								<th>Role</th>
								<th>RSSI</th>
								<th>dBm</th>
							</tr>
EOF_02
/sbin/get-rssi.sh > /tmp/page
tail -n +2 /tmp/page | awk '{print "<tr><td>"$5"</td><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td></tr>"}'
cat <<EOF_03
						</table>
					</fieldset>
					<br>
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
EOF_03
iwlist ath0 scanning | awk -F '[ :=]+' '/(ESS|Qual)/{ printf "<td>"$3"</td>" } /Encr/{ print "<td>"$4"</td><td><a href='#'>Connect</a></td></tr>" } /Cell/{ printf "<tr><td>"$6":"$7":"$8":"$9":"$10":"$11"</td>" }' | tr -d '"'
cat <<EOF_99
						</table>
					</fieldset>
				</td>
			</tr>
		</table>
	</body>
</html>
EOF_99
