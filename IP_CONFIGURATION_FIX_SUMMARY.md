# IP Configuration Fix - Summary

## Problem Fixed
The Flutter app was failing to connect to the Django backend with timeout errors. The IP addresses were hardcoded and outdated.

## Solution Implemented

### 1. **Centralized Configuration** 
Created `lib/core/config/backend_config.dart` - a single place to configure:
- Machine IP address
- Port number
- API path
- Timeout durations

### 2. **Smart Backend URL Discovery**
Updated `lib/core/services/api_service.dart` to:
- Try multiple backend URLs in parallel
- Use aggressive timeouts (1 second per URL)
- Cache the first working URL for future requests
- Provide helpful error messages with setup instructions

### 3. **Tried URLs (in order)**
The app now tries to connect to:
1. `http://localhost:8000/api` - Web/local
2. `http://127.0.0.1:8000/api` - Fallback localhost
3. `http://10.0.2.2:8000/api` - Android emulator
4. `http://{YOUR_MACHINE_IP}:8000/api` - **Your machine (needs config)**
5. Common network patterns (routers, docker, etc.)

### 4. **Fixed Memory Leak**
Fixed `admin_home_screen.dart` - Added `mounted` check before calling `setState()` to prevent errors when screen is disposed.

---

## How to Use

### Step 1: Find Your Machine IP
```powershell
# Windows
ipconfig
# Look for IPv4 Address like: 192.168.1.50
```

### Step 2: Update Configuration
Edit: `lib/core/config/backend_config.dart`

Change:
```dart
static const String MACHINE_IP = '192.168.0.100'; // Your IP here
```

### Step 3: Start Django Backend
```bash
python manage.py runserver 0.0.0.0:8000
```

### Step 4: Run Flutter App
```bash
flutter run
```

---

## Files Modified

1. **`lib/core/services/api_service.dart`**
   - Imports `BackendConfig`
   - Uses config-based URLs and timeouts
   - Improved URL discovery with parallel requests
   - Better error messages

2. **`lib/core/config/backend_config.dart`** (NEW)
   - Centralized backend configuration
   - Easy IP and timeout customization

3. **`lib/features/admin_panel/screens/admin_home_screen.dart`**
   - Fixed memory leak with `mounted` check
   - Better error handling

---

## Configuration Options

In `backend_config.dart`:
```dart
static const String MACHINE_IP = '192.168.0.100';      // Your machine IP
static const int PORT = 8000;                           // Django port
static const int SINGLE_REQUEST_TIMEOUT = 1;            // Per-URL timeout
static const int TOTAL_DISCOVERY_TIMEOUT = 8;           // All URLs timeout
static const int API_CALL_TIMEOUT = 30;                 // API request timeout
```

---

## Debugging

Run with verbose logging:
```bash
flutter run -v
```

Look for messages:
- `✅ Found working backend URL: ...` - Success
- `🎯 Using backend URL: ...` - Selected URL
- `❌ Failed to connect to ...` - Individual failures

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Connection refused | Django not running. Start with `python manage.py runserver 0.0.0.0:8000` |
| Connection timed out | Update MACHINE_IP in backend_config.dart to correct value |
| setState() error on dispose | Fixed - now checks `mounted` before setState |
| Can't find machine IP | Run `ipconfig` on Windows, `ifconfig` on Mac/Linux |

---

## What's Next
The app will now:
1. Try to find a working backend automatically
2. Cache the working URL for fast reconnects
3. Provide clear error messages if connection fails
4. Support switching between different network configurations easily

No more hardcoded IPs that break when network changes! 🎉
