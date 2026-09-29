include $(TOPDIR)/rules.mk

PKG_NAME:=chrome-headless-shell
PKG_VERSION:=154.0.8037.57
PKG_RELEASE:=1

PKG_LICENSE:=BSD-3-Clause
PKG_MAINTAINER:=syb999

include $(INCLUDE_DIR)/package.mk

RSTRIP:=:

define Package/chrome-headless-shell
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Chrome for Testing headless shell (arm64)
  URL:=https://googlechromelabs.github.io/chrome-for-testing/
  DEPENDS:=@TARGET_rockchip +chrome-glibc-runtime
endef

define Package/chrome-headless-shell/description
  Google Chrome for Testing, chrome-headless-shell build, linux-arm64 (glibc).
  Browser files go to /opt/chrome-root/opt/chrome, launcher to
  /opt/chrome-root/run-chrome.sh (进入 glibc chroot 后再启动浏览器).

  Usage:
    /opt/chrome-root/run-chrome.sh --dump-dom https://example.com
    /opt/chrome-root/run-chrome.sh --screenshot=/tmp/a.png --window-size=1280,800         --virtual-time-budget=8000 https://www.baidu.com

  chrome-headless-shell 与 chromedriver 必须同版本: 两者都来自同一个
  Chrome for Testing 版本号, 升级时两个包一起改 PKG_VERSION/PKG_HASH。
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/chrome-headless-shell/install
	$(INSTALL_DIR) $(1)/opt/chrome-root/opt/chrome
	$(CP) ./files/opt/chrome/. $(1)/opt/chrome-root/opt/chrome/
	$(INSTALL_DIR) $(1)/opt/chrome-root
	$(INSTALL_BIN) ./files/run-chrome.sh $(1)/opt/chrome-root/run-chrome.sh
	$(INSTALL_DIR) $(1)/usr/share/doc/chrome-headless-shell
	$(INSTALL_DATA) ./README.md $(1)/usr/share/doc/chrome-headless-shell/README
endef

define Package/chrome-headless-shell/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	chmod 0755 /opt/chrome-root/run-chrome.sh 2>/dev/null
	chmod 0755 /opt/chrome-root/opt/chrome/chrome-headless-shell 2>/dev/null
	echo "chrome-headless-shell: 试跑 /opt/chrome-root/run-chrome.sh --version"
}
exit 0
endef

$(eval $(call BuildPackage,chrome-headless-shell))
