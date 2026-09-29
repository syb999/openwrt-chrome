#!/bin/sh
# 重新生成 chrome-glibc-runtime 的 ./files 载荷 (在有网、有 dpkg-deb 的 x86_64 主机上跑)
# 原理: 用 apt 的 Dir 覆盖把 arm64 的 deb 下到临时目录, 再用 dpkg-deb -x 展开成根文件系统。
# 不需要 root, 不需要 docker, 不需要 qemu。
set -e
WORK=${WORK:-/tmp/chrome-glibc-payload}
DEBS=$WORK/arm
PKGS="libc6 libgcc-s1 libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0
      libcups2 libdbus-1-3 libxkbcommon0 libgbm1 libx11-6 libxcomposite1 libxdamage1
      libxext6 libxfixes3 libxrandr2 libasound2 libexpat1 libxcb1 libglib2.0-0 libudev1
      ca-certificates fontconfig fonts-dejavu-core fonts-wqy-microhei"

rm -rf "$WORK"; mkdir -p "$DEBS/lists/partial" "$DEBS/cache/archives/partial" "$WORK/root"
: > "$DEBS/status"
printf 'deb [arch=arm64] http://deb.debian.org/debian bookworm main\n' > "$DEBS/sources.list"

A="-o Dir=$DEBS -o Dir::Etc::sourcelist=$DEBS/sources.list -o Dir::Etc::sourceparts=/dev/null
   -o Dir::State::lists=$DEBS/lists -o Dir::Cache=$DEBS/cache
   -o Dir::State::status=$DEBS/status -o APT::Architecture=arm64 -o APT::Architectures=arm64"

apt-get $A --allow-unauthenticated update
apt-get $A --allow-unauthenticated -y --download-only --no-install-recommends install $PKGS

for d in "$DEBS"/cache/archives/*.deb; do dpkg-deb -x "$d" "$WORK/root/"; done

cd "$WORK/root"
mkdir -p etc tmp var/tmp dev/shm proc sys root
printf 'root:x:0:0:root:/root:/bin/sh\n' > etc/passwd
printf 'root:x:0:\n' > etc/group
printf 'nameserver 223.5.5.5\n' > etc/resolv.conf   # 运行时会被启动器用路由器的 /tmp/resolv.conf 覆盖
printf '127.0.0.1 localhost\n' > etc/hosts

# 花装: 去掉对本用途无用的部分
rm -rf usr/share/doc usr/share/man usr/share/locale var/lib/apt var/lib/dpkg var/cache var/log

HERE=$(cd "$(dirname "$0")" && pwd)
rm -rf "$HERE/files"; mkdir -p "$HERE/files"
tar -C "$WORK/root" -cf - lib usr etc var root dev proc sys tmp | tar -C "$HERE/files" -xf -
echo "载荷已生成: $HERE/files ($(du -sh "$HERE/files" | cut -f1))"
