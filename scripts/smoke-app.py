#!/usr/bin/env python3
"""Check packaged-app startup, Dock policy, and background window behavior."""
import subprocess
import sys

process = subprocess.Popen(["dist/Keebs.app/Contents/MacOS/Keebs"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
try:
    try:
        output, _ = process.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        probe = subprocess.run(
            ["swift", "scripts/check-app-lifecycle.swift", str(process.pid)],
            capture_output=True, text=True, timeout=30,
        )
        if probe.returncode:
            sys.exit(probe.stderr or probe.stdout)
        if process.poll() is not None:
            sys.exit("Packaged app exited during the lifecycle check.")
        print(probe.stdout.strip())
    else:
        sys.exit("Packaged app exited unexpectedly: " + output.decode(errors="replace"))
finally:
    if process.poll() is None:
        process.terminate()
    try:
        output, _ = process.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        output, _ = process.communicate()
if b"dyld:" in output or b"Error: An error occurred in retrieving update information" in output:
    sys.exit(output.decode(errors="replace"))
print("Packaged app launched and remained running in the background.")
