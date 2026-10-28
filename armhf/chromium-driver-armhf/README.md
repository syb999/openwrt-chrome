# chromium-driver-armhf

Debian bookworm 的 `chromium-driver`（armhf，150.x）+ 包装器 `cdrv.sh`，给 32 位 ARM 的
musl OpenWrt（玩客云）用。装在 glibc chroot `/opt/chrome-root` 里。

## 内容

| 路径 | 说明 |
|---|---|
| `/opt/chrome-root/opt/chrome-tools/chromedriver` | chromedriver 本体（ELF，glibc armhf，17MB） |
| `/opt/chrome-root/cdrv.sh` | 进 chroot 启动，并带 `--binary-location=/opt/chrome/chromium` |

## 用法（python3-selenium）

```python
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

o = Options()
o.binary_location = "/opt/chrome/chromium"
o.add_argument("--headless=new")          # armhf 跑的是完整 chromium，不是 headless_shell
for a in ("--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"):
    o.add_argument(a)

d = webdriver.Chrome(service=Service(executable_path="/opt/chrome-root/cdrv.sh"), options=o)
d.get("https://www.baidu.com"); print(d.title); d.quit()
```

## 版本约束

`chromium-driver-armhf` 与 `chromium-armhf` **必须同版本**（都取 Debian bookworm 的同一个
`chromium` 源码版本，当前 150.0.7871.100）；两个包的 `PKG_VERSION` 一起改。

## 排障

- `cdrv.sh --version` 单独验驱动本身（打印 ChromeDriver 版本号即正常）
- 手动直连：`cdrv.sh --port=9515` 然后 `curl http://127.0.0.1:9515/status`
- 起不来先看 chromedriver 的 log（selenium 里 `Service(..., log_output=...)`）
