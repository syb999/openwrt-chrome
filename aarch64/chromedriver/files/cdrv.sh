#!/bin/sh
# chromedriver 启动器 (OpenWrt/musl -> glibc chroot)
# 让系统里的 python3(selenium, musl) 去驱动 chroot 里的 glibc chromedriver,
# chromedriver 再拉起同一个 chroot 里的 chrome-headless-shell。
# 用法: selenium 里 Service(executable_path="/opt/chrome-root/cdrv.sh")
# 测试时可以换 root: CHROME_ROOT=/tmp/chrome-test <此脚本> --version
ROOT="${CHROME_ROOT:-/opt/chrome-root}"
DRV=/opt/chrome-tools/chromedriver
BIN=/opt/chrome/chrome-headless-shell

[ -x "$ROOT$DRV" ] || { echo "chromedriver 不在 $ROOT$DRV" >&2; exit 1; }
[ -x "$ROOT$BIN" ] || { echo "chrome 不在 $ROOT$BIN (需要 chrome-headless-shell 包)" >&2; exit 1; }

is_mounted() { grep -q " $ROOT$1 " /proc/mounts; }

mkdir -p /tmp/shm 2>/dev/null
is_mounted /dev  || mount -o bind /dev  "$ROOT/dev"
is_mounted /proc || mount -t proc proc  "$ROOT/proc"
is_mounted /sys  || mount -o bind /sys  "$ROOT/sys"
is_mounted /tmp  || mount -o bind /tmp  "$ROOT/tmp"
[ -s /tmp/resolv.conf ] && cp -f /tmp/resolv.conf "$ROOT/etc/resolv.conf" 2>/dev/null

# chromedriver 与 chrome 必须同版本, 由两个包的 PKG_VERSION 保证
exec chroot "$ROOT" "$DRV" --binary-location="$BIN" "$@"
