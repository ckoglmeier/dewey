#!/usr/bin/env python3
"""
Dewey Hosted API — contract mock server (stdlib only).

Implements the CLIENT-FACING surface of docs/hosted-api.md v1.0:
  GET  /healthz
  POST /v1/license/validate
  POST /v1/events

Environment variables (must be set by the caller):
  MOCK_VALID_KEY      — key that is treated as active (returns valid:true / 200)
  MOCK_CANCELED_KEY   — key that is treated as canceled (valid:false / 403)

Any other key is treated as unknown / revoked (valid:false / 401).

Usage:
  python3 contract_mock_server.py --port 0

The bound port is printed to stdout on a line by itself when the server is
ready to accept connections (before the first request is handled).

Pass --port 0 to let the OS pick a free port.
"""

import argparse
import http.server
import json
import os
import sys

MAX_BODY = 1_048_576  # 1 MB


def _read_env(name):
    val = os.environ.get(name, "")
    if not val:
        sys.exit(f"contract_mock_server: {name} must be set")
    return val


class ContractHandler(http.server.BaseHTTPRequestHandler):
    """Minimal handler matching the wire contract exactly."""

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _send_json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        """Return (body_bytes, too_large). Drains the socket on oversized."""
        length = int(self.headers.get("Content-Length", 0))
        if length > MAX_BODY:
            # Drain so the client receives the response cleanly
            remaining = length
            while remaining > 0:
                chunk = min(remaining, 65536)
                self.rfile.read(chunk)
                remaining -= chunk
            return None, True
        return self.rfile.read(length), False

    def _bearer_key(self):
        """Return the key from the Authorization: Bearer header, or None."""
        auth = self.headers.get("Authorization", "")
        if auth.lower().startswith("bearer "):
            return auth[len("bearer "):]
        return None

    # ------------------------------------------------------------------
    # Routes
    # ------------------------------------------------------------------

    def do_GET(self):
        if self.path == "/healthz":
            self._send_json(200, {"ok": True})
        else:
            self._send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path == "/v1/license/validate":
            self._handle_validate()
        elif self.path == "/v1/events":
            self._handle_events()
        else:
            self._send_json(404, {"error": "not found"})

    def _handle_validate(self):
        """POST /v1/license/validate — always 200, boolean-only response."""
        body, too_large = self._read_body()
        if too_large:
            self._send_json(413, {"error": "request body too large (max 1 MB)"})
            return
        try:
            data = json.loads(body)
            key = data.get("key", "")
        except (json.JSONDecodeError, AttributeError):
            # Malformed body — treat as unknown key
            self._send_json(200, {"valid": False})
            return

        valid_key = self.server.mock_valid_key
        canceled_key = self.server.mock_canceled_key
        if key == valid_key:
            self._send_json(200, {"valid": True})
        else:
            # canceled, revoked, or unknown all return valid:false
            self._send_json(200, {"valid": False})

    def _handle_events(self):
        """POST /v1/events — bearer auth, JSONL, 1 MB cap."""
        # Auth check
        bearer = self._bearer_key()
        valid_key = self.server.mock_valid_key
        canceled_key = self.server.mock_canceled_key

        if bearer != valid_key and bearer != canceled_key:
            # Missing, unknown, or revoked key → 401
            # We must drain any body before sending the response
            body, _ = self._read_body()
            self._send_json(401, {"error": "invalid or missing license key"})
            return

        if bearer == canceled_key:
            body, _ = self._read_body()
            self._send_json(403, {"error": "subscription canceled"})
            return

        # Key is valid — read body
        body, too_large = self._read_body()
        if too_large:
            self._send_json(413, {"error": "request body too large (max 1 MB)"})
            return

        # Process JSONL
        accepted = 0
        rejected = 0
        for raw_line in body.split(b"\n"):
            line = raw_line.strip()
            if not line:
                continue  # blank lines ignored
            try:
                obj = json.loads(line)
                if not isinstance(obj, dict):
                    rejected += 1
                else:
                    accepted += 1
            except json.JSONDecodeError:
                rejected += 1

        self._send_json(200, {"accepted": accepted, "rejected": rejected})

    # Silence the default request log to keep test output clean.
    def log_message(self, fmt, *args):
        pass


class ContractMockServer(http.server.HTTPServer):
    def __init__(self, addr, handler, valid_key, canceled_key):
        super().__init__(addr, handler)
        self.mock_valid_key = valid_key
        self.mock_canceled_key = canceled_key


def main():
    parser = argparse.ArgumentParser(description="Dewey contract mock server")
    parser.add_argument("--port", type=int, default=0, help="Port to listen on (0=ephemeral)")
    args = parser.parse_args()

    valid_key = _read_env("MOCK_VALID_KEY")
    canceled_key = _read_env("MOCK_CANCELED_KEY")

    server = ContractMockServer(
        ("127.0.0.1", args.port),
        ContractHandler,
        valid_key=valid_key,
        canceled_key=canceled_key,
    )
    bound_port = server.server_address[1]
    # Print the bound port so the caller can read it before issuing requests.
    print(bound_port, flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
