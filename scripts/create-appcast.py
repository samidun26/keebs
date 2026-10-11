#!/usr/bin/env python3
"""Create a Sparkle feed for one fully signed GitHub release."""
import argparse
import base64
import datetime
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from email.utils import format_datetime
from pathlib import Path

SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE)


def create_appcast(metadata, archive, tag, notes=""):
    version = metadata["version"]
    build = metadata["build"]
    if not re.fullmatch(r"\d+\.\d+\.\d+", version) or tag != f"v{version}":
        raise ValueError("Release tag must match CFBundleShortVersionString (vX.Y.Z).")
    if not re.fullmatch(r"[1-9]\d*", build):
        raise ValueError("CFBundleVersion must be a positive integer.")
    signature = metadata["signature"]
    if len(base64.b64decode(signature, validate=True)) != 64:
        raise ValueError("An Ed25519 archive signature is required.")
    size = archive.stat().st_size
    if size <= 0 or metadata["length"] != size or metadata["sha256"] != hashlib.sha256(archive.read_bytes()).hexdigest():
        raise ValueError("Archive changed after signing.")
    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = "Keebs Updates"
    ET.SubElement(channel, "link").text = "https://github.com/samidun26/keebs"
    ET.SubElement(channel, "description").text = "Signed updates for Keebs."
    item = ET.SubElement(channel, "item")
    ET.SubElement(item, "title").text = f"Keebs {version}"
    ET.SubElement(item, f"{{{SPARKLE}}}version").text = build
    ET.SubElement(item, f"{{{SPARKLE}}}shortVersionString").text = version
    ET.SubElement(item, f"{{{SPARKLE}}}minimumSystemVersion").text = metadata["minimumSystemVersion"]
    ET.SubElement(item, "pubDate").text = format_datetime(datetime.datetime.now(datetime.timezone.utc))
    ET.SubElement(item, "description").text = notes or f"Keebs {version} is ready to install."
    ET.SubElement(item, "enclosure", {
        "url": f"https://github.com/samidun26/keebs/releases/download/{tag}/Keebs-macOS.zip",
        f"{{{SPARKLE}}}edSignature": signature, "length": str(size), "type": "application/octet-stream",
    })
    ET.indent(rss)
    return ET.tostring(rss, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--notes", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.write_bytes(create_appcast(
        json.loads(args.metadata.read_text()), args.archive, args.tag,
        args.notes.read_text() if args.notes else "",
    ))
