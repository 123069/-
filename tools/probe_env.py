"""调试用：打印页面视口尺寸，确认移动端模拟是否精确。"""

from __future__ import annotations

import json
import sys
import time

sys.path.insert(0, __file__.rsplit("\\", 1)[0])
from shot import WebSocket, http_json  # noqa: E402

EXPR = """(() => ({
  innerW: window.innerWidth,
  innerH: window.innerHeight,
  clientW: document.documentElement.clientWidth,
  clientH: document.documentElement.clientHeight,
  dpr: window.devicePixelRatio,
  vv: window.visualViewport ? { w: window.visualViewport.width, h: window.visualViewport.height, s: window.visualViewport.scale } : null,
  bodyH: document.body.getBoundingClientRect().height,
  scrollH: document.documentElement.scrollHeight,
  view: (() => { const el = document.querySelector('flutter-view'); if (!el) return null; const r = el.getBoundingClientRect(); return { w: r.width, h: r.height }; })(),
  ua: navigator.userAgent.includes('Mobile')
}))()"""


def main() -> None:
    port = 9222
    targets = http_json(port, "/json/list")
    pages = [t for t in targets if t.get("type") == "page"]
    page = next((t for t in pages if t.get("url") == "about:blank"), pages[0])
    ws = WebSocket(page["webSocketDebuggerUrl"])
    try:
        ws.call("Page.enable")
        ws.call("Network.enable")
        ws.call("Network.setCacheDisabled", {"cacheDisabled": True})
        ws.call(
            "Emulation.setDeviceMetricsOverride",
            {"width": 390, "height": 844, "deviceScaleFactor": 2, "mobile": True},
        )
        ws.call("Page.navigate", {"url": "http://127.0.0.1:8099/?tab=budget"})
        time.sleep(7)
        result = ws.call(
            "Runtime.evaluate", {"expression": EXPR, "returnByValue": True}
        )
        print(json.dumps(result.get("result", {}).get("value"), indent=2, ensure_ascii=False))
    finally:
        ws.close()


if __name__ == "__main__":
    main()
