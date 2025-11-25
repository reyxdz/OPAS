#!/usr/bin/env python
import subprocess
import sys
import time
import requests

# Start Django server
print("Starting Django server...")
proc = subprocess.Popen(
    [sys.executable, "manage.py", "runserver", "0.0.0.0:8000"],
    cwd=r"C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django",
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1
)

# Wait for server to start
print("Waiting for server to start...")
time.sleep(5)

# Test server connectivity
test_urls = [
    "http://localhost:8000/",
    "http://127.0.0.1:8000/",
    "http://10.198.118.34:8000/",
]

for url in test_urls:
    try:
        print(f"Testing {url}...")
        response = requests.get(url, timeout=3)
        print(f"✅ {url} - Status: {response.status_code}")
    except Exception as e:
        print(f"❌ {url} - Error: {e}")

# Print server output
print("\n--- Django Server Output ---")
try:
    # Read first 20 lines of output
    for i in range(20):
        line = proc.stdout.readline()
        if line:
            print(line.strip())
        else:
            break
except:
    pass

# Keep process alive
try:
    proc.wait(timeout=60)
except:
    proc.terminate()
