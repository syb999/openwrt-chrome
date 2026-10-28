#!/bin/sh
# chromium (Debian armhf) 启动器 (OpenWrt/musl -> glibc armhf chroot, 无需 docker/qemu)
# 用法: /opt/chrome-root/run-chrome.sh --version
#       /opt/chrome-root/run-chrome.sh --dump-dom https://example.com
#       /opt/chrome-root/run-chrome.sh --screenshot=/tmp/a.png --window-size=1280,800 <url>
# 测试时可以换 root: CHROME_ROOT=/tmp/chrome-test /opt/chrome-root/run-chrome.sh --version
#
# 和 aarch64 版的差别: 32 位 ARM 没有官方的 chrome-headless-shell,
# 这里跑的是 Debian bookworm 的 chromium(armhf, 150.x), 所以由本脚本补 --headless=new。
ROOT="${CHROME_ROOT:-/opt/chrome-root}"
BIN=/opt/chrome/chromium
FALLBACK=/opt/chrome/chrome-headless-shell

[ -x "$ROOT$BIN" ] || BIN=$FALLBACK
if [ ! -x "$ROOT$BIN" ]; then
	echo "chromium 不在 $ROOT/opt/chrome/ (需要 chromium-armhf 包)" >&2
	exit 1
fi

is_mounted() { grep -q " $ROOT$1 " /proc/mounts; }

mkdir -p /tmp/shm /tmp/chrome-profile 2>/dev/null
is_mounted /dev  || mount -o bind /dev  "$ROOT/dev"
is_mounted /proc || mount -t proc proc  "$ROOT/proc"
is_mounted /sys  || mount -o bind /sys  "$ROOT/sys"
is_mounted /tmp  || mount -o bind /tmp  "$ROOT/tmp"

# DNS: 跟随路由器当前生效的解析配置
[ -s /tmp/resolv.conf ] && cp -f /tmp/resolv.conf "$ROOT/etc/resolv.conf" 2>/dev/null

# headless 只要没被显式要求就不要 --headless; 默认给 new headless
case " $* " in
	*" --headless"*|*" --dump-dom"*|*" --screenshot"*|*" --print-to-pdf"*|*" --version"*) ;;
	*) set -- --headless=new "$@" ;;
esac

exec chroot "$ROOT" "$BIN" \
    --no-sandbox \
    --disable-gpu \
    --disable-dev-shm-usage \
    --no-first-run \
    --user-data-dir=/tmp/chrome-profile \
    "$@"
