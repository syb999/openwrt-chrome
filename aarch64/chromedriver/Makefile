include $(TOPDIR)/rules.mk

PKG_NAME:=chromedriver
PKG_VERSION:=154.0.8037.57
PKG_RELEASE:=1

PKG_LICENSE:=BSD-3-Clause
PKG_MAINTAINER:=syb999

include $(INCLUDE_DIR)/package.mk

RSTRIP:=:

define Package/chromedriver
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=ChromeDriver for chrome-headless-shell (arm64)
  URL:=https://googlechromelabs.github.io/chrome-for-testing/
  DEPENDS:=@TARGET_rockchip +chrome-headless-shell
endef

define Package/chromedriver/description
  ChromeDriver (Chrome for Testing, linux-arm64, glibc) plus the wrapper
  /opt/chrome-root/cdrv.sh that enters the glibc chroot and starts it with
  --binary-location pointing at the packaged chrome-headless-shell.

  It runs the driver inside the chroot, so the musl-side python3 (selenium) can
  drive it and the driver can spawn the browser:

    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.chrome.options import Options
    o = Options(); o.binary_location = "/opt/chrome/chrome-headless-shell"
    o.add_argument("--no-sandbox"); o.add_argument("--disable-gpu")
    o.add_argument("--disable-dev-shm-usage")
    webdriver.Chrome(service=Service(executable_path="/opt/chrome-root/cdrv.sh"),
                     options=o)

  chromedriver 与 chrome 必须同版本 (同一个 Chrome for Testing 版本号)。
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/chromedriver/install
	$(INSTALL_DIR) $(1)/opt/chrome-root/opt/chrome-tools
	$(INSTALL_BIN) ./files/opt/chrome-tools/chromedriver $(1)/opt/chrome-root/opt/chrome-tools/chromedriver
	$(INSTALL_DIR) $(1)/opt/chrome-root
	$(INSTALL_BIN) ./files/cdrv.sh $(1)/opt/chrome-root/cdrv.sh
	$(INSTALL_DIR) $(1)/usr/share/doc/chromedriver
	$(INSTALL_DATA) ./README.md $(1)/usr/share/doc/chromedriver/README
endef

define Package/chromedriver/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	chmod 0755 /opt/chrome-root/cdrv.sh 2>/dev/null
	chmod 0755 /opt/chrome-root/opt/chrome-tools/chromedriver 2>/dev/null
	DRV=$(/opt/chrome-root/cdrv.sh --version 2>/dev/null | head -1)
	echo "chromedriver: $${DRV:-未能取到版本, 看看 runtime/chrome 包装了没}"
}
exit 0
endef

$(eval $(call BuildPackage,chromedriver))
