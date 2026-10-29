#
# luci-app-chrome-armhf —— 32 位 ARM(armv7/Cortex-A5, 玩客云 meson8b)版的
# luci-app-chrome。与 aarch64 版(package/luci-app-chrome)是**两个独立包**,
# 互不影响, 也不共享任何文件路径以外的代码:
#   浏览器  chromium-armhf  (Debian bookworm chromium 150, 完整浏览器)
#   驱动    chromium-driver-armhf (同版本 chromedriver + cdrv.sh)
#   运行环境 chrome-glibc-runtime-armhf (glibc armhf 用户空间, chroot)
# 与 aarch64 版的真正差别只有两处(本包内已处理好):
#   1. 完整 chromium 必须显式 --headless=new(chrome-headless-shell 天生 headless);
#   2. 进程名是 chromium 而不是 chrome-headless-shell ⇒ 清残留/查状态的匹配要认得它。
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-chrome-armhf
# 🔴 luci.mk 生成的 `Version:` 字段只取 PKG_VERSION（PKG_RELEASE 不进 Version），
# 所以**每次发新版都必须把这个值往上抬**，否则 opkg 会判定 "installed in root is
# up to date" 而拒绝安装（就地升级就"看不到新功能"）。
# 约定：日期 + 当天第几版。
PKG_VERSION:=2026-10-29-2
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=syb999

# luci.mk turns every po/<lang>/ directory into a luci-i18n-chrome-<lang>
# subpackage: po/zh_Hans/chrome.po is compiled with po2lmo into
#   /usr/lib/lua/luci/i18n/chrome.zh-cn.lmo
# and shipped as luci-i18n-chrome-zh-cn.  Select
# CONFIG_PACKAGE_luci-i18n-chrome-zh-cn=y for the Chinese UI; without it the
# English source strings are used (that is the default).
#
# The app ships a JS view under htdocs/, a python3 backend under root/ and the
# translation catalogues under po/.
LUCI_TITLE:=LuCI App for headless Chromium (armhf / 32-bit ARM) - page grabber + media resource extractor
#
# 依赖 armhf 三件套(各自带 @TARGET_amlogic, 目标限制由此继承).
# python3-selenium 会带进 python3-urllib + python3-openssl + certifi + urllib3.
# 注意: 本包只装 ipk, **不进固件**(内存只有 1GB, 固件里放不下 chromium 的 400MB 载荷)。
LUCI_DEPENDS:=+luci-base +chromium-armhf +chromium-driver-armhf +python3-selenium
LUCI_PKGARCH:=all

# luci.mk only defines a default postinst `ifndef`, so this one replaces it:
# the same cache clearing as the default, plus a fresh mtime on the shipped view
# JS (the packaging preserves the source mtime, and a months-old Last-Modified
# makes browsers treat their cached copy as fresh ==> "the frontend change did
# not take effect"), plus the workaround for the translation dictionary.
#
# /cgi-bin/luci/admin/translations/<lang> (window.TR, used by _() in JS views)
# is served with "Cache-Control: max-age=31536000" and an ETag computed from
# luci-base's own base.<lang>.lmo, while the theme omits ?v= -> after a
# translation update browsers would keep the stale dictionary for a year.
# Touching that lmo changes the ETag (content untouched) so every client
# refetches the dictionary.
define Package/luci-app-chrome/postinst
[ -n "$${IPKG_INSTROOT}" ] || {
	rm -f /tmp/luci-indexcache
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null
	chmod 0755 /usr/bin/chromeui 2>/dev/null
	touch /www/luci-static/resources/view/chrome/main.js 2>/dev/null
	# the view JS has no versioned URL, so a browser may keep its copy: tell the
	# user to hard-refresh once after an upgrade (see README)
	for l in /usr/lib/lua/luci/i18n/base.*.lmo; do
		[ -e "$$l" ] && touch "$$l"
	done
	exit 0
}
endef

# luci.mk ends with `$(eval $(call BuildPackage,...))`, and that call EXPANDS the
# whole BuildPackage body immediately - so a `define Build/Compile` written after
# the include is too late to have any effect (the recipe was already inlined).
# Hooks referenced by the BuildPackage body work if they are registered BEFORE
# the include, which is what these two are for: drop host bytecode that would
# otherwise be shipped.
#
# (luci.mk copies root/ into PKG_BUILD_DIR verbatim and installs it from there,
# so running `python3 -m py_compile root/usr/bin/chromeui` in this directory
# used to put a host .pyc inside the ipk.)
define chromeui-drop-host-pycache
	find $(PKG_BUILD_DIR) -name '__pycache__' -type d -print0 | xargs -0 -r rm -rf
	find $(PKG_BUILD_DIR) -name '*.pyc' -delete
	# stamp the real package version into the backend AND the view script, so the
	# page can tell whether the browser is still running an older main.js
	sed -i 's/__PKG_VERSION__/$(PKG_VERSION)/g' $(PKG_BUILD_DIR)/root/usr/bin/chromeui
	sed -i 's/__PKG_VERSION__/$(PKG_VERSION)/g' $(PKG_BUILD_DIR)/htdocs/luci-static/resources/view/chrome/main.js
	# the view reads its own catalogue over the RPC channel (LuCI's HTTP one is
	# cached for a year, see tools/po2json.py)
	$(if $(wildcard ./po/zh_Hans/chrome.po),python3 ./tools/po2json.py ./po/zh_Hans/chrome.po $(PKG_BUILD_DIR)/root/usr/share/chromeui/i18n/zh-cn.json,true)
endef
Hooks/Prepare/Post += chromeui-drop-host-pycache
Hooks/Compile/Pre += chromeui-drop-host-pycache

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
