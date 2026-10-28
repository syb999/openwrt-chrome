#!/bin/sh
# chromedriver 启动器: 进 glibc armhf chroot 启动 Debian 的 chromedriver,
# 让它去拉起同一个 chroot 里的 chromium。
# 用法: /opt/chrome-root/cdrv.sh --version
#       /opt/chrome-root/cdrv.sh --port=9515
ROOT="${CHROME_ROOT:-/opt/chrome-root}"
DRV=/opt/chrome-tools/chromedriver
BROWSER=/opt/chrome/chromium

[ -x "$ROOT$DRV" ] || { echo "chromedriver 不在 $ROOT$DRV (需要 chromium-driver-armhf 包)" >&2; exit 1; }
[ -x "$ROOT$BROWSER" ] || { echo "chromium 不在 $ROOT$BROWSER (需要 chromium-armhf 包)" >&2; exit 1; }

is_mounted() { grep -q " $ROOT$1 " /proc/mounts; }
mkdir -p /tmp/shm /tmp/chrome-profile 2>/dev/null
is_mounted /dev  || mount -o bind /dev  "$ROOT/dev"
is_mounted /proc || mount -t proc proc  "$ROOT/proc"
is_mounted /sys  || mount -o bind /sys  "$ROOT/sys"
is_mounted /tmp  || mount -o bind /tmp  "$ROOT/tmp"
[ -s /tmp/resolv.conf ] && cp -f /tmp/resolv.conf "$ROOT/etc/resolv.conf" 2>/dev/null

exec chroot "$ROOT" "$DRV" --binary-location="$BROWSER" "$@"
