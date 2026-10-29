include $(TOPDIR)/rules.mk

PKG_NAME:=chrome-glibc-runtime-armhf
PKG_VERSION:=2026-10-28
PKG_RELEASE:=3

PKG_LICENSE:=LGPL-2.1-or-later MPL-2.0 MIT
PKG_MAINTAINER:=syb999

include $(INCLUDE_DIR)/package.mk

# 预编译载荷, 保持字节一致: 默认 rstrip 会改写共享库, 对 glibc 不安全
RSTRIP:=:

define Package/chrome-glibc-runtime-armhf
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=glibc armhf userland for glibc-only binaries on musl OpenWrt (chroot at /opt/chrome-root)
  URL:=https://www.debian.org/
  # 32 位 ARM (armv7, 例如玩客云 amlogic/meson8b cortex-a5 vfpv4)
  DEPENDS:=@TARGET_amlogic
endef

define Package/chrome-glibc-runtime-armhf/description
  Debian bookworm armhf userland (glibc 2.36) trimmed to exactly the shared libraries
  chromium NEEDs (recursive NEEDED closure), plus CA bundle, DejaVu and WenQuanYi fonts,
  installed as a chroot root at /opt/chrome-root.

  This is what lets glibc-only 32-bit ARM binaries (Debian's chromium, chromedriver) run
  on a musl OpenWrt rootfs natively - no qemu.  Same layout as the aarch64 packages, so
  luci-app-chrome works unchanged.

  Pair with chromium-armhf (browser) and chromium-driver-armhf (Selenium).
  Payload is prebuilt; regenerate with ./gen-payload.sh.
endef

# 无上游源码, 全部载荷在 ./files
define Build/Prepare
endef

define Build/Compile
endef

define Package/chrome-glibc-runtime-armhf/install
	$(INSTALL_DIR) $(1)/opt/chrome-root
	$(CP) ./files/. $(1)/opt/chrome-root/
	$(INSTALL_DIR) $(1)/usr/share/doc/chrome-glibc-runtime-armhf
	$(INSTALL_DATA) ./README.md $(1)/usr/share/doc/chrome-glibc-runtime-armhf/README
endef

# 32 位 armv7 用户空间: 关键库必须可执行位, 否则 ld.so 找不到
define Package/chrome-glibc-runtime-armhf/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	chmod 0755 /opt/chrome-root/lib/ld-linux-armhf.so.3 2>/dev/null
	chmod 0755 /opt/chrome-root/lib/arm-linux-gnueabihf/*.so* 2>/dev/null
	chmod 0755 /opt/chrome-root/usr/lib/arm-linux-gnueabihf/*.so* 2>/dev/null
}
exit 0
endef

$(eval $(call BuildPackage,chrome-glibc-runtime-armhf))
