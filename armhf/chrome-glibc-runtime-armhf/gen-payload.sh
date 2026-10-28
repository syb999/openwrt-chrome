#!/bin/sh
# 重新生成 chrome-glibc-runtime-armhf 的 ./files 载荷 (在有网、有 dpkg-deb+python3 的主机上跑)
# 原理: 用 apt 的 Dir 覆盖把 armhf 的 deb 下到临时目录, 用 dpkg-deb -x 展开,
#       然后只保留 chromium 真正 NEEDED 的共享库(递归闭包) + 证书 + 字体。
# 不需要 root, 不需要 docker, 不需要 qemu。
#
# 为什么不能直接搬 aarch64 那套: 官方没有 32 位 ARM 版 Chrome/chrome-headless-shell,
# 只能用 Debian bookworm 的 chromium(armhf, 150.x) + chromium-driver。
# Debian 从 trixie(151+) 起不再构建 armhf, 所以 150 是 armhf 的天花板。
set -e
LC_ALL=C
export LC_ALL

HERE=$(cd "$(dirname "$0")" && pwd)   # 必须在后面 cd 之前算

WORK=${WORK:-/tmp/chrome-armhf-payload}
DEBS=$WORK/arm
ROOT=$WORK/root
CHROME_BIN_REL=usr/lib/chromium/chromium

PKGS="chromium chromium-driver
      libc6 libgcc-s1 ca-certificates fontconfig fonts-dejavu-core fonts-wqy-microhei
      libnss3 libnspr4 libglib2.0-0 libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0
      libdbus-1-3 libexpat1 libcups2 libdrm2 libgbm1 libxkbcommon0 libasound2 libpulse0"

rm -rf "$WORK"; mkdir -p "$DEBS/lists/partial" "$DEBS/cache/archives/partial" \
	"$DEBS/etc/apt/preferences.d" "$DEBS/etc/apt/trusted.gpg.d" "$ROOT"
: > "$DEBS/status"
printf 'deb [arch=armhf trusted=yes] http://deb.debian.org/debian bookworm main\n' > "$DEBS/sources.list"

A="-o Dir=$DEBS -o Dir::Etc::sourcelist=$DEBS/sources.list -o Dir::Etc::sourceparts=/dev/null
   -o Dir::State::lists=$DEBS/lists -o Dir::Cache=$DEBS/cache
   -o Dir::State::status=$DEBS/status -o APT::Architecture=armhf -o APT::Architectures=armhf,all"

apt-get $A update
apt-get $A -y --download-only --no-install-recommends install $PKGS

