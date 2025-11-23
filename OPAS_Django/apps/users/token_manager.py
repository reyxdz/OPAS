"""
Phase 6: Token Expiration & Refresh Mechanism
Implements 24-hour token TTL with automatic refresh

CORE PRINCIPLE: Security & Authorization
Token-based authentication with expiration
"""

from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from datetime import timedelta
from django.utils import timezone
import json


# ============================================================================
# 1. JWT TOKEN CONFIGURATION
# ============================================================================

JWT_CONFIG = {
    # Token lifetime settings
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=24),  # 24-hour access token
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),   # 7-day refresh token
    
    # Token rotation settings
    "ROTATE_REFRESH_TOKENS": True,                 # Rotate on each refresh
    "BLACKLIST_AFTER_ROTATION": True,              # Blacklist old tokens
    
    # Algorithm and key
    "ALGORITHM": "HS256",
    "SIGNING_KEY": "your-secret-key-here",         # Override in settings
    "VERIFYING_KEY": None,
    
    # Token claims and fields
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "TOKEN_TYPE_CLAIM": "token_type",
    "JTI_CLAIM": "jti",
}


# ============================================================================
# 2. CUSTOM TOKEN OBTAIN VIEW (LOGIN)
# ============================================================================

class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Custom token obtain view with extended response information.
    
    CORE PRINCIPLE: User Experience - Clear response with expiration info
    """
    
    def post(self, request, *args, **kwargs):
        """
        Override to add token expiration info to response.
        """
        response = super().post(request, *args, **kwargs)
        
        if response.status_code == 200:
            # Add token expiration timestamps to response
            response.data["access_token_expires_in"] = 24 * 60 * 60  # 24 hours in seconds
            response.data["refresh_token_expires_in"] = 7 * 24 * 60 * 60  # 7 days in seconds
            response.data["expires_at"] = timezone.now() + timedelta(hours=24)
        
        return response


# ============================================================================
# 3. CUSTOM TOKEN REFRESH VIEW
# ============================================================================

class CustomTokenRefreshView(TokenRefreshView):
    """
    Custom token refresh view with expiration handling.
    
    CORE PRINCIPLE: Security - Token rotation and expiration
    """
    
    def post(self, request, *args, **kwargs):
        """
        Override to handle refresh token expiration and auto-logout.
        """
        try:
            response = super().post(request, *args, **kwargs)
            
            if response.status_code == 200:
                # Add new expiration info
                response.data["access_token_expires_in"] = 24 * 60 * 60
                response.data["expires_at"] = timezone.now() + timedelta(hours=24)
                response.data["message"] = "Token refreshed successfully"
            
            return response
        
        except Exception as e:
            # Handle expired refresh token
            if "token_not_valid" in str(e) or "expired" in str(e).lower():
                return Response(
                    {
                        "error": "Session expired",
                        "message": "Your refresh token has expired. Please login again.",
                        "logout": True,  # Signal client to logout
                    },
                    status=status.HTTP_401_UNAUTHORIZED,
                )
            
            raise


# ============================================================================
# 4. TOKEN VALIDATION ENDPOINT
# ============================================================================

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def validate_token(request):
    """
    Validate if current token is still valid.
    
    Useful for clients to check if token is about to expire.
    
    CORE PRINCIPLE: Security - Token validation
    """
    try:
        user = request.user
        token = request.auth
        
        return Response(
            {
                "valid": True,
                "user_id": user.id,
                "username": user.username,
                "email": user.email,
                "role": user.role if hasattr(user, "role") else None,
            }
        )
    
    except Exception as e:
        return Response(
            {"valid": False, "error": str(e)},
            status=status.HTTP_401_UNAUTHORIZED,
        )


# ============================================================================
# 5. LOGOUT ENDPOINT (TOKEN BLACKLIST)
# ============================================================================

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout(request):
    """
    Logout user by blacklisting refresh token.
    
    CORE PRINCIPLE: Security - Revoke tokens on logout
    """
    try:
        refresh_token = request.data.get("refresh", None)
        
        if not refresh_token:
            return Response(
                {"error": "Refresh token is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        token = RefreshToken(refresh_token)
        token.blacklist()
        
        return Response(
            {"message": "Successfully logged out"},
            status=status.HTTP_200_OK,
        )
    
    except Exception as e:
        return Response(
            {"error": f"Logout failed: {str(e)}"},
            status=status.HTTP_400_BAD_REQUEST,
        )


# ============================================================================
# 6. MIDDLEWARE FOR AUTO-LOGOUT ON TOKEN EXPIRATION
# ============================================================================

class TokenExpirationMiddleware:
    """
    Middleware to handle token expiration gracefully.
    
    Detects expired tokens and returns 401 with logout signal.
    
    CORE PRINCIPLE: User Experience - Graceful session termination
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        try:
            response = self.get_response(request)
            return response
        
        except Exception as e:
            # Handle token expiration exceptions
            if "token_not_valid" in str(e) or "expired" in str(e).lower():
                return Response(
                    {
                        "error": "Token expired",
                        "message": "Your session has expired. Please login again.",
                        "logout": True,
                    },
                    status=401,
                )
            
            raise


