#
# Copyright (C) 2007-2010 OpenWrt.org
# Copyright (C) 2012-2013 WiFi Mesh: New Zealand Limited
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wifimesh
PKG_VERSION:3.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/wifimesh
	SUBMENU:=WiFi Mesh
	SECTION:=net
	CATEGORY:=Network
	DEPENDS:=+om-watchdog +curl +unzip +coova-chilli
	TITLE:=WiFi Mesh (base)
	URL:=http://www.wifi-mesh.co.nz/
endef

define Package/wifimesh/description
	Auto configuration, dashboard reporting and 802.11s meshing.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/wifimesh/install
	$(INSTALL_DIR) $(1)
	$(CP) ./files/* $(1)/
endef

define Package/wifimesh/postinst
#!/bin/sh
# check if we are on real system
if [ -z "${IPKG_INSTROOT}" ]; then
	echo "Fix the permissions for wifimesh"
	chmod +x /etc/init.d/chilli
	chmod +x /etc/init.d/wifimesh
	chmod +x /etc/rc.d/chilli
	chmod +x /etc/rc.d/wifimesh
	chmod +x /sbin/wifimesh/*.sh
	chmod +x /www/cgi-bin/*.cgi
	
	echo "Enabling rc.d symlink for wifimesh"
	/etc/init.d/wifimesh enable
fi
exit 0
endef

define Package/wifimesh/prerm
#!/bin/sh
# check if we are on real system
if [ -z "${IPKG_INSTROOT}" ]; then
	echo "Removing rc.d symlink for wifimesh"
	/etc/init.d/wifimesh disable
fi
exit 0
endef

$(eval $(call BuildPackage,wifimesh))