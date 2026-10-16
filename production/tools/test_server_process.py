"""Black-box persistence and lock tests against a real compiled rexd process.

Set REX_SERVER_BINARY to an isolated build. Never points at an existing service.
"""
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time
import unittest
import urllib.error
import urllib.request


@unittest.skipUnless(os.environ.get("REX_SERVER_BINARY"), "requires a compiled isolated rexd binary")
class ServerProcessTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.binary = str(Path(os.environ["REX_SERVER_BINARY"]).resolve())
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            self.port = listener.getsockname()[1]
        self.env = os.environ.copy()
        for name in ("REX_TLS_CERT", "REX_TLS_KEY", "REX_ADMIN_TOKEN", "REX_BEHIND_TLS_PROXY"):
            self.env.pop(name, None)
        self.env.update(REX_STORE=str(Path(self.directory.name) / "state.json"),
                        REX_LISTEN=f"127.0.0.1:{self.port}")
        self.process = None
        self.addCleanup(self.stop)
        self.http = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def start(self):
        self.process = subprocess.Popen([self.binary], env=self.env,
                                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if self.process.poll() is not None:
                self.fail("server exited before readiness")
            try:
                if self.request("GET", "/healthz")[0] == 200:
                    return
            except OSError:
                time.sleep(0.05)
        self.fail("server did not start within five seconds")

    def stop(self):
        if self.process is not None:
            if self.process.poll() is None:
                self.process.terminate()
                try:
                    self.process.wait(timeout=12)
                except subprocess.TimeoutExpired:
                    self.process.kill()
                    self.process.wait(timeout=5)
            self.process = None

    def request(self, method, path, token=None, body=None):
        headers = {}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        data = None
        if body is not None:
            headers["Content-Type"] = "application/json"
            data = json.dumps(body).encode()
        request = urllib.request.Request(f"http://127.0.0.1:{self.port}{path}",
                                         data=data, headers=headers, method=method)
        try:
            response = self.http.open(request, timeout=3)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            content = response.read()
            return response.status, json.loads(content) if content else None

    def test_real_process_restart_receipts_logout_and_exclusive_lock(self):
        self.start()
        status, guest = self.request("POST", "/v1/guests", body={})
        self.assertEqual(status, 201)
        token = guest["token"]
        command = {"action_id": "process-create-00001", "game": "tarneeb"}
        status, table = self.request("POST", "/v1/tables", token, command)
        self.assertEqual(status, 200)
        duplicate_process = subprocess.run([self.binary], env=self.env,
                                           capture_output=True, timeout=5)
        self.assertNotEqual(duplicate_process.returncode, 0)
        self.assertIn(b"already locked", duplicate_process.stderr)
        # Cold process stop/restart, not just constructing another Service.
        self.stop()
        self.start()
        status, recovered = self.request("GET", "/v1/me", token)
        self.assertEqual(status, 200)
        self.assertEqual(recovered["table_id"], table["id"])
        status, receipt = self.request("POST", "/v1/tables", token, command)
        self.assertEqual(status, 200)
        self.assertEqual(receipt, table)
        status, current = self.request("GET", "/v1/tables/" + table["id"], token)
        self.assertEqual(status, 200)
        self.assertEqual(current, table)
        self.assertEqual(self.request("DELETE", "/v1/session", token)[0], 204)
        self.stop()
        self.start()
        self.assertEqual(self.request("GET", "/v1/me", token)[0], 401)

    def test_insecure_non_loopback_and_short_admin_key_fail_closed(self):
        for changes, expected in [
            ({"REX_LISTEN": "0.0.0.0:0"}, b"non-loopback HTTP"),
            ({"REX_ADMIN_TOKEN": "too-short"}, b"at least 32 bytes"),
        ]:
            env = {**self.env, **changes}
            result = subprocess.run([self.binary], env=env, capture_output=True, timeout=5)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(expected, result.stderr)


if __name__ == "__main__":
    unittest.main()
