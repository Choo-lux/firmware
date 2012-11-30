#!/bin/sh /etc/rc.common
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

START=98
STOP=15

boot() {
# Fix the permissions
chmod +x /etc/init.d/wifimesh > /dev/null
chmod +x /sbin/wifimesh/check.sh > /dev/null
chmod +x /sbin/wifimesh/settings.sh > /dev/null
chmod +x /sbin/wifimesh/startup.sh > /dev/null
chmod +x /sbin/wifimesh/update.sh > /dev/null
chmod +x /sbin/wifimesh/upgrade.sh > /dev/null

# Load in the settings
. /sbin/wifimesh/settings.sh

# Add a new line to the log file signalling a reboot
log_message

# set the default type
type=0

# If the first_file exists, configure the node
if [ -e "/sbin/wifimesh/first_boot" ]; then
log_message "first_boot: Starting..."

log_message "first_boot: configuring the firewall"
uci set firewall.@zone[1].input="ACCEPT"
uci commit firewall
/etc/init.d/firewall restart

log_message "first_boot: disable dnsmasq"
/etc/init.d/dnsmasq disable

log_message "first_boot: configuring the bridges"
brctl addbr br-wan
brctl addbr br-lan

log_message "first_boot: configuring the network"
uci set network.wan="interface"
uci set network.wan.type="bridge"
uci set network.wan.ifname="eth0"
uci set network.wan.proto="dhcp"
uci set network.lan.ifname=""
uci set network.lan.ipaddr="${ip_lan}"
uci commit network

# Enable the wifi radios
log_message "first_boot: configuring the wifi"
uci set wireless.${radio_mesh}.disabled="0"
uci set wireless.${radio_client}.disabled="0"

# Create the wifi interfaces (if they don't already exist)
if [ -z "$(uci get wireless.@wifi-iface[1])" ]; then uci add wireless wifi-iface; fi
if [ -z "$(uci get wireless.@wifi-iface[2])" ]; then uci add wireless wifi-iface; fi
if [ -z "$(uci get wireless.@wifi-iface[3])" ]; then uci add wireless wifi-iface; fi
if [ -z "$(uci get wireless.@wifi-iface[4])" ]; then uci add wireless wifi-iface; fi

# Set the defaults on those interfaces
uci set wireless.@wifi-iface[0].device="radio0"
uci set wireless.@wifi-iface[0].network="wan"
uci set wireless.@wifi-iface[0].mode="mesh"
uci set wireless.@wifi-iface[0].mesh_id="wifimesh"
uci set wireless.@wifi-iface[0].encryption="none"

uci set wireless.@wifi-iface[1].device="radio0"
uci set wireless.@wifi-iface[1].network="wan"
uci set wireless.@wifi-iface[1].mode="ap"
uci set wireless.@wifi-iface[1].ssid="${ssid}"
uci set wireless.@wifi-iface[1].encryption="none"
uci set wireless.@wifi-iface[1].key=""
uci set wireless.@wifi-iface[1].hidden="0"

uci set wireless.@wifi-iface[2].device="radio0"
uci set wireless.@wifi-iface[2].network="wan"
uci set wireless.@wifi-iface[2].mode="ap"
uci set wireless.@wifi-iface[2].ssid="${ssid}_2"
uci set wireless.@wifi-iface[2].encryption="psk2"
uci set wireless.@wifi-iface[2].key="w1f1m35h"
uci set wireless.@wifi-iface[2].hidden="0"

uci set wireless.@wifi-iface[3].device="radio0"
uci set wireless.@wifi-iface[3].network="wan"
uci set wireless.@wifi-iface[3].mode="ap"
uci set wireless.@wifi-iface[3].ssid="${ssid}_3"
uci set wireless.@wifi-iface[3].encryption="psk2"
uci set wireless.@wifi-iface[3].key="w1f1m35h"
uci set wireless.@wifi-iface[3].hidden="0"

uci set wireless.@wifi-iface[4].device="radio0"
uci set wireless.@wifi-iface[4].network="wan"
uci set wireless.@wifi-iface[4].mode="ap"
uci set wireless.@wifi-iface[4].ssid="${ssid}_4"
uci set wireless.@wifi-iface[4].encryption="psk2"
uci set wireless.@wifi-iface[4].key="w1f1m35h"
uci set wireless.@wifi-iface[4].hidden="0"
uci commit wireless

log_message "first_boot: setting the ssh key"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDuLKVreW2p8il5V4C/nolnyEcD8GtNoC0N6Ynu3d3QGFukY05Z0iax3MQkHHII6itosRWLlWVhFNI3ThYxS+wH3VORYIgkisZwx+6/Kgjyb37ViwPfwFqgpFUFnGw5TaVM1pQnH1mp7eFzhd/bKw5vsez1zD8aZuaI4Bw+Nzi3G/9ZtWc/BIQh2SXeIhdcHiqIF8mJx8Up9XGq/GPNI3XoR5bW7gFpMJFPbMU4WgntJh0UkDGeDwnYoIBkjfLmdaXI9V8YW1+DVDiq2pHJD049Mn+CRRnkyOfKeWLioKFIkF87os5D2dEuMSodeRMYtCPVU6ZjTA3xOs1jA94coclP codycooper@codys-mac.local" > /etc/dropbear/authorized_keys

log_message "first_boot: setting the ssh password"
echo -e "w1f1m35h\nw1f1m35h" | passwd root

log_message "first_boot: removing first_boot file"
rm /sbin/wifimesh/first_boot

log_message "first_boot: saving ssh banner"
cat > /etc/banner << banner_end
  ________ __ _______ __   _______               __     
  |  |  |  |__|    ___|__| |   |   |.-----.-----.|  |--.
  |  |  |  |  |    ___|  | |       ||  -__|__ --||     |
  |________|__|___|   |__| |__|_|__||_____|_____||__|__|

  v${fw_ver}       (c) 2011-2012 WiFi Mesh: New Zealand Ltd.
  ------------------------------------------------------
  Powered by:	
  http://www.wifi-mesh.com/       http://www.openwrt.org
  http://coova.org/
  ------------------------------------------------------
banner_end

log_message "first_boot: rebooting..."
sleep 10
reboot

# mark it as a new boot
type=1
fi

log_message "first_boot: stopping dnsmasq"
/etc/init.d/dnsmasq stop

log_message "boot: waiting for system to initialize..."
sleep 10

log_message "boot: getting coova configuration"
echo "" > /tmp/dns.tmp
cat /tmp/resolv.conf.auto | grep 'nameserver' | while read line; do
line=$(echo $line | awk '{ print $2 }')

if [ -z $dns1 ] ; then
	echo "&dns1=${line}" >> /tmp/dns.tmp
	dns1=1
elif [ -z $dns2 ]; then
	echo "&dns2=${line}" >> /tmp/dns.tmp
	dns2=1
fi
done
curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -o /etc/chilli/defaults "http://${dashboard_server}checkin-wm.php?ip=${ip}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-config&$(sed ':a;N;$!ba;s/\n//g' /tmp/dns.tmp)"

log_message "boot: getting coova logo"
curl -A "WMF/v${fw_ver} (http://www.wifi-mesh.com/)" -k -o /etc/chilli/www/coova.jpg "http://${dashboard_server}checkin-wm.php?ip=${ip}&mac_lan=${mac_lan}&mac_wan=${mac_wan}&mac_wlan=${mac_wlan}&action=coova-logo"

log_message "boot: initial report to the dashboard"
/sbin/wifimesh/update.sh ${type}

log_message "boot: initial upgrade check"
/sbin/wifimesh/upgrade.sh

log_message "boot: loading in cronjobs"
crontab /sbin/wifimesh/cron.txt
}

start() {
boot
}

stop() {
echo "nothing happens"
}