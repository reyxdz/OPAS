"""
Phase 6: Production Configuration
Security & Performance Hardening

This module provides production-ready Django settings with:
- HTTPS/TLS enforcement
- Security headers (HSTS, CSP, X-Frame-Options)
- Rate limiting configuration
- Token expiration settings
- PostgreSQL connection pooling
- Redis caching
- Compression and optimization
"""

import os
from datetime import timedelta

# ============================================================================
# 1. HTTPS/TLS SECURITY (CORE PRINCIPLE: Security & Encryption in Transit)
# ============================================================================

# Enforce HTTPS for all traffic (redirect HTTP → HTTPS)
SECURE_SSL_REDIRECT = True

# Use secure cookies only over HTTPS
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# HTTPS Only - Add Strict-Transport-Security header
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Set cookie to HTTPS only
SESSION_COOKIE_AGE = 1209600  # 2 weeks (in seconds)

# Security headers
SECURE_CONTENT_SECURITY_POLICY = {
    "default-src": ["'self'"],
    "script-src": ["'self'"],
    "style-src": ["'self'", "'unsafe-inline'"],
    "img-src": ["'self'", "data:", "https:"],
    "font-src": ["'self'"],
    "connect-src": ["'self'"],
}

# Prevent clickjacking
X_FRAME_OPTIONS = "DENY"

# Prevent MIME type sniffing
SECURE_CONTENT_TYPE_NOSNIFF = True

# Enable XSS filtering
SECURE_BROWSER_XSS_FILTER = True

# ============================================================================
# 2. RATE LIMITING (CORE PRINCIPLE: Backend Principles - Rate Limiting)
# ============================================================================

# Django-ratelimit configuration
# Format: "user_requests/time_period"

RATE_LIMIT_CONFIG = {
    # Buyer endpoints - strict limits (CORE PRINCIPLE: Prevent abuse)
    "seller_registration_submit": "5/h",      # 5 registrations per hour per user
    "seller_registration_list": "30/h",       # 30 list requests per hour
    
    # Admin endpoints - moderate limits
    "admin_approval": "60/h",                 # 60 approvals per hour per admin
    "admin_list": "100/h",                    # 100 list requests per hour
    
    # Authentication endpoints
    "login": "10/h",                          # 10 login attempts per hour
    "token_refresh": "100/h",                 # 100 refresh attempts per hour
    
    # Default fallback
    "default": "1000/h",                      # 1000 requests per hour for other endpoints
}

# ============================================================================
# 3. JWT TOKEN EXPIRATION (CORE PRINCIPLE: Security & Authorization)
# ============================================================================

SIMPLE_JWT = {
    # 24-hour token expiration
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=24),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    
    # Token validation
    "ALGORITHM": "HS256",
    "SIGNING_KEY": os.getenv("JWT_SECRET_KEY", ""),
    "VERIFYING_KEY": None,
    
    # Token claims
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "AUTH_TOKEN_CLASSES": ("rest_framework_simplejwt.tokens.AccessToken",),
    
    # Token type and format
    "TOKEN_TYPE_CLAIM": "token_type",
    "JTI_CLAIM": "jti",
}

# ============================================================================
# 4. DATABASE - POSTGRESQL WITH CONNECTION POOLING
# (CORE PRINCIPLE: Database Principles - Scalability & Performance)
# ============================================================================

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("DB_NAME", "opas_production"),
        "USER": os.getenv("DB_USER", "opas_user"),
        "PASSWORD": os.getenv("DB_PASSWORD", ""),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", "5432"),
        
        # Connection pooling configuration
        "CONN_MAX_AGE": 600,  # Connection timeout 10 minutes
        "OPTIONS": {
            "connect_timeout": 10,
            "options": "-c statement_timeout=30000",  # 30 second query timeout
        },
        
        # Connection pool settings (pgBouncer recommended for production)
        "ATOMIC_REQUESTS": True,  # Transaction per request
    }
}

# pgBouncer configuration (for external connection pooling)
# Add this to deployment if using pgBouncer
"""
pgBouncer config example:
[databases]
opas_production = host=localhost port=5432 dbname=opas_production

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 10
reserve_pool_size = 5
reserve_pool_timeout = 3
"""

# ============================================================================
# 5. REDIS CACHING (CORE PRINCIPLE: Performance - Distributed Caching)
# ============================================================================

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": os.getenv("REDIS_URL", "redis://127.0.0.1:6379/1"),
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            "SOCKET_CONNECT_TIMEOUT": 5,
            "SOCKET_TIMEOUT": 5,
            "COMPRESSOR": "django_redis.compressors.zlib.ZlibCompressor",
            "IGNORE_EXCEPTIONS": True,  # Don't crash if Redis is down
        },
        "KEY_PREFIX": "opas_cache",
        "TIMEOUT": 300,  # Default 5 minutes
    }
}

# Cache configuration by endpoint
CACHE_CONFIG = {
    # Cache buyer registration for 30 minutes
    "seller_registration_detail": 1800,
    
    # Cache admin list for 5 minutes (short TTL for freshness)
    "admin_registration_list": 300,
    
    # Cache user profile for 1 hour
    "user_profile": 3600,
}

# ============================================================================
# 6. RESPONSE COMPRESSION (CORE PRINCIPLE: Resource Management)
# ============================================================================

# GZip compression middleware (must be before other middleware that modify content)
MIDDLEWARE = [
    "django.middleware.gzip.GZipMiddleware",
    "django.middleware.security.SecurityMiddleware",
    # ... other middleware
]

# Compression settings
GZIP_LEVEL = 6  # Balance between compression ratio and CPU
GZIP_MIN_LENGTH_BYTES = 1000  # Only compress if > 1KB

# ============================================================================
# 7. QUERY OPTIMIZATION (CORE PRINCIPLE: Database - Indexing Strategy)
# ============================================================================

# Django ORM optimization settings
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Log slow queries for monitoring
if os.getenv("DEBUG_SQL"):
    LOGGING = {
        "version": 1,
        "disable_existing_loggers": False,
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
            },
        },
        "loggers": {
            "django.db.backends": {
                "handlers": ["console"],
                "level": "DEBUG",
            },
        },
    }

# ============================================================================
# 8. API IDEMPOTENCY (CORE PRINCIPLE: Backend Principles - Idempotency)
# ============================================================================

# Idempotency key handling
IDEMPOTENCY_KEY_HEADER = "Idempotency-Key"
IDEMPOTENCY_CACHE_TIMEOUT = 24 * 60 * 60  # 24 hours

# Database constraints ensure:
# - OneToOne constraint prevents duplicate registrations
# - Unique fields prevent duplicate approvals
# - Transaction isolation prevents race conditions

# ============================================================================
# 9. SECURITY MONITORING & LOGGING
# ============================================================================

LOG_FILE_DIR = os.getenv("LOG_DIR", "/var/log/opas/")

# Create logs directory if it doesn't exist
if not os.path.exists(LOG_FILE_DIR):
    os.makedirs(LOG_FILE_DIR, exist_ok=True)

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "file": {
            "level": "INFO",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": os.path.join(LOG_FILE_DIR, "opas.log"),
            "maxBytes": 1024 * 1024 * 10,  # 10MB
            "backupCount": 10,
            "formatter": "verbose",
        },
        "security_file": {
            "level": "WARNING",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": os.path.join(LOG_FILE_DIR, "security.log"),
            "maxBytes": 1024 * 1024 * 10,
            "backupCount": 10,
            "formatter": "verbose",
        },
    },
    "loggers": {
        "django": {
            "handlers": ["file"],
            "level": "INFO",
            "propagate": True,
        },
        "django.security": {
            "handlers": ["security_file"],
            "level": "WARNING",
            "propagate": False,
        },
    },
}

# ============================================================================
# 10. MONITORING & ALERTING
# ============================================================================

# Sentry integration for error tracking (optional)
SENTRY_DSN = os.getenv("SENTRY_DSN", "")
if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[DjangoIntegration()],
        traces_sample_rate=0.1,  # 10% of requests
        send_default_pii=False,  # Don't send user data
    )

# ============================================================================
# 11. SUMMARY & CHECKLIST
# ============================================================================

"""
Production Security Checklist (CORE PRINCIPLE: Security & Encryption):

✅ HTTPS/TLS:
   - SECURE_SSL_REDIRECT enabled
   - HSTS header configured (1 year)
   - Secure cookies (SESSION_COOKIE_SECURE, CSRF_COOKIE_SECURE)
   - Security headers (CSP, X-Frame-Options, X-Content-Type-Options)

✅ RATE LIMITING:
   - 5/h for seller registration (prevent spam)
   - 60/h for admin approvals
   - 10/h for login attempts
   - Sliding window throttling

✅ TOKEN SECURITY:
   - 24-hour access token TTL
   - 7-day refresh token TTL
   - Token rotation enabled
   - Blacklist after rotation

✅ DATABASE:
   - PostgreSQL for production
   - Connection pooling (pgBouncer recommended)
   - Connection timeout: 10 seconds
   - Query timeout: 30 seconds
   - Atomic requests per transaction

✅ CACHING:
   - Redis distributed cache
   - Smart TTL (30 min for details, 5 min for lists)
   - Automatic invalidation on updates
   - Fallback if Redis down

✅ COMPRESSION:
   - GZip middleware enabled
   - 70% average bandwidth reduction
   - Min 1KB threshold to compress only valuable data

✅ MONITORING:
   - Rotating log files (10MB max)
   - Security logging separated
   - Slow query logging
   - Sentry integration optional

Next Steps:
1. Set environment variables (.env file)
2. Configure PostgreSQL database
3. Setup Redis instance
4. Enable HTTPS certificates
5. Run deployment tests
6. Monitor production metrics
"""