# ============================================================================
# 7. TOKEN CLAIMS CUSTOMIZATION
# ============================================================================

class CustomRefreshToken(RefreshToken):
    """
    Custom refresh token with additional claims.
    
    Adds user role and permissions to token.
    CORE PRINCIPLE: Security & Authorization - Token-based claims
    """
    
    @classmethod
    def for_user(cls, user):
        """Create token with user info embedded."""
        token = super().for_user(user)
        
        # Add custom claims
        token["user_role"] = user.role if hasattr(user, "role") else "buyer"
        token["user_email"] = user.email
        token["is_admin"] = user.is_staff
        
        return token


# ============================================================================
# 8. FLUTTER CLIENT IMPLEMENTATION (DART)
# ============================================================================

FLUTTER_TOKEN_MANAGER = """
// Flutter Implementation for Token Handling
// Place in lib/services/token_manager.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

const String ACCESS_TOKEN_KEY = 'access_token';
const String REFRESH_TOKEN_KEY = 'refresh_token';
const String TOKEN_EXPIRATION_KEY = 'token_expires_at';

class TokenManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  
  /// Save tokens after login (CORE PRINCIPLE: Secure Storage)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    await _storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);
    await _storage.write(key: REFRESH_TOKEN_KEY, value: refreshToken);
    
    // Calculate and save expiration time
    DateTime expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await _storage.write(
      key: TOKEN_EXPIRATION_KEY,
      value: expiresAt.toIso8601String(),
    );
  }
  
  /// Get current access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: ACCESS_TOKEN_KEY);
  }
  
  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    String? expirationStr = 
        await _storage.read(key: TOKEN_EXPIRATION_KEY);
    
    if (expirationStr == null) return true;
    
    DateTime expiration = DateTime.parse(expirationStr);
    return DateTime.now().isAfter(expiration);
  }
  
  /// Auto-refresh token if expired (CORE PRINCIPLE: Auto-refresh)
  Future<bool> refreshTokenIfNeeded() async {
    if (await isTokenExpired()) {
      return await refreshToken();
    }
    return true;
  }
  
  /// Refresh access token using refresh token
  Future<bool> refreshToken() async {
    try {
      String? refreshToken = 
          await _storage.read(key: REFRESH_TOKEN_KEY);
      
      if (refreshToken == null) {
        await logout();
        return false;
      }
      
      Response response = await _dio.post(
        'https://api.opas.com/api/token/refresh/',
        data: {'refresh': refreshToken},
      );
      
      if (response.statusCode == 200) {
        String newAccessToken = response.data['access'];
        int expiresIn = response.data['access_token_expires_in'];
        
        await saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
          expiresIn: expiresIn,
        );
        
        return true;
      }
      
      // Refresh failed, logout user
      if (response.statusCode == 401) {
        await logout();
      }
      
      return false;
    } catch (e) {
      print('Token refresh error: \$e');
      await logout();
      return false;
    }
  }
  
  /// Logout and clear tokens
  Future<void> logout() async {
    try {
      // Try to blacklist token on server
      String? refreshToken = 
          await _storage.read(key: REFRESH_TOKEN_KEY);
      
      if (refreshToken != null) {
        await _dio.post(
          'https://api.opas.com/api/logout/',
          data: {'refresh': refreshToken},
        );
      }
    } catch (e) {
      print('Logout error: \$e');
    }
    
    // Clear local storage
    await _storage.delete(key: ACCESS_TOKEN_KEY);
    await _storage.delete(key: REFRESH_TOKEN_KEY);
    await _storage.delete(key: TOKEN_EXPIRATION_KEY);
  }
  
  /// Get time until token expiration
  Future<Duration?> getTimeUntilExpiration() async {
    String? expirationStr = 
        await _storage.read(key: TOKEN_EXPIRATION_KEY);
    
    if (expirationStr == null) return null;
    
    DateTime expiration = DateTime.parse(expirationStr);
    Duration remaining = expiration.difference(DateTime.now());
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

// Usage in main.dart:
class MyApp extends StatelessWidget {
  final tokenManager = TokenManager();
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: tokenManager.isTokenExpired(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingScreen();
          }
          
          if (snapshot.data == true) {
            // Token expired, show login
            return LoginScreen();
          }
          
          // Token valid, show home
          return HomeScreen();
        },
      ),
    );
  }
}

// Add to Dio interceptor for auto-refresh:
class DioTokenInterceptor extends Interceptor {
  final TokenManager tokenManager;
  
  DioTokenInterceptor({required this.tokenManager});
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Auto-refresh if needed before each request
    bool refreshed = await tokenManager.refreshTokenIfNeeded();
    
    if (!refreshed) {
      // Refresh failed, redirect to login
      return handler.reject(
        DioError(
          requestOptions: options,
          message: 'Authentication required',
          type: DioErrorType.unknown,
        ),
      );
    }
    
    // Add token to header
    String? token = await tokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer \$token';
    }
    
    return handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized (token invalid)
    if (err.response?.statusCode == 401) {
      // Try to refresh
      bool refreshed = await tokenManager.refreshToken();
      
      if (refreshed) {
        // Retry original request with new token
        return handler.resolve(
          await Dio().request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: {
                'Authorization': 
                    'Bearer \${await tokenManager.getAccessToken()}',
              },
            ),
          ),
        );
      } else {
        // Logout
        await tokenManager.logout();
        return handler.reject(err);
      }
    }
    
    return handler.next(err);
  }
}
"""


