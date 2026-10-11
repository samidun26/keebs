import hashlib
import json
import os
import plistlib
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
    expected_signature = "3knjTM3m+nn3FPBNtRsszNfC7lbNdkqiQxWoJAY5EoR8kSCtJIuk1aKHRx1vtpVcGL9SqT3Sh/CIolv0X3EZBQ=="

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
        self.assertEqual(metadata["signature"], self.expected_signature)
        self.assertEqual(metadata["sha256"], hashlib.sha256(self.archive.read_bytes()).hexdigest())
        self.assertNotIn(self.seed, result.stdout + result.stderr)

    def test_missing_or_mismatched_key_is_rejected_without_leaking_it(self):
        for seed in [None, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="]:
            result = self.sign(seed)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, "")
            if seed:
                self.assertNotIn(seed, result.stderr)
