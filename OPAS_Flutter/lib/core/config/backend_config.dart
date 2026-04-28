/// Backend Configuration
/// 
/// This file contains configuration for connecting to the Django backend server.
/// Update the machineIp if you change the machine running Django or network.

class BackendConfig {
  /// IMPORTANT: Update this to your machine's local IP address
  /// Find your IP by running: ipconfig (Windows) or ifconfig (Linux/Mac)
  /// Look for IPv4 Address in the format: 192.168.x.x or 10.x.x.x
  /// 
  /// Current value is a placeholder - CHANGE THIS TO YOUR ACTUAL IP
  static const String machineIp = '192.168.254.110'; // ⬅️ UPDATE THIS LINE
  
  static const int port = 8000;
  static const String apiPath = '/api';
  
  /// Full machine URL
  static String get machineUrl => 'http://$machineIp:$port$apiPath';
  
  /// List of backend URLs to try in order of preference
  static List<String> get possibleBackendUrls => [
    machineUrl,                                  // Your machine (UPDATE machineIp above) - TRY FIRST
    'http://10.0.2.2:$port$apiPath',            // Android emulator special IP (try early)
    'http://host.docker.internal:$port$apiPath', // Docker/Emulator gateway
    'http://localhost:$port$apiPath',           // Web/localhost
    'http://127.0.0.1:$port$apiPath',           // Fallback localhost
    'http://192.168.0.1:$port$apiPath',         // Common router IP
    'http://192.168.1.1:$port$apiPath',         // Common router IP
    'http://192.168.1.100:$port$apiPath',       // Common local network
    'http://172.16.0.1:$port$apiPath',          // Docker/VM network
  ];
  
  /// Django server command to run the backend
  static const String djangoRunCommand = 'python manage.py runserver 0.0.0.0:8000';
  
  /// Timeouts (in seconds)
  static const int singleRequestTimeout = 2;
  static const int totalDiscoveryTimeout = 15;
  static const int apiCallTimeout = 30;
}
