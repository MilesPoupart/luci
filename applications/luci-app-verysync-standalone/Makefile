# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Verysync
LUCI_DEPENDS:=+wget +curl
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-verysync-standalone
PKG_VERSION:=1.8
PKG_RELEASE:=4

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
