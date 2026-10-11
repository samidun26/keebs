#!/usr/bin/env python3
"""Launch the packaged app briefly to catch framework/configuration crashes."""
import subprocess
import sys

process = subprocess.Popen(["dist/Keebs.app/Contents/MacOS/Keebs"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
try:
    output, _ = process.communicate(timeout=5)
except subprocess.TimeoutExpired:
    process.terminate()
    try:
        output, _ = process.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        output, _ = process.communicate()
    if b"dyld:" in output or b"Error: An error occurred in retrieving update information" in output:
        sys.exit(output.decode(errors="replace"))
    print("Packaged app launched and remained running.")
else:
    sys.exit("Packaged app exited unexpectedly: " + output.decode(errors="replace"))
