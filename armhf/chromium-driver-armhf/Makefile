include $(TOPDIR)/rules.mk

PKG_NAME:=chromium-driver-armhf
PKG_VERSION:=150.0.7871.100
PKG_RELEASE:=3

PKG_LICENSE:=BSD-3-Clause
PKG_MAINTAINER:=syb999

include $(INCLUDE_DIR)/package.mk

RSTRIP:=:

define Package/chromium-driver-armhf
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=chromedriver 150 (Debian armhf) + wrapper for the glibc chroot
  URL:=https://packages.debian.org/bookworm/armhf/chromium-driver
  DEPENDS:=@TARGET_amlogic +chrome-glibc-runtime-armhf +chromium-armhf
  PROVIDES:=chrome-driver
endef

define Package/chromium-driver-armhf/description
  Debian bookworm chromedriver armhf (150.x) installed into the glibc chroot at
  /opt/chrome-root, plus the launcher /opt/chrome-root/cdrv.sh which enters the
  chroot and points the driver at the chromium binary there.

  Version must match chromium-armhf exactly (both 150.0.7871.100): the Debian
  chromium and chromium-driver packages are built from the same source release.

  Usage (python3-selenium):
    o = Options(); o.binary_location = "/opt/chrome/chromium"
    o.add_argument("--headless=new")        # armhf 跑的是完整 chromium, 不是 headless_shell
    for a in ("--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"):
        o.add_argument(a)
    d = webdriver.Chrome(service=Service(executable_path="/opt/chrome-root/cdrv.sh"), options=o)
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/chromium-driver-armhf/install
	$(INSTALL_DIR) $(1)/opt/chrome-root/opt/chrome-tools
	$(CP) ./files/opt/chrome-tools/chromedriver $(1)/opt/chrome-root/opt/chrome-tools/chromedriver
	$(INSTALL_DIR) $(1)/opt/chrome-root
	$(INSTALL_BIN) ./files/cdrv.sh $(1)/opt/chrome-root/cdrv.sh
	$(INSTALL_DIR) $(1)/usr/share/doc/chromium-driver-armhf
	$(INSTALL_DATA) ./README.md $(1)/usr/share/doc/chromium-driver-armhf/README
endef

define Package/chromium-driver-armhf/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	chmod 0755 /opt/chrome-root/cdrv.sh 2>/dev/null
	chmod 0755 /opt/chrome-root/opt/chrome-tools/chromedriver 2>/dev/null
	echo "chromium-driver-armhf: 试跑 /opt/chrome-root/cdrv.sh --version"
}
exit 0
endef

$(eval $(call BuildPackage,chromium-driver-armhf))
