include $(TOPDIR)/rules.mk

PKG_NAME:=wifimesh
PKG_VERSION:1.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/wifimesh/Default
  URL:=http://www.wifi-mesh.com/
  MAINTAINER:=Cody Cooper <cody@wifi-mesh.com>
endef

define Package/wifimesh
	SECTION:=net
	CATEGORY:=Network
	TITLE:=WiFi Mesh
endef

define Package/wifimesh/description
	Auto configuring, reporting and meshing set of scripts.
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
if [ -z "$${IPKG_INSTROOT}" ]; then
        echo "Fix the permissions for wifimesh"
        chmod -R +x /etc/init.d
        chmod -R +x /etc/rc.d
        chmod -R +x /sbin/wifimesh
        
        echo "Enabling rc.d symlink for wifimesh"
        /etc/init.d/wifimesh enable
fi
exit 0
endef

define Package/wifimesh/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
        echo "Removing rc.d symlink for wifimesh"
        /etc/init.d/wifimesh disable
fi
exit 0
endef

$(eval $(call BuildPackage,wifimesh))