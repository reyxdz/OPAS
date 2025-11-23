# Phase 3.5 Complete Deployment & Setup Guide

**Status**: ✅ PRODUCTION READY  
**Date**: November 23, 2025  
**Document Type**: Complete Reference Guide  

---

## 📋 Table of Contents

1. [Quick Start (5 minutes)](#quick-start)
2. [Development Setup (10 minutes)](#development-setup)
3. [Database Configuration](#database-configuration)
4. [Running Tests](#running-tests)
5. [API Testing](#api-testing)
6. [Deployment Options](#deployment-options)
7. [Configuration Reference](#configuration-reference)
8. [Troubleshooting](#troubleshooting)
9. [Performance Tuning](#performance-tuning)
10. [Monitoring & Logging](#monitoring--logging)

---

## 🚀 Quick Start

**Time**: 5 minutes  
**Goal**: Get the application running locally

### Step 1: Clone and Setup
```bash
# Clone the repository
git clone https://github.com/reyxdz/OPAS.git
cd OPAS/OPAS_Django

# Create virtual environment
python -m venv venv
source venv/Scripts/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your settings:
# DATABASE_URL=postgresql://user:password@localhost:5432/opas_db
# SECRET_KEY=your-secret-key-here
# DEBUG=True (development only)
```

### Step 3: Database Setup
```bash
# Apply migrations
python manage.py migrate

# Create admin user
python manage.py createsuperuser
# Email: admin@opas.ph
# Password: YourSecurePassword
```

### Step 4: Generate Demo Data (Optional)
```bash
# Create realistic test data
python manage.py shell < generate_phase_3_5_demo_data.py
```

### Step 5: Start Server
```bash
# Start development server
python manage.py runserver

# Server will be available at: http://localhost:8000
```

### Step 6: Access Admin Panel
```
URL: http://localhost:8000/admin/
Email: admin@opas.ph
Password: YourSecurePassword
```

---

## 🔧 Development Setup

**Time**: 10 minutes  
**Goal**: Complete development environment

### Prerequisites

**System Requirements:**
```
Python:     3.8 or higher
Node.js:    14.0+ (for frontend, optional)
PostgreSQL: 12+
Redis:      6.0+ (optional, for caching)
Git:        2.30+
```

**Python Packages:**
```
Django==4.2.0
djangorestframework==3.14.0
psycopg2-binary==2.9.0
python-decouple==3.8
Pillow==9.5.0
requests==2.30.0
pytest==7.3.0
pytest-django==4.5.0
```

### Installation Steps

#### 1. Clone Repository
```bash
git clone https://github.com/reyxdz/OPAS.git
cd OPAS_Application/OPAS_Django
```

#### 2. Create Virtual Environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

#### 3. Install Dependencies
```bash
# Upgrade pip
pip install --upgrade pip

# Install all requirements
pip install -r requirements.txt

# Optional: Install development tools
pip install django-debug-toolbar ipython pytest-cov
```

#### 4. Create Environment File
```bash
# Create .env file
cat > .env << EOF
# Database
DATABASE_ENGINE=django.db.backends.postgresql
DATABASE_NAME=opas_db
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_HOST=localhost
DATABASE_PORT=5432

# Django
SECRET_KEY=your-secret-key-change-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Email (optional)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend

# JWT
JWT_SECRET=your-jwt-secret-key
JWT_ALGORITHM=HS256

# AWS (if using S3 for media)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_STORAGE_BUCKET_NAME=
EOF
```

#### 5. Configure Database
```bash
# For PostgreSQL locally
createdb opas_db
psql opas_db < path/to/initial_data.sql  # if exists
```

#### 6. Run Migrations
```bash
# Check migration status
python manage.py showmigrations

# Apply all migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
```

#### 7. Test Installation
```bash
# Run basic test
python manage.py check

# Run test suite
python manage.py test apps.users -v 2

# Start development server
python manage.py runserver 0.0.0.0:8000
```

### IDE Configuration

#### PyCharm Setup
```
1. File → Settings → Project → Python Interpreter
2. Add Interpreter → Existing Environment
3. Select: venv/Scripts/python.exe
4. Mark venv folder as excluded
5. Configure Django support:
   - File → Settings → Django
   - Enable Django support
   - Django project root: OPAS_Django
   - Settings module: core.settings
```

#### VS Code Setup
```json
// .vscode/settings.json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true,
  "[python]": {
    "editor.defaultFormatter": "ms-python.python",
    "editor.formatOnSave": true
  }
}
```

---

## 🗄️ Database Configuration

### PostgreSQL Setup

#### Local Development
```bash
# Install PostgreSQL
# Windows: https://www.postgresql.org/download/windows/
# macOS: brew install postgresql@14
# Linux: sudo apt-get install postgresql-14

# Start PostgreSQL service
# Windows: Services app
# macOS: brew services start postgresql@14
# Linux: sudo systemctl start postgresql

# Create database
sudo -u postgres createdb opas_db
sudo -u postgres createuser opas_user
sudo -u postgres psql -c "ALTER USER opas_user WITH PASSWORD 'password';"
sudo -u postgres psql -c "ALTER ROLE opas_user SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE opas_user SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE opas_user SET default_transaction_deferrable TO on;"
sudo -u postgres psql -c "ALTER ROLE opas_user SET timezone TO 'UTC';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE opas_db TO opas_user;"
```

#### Connection String
```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'opas_db',
        'USER': 'opas_user',
        'PASSWORD': 'password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

### Database Migrations

#### Create Migrations
```bash
# After model changes
python manage.py makemigrations

# Check for issues
python manage.py migrate --plan

# Apply migrations
python manage.py migrate
```

#### Rollback Migration
```bash
# Show current migrations
python manage.py showmigrations

# Rollback to specific migration
python manage.py migrate apps.users 0010

# Remove latest migration file manually if needed
rm apps/users/migrations/0011_*.py
```

#### Backup Database
```bash
# Create backup
pg_dump opas_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
psql opas_db < backup_20250101_120000.sql
```

---

## ✅ Running Tests

### Unit Tests

#### Run All Tests
```bash
# Run all tests with verbose output
python manage.py test --verbosity=2

# Run specific app tests
python manage.py test apps.users --verbosity=2

# Run specific test class
python manage.py test apps.users.tests.DashboardTestCase --verbosity=2

# Run specific test method
python manage.py test apps.users.tests.DashboardTestCase.test_stats_endpoint --verbosity=2
```

#### Run Tests with Coverage
```bash
# Install coverage
pip install coverage

# Run tests with coverage
coverage run --source='.' manage.py test

# Generate report
coverage report -m

# Generate HTML report
coverage html
open htmlcov/index.html
```

### Phase 3.5 Specific Tests

#### Generate Demo Data
```bash
python manage.py shell < generate_phase_3_5_demo_data.py

# Output:
# ✓ Created 50 sellers
# ✓ Created 250+ products
# ✓ Created 100+ orders
# ✓ Created 50+ OPAS submissions
# ✓ Created 25+ marketplace alerts
# ✓ Created 20+ price violations
```

#### Run Dashboard Tests
```bash
# Run Phase 3.5 dashboard tests
python manage.py test apps.users.test_phase_3_5_dashboard --verbosity=2

# Expected: 45+ tests, all passing
# Coverage: Dashboard metrics, authorization, response format, performance
```

#### Run Workflow Tests
```bash
# Run complete workflow test
python manage.py shell < test_phase_3_5_complete_workflow.py

# Output:
# [Step 1] Admin Authentication ✓
# [Step 2] Verify Demo Data ✓
# [Step 3] Dashboard Endpoint ✓
# [Step 4] Response Structure ✓
# [Step 5] Metrics Integrity ✓
# [Step 6] Permission Enforcement ✓
# ✓ ALL TESTS PASSED (26/26)
```

### Pytest Integration (Alternative)

```bash
# Install pytest-django
pip install pytest-django pytest-cov

# Create pytest.ini
[pytest]
DJANGO_SETTINGS_MODULE = core.settings
python_files = tests.py test_*.py *_tests.py

# Run tests
pytest

# Run with coverage
pytest --cov=apps --cov-report=html
```

---

## 🧪 API Testing

### Using cURL

#### Get Admin Token
```bash
# Request token
curl -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin@opas.ph",
    "password": "YourPassword"
  }'

# Response:
# {"token": "abc123xyz..."}
```

#### Test Dashboard Endpoint
```bash
# Get dashboard stats
curl -X GET http://localhost:8000/api/admin/dashboard/stats/ \
  -H "Authorization: Token abc123xyz..." \
  -H "Content-Type: application/json"

# Response: Complete metrics JSON
```

#### Test Other Endpoints
```bash
# Get sellers
curl -X GET http://localhost:8000/api/admin/sellers/ \
  -H "Authorization: Token abc123xyz..."

# Get prices
curl -X GET http://localhost:8000/api/admin/prices/ \
  -H "Authorization: Token abc123xyz..."

# Get OPAS submissions
curl -X GET http://localhost:8000/api/admin/opas/ \
  -H "Authorization: Token abc123xyz..."
```

### Using Postman

#### Import Collection
```
1. Open Postman
2. File → Import
3. Import from URL or file
4. Set base URL: {{base_url}}/api
5. Set variables:
   - base_url: http://localhost:8000
   - token: your_admin_token
```

#### Create Requests
```
GET /admin/dashboard/stats/
  Headers: Authorization: Token {{token}}
  
GET /admin/sellers/
  Headers: Authorization: Token {{token}}
  
GET /admin/prices/
  Headers: Authorization: Token {{token}}
```

### Using Python Requests
```python
import requests

# Setup
BASE_URL = 'http://localhost:8000'
TOKEN = 'your_admin_token'
HEADERS = {'Authorization': f'Token {TOKEN}'}

# Get dashboard stats
response = requests.get(
    f'{BASE_URL}/api/admin/dashboard/stats/',
    headers=HEADERS
)
metrics = response.json()

# Display metrics
print(f"Health Score: {metrics['marketplace_health_score']}")
print(f"Total Sellers: {metrics['seller_metrics']['total_sellers']}")
print(f"Active Listings: {metrics['market_metrics']['active_listings']}")
```

---

## 🌐 Deployment Options

### 1. Heroku Deployment

#### Create Procfile
```
# Procfile
web: gunicorn core.wsgi --log-file -
release: python manage.py migrate
```

#### Deploy
```bash
# Install Heroku CLI
# https://devcenter.heroku.com/articles/heroku-cli

# Login to Heroku
heroku login

# Create app
heroku create opas-admin-api

# Set environment variables
heroku config:set DEBUG=False
heroku config:set SECRET_KEY=your-secret-key
heroku config:set DATABASE_URL=postgresql://...

# Deploy
git push heroku main

# Run migrations
heroku run python manage.py migrate

# Create superuser
heroku run python manage.py createsuperuser
```

### 2. AWS Elastic Beanstalk

#### Configure EB
```bash
# Install EB CLI
pip install awsebcli

# Initialize
eb init -p python-3.9 opas-admin

# Create environment
eb create opas-admin-prod

# Deploy
eb deploy

# Check status
eb status

# View logs
eb logs
```

#### Create .ebextensions/django.config
```yaml
container_commands:
  01_migrate:
    command: "python manage.py migrate"
    leader_only: true
  02_collectstatic:
    command: "python manage.py collectstatic --noinput"

option_settings:
  aws:elasticbeanstalk:container:python:
    WSGIPath: core.wsgi:application
  aws:elasticbeanstalk:application:environment:
    PYTHONPATH: /var/app/current:$PYTHONPATH
```

### 3. Docker Deployment

#### Create Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Expose port
EXPOSE 8000

# Run gunicorn
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000"]
```

#### Create docker-compose.yml
```yaml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: opas_db
      POSTGRES_USER: opas_user
      POSTGRES_PASSWORD: secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    command: gunicorn core.wsgi:application --bind 0.0.0.0:8000
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://opas_user:secure_password@db:5432/opas_db
      DEBUG: False
      SECRET_KEY: your-secret-key
    depends_on:
      - db
    volumes:
      - .:/app

  redis:
    image: redis:7
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

#### Run with Docker
```bash
# Build and start
docker-compose up -d

# Run migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# Generate demo data
docker-compose exec web python manage.py shell < generate_phase_3_5_demo_data.py

# Stop
docker-compose down
```

### 4. Traditional Server Deployment (Nginx + Gunicorn)

#### Install Dependencies
```bash
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv nginx postgresql

# Create application user
sudo useradd -m opas_user
sudo su - opas_user
```

#### Setup Application
```bash
# Clone repository
git clone https://github.com/reyxdz/OPAS.git
cd OPAS_Application/OPAS_Django

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
pip install gunicorn

# Configure .env
cp .env.example .env
# Edit .env with production settings
```

#### Configure Systemd Service
```ini
# /etc/systemd/system/opas.service
[Unit]
Description=OPAS Admin API
After=network.target

[Service]
User=opas_user
WorkingDirectory=/home/opas_user/OPAS_Application/OPAS_Django
ExecStart=/home/opas_user/OPAS_Application/OPAS_Django/venv/bin/gunicorn \
    --workers 4 \
    --bind unix:/home/opas_user/OPAS_Application/OPAS_Django/opas.sock \
    core.wsgi:application

[Install]
WantedBy=multi-user.target
```

#### Configure Nginx
```nginx
# /etc/nginx/sites-available/opas
upstream opas {
    server unix:/home/opas_user/OPAS_Application/OPAS_Django/opas.sock;
}

server {
    listen 80;
    server_name api.opas.ph;

    location / {
        proxy_pass http://opas;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /home/opas_user/OPAS_Application/OPAS_Django/staticfiles/;
    }

    location /media/ {
        alias /home/opas_user/OPAS_Application/OPAS_Django/media/;
    }
}
```

#### Enable and Start
```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/opas /etc/nginx/sites-enabled/

# Test nginx config
sudo nginx -t

# Restart services
sudo systemctl restart nginx
sudo systemctl start opas
sudo systemctl enable opas
```

---

## ⚙️ Configuration Reference

### Django Settings

#### Core Settings
```python
# core/settings.py

# Security
DEBUG = False  # Always False in production
ALLOWED_HOSTS = ['api.opas.ph', 'www.opas.ph']
SECRET_KEY = os.environ.get('SECRET_KEY')

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DATABASE_NAME'),
        'USER': os.environ.get('DATABASE_USER'),
        'PASSWORD': os.environ.get('DATABASE_PASSWORD'),
        'HOST': os.environ.get('DATABASE_HOST'),
        'PORT': os.environ.get('DATABASE_PORT', '5432'),
    }
}

# Cache
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 100,
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour'
    }
}

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': 'logs/opas.log',
            'formatter': 'verbose'
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
}
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: ModuleNotFoundError: No module named 'django'
**Solution:**
```bash
# Activate virtual environment
source venv/Scripts/activate  # Windows: venv\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

#### Issue: Database connection refused
**Solution:**
```bash
# Verify PostgreSQL is running
# Windows: Check Services
# macOS: brew services list
# Linux: sudo systemctl status postgresql

# Check database credentials in .env
# Verify database exists
createdb opas_db

# Test connection
psql -U opas_user -d opas_db -h localhost
```

#### Issue: Dashboard endpoint returns 404
**Solution:**
```bash
# Verify URLs are configured
# Check admin_urls.py is included in main urls.py
python manage.py show_urls | grep dashboard

# Restart development server
python manage.py runserver
```

#### Issue: Permission denied (403) on dashboard endpoint
**Solution:**
```python
# Verify user is admin
python manage.py shell
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> user = User.objects.get(email='admin@opas.ph')
>>> print(user.role)  # Should be 'ADMIN'

# Verify token
>>> from rest_framework.authtoken.models import Token
>>> token = Token.objects.get(user=user)
>>> print(token.key)
```

#### Issue: Migrations not applying
**Solution:**
```bash
# Check migration status
python manage.py showmigrations

# Apply migrations step by step
python manage.py migrate apps.users 0001
python manage.py migrate apps.users

# If stuck, rollback and reapply
python manage.py migrate apps.users 0009
python manage.py migrate apps.users
```

#### Issue: Slow response time (> 2000ms)
**Solution:**
```bash
# Enable query logging
# Add to settings.py:
LOGGING['loggers']['django.db.backends'] = {
    'handlers': ['console'],
    'level': 'DEBUG',
}

# Check for N+1 queries in shell
python manage.py shell
>>> from django.test.utils import CaptureQueriesContext
>>> from django.db import connection
>>> with CaptureQueriesContext(connection) as queries:
...     # Your code here
>>> print(f"{len(queries)} queries executed")

# Optimize with select_related/prefetch_related
```

---

## 📊 Performance Tuning

### Database Optimization

#### Create Indexes
```sql
-- Performance-critical indexes
CREATE INDEX idx_seller_status ON users_user(seller_status);
CREATE INDEX idx_product_deleted ON sellerproduct(is_deleted);
CREATE INDEX idx_order_status ON sellerorder(status);
CREATE INDEX idx_alert_status ON marketplace_alert(status);
```

#### Connection Pooling
```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'CONN_MAX_AGE': 600,  # Connection pooling
        'OPTIONS': {
            'connect_timeout': 10,
        }
    }
}
```

### Redis Caching

#### Enable Caching
```python
# settings.py
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
            'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
        }
    }
}

