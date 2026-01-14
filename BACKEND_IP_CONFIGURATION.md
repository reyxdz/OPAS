# Backend IP Configuration Guide

## Problem
The Flutter app needs to connect to the Django backend server. When the server IP changes or you're on a different network, the app fails to connect with timeout errors.

## Solution
Update the `MACHINE_IP` in the backend configuration file.

---

## Quick Setup Steps

### Step 1: Find Your Machine's IP Address

**On Windows (Command Prompt/PowerShell):**
```powershell
ipconfig
```
Look for **IPv4 Address** under your network adapter (usually looks like `192.168.x.x` or `10.x.x.x`)

**On Mac/Linux (Terminal):**
```bash
ifconfig
```
Look for `inet` address (usually looks like `192.168.x.x`)

### Step 2: Update Backend Configuration

Edit this file:
```
lib/core/config/backend_config.dart
```

Change this line:
```dart
static const String MACHINE_IP = '192.168.0.100'; // ⬅️ UPDATE THIS LINE
```

To your actual machine IP, e.g.:
```dart
static const String MACHINE_IP = '192.168.1.50'; // Your actual IP
```

### Step 3: Start Django Backend

Make sure Django is running:
```bash
python manage.py runserver 0.0.0.0:8000
```

### Step 4: Rebuild Flutter App

```bash
flutter clean
flutter pub get
flutter run
```

---

## Connection Order

The app tries to connect in this order:
1. `http://localhost:8000/api` (Web & local testing)
2. `http://127.0.0.1:8000/api` (Fallback localhost)
3. `http://10.0.2.2:8000/api` (Android emulator)
4. `http://{YOUR_MACHINE_IP}:8000/api` (Your machine - **UPDATE THIS**)
5. Other common network IPs (routers, docker, etc.)

The app will automatically try each URL until it finds a working connection.

---

## Troubleshooting

### Error: "Could not connect to backend"
- Make sure Django is running: `python manage.py runserver 0.0.0.0:8000`
- Update your machine IP in `backend_config.dart`
- Check network connectivity (ping your machine from the device)
- Firewall might be blocking - allow port 8000

### Error: "Connection refused"
- Django is not running. Start it first
- Check if Django is listening on the correct IP: `netstat -an | grep 8000`

### Error: "Connection timed out"
- Your machine IP is incorrect. Re-run `ipconfig` and verify
- Network connectivity issue. Try pinging the machine
- Port 8000 might be in use by another process

### Emulator specific issues
- For Android emulator, use `10.0.2.2` (special alias for host machine)
- For iOS simulator, `localhost` usually works
- For physical device, use your machine's local network IP

---

## Customizing Timeouts

You can also adjust timeout values in `backend_config.dart`:
```dart
/// Timeouts (in seconds)
static const int SINGLE_REQUEST_TIMEOUT = 1;      // Per URL test
static const int TOTAL_DISCOVERY_TIMEOUT = 8;     // All URLs combined
static const int API_CALL_TIMEOUT = 30;           // Regular API calls
```

Increase these if you have a slow network.

---

## Production Deployment

For production:
1. Use your actual server domain instead of IP
2. Use HTTPS (update URLs to `https://...`)
3. Update `BackendConfig.possibleBackendUrls` to only include production URLs

Example:
```dart
static const String MACHINE_IP = 'api.yourdomain.com'; // Your domain
```

---

## Need Help?

Check the logs in Flutter:
```bash
flutter run -v  # Verbose logging
```

Look for messages like:
- `✅ Found working backend URL: ...` (Success)
- `❌ Failed to connect to ...` (Individual URL failures)
- `🎯 Using backend URL: ...` (Final selected URL)
