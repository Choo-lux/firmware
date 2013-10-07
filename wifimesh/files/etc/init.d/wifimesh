#!/bin/sh /etc/rc.common
# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

START=98
STOP=15

boot() {
# Fix the permissions
chmod +x /etc/init.d/chilli > /dev/null
chmod +x /etc/init.d/wifimesh > /dev/null
chmod +x /sbin/wifimesh/*.sh > /dev/null

# Start wifimesh at boot
/etc/init.d/wifimesh enable

# Load in the settings
. /sbin/wifimesh/settings.sh

# If the first_file exists, configure the node
if [ "$(uci get wifimesh.system.first_boot)" -eq 1 ]; then
log_message "first_boot: starting..."

log_message "first_boot: configuring the device variables"
uci set wifimesh.system.architecture=$(grep 'DISTRIB_TARGET' /etc/openwrt_release | cut -d '"' -f 2 | cut -d / -f 1)
uci set wifimesh.system.cpu=$(grep 'system type' /proc/cpuinfo | cut -f2 -d ":" | cut -b 2-50 | awk '{ print $2 }')
uci set wifimesh.system.device=$(grep 'machine' /proc/cpuinfo | cut -f2 -d ":" | cut -b 2-50 | sed 's/ /_/g')

log_message "first_boot: configuring the firewall"
uci set firewall.@zone[1].input="ACCEPT"

log_message "first_boot: configuring the network"
brctl addbr br-wan
brctl addbr br-lan

uci set network.wan="interface"
uci set network.wan.type="bridge"
uci set network.wan.ifname="eth0"
uci set network.wan.proto="dhcp"
uci set network.lan.ifname=""
uci set network.lan.ipaddr="${ip_lan}"
uci set network.lan.ifname="eth1"
uci set network.wan.ifname="eth0"

echo "127.0.0.1 localhost" > /etc/hosts
echo "${ip_lan} my.wifi-mesh.co.nz my.robin-mesh.com my.open-mesh.com node chilli" >> /etc/hosts

log_message "first_boot: configuring the wifi"
uci set wireless.radio0.disabled="0"
uci set wireless.radio0.distance="2000"
uci set wireless.radio0.country="US"
uci set wireless.radio0.txpower="99"

if [ -z "$(uci get wireless.@wifi-iface[1])" ]; then uci add wireless wifi-iface; fi

uci set wireless.@wifi-iface[0].device="radio0"
uci set wireless.@wifi-iface[0].network="wan"
uci set wireless.@wifi-iface[0].mode="mesh"
uci set wireless.@wifi-iface[0].mesh_id="wifimesh"
uci set wireless.@wifi-iface[0].encryption="none"

uci set wireless.@wifi-iface[1].device="radio0"
uci set wireless.@wifi-iface[1].network="lan"
uci set wireless.@wifi-iface[1].mode="ap"
uci set wireless.@wifi-iface[1].ssid="wifimesh"
uci set wireless.@wifi-iface[1].encryption="none"
uci set wireless.@wifi-iface[1].key=""
uci set wireless.@wifi-iface[1].hidden="0"

log_message "first_boot: setting the ssh default key"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDuLKVreW2p8il5V4C/nolnyEcD8GtNoC0N6Ynu3d3QGFukY05Z0iax3MQkHHII6itosRWLlWVhFNI3ThYxS+wH3VORYIgkisZwx+6/Kgjyb37ViwPfwFqgpFUFnGw5TaVM1pQnH1mp7eFzhd/bKw5vsez1zD8aZuaI4Bw+Nzi3G/9ZtWc/BIQh2SXeIhdcHiqIF8mJx8Up9XGq/GPNI3XoR5bW7gFpMJFPbMU4WgntJh0UkDGeDwnYoIBkjfLmdaXI9V8YW1+DVDiq2pHJD049Mn+CRRnkyOfKeWLioKFIkF87os5D2dEuMSodeRMYtCPVU6ZjTA3xOs1jA94coclP cody@wifi-mesh.co.nz" > /etc/dropbear/authorized_keys

log_message "first_boot: setting the ssh default password"
echo -e "w1f1m35h\nw1f1m35h" | passwd root

log_message "first_boot: configuring coovachilli"
echo "HS_LANIF='br-lan'
HS_WANIF='br-wan'
HS_NETWORK='$(echo $ip_lan | cut -d . -f 1-3).0'
HS_NETMASK='255.255.255.0'
HS_UAMLISTEN='${ip_lan}'
HS_NASMAC='$(ifconfig br-lan | grep 'HWaddr' | awk '{ print $5 }' | sed 's/:/-/g')'
HS_NASIP='${ip_lan}'
HS_UAMPORT='3990'
HS_UAMUIPORT='4990'
HS_DNS1='8.8.8.8'
HS_DNS2='8.8.4.4'
HS_NASID='000'
HS_RADIUS='localhost'
HS_RADIUS2='localhost'
HS_RADSECRET='secret'
HS_UAMSECRET='secret'
HS_UAMALIASNAME='chilli'
HS_AAA='http'
HS_UAMAAAURL='http://localhost/aaa.txt'
HS_UAMSERVER='${ip_lan}'
HS_UAMFORMAT='http://dashboard.wifi-mesh.co.nz/aaa.php'
HS_UAMHOMEPAGE='http://${ip_lan}:3990/www/coova.html'
HS_TCP_PORTS='22 23 80 443'
HS_MODE='hotspot'
HS_TYPE='chillispot'
HS_WWWDIR='/etc/chilli/www'
HS_WWWBIN='/etc/chilli/wwwsh'
HS_RAD_PROTO='chap'" > /etc/chilli/defaults
/etc/init.d/chilli enable

log_message "first_boot: removing first_boot marker file"
uci set wifimesh.system.first_boot="0"

log_message "first_boot: saving configuration"
uci commit
sleep 5

log_message "first_boot: getting dashboard configuration"
/sbin/wifimesh/update.sh 1

log_message "first_boot: done, rebooting..."
sleep 1
reboot
fi

log_message "boot: saving ssh banner"
cat > /etc/banner << banner_end
  ________ __ _______ __   _______               __     
  |  |  |  |__|    ___|__| |   |   |.-----.-----.|  |--.
  |  |  |  |  |    ___|  | |       ||  -__|__ --||     |
  |________|__|___|   |__| |__|_|__||_____|_____||__|__|

  v$(uci get wifimesh.system.version)       (c) 2011-2013 WiFi Mesh: New Zealand Ltd.
  ------------------------------------------------------
  Powered by:	
  http://www.wifi-mesh.co.nz     http://www.openwrt.org
  http://coova.org               http://www.wifirush.com
  ------------------------------------------------------
banner_end

log_message "boot: loading in cronjobs"
echo "# Copyright © 2011-2013 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

* * * * * /sbin/wifimesh/check.sh
* * * * * /sbin/wifimesh/update.sh
0 * * * * /sbin/wifimesh/upgrade.sh
*/5 * * * * /sbin/wifimesh/monitor.sh
" > /tmp/cron.tmp
crontab /tmp/cron.tmp

log_message "boot: enabling stp"
sleep 1 && brctl stp br-wan on
}

start() {
boot
}

stop() {
echo "nothing happens"
}
