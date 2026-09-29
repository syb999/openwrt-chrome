# chrome-glibc-runtime

给 musl 的 OpenWrt 提供一套 glibc 用户空间, 让只认 glibc 的二进制(Chrome/chromedriver)
能跑起来。做法是把整套 glibc 用户空间放在一个 chroot 里(`/opt/chrome-root`), 内核共用,
运行时是原生 aarch64 速度(不走 qemu 模拟)。

## 为什么不能直接编

Chrome/chromedriver 官方 linux-arm64 包是 glibc 动态链接, ELF interpreter 写死
`/lib/ld-linux-aarch64.so.1`; OpenWrt 是 musl, 只有 `/lib/ld-musl-aarch64.so.1`。
在 musl 根文件系统里直接跑会得到:
`Could not open '/lib/ld-linux-aarch64.so.1': No such file or directory`
把 Chromium 编成 musl 版也不现实(官方只支持 glibc+clang, 本树 gcc 8.4 连 -std=c++20 都不认)。

## 载荷构成

Debian bookworm arm64 的 deb 展开后裁剪而成, 保留:
- lib/ + usr/lib/aarch64-linux-gnu/  glibc 2.36 及 Chrome NEEDED 的全部库
- etc/ssl (CA 证书, 保证 HTTPS)、etc/passwd、etc/hosts、etc/fonts
- usr/share/fonts (DejaVu + 文泉驿, 中文页面不会变方块)
- dev/ proc/ sys/ tmp/ 空目录, 由启动器 bind mount 进来

## 重新生成

`./gen-payload.sh` 会在 x86_64 主机上重新下载 arm64 deb 并展开成 ./files。
apt 源默认用 deb.debian.org; CN 网络下可换成镜像:
`sed -i 's|deb.debian.org|mirrors.aliyun.com|' gen-payload.sh`

只动 runtime 不用重新生成: 只有 glibc/字体/证书要升级时才需要。
