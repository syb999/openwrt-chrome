include $(TOPDIR)/rules.mk

PKG_NAME:=chromium-armhf
PKG_VERSION:=150.0.7871.100
PKG_RELEASE:=1

PKG_LICENSE:=BSD-3-Clause
PKG_MAINTAINER:=syb999

include $(INCLUDE_DIR)/package.mk

RSTRIP:=:

define Package/chromium-armhf
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Chromium 150 (Debian armhf) for 32-bit ARM OpenWrt, runs in the glibc chroot
  URL:=https://packages.debian.org/bookworm/armhf/chromium
  DEPENDS:=@TARGET_amlogic +chrome-glibc-runtime-armhf
  PROVIDES:=chrome-browser
endef

define Package/chromium-armhf/description
  Debian bookworm chromium armhf (150.x) installed into the glibc chroot at
  /opt/chrome-root - the 32-bit ARM answer to the aarch64 chrome-headless-shell
  package (Google ships no 32-bit ARM Chrome).

  Layout is identical to the aarch64 packages, so luci-app-chrome and the
  /opt/chrome-root/run-chrome.sh contract keep working:
    /opt/chrome-root/opt/chrome/chromium               the browser (ELF, glibc armhf)
    /opt/chrome-root/opt/chrome/chrome-headless-shell  symlink for compatibility
    /opt/chrome-root/run-chrome.sh                     launcher (chroot + bind mounts)

  Note: chromium needs --headless=new for headless operation; run-chrome.sh adds it
  automatically. In Selenium, pass "--headless=new" yourself.

  armhf support tops out at chromium 150: Debian stopped building armhf from 151.
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/chromium-armhf/install
	$(INSTALL_DIR) $(1)/opt/chrome-root/opt/chrome
	$(CP) ./files/opt/chrome/. $(1)/opt/chrome-root/opt/chrome/
	$(INSTALL_DIR) $(1)/opt/chrome-root
	$(INSTALL_BIN) ./files/run-chrome.sh $(1)/opt/chrome-root/run-chrome.sh
	$(INSTALL_DIR) $(1)/usr/share/doc/chromium-armhf
	$(INSTALL_DATA) ./README.md $(1)/usr/share/doc/chromium-armhf/README
endef

define Package/chromium-armhf/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	chmod 0755 /opt/chrome-root/run-chrome.sh 2>/dev/null
	chmod 0755 /opt/chrome-root/opt/chrome/chromium 2>/dev/null
	chmod 0755 /opt/chrome-root/opt/chrome/chrome_crashpad_handler 2>/dev/null
	[ -e /opt/chrome-root/opt/chrome/chrome-headless-shell ] || \
		ln -sf chromium /opt/chrome-root/opt/chrome/chrome-headless-shell 2>/dev/null
	echo "chromium-armhf: 试跑 /opt/chrome-root/run-chrome.sh --version"
}
exit 0
endef

$(eval $(call BuildPackage,chromium-armhf))
