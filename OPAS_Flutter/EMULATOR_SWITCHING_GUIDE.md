# Emulator Switching Solution - Dynamic Backend URL Detection

## Problem Solved ✅

You no longer need to manually change the IP address when switching between emulators (Edge browser ↔ Physical phone).

## How It Works

The updated `ApiService` now has **automatic backend URL detection** that:

1. **Tries multiple connection methods automatically**
   - `http://localhost:8000/api` (Web/Edge browser)
   - `http://127.0.0.1:8000/api` (Fallback localhost)
   - `http://10.0.2.2:8000/api` (Android emulator special IP)
   - `http://192.168.1.1:8000/api` (Common router IP)

2. **Caches the working URL** so it doesn't need to retry every request

3. **Handles connection failures gracefully** by attempting to find a working URL on first failure

4. **Provides manual reset option** when you switch emulators

## What Changed

### Updated Files:
- **`lib/core/services/api_service.dart`**
  - Added `resetCachedUrl()` method
  - Added `_findWorkingUrl()` method for auto-detection
  - Updated `registerUser()` and `loginUser()` with fallback logic
  - Added list of possible backend URLs

- **`lib/core/widgets/api_connection_debug_dialog.dart`** (NEW)
  - Debug dialog to manually reset cache when needed
  - Shows current backend URL
  - One-click reset button

## Usage

### Option 1: Automatic (No Action Needed)
Just switch emulators and try logging in. The app will automatically detect and use the correct backend URL.

### Option 2: Manual Reset (If Needed)
If you want to force a URL reset when switching emulators:

```dart
// In any screen, call:
ApiService.resetCachedUrl();

// Then try login/signup again - it will auto-detect
```

### Option 3: Use Debug Dialog
Add this to any screen's action buttons (e.g., login screen):

```dart
IconButton(
  icon: const Icon(Icons.settings_input_antenna),
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => const ApiConnectionDebugDialog(),
    );
  },
)
```

Then import:
```dart
import 'package:opas_flutter/core/widgets/api_connection_debug_dialog.dart';
```

## Workflow for Switching Emulators

### Switching from Edge Browser → Phone:
1. Close Edge browser (or just leave it)
2. Switch to physical phone emulator
3. Rebuild Flutter app: `flutter clean && flutter pub get && flutter run`
4. Try logging in - **app auto-detects** the correct IP (10.107.31.34 or similar)

### Switching from Phone → Edge Browser:
1. Kill phone emulator
2. Open Edge in Flutter web
3. Run: `flutter run -d edge`
4. Try logging in - **app auto-detects** localhost:8000

## Backend Server Setup

Make sure Django is running with network access enabled:

```powershell
cd C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django
python manage.py runserver 0.0.0.0:8000
```

The `0.0.0.0` binding allows connections from any device on the network.

## Technical Details

### Possible Backend URLs (Tried in Order):
1. `http://localhost:8000/api` - Web development
2. `http://127.0.0.1:8000/api` - Localhost fallback
3. `http://10.0.2.2:8000/api` - Android emulator gateway
4. `http://192.168.1.1:8000/api` - Common local network

### How Auto-Detection Works:
1. First attempt uses cached URL (or localhost as default)
2. If connection fails (0 status code), triggers `_findWorkingUrl()`
3. Tests each possible URL with a 5-second timeout
4. Caches the first successful URL found
5. Retries original request with working URL

### Error Handling:
- If no URL works: Clear error message listing all attempted URLs
- Helpful suggestion to check if Django is running

## Benefits

✅ **Zero Configuration** - No manual IP changes needed  
✅ **Seamless Switching** - Switch emulators without code changes  
✅ **Automatic Recovery** - Handles network changes gracefully  
✅ **Development Friendly** - Works with both web and mobile  
✅ **Debugging** - Optional debug dialog for troubleshooting  

## Troubleshooting

If you still get timeout errors:

1. **Check Django is running:**
   ```powershell
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Verify network connectivity:**
   - Phone and computer on same WiFi
   - Test: Open `http://10.107.31.34:8000/api/` on phone browser

3. **Clear cache manually:**
   ```dart
   ApiService.resetCachedUrl();
   ```

4. **Check firewall:**
   - Windows Firewall might block port 8000
   - Allow Django through firewall if needed

5. **Use debug dialog:**
   - Shows current working backend URL
   - See what URL is being used
