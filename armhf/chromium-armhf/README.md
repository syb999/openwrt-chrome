# chromium-armhf

**32 位 ARM**（玩客云 amlogic/meson8b `cortex-a5` + `vfpv4`）上能跑的那个 Chromium ——
Debian bookworm 的 `chromium`（armhf，150.x）装进 glibc chroot `/opt/chrome-root`，
原生 32 位执行，不走 qemu。

## 为什么不是 chrome-headless-shell

Google（Chrome / Chrome for Testing）只发布 `linux64` 和 `linux-arm64`，**没有 32 位 ARM 版本**，
所以 aarch64 用的 `chrome-headless-shell` 在玩客云上无解（只能 qemu 模拟，实测一渲染就
`qemu: uncaught target signal 5`）。32 位这条路唯一的现成二进制是 Debian 的 chromium armhf。

## 布局（和 aarch64 包保持一致，luci-app-chrome 不用改）

| 路径 | 说明 |
|---|---|
| `/opt/chrome-root/opt/chrome/chromium` | 浏览器本体（ELF，interpreter `/lib/ld-linux-armhf.so.3`） |
| `/opt/chrome-root/opt/chrome/chrome-headless-shell` | 指向 `chromium` 的软链，兼容老路径/老检查 |
| `/opt/chrome-root/opt/chrome/` | `*.pak`、`locales/`、`icudtl.dat`、`libEGL.so`、`libGLESv2.so`、`libvk_swiftshader.so`、`chrome_crashpad_handler` |
| `/opt/chrome-root/run-chrome.sh` | 启动器：进 chroot、bind /dev /proc /sys /tmp、自动补 `--headless=new` |

## 用法

```sh
/opt/chrome-root/run-chrome.sh --version
/opt/chrome-root/run-chrome.sh --dump-dom https://example.com
/opt/chrome-root/run-chrome.sh --screenshot=/tmp/a.png --window-size=1280,800 \
    --virtual-time-budget=8000 https://www.baidu.com
```

## 和 aarch64 版的行为差异

1. **必须带 headless 参数**：`chrome-headless-shell` 天生 headless，而这里跑的是完整
   chromium，所以要 `--headless=new`。`run-chrome.sh` 会自动补；但 **Selenium 里必须自己加**：
   `o.add_argument("--headless=new")`。
2. **没有 `--single-process` 需求**：设备是原生 armv7，多进程正常。
3. **版本封顶 150**：Debian 从 trixie（151+）起不再构建 armhf。换版本时
   `chromium-armhf` 与 `chromium-driver-armhf` 的 `PKG_VERSION` 必须一起改（同源同版）。
4. **WebGL**：默认关闭；需要时加 `--enable-unsafe-swiftshader`（`libvk_swiftshader.so` 已带）。

## 体积/性能（实测数据）

- 载荷 234MB（chromium 本体 195MB + resources/locales/icu 等）
- 配套 runtime 53MB，driver 17MB → 安装后合计 **约 305MB**
- Cortex-A5 1.2GHz 无 NEON：Debian armhf 基线是 armv7+vfpv3-d16，兼容不会 SIGILL；
  渲染一个普通页面预计 3–10 秒，抓数据够用，当浏览器天天用会很痛苦
- 内存 1GB 建议开 zram（单页约 250–350MB RSS）

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
