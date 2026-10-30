"""用 Chrome DevTools Protocol 给「清账」截图。

不依赖第三方库：自己实现最小的 WebSocket 客户端（仅本机调试用）。
步骤：启动 Edge/Chrome 的 --remote-debugging-port，然后运行本脚本。

用法：
    python tools/shot.py <url> <输出目录> [--scheme light|dark] [--width 390] [--height 844]

示例：
    python tools/shot.py "http://127.0.0.1:8099/" docs/shots --scheme dark
"""

from __future__ import annotations

import base64
import json
import os
import socket
import struct
import sys
import time
import urllib.parse
import urllib.request

DEFAULT_PORT = 9222


def http_json(port: int, path: str, method: str = "GET") -> dict:
    req = urllib.request.Request(f"http://127.0.0.1:{port}{path}", method=method)
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


class WebSocket:
    def __init__(self, url: str) -> None:
        assert url.startswith("ws://"), url
        hostport, _, path = url[5:].partition("/")
        host, _, port = hostport.partition(":")
        self.sock = socket.create_connection((host, int(port)), timeout=60)
        key = base64.b64encode(os.urandom(16)).decode()
        request = (
            f"GET /{path} HTTP/1.1\r\n"
            f"Host: {hostport}\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            "Sec-WebSocket-Version: 13\r\n\r\n"
        )
        self.sock.sendall(request.encode())
        head = b""
        while b"\r\n\r\n" not in head:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise RuntimeError("websocket handshake closed")
            head += chunk
        if b"101" not in head.split(b"\r\n")[0]:
            raise RuntimeError(head[:200])
        self._id = 0

    def _read_exact(self, n: int) -> bytes:
        buf = b""
        while len(buf) < n:
            chunk = self.sock.recv(n - len(buf))
            if not chunk:
                raise RuntimeError("websocket closed")
            buf += chunk
        return buf

    def send_json(self, obj: dict) -> None:
        payload = json.dumps(obj).encode("utf-8")
        frame = bytearray([0x81])
        mask = os.urandom(4)
        size = len(payload)
        if size < 126:
            frame.append(0x80 | size)
        elif size < 65536:
            frame.append(0x80 | 126)
            frame += struct.pack(">H", size)
        else:
            frame.append(0x80 | 127)
            frame += struct.pack(">Q", size)
        frame += mask
        frame += bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        self.sock.sendall(bytes(frame))

    def recv_json(self) -> dict:
        while True:
            head = self._read_exact(2)
            opcode = head[0] & 0x0F
            length = head[1] & 0x7F
            if length == 126:
                length = struct.unpack(">H", self._read_exact(2))[0]
            elif length == 127:
                length = struct.unpack(">Q", self._read_exact(8))[0]
            payload = self._read_exact(length)
            if opcode == 0x8:
                raise RuntimeError("websocket closed by peer")
            if opcode in (0x1, 0x2):
                return json.loads(payload.decode("utf-8", "replace"))

    def call(self, method: str, params: dict | None = None, timeout: float = 60) -> dict:
        self._id += 1
        call_id = self._id
        self.send_json({"id": call_id, "method": method, "params": params or {}})
        deadline = time.time() + timeout
        while time.time() < deadline:
            message = self.recv_json()
            if message.get("id") == call_id:
                if "error" in message:
                    raise RuntimeError(f"{method}: {message['error']}")
                return message.get("result", {})
        raise TimeoutError(method)

    def close(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass


def origin_of(url: str) -> str:
    parts = urllib.parse.urlsplit(url)
    return f"{parts.scheme}://{parts.netloc}"


def shoot(
    url: str,
    output: str,
    port: int = DEFAULT_PORT,
    width: int = 390,
    height: int = 844,
    dpr: float = 2,
    scheme: str = "dark",
    wait: float = 7.0,
) -> None:
    targets = http_json(port, "/json/list")
    pages = [t for t in targets if t.get("type") == "page"]
    page = next((t for t in pages if t.get("url") == "about:blank"), pages[0])
    ws = WebSocket(page["webSocketDebuggerUrl"])
    try:
        ws.call("Network.enable")
        ws.call("Network.setCacheDisabled", {"cacheDisabled": True})
        ws.call("Page.enable")
        ws.call(
            "Emulation.setDeviceMetricsOverride",
            {
                "width": width,
                "height": height,
                "deviceScaleFactor": dpr,
                "mobile": True,
            },
        )
        ws.call(
            "Emulation.setEmulatedMedia",
            {"features": [{"name": "prefers-color-scheme", "value": scheme}]},
        )
        # 每次都清掉本地存储，保证截图是「首次打开」的示例数据
        ws.call(
            "Storage.clearDataForOrigin",
            {"origin": origin_of(url), "storageTypes": "local_storage"},
        )
        ws.call("Page.navigate", {"url": url})
        time.sleep(wait)
        result = ws.call(
            "Page.captureScreenshot",
            {"format": "png", "captureBeyondViewport": False},
        )
        raw = base64.b64decode(result["data"])
        with open(output, "wb") as handle:
            handle.write(raw)
        print(f"saved {output} ({len(raw)} bytes)")
    finally:
        ws.close()


def main() -> None:
    args = sys.argv[1:]
    if len(args) < 2:
        print(__doc__)
        raise SystemExit(2)
    url = args[0]
    out_dir = args[1]
    scheme = "dark"
    width, height = 390, 844
    if "--scheme" in args:
        scheme = args[args.index("--scheme") + 1]
    if "--width" in args:
        width = int(args[args.index("--width") + 1])
    if "--height" in args:
        height = int(args[args.index("--height") + 1])
    os.makedirs(out_dir, exist_ok=True)

    pages = [
        ("01-home.png", ""),
        ("02-stats.png", "?tab=stats"),
        ("03-budget.png", "?tab=budget"),
        ("04-settings.png", "?tab=settings"),
        ("05-add.png", "?amount=25.5&category=%E9%A4%90%E9%A5%AE&note=%E5%8D%88%E9%A4%90&auto=0"),
        ("06-automation.png", "?tab=automation"),
        ("07-deposits.png", "?tab=deposits"),
    ]
    for name, query in pages:
        target = url.rstrip("/") + "/" + query
        shoot(target, os.path.join(out_dir, name), scheme=scheme, width=width, height=height)
        time.sleep(0.5)


if __name__ == "__main__":
    main()