# Cache dashboard endpoint (1 minute)
from django.views.decorators.cache import cache_page

@cache_page(60)  # Cache for 60 seconds
def dashboard_stats(request):
    # endpoint code
    pass
```

### Query Optimization

#### Use select_related
```python
# Avoid N+1 queries
sellers = User.objects.select_related('seller_status').all()

# In serializers
class SellerSerializer(serializers.ModelSerializer):
    seller_status_display = serializers.CharField(
        source='get_seller_status_display'
    )
    
    class Meta:
        model = User
        fields = ['id', 'email', 'seller_status', 'seller_status_display']
```

#### Use prefetch_related
```python
# For reverse foreign keys
products = SellerProduct.objects.prefetch_related('orders').all()
```

---

## 📈 Monitoring & Logging

### Application Monitoring

#### Sentry Error Tracking
```python
# settings.py
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn="https://your-sentry-dsn@sentry.io/project-id",
    integrations=[DjangoIntegration()],
    traces_sample_rate=0.1,
    send_default_pii=False
)
```

#### Application Logs
```python
# apps/users/admin_viewsets.py
import logging

logger = logging.getLogger(__name__)

class DashboardViewSet(viewsets.ViewSet):
    def stats(self, request):
        logger.info(f"Dashboard stats requested by {request.user.email}")
        try:
            # ... implementation
            logger.info("Dashboard stats generated successfully")
        except Exception as e:
            logger.error(f"Error generating dashboard stats: {str(e)}")