for d in "$DEBS"/cache/archives/*.deb; do dpkg-deb -x "$d" "$ROOT/"; done

cd "$ROOT"
mkdir -p etc tmp var/tmp dev/shm proc sys root run
printf 'root:x:0:0:root:/root:/bin/sh\n' > etc/passwd
printf 'root:x:0:\n' > etc/group
printf 'nameserver 223.5.5.5\n' > etc/resolv.conf    # 运行时由启动器用路由器的 /tmp/resolv.conf 覆盖
printf '127.0.0.1 localhost\n' > etc/hosts

# 去掉对本用途无用的部分
rm -rf usr/share/doc usr/share/man usr/share/locale usr/share/icons usr/share/perl usr/share/perl5 \
       var/lib/apt var/lib/dpkg var/cache var/log \
       usr/lib/*/perl* usr/lib/*/systemd usr/lib/tmpfiles.d usr/lib/systemd usr/lib/kernel \
       usr/lib/*/gconv usr/lib/*/pulseaudio/*.la \
       usr/lib/chromium/libVkLayer_khronos_validation.so*
# chroot 里只跑浏览器: systemd/udev/init/lsb/pam 这些目录整块去掉。
# 留着会要命: lib/systemd/systemd-* 这些 ELF NEED libsystemd-shared-252.so ->
# libaudit/libcryptsetup/libkmod/libpam/libseccomp... OpenWrt 打包时的 ABI 检查
# 会直接拒建("is missing dependencies for the following libraries")。
rm -rf lib/systemd lib/udev lib/init lib/lsb lib/modprobe.d lib/usrmerge \
       usr/lib/systemd usr/lib/environment.d usr/lib/modules-load.d usr/lib/sysctl.d \
       usr/lib/sysusers.d usr/lib/binfmt.d usr/lib/pam.d usr/lib/tmpfiles.d usr/lib/usrmerge \
       usr/lib/dbus-1.0 etc/pam.d etc/init.d etc/rc.d etc/systemd etc/dbus-1 etc/modprobe.d etc/sysctl.d

# 只保留 chromium 递归 NEEDED 的库: 否则会把 mesa/LLVM/icu/z3 这些没用的塞进来(+400MB)
# 注意: 必须按 SONAME 命名拷(libglib-2.0.so.0), 不能拷 realpath 的文件名
#       (libglib-2.0.so.0.7400.6) —— 加载器只认 SONAME, 拷错名字就等于没装。
python3 - "$PWD" "$CHROME_BIN_REL" <<'PY'
import os, re, subprocess, sys, glob, shutil
root, binrel = sys.argv[1], sys.argv[2]
env = dict(os.environ, LC_ALL="C")
libdirs = [f"{root}/lib/arm-linux-gnueabihf", f"{root}/usr/lib/arm-linux-gnueabihf",
           f"{root}/lib", f"{root}/usr/lib"]

def needed(p):
    out = subprocess.run(["readelf", "-d", p], capture_output=True, text=True, env=env).stdout
    return re.findall(r"\(NEEDED\).*?\[([^\]]+)\]", out)

def find(lib):
    for d in libdirs:
        q = os.path.join(d, lib)
        if os.path.exists(q):
            return q
    hits = glob.glob(f"{root}/**/{lib}", recursive=True)
    return hits[0] if hits else None

libs, missing, queue, seen = {}, set(), [f"{root}/{binrel}"], set()
while queue:
    cur = queue.pop()
    for lib in needed(cur):
        if lib in seen:
            continue
        seen.add(lib)
        p = find(lib)
        if not p:
            missing.add(lib)
            continue
        libs[lib] = os.path.realpath(p)          # SONAME -> 真实文件
        queue.append(p)

# 运行期 dlopen 的私有库(不在 NEEDED 链里)
for p in glob.glob(f"{root}/usr/lib/**/libpulsecommon-*.so", recursive=True):
    libs[os.path.basename(p)] = os.path.realpath(p)

libdst = f"{root}/usr/lib/arm-linux-gnueabihf"
if os.path.isdir(libdst):
    shutil.rmtree(libdst)
os.makedirs(libdst, exist_ok=True)
for soname, real in libs.items():
    dst = os.path.join(libdst, soname)
    shutil.copy2(real, dst)
    os.chmod(dst, 0o755)

# Debian 布局: /lib/arm-linux-gnueabihf/ld-2.36.so + /lib/ld-linux-armhf.so.3 软链
lddir = f"{root}/lib/arm-linux-gnueabihf"
os.makedirs(lddir, exist_ok=True)
src = glob.glob(f"{root}/lib/arm-linux-gnueabihf/ld-*.so") or glob.glob(f"{root}/lib/ld-*.so")
if src:
    real = os.path.realpath(src[0])
    name = os.path.basename(real)
    shutil.copy2(real, os.path.join(lddir, name))
    os.chmod(os.path.join(lddir, name), 0o755)
    link = f"{root}/lib/ld-linux-armhf.so.3"
    if os.path.lexists(link):
        os.remove(link)
    os.symlink("arm-linux-gnueabihf/" + name, link)
print(f"保留 {len(libs)} 个库, 缺库: {sorted(missing) or '无'}")
PY

rm -rf "$HERE/files"; mkdir -p "$HERE/files"
tar -C "$ROOT" -cf - lib usr etc var root dev proc sys tmp run | tar -C "$HERE/files" -xf -
echo "载荷已生成: $HERE/files ($(du -sh "$HERE/files" | cut -f1))"
