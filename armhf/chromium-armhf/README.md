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