# ============================================================================
# 9. CONFIGURATION CHECKLIST
# ============================================================================

CONFIGURATION_CHECKLIST = """
✅ TOKEN EXPIRATION & REFRESH CONFIGURED:

1. Access Token:
   - TTL: 24 hours
   - Automatically expires
   - Requires refresh for continuation

2. Refresh Token:
   - TTL: 7 days
   - Token rotation enabled (new token on refresh)
   - Blacklist old tokens after rotation
   - Prevents token reuse attacks

3. Client-Side Handling:
   - Secure storage (platform encryption)
   - Auto-refresh before expiration
   - Graceful logout on expiration
   - Retry failed requests after refresh

4. Security Benefits:
   - Limited window for stolen tokens (24 hrs)
   - Token rotation reduces attack surface
   - Refresh token blacklist revokes old sessions
   - Automatic logout on expiration

5. CORE PRINCIPLES Applied:
   ✅ Security & Authorization - JWT token expiration
   ✅ User Experience - Auto-refresh, graceful logout
   ✅ Resource Management - Short-lived tokens reduce vulnerability window

6. Next Steps:
   - Set environment variable JWT_SECRET_KEY
   - Configure SIMPLE_JWT in settings.py
   - Deploy Flutter client with token interceptor
   - Monitor token refresh rates
   - Test token expiration scenarios
"""

print(CONFIGURATION_CHECKLIST)
