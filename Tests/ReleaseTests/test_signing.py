import base64
import hashlib
import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


@unittest.skipUnless(sys.platform == "darwin", "CryptoKit release signer runs on macOS")
class SigningTests(unittest.TestCase):
    # Public RFC 8032 test key, unrelated to Keebs' production update key.
    seed = "nWGxne/9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A="
    public_key = "11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo="

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        self.archive = root / "Keebs.zip"
        self.archive.write_bytes(b"Keebs signed test archive")
        self.info = root / "Info.plist"
        self.info.write_bytes(plistlib.dumps({
            "SUPublicEDKey": self.public_key, "CFBundleShortVersionString": "0.1.2",
            "CFBundleVersion": "3", "LSMinimumSystemVersion": "14.0",
        }))

    def sign(self, seed):
        env = dict(os.environ)
        env.pop("SPARKLE_PRIVATE_KEY", None)
        if seed is not None:
            env["SPARKLE_PRIVATE_KEY"] = seed
        return subprocess.run(
            ["swift", str(Path(__file__).resolve().parents[2] / "scripts/sign-release.swift"), str(self.archive), str(self.info)],
            env=env, capture_output=True, text=True, timeout=60,
        )

    def test_crypto_signature_matches_independent_ed25519_implementation(self):
        result = self.sign(self.seed)
        self.assertEqual(result.returncode, 0, result.stderr)
        metadata = json.loads(result.stdout)
        # CryptoKit may randomize the Ed25519 nonce. Verify authenticity with
        # OpenSSL rather than requiring byte-identical deterministic signatures.
        root = Path(self.directory.name)
        public_der = root / "public.der"
        public_der.write_bytes(bytes.fromhex("302a300506032b6570032100") + base64.b64decode(self.public_key))
        signature = root / "signature.bin"
        signature.write_bytes(base64.b64decode(metadata["signature"], validate=True))
        candidates = ["/opt/homebrew/opt/openssl@3/bin/openssl", "/usr/local/opt/openssl@3/bin/openssl", shutil.which("openssl")]
        openssl = next(p for p in candidates if p and Path(p).is_file())
        verified = subprocess.run([openssl, "pkeyutl", "-verify", "-rawin", "-pubin",
                                   "-keyform", "DER", "-inkey", str(public_der),
                                   "-sigfile", str(signature), "-in", str(self.archive)],
                                  capture_output=True, text=True, timeout=10)
        self.assertEqual(verified.returncode, 0, verified.stdout + verified.stderr)
        self.assertEqual(metadata["sha256"], hashlib.sha256(self.archive.read_bytes()).hexdigest())
        self.assertNotIn(self.seed, result.stdout + result.stderr)

    def test_missing_or_mismatched_key_is_rejected_without_leaking_it(self):
        for seed in [None, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="]:
            result = self.sign(seed)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, "")
            if seed:
                self.assertNotIn(seed, result.stderr)
