#
# Copyright (C) 2007-2010 OpenWrt.org
# Copyright (C) 2012-2013 WiFi Mesh: New Zealand Limited
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wifimesh-monitor
PKG_VERSION:3.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/wifimesh-monitor
	SUBMENU:=WiFi Mesh
	SECTION:=net
	CATEGORY:=Network
	DEPENDS:=+wifimesh +libc +libpthread +libopenssl +libpcap +iwinfo +wireless-tools
	TITLE:=WiFi Mesh Monitor
	URL:=http://www.wifi-mesh.co.nz/
endef

define Package/wifimesh-monitor/description
	Adds wireless monitoring to the WiFi Mesh system.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/wifimesh-monitor/install
	$(INSTALL_DIR) $(1)
	$(CP) ./files/* $(1)/
endef

define Package/wifimesh-monitor/postinst
#!/bin/sh
# check if we are on real system
if [ -z "${IPKG_INSTROOT}" ]; then
	logger "Fix the permissions for wifimesh-monitor"
	chmod +x /usr/sbin/airodump-ng
fi
exit 0
endef

$(eval $(call BuildPackage,wifimesh-monitor))