# chrome-headless-shell

Chrome for Testing 的 headless shell 版本 (linux-arm64, glibc), 配合
chrome-glibc-runtime 提供的 chroot 在 musl OpenWrt 上原生运行。

## 升级版本

1. 到 Chrome for Testing 的已知版本接口取同版本的两个包:
   https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json
   需要 `chrome-headless-shell` 的 `linux-arm64` 和 `chromedriver` 的 `linux-arm64`。
2. 本包: 改 PKG_VERSION, 把 files/opt/chrome 换成新解包内容。
   chromedriver 包: 改 PKG_VERSION, 换 files/opt/chrome-tools/chromedriver。
   两个包版本必须一致。
3. 重新 `make package/chrome-headless-shell/compile package/chromedriver/compile`。

## 验证(每次换版本都要做)

    /opt/chrome-root/run-chrome.sh --version
    /opt/chrome-root/run-chrome.sh --dump-dom https://example.com
    /opt/chrome-root/run-chrome.sh --screenshot=/tmp/a.png --window-size=1280,800 \
        --virtual-time-budget=8000 https://www.baidu.com
把截图取回来看中文有没有变成方块(字体在 runtime 包里)。

## 已知限制

- WebGL 默认不可用(chrome 154+ 关掉了自动软件渲染)。需要 WebGL 时加
  `--enable-unsafe-swiftshader`(libvk_swiftshader.so 已在包内)。
- 多进程在 qemu-user 下无法工作(zygote 会 re-exec /proc/self/exe), 设备上是原生执行,
  不受影响; 只在主机上用 qemu 验证时才需要 `--single-process --no-zygote`。
