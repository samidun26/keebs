import base64
import importlib.util
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

spec = importlib.util.spec_from_file_location("appcast", Path(__file__).resolve().parents[2] / "scripts/create-appcast.py")
appcast = importlib.util.module_from_spec(spec)
spec.loader.exec_module(appcast)


class AppcastTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.archive = Path(self.directory.name) / "Keebs-macOS.zip"
        self.archive.write_bytes(b"signed test archive")
        self.metadata = {
            "version": "0.1.2", "build": "3", "minimumSystemVersion": "14.0",
            "length": self.archive.stat().st_size, "signature": base64.b64encode(bytes(64)).decode(),
        }

    def test_feed_contains_signed_version_and_escaped_notes(self):
        feed = ET.fromstring(appcast.create_appcast(self.metadata, self.archive, "v0.1.2", "Keys & <sounds>"))
        item = feed.find("channel/item")
        self.assertEqual(item.find(f"{{{appcast.SPARKLE}}}version").text, "3")
        self.assertEqual(item.find("description").text, "Keys & <sounds>")
        enclosure = item.find("enclosure")
        self.assertEqual(enclosure.get("url"), "https://github.com/samidun26/keebs/releases/download/v0.1.2/Keebs-macOS.zip")
        self.assertEqual(enclosure.get(f"{{{appcast.SPARKLE}}}edSignature"), self.metadata["signature"])

    def test_wrong_tag_or_invalid_signature_cannot_be_published(self):
        with self.assertRaises(ValueError):
            appcast.create_appcast(self.metadata, self.archive, "v0.1.1")
        self.metadata["signature"] = "not a signature"
        with self.assertRaises(ValueError):
            appcast.create_appcast(self.metadata, self.archive, "v0.1.2")

    def test_archive_changed_after_signing_is_rejected(self):
        self.archive.write_bytes(b"changed")
        with self.assertRaises(ValueError):
            appcast.create_appcast(self.metadata, self.archive, "v0.1.2")
