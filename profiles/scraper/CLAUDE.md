
# Scraper Profile

For web scraping against anti-bot protected sites. Built around
**CloakBrowser** — a stealth Chromium where the fingerprint patches
(canvas, WebGL, audio, fonts, GPU, `navigator.webdriver`, CDP leaks,
TLS/JA3, …) are compiled into the binary at the C++ level, not injected
via JS at runtime. Drop-in Playwright/Puppeteer replacement.

## CloakBrowser

Python and Node packages are pre-installed (`pip` + `npm -g`). The
underlying patched Chromium binary (~200 MB) is **not** baked into the
image — it auto-downloads on first `launch()` and caches under the
user's home (ephemeral here unless your work lives in `/work/project`).

```python
from cloakbrowser import launch

browser = launch()                  # headless by default
page = browser.new_page()
page.goto("https://protected-site.com")
browser.close()
```

```javascript
const { launch } = require('cloakbrowser');
const browser = await launch();
const page = await browser.newPage();
await page.goto('https://protected-site.com');
await browser.close();
```

The API mirrors Playwright/Puppeteer — same methods, same selectors.

### Human-like interaction

Pass `humanize=True` (Python) / `humanize: true` (Node) to `launch()`
for Bézier mouse paths, natural keyboard timing, and realistic scroll
physics. One flag, no extra code.

## Headless vs. headed (Xvfb)

CloakBrowser patches the headless UA leak, so **headless mode works
against most detectors**. For the strongest stealth (and to match the
vendor's published reCAPTCHA v3 / Turnstile scores), run **headed**
inside a virtual display:

```sh
# One-shot: xvfb-run wraps the command in a throwaway :99 display
xvfb-run -a python my_scraper.py

# Long-lived: bring up Xvfb yourself, then run anything against $DISPLAY
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
python my_scraper.py
```

In code, request headed mode via the standard Playwright option:
`launch(headless=False)`.

Installed for this: `xorg-server-xvfb` (provides `Xvfb`, `xvfb-run`)
and `xorg-xauth`.

## Seeing the page from a Claude session

There is no attached display — `xvfb-run` gives the browser a framebuffer
to render into, but nothing renders it back to you. Capture state via
Playwright instead and read the resulting file:

```python
import os, subprocess
# Start Xvfb once per session (skip if already up)
if "DISPLAY" not in os.environ:
    subprocess.Popen(["Xvfb", ":99", "-screen", "0", "1920x1080x24"])
    os.environ["DISPLAY"] = ":99"

from cloakbrowser import launch
browser = launch(headless=False)
page = browser.new_page()
page.goto("https://example.com")
page.screenshot(path="/tmp/page.png", full_page=True)
print(page.content()[:2000])   # HTML snapshot to stdout
browser.close()
```

Then `Read /tmp/page.png` to see the rendered page. For long-running
debugging keep the browser alive in a `shell-session-mcp` Python REPL
and screenshot between actions — much cheaper than relaunching.

If you only need DOM/text, `headless=True` is fine and skips Xvfb
entirely; reserve headed mode for cases where the anti-bot check
actually requires a real visible window.

## Fonts

`ttf-liberation`, `noto-fonts`, `noto-fonts-emoji`, `noto-fonts-cjk`
are installed so font enumeration looks like a normal desktop. Empty
font lists are a strong bot signal — don't strip these.

## Proxies

CloakBrowser does **not** bundle proxy rotation or CAPTCHA solving.
Bring your own — standard Playwright proxy options work:

```python
launch(proxy={"server": "http://user:pass@host:port"})
```

For HTTP-level scraping that doesn't need a full browser, the base
image already ships `curl_cffi` (browser-TLS-fingerprint Python client)
— often enough to bypass JA3/JA4 checks without spinning up Chromium.

## When not to use CloakBrowser

- Plain JSON/HTML APIs with no bot wall → use `curl`, `httpie`, or
  `requests` / `curl_cffi` (faster, no 200 MB binary).
- Sites that need real human CAPTCHA solving → CloakBrowser prevents
  CAPTCHAs from appearing, but does not solve them when they do.

## Useful base-image tools for scraping pipelines

- `jq` / `miller` (`mlr`) — post-process scraped JSON/CSV.
- `curl_cffi` — Python HTTP client with Chrome/Firefox/Safari TLS
  fingerprints (see base `CLAUDE.md`).
- `socat` — quick SOCKS/TCP relays when chaining proxies.
- `rg` — grep over large scraped corpora.
