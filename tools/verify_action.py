"""验证「自动记账」：打开带 amount 的链接，应直接入账并弹出提示。

用法：python tools/verify_action.py <url> <输出png>
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shot import WebSocket, http_json  # noqa: E402

import time  # noqa: E402


def main() -> None:
    url = sys.argv[1]
    out = sys.argv[2]
    targets = http_json(9222, "/json/list")
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
        ws.call(
            "Emulation.setEmulatedMedia",
            {"features": [{"name": "prefers-color-scheme", "value": "light"}]},
        )
        ws.call("Page.navigate", {"url": url})
        time.sleep(3.0)
        shot = ws.call(
            "Page.captureScreenshot", {"format": "png", "captureBeyondViewport": False}
        )
        import base64

        with open(out, "wb") as handle:
            handle.write(base64.b64decode(shot["data"]))
        print("saved", out)
    finally:
        ws.close()


if __name__ == "__main__":
    main()
