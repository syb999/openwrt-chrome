# chrome-glibc-runtime-armhf

给 **32 位 ARM** 的 musl OpenWrt（玩客云 amlogic/meson8b，`cortex-a5` + `vfpv4`）提供一套
glibc 用户空间，让只认 glibc 的二进制（Debian 的 chromium / chromedriver）能原生跑起来。
做法和 aarch64 版一致：整套 glibc 用户空间放在 chroot 里（`/opt/chrome-root`），内核共用，
**原生 32 位执行，不走 qemu**。

## 为什么不直接搬 aarch64 那套

- 官方（Chrome / Chrome for Testing）**没有 32 位 ARM 版**，`chrome-headless-shell` 只有
  `linux64` / `linux-arm64`。aarch64 二进制在 Cortex-A5 上是指令集不兼容，只能 qemu 模拟
  （实测：`--version` 能过，一渲染就 `qemu: uncaught target signal 5`）。
- 所以 32 位这条路只能用 **Debian bookworm 的 chromium（armhf，150.x）**：
  ELF interpreter 是 `/lib/ld-linux-armhf.so.3`，musl 根文件系统里没有 → 同样需要 glibc chroot。
- armhf 的天花板是 **chromium 150**：Debian 从 trixie（151+）起不再构建 armhf。

## 载荷构成（只装 chromium 真正要的）

用 `apt` 的 Dir 覆盖把 armhf deb 下到临时目录（不需要 root/docker/qemu），`dpkg-deb -x` 展开，
然后**按 chromium 的递归 NEEDED 闭包裁剪**：

- 下载 238 个 deb / 207MB，全部展开 679MB
- 裁剪后只剩 **99 个共享库（26.6MB）** + `/lib/ld-linux-armhf.so.3`
- 加上 CA 证书、DejaVu + 文泉驿微米黑字体、fontconfig，最终载荷 **≈ 45MB**
- 实测：`qemu-arm-static -L files usr/lib/chromium/chromium --headless --version`
  → `Chromium 150.0.7871.100`（依赖齐全）

被裁掉的都是没用的：perl、libLLVM-15(98M)、libicudata(30M)、libz3、mesa dri、gconv、systemd 组件。

## 重新生成

```sh
./gen-payload.sh            # WORK=/tmp/chrome-armhf-payload 可覆盖
```

CN 网络可换源：`sed -i 's|deb.debian.org|mirrors.aliyun.com|' gen-payload.sh`。
只有 glibc/字体/证书要升级时才需要重新生成；换 chromium 版本不动本包。

## 目录约定（和 aarch64 包一致）

| 路径 | 内容 |
|---|---|
| `/opt/chrome-root/lib/ld-linux-armhf.so.3` | glibc 动态加载器（ELF interpreter） |
| `/opt/chrome-root/usr/lib/arm-linux-gnueabihf/` | 99 个 NEEDED 库 |
| `/opt/chrome-root/etc/ssl` | CA 证书（HTTPS 必需） |
| `/opt/chrome-root/usr/share/fonts` | DejaVu + 文泉驿（中文页面不变方块） |

## 运行时依赖的两个隐藏坑（2026-10 设备实测，务必保留）

1. **glibc 的 NSS 解析模块是 dlopen 的**，必须装在 `usr/lib/arm-linux-gnueabihf/`：
   `libnss_dns.so.2`、`libnss_files.so.2`、`libnss_compat.so.2`、`libnss_hesiod.so.2`
   （来自 Debian 的 **libc6** 包，不是 libnss3）。
   缺了以后 chroot 内 `getaddrinfo()` 不通 ⇒ **只有 Chrome 早先缓存过 IP 的网站能打开**，
   其余全是 `ERR_TIMED_OUT`。同时也需要 `libnss3` 的 crypto 模块：
   `libsoftokn3 / libfreebl3 / libfreeblpriv3 / libnssckbi / libnssdbm3 / libsmime3 / libssl3`（+ `libsqlite3.so.0`），
   缺了会在访问 https 时报 `FATAL:crypto/nss_util.cc nss_error=-5925` → 进程 `Aborted`。

2. **每个进程要用独立 profile**：`run-chrome.sh` 里 `PROFILE="${CHROME_PROFILE:-/tmp/chrome-profile-$$}"`。
   共用一个 profile 时 Chrome 会把错误页缓存下来，网络修好之后仍然一直返回旧的 `ERR_*` 页面
   （特征：错误页字节数每次都完全相同）。
   Selenium 侧**不要**自己传 `--user-data-dir`，chromedriver 会给每个会话建临时 profile。

## 诊断工具

```sh
run-chrome.sh --headless=new --log-net-log=/tmp/nl.json --net-log-capture-mode=Everything --dump-dom <URL>
```
```python
import json
d = json.load(open("/tmp/nl.json"))
m = {v: k for k, v in d["constants"]["logEventTypes"].items()}
# HOST_RESOLVER_MANAGER_CACHE_HIT → ip_endpoints  (解析出了什么 IP)
# SOCKET_CONNECT / TCP_CONNECT_ATTEMPT → address + net_error (-7 超时 / -10 拒绝 / -106 断网)
```
`ERR_INTERNET_DISCONNECTED` 和连 `[2001:4860:4860::8888]:443` 是 Chrome 的 Secure DNS/后台探测噪声，
不是根因（`--disable-features=DnsOverHttps`、策略 `BuiltInDnsClientEnabled:false` 都治不了）。
