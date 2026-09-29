include $(TOPDIR)/rules.mk

PKG_NAME:=chrome-glibc-runtime
PKG_VERSION:=2026-09-28
PKG_RELEASE:=1

PKG_LICENSE:=LGPL-2.1-or-later MPL-2.0 MIT
PKG_MAINTAINER:=syb999

include $(INCLUDE_DIR)/package.mk

# 预编译载荷, 保持字节一致: 默认 rstrip 会改写共享库, 对 glibc 不安全
RSTRIP:=:

define Package/chrome-glibc-runtime
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=glibc userland for glibc-only binaries on musl OpenWrt (chroot at /opt/chrome-root)
  URL:=https://www.debian.org/
  DEPENDS:=@TARGET_rockchip
endef

define Package/chrome-glibc-runtime/description
  Debian bookworm arm64 userland (glibc 2.36, libnss3/libnspr4/libglib2/libgio/libatk/
  libatspi/libdbus/libexpat/libX11/libxcb/libxkbcommon/libgbm/libdrm/libudev/libasound/
  libcups + DejaVu & WenQuanYi fonts + CA bundle), trimmed to what Chrome needs and
  installed as a chroot root at /opt/chrome-root.  This is what lets glibc-only
  binaries (chrome-headless-shell, chromedriver) run on a musl OpenWrt rootfs.
  The payload is prebuilt; regenerate it with ./gen-payload.sh.
endef

# 无上游源码, 全部载荷在 ./files
define Build/Prepare
endef

define Build/Compile
endef

define Package/chrome-glibc-runtime/install
	$(INSTALL_DIR) $(1)/opt/chrome-root
	$(CP) ./files/. $(1)/opt/chrome-root/
	$(INSTALL_DIR) $(1)/usr/share/doc/chrome-glibc-runtime
	$(INSTALL_DATA) ./README.md $(1)/usr/share/doc/chrome-glibc-runtime/README
endef

$(eval $(call BuildPackage,chrome-glibc-runtime))
