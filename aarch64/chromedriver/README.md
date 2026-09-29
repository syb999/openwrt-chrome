# chromedriver

Chrome for Testing 的 chromedriver (linux-arm64, glibc) + 包装器 `cdrv.sh`。

chromedriver 也是 glibc 二进制, 所以它同样住在 chroot 里; `cdrv.sh` 负责进 chroot 并
带上 `--binary-location=/opt/chrome/chrome-headless-shell`, 让驱动拉起浏览器。

## 用法 (python3-selenium)

    python3 - <<'PY'
    from selenium import webdriver
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.chrome.options import Options
    o = Options(); o.binary_location = "/opt/chrome/chrome-headless-shell"
    for a in ("--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"):
        o.add_argument(a)
    d = webdriver.Chrome(service=Service(executable_path="/opt/chrome-root/cdrv.sh"), options=o)
    d.get("https://www.baidu.com"); print(d.title); d.quit()
    PY

## 版本约束

chromedriver 与 chrome-headless-shell 必须同版本, 都在同一个 Chrome for Testing
版本号下取; 两个包的 PKG_VERSION 要一起改。

## 排障

- 起不来先看 `/tmp/chromedriver.log`(selenium 里 log_output 指定)。
- `cdrv.sh --version` 能单独验证驱动本身: 打印 ChromeDriver 版本号即正常。
- 手动直连(不用 selenium)可以这样确认整条链:
  `/opt/chrome-root/cdrv.sh --port=9515` 然后 curl http://127.0.0.1:9515/status