```

### Health Checks

#### Add Health Check Endpoint
```python
# urls.py
from django.views.generic import TemplateView

urlpatterns = [
    # ...
    path('health/', TemplateView.as_view(
        template_name='health.html',
        extra_context={'status': 'healthy'}
    )),
]
```

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] All tests passing (100% success rate)
- [ ] Code reviewed and approved
- [ ] Database migrations tested
- [ ] Performance verified (< 2000ms)
- [ ] Security review completed
- [ ] Environment variables configured
- [ ] SSL/TLS certificates obtained
- [ ] Backup plan documented

### Deployment
- [ ] Database backup created
- [ ] Migrations applied to production
- [ ] Static files collected
- [ ] Application deployed
- [ ] Health checks passing
- [ ] Monitoring configured
- [ ] Alerts enabled
- [ ] Documentation updated

### Post-Deployment
- [ ] Verify all endpoints responding
- [ ] Check error logs
- [ ] Monitor performance metrics
- [ ] Test critical workflows
- [ ] Notify stakeholders
- [ ] Document any issues
- [ ] Schedule follow-up review

---

## 📞 Support & Maintenance

### Regular Maintenance Tasks

#### Weekly
- [ ] Check error logs
- [ ] Review slow queries
- [ ] Verify backups completed

#### Monthly
- [ ] Review performance metrics
- [ ] Update security patches
- [ ] Check disk space
- [ ] Test backup restoration

#### Quarterly
- [ ] Security audit
- [ ] Performance optimization review
- [ ] Update documentation
- [ ] Team training/updates

### Getting Help

**Documentation:**
- API Reference: `/api/docs/`
- Setup Guide: See this file
- Phase 3.5 Reports: `OPAS_Django/PHASE_3_5_*.md`

**Community:**
- GitHub Issues: https://github.com/reyxdz/OPAS/issues
- Email: support@opas.ph
- Slack: #opas-admin-api

---

## 📋 Final Checklist

- [x] Development environment setup documented
- [x] Database configuration explained
- [x] Tests documented and ready to run
- [x] API testing guide provided
- [x] Deployment options documented
- [x] Configuration reference complete
- [x] Troubleshooting guide provided
- [x] Performance tuning documented
- [x] Monitoring setup explained
- [x] Deployment checklist provided

**Status: PRODUCTION READY** ✅

---

**Document Version**: 1.0  
**Last Updated**: November 23, 2025  
**Next Review**: December 23, 2025
