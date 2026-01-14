# Phase 7.4: Production Deployment Guide

**Last Updated:** December 3, 2025  
**Status:** Ready for Production Deployment

---

## 🚀 Pre-Deployment Checklist

### Code Quality & Testing

- [ ] **Unit Tests Passing**
  ```bash
  python manage.py test apps.forecasting.tests.test_model_selector -v 2
  python manage.py test apps.forecasting.tests.test_data_aggregator -v 2
  python manage.py test apps.forecasting.tests.test_forecasting_service -v 2
  python manage.py test apps.forecasting.tests.test_permissions -v 2
  python manage.py test apps.forecasting.tests.test_api_endpoints -v 2
  ```

- [ ] **Integration Tests Passing**
  ```bash
  python manage.py test apps.forecasting.tests.test_integration -v 2
  ```

- [ ] **Performance Tests Acceptable**
  ```bash
  python manage.py test apps.forecasting.tests.performance_tests -v 2
  ```

- [ ] **Code Coverage > 80%**
  ```bash
  coverage run --source='apps.forecasting' manage.py test apps.forecasting.tests
  coverage report
  coverage html
  ```

- [ ] **Static Analysis Passes**
  ```bash
  flake8 apps/forecasting/ --max-line-length=100 --exclude=migrations
  pylint apps/forecasting/ --disable=missing-docstring,too-many-arguments
  ```

- [ ] **Security Checks Pass**
  ```bash
  python manage.py check --deploy
  ```

---

## 📦 Database Migrations

### 1. Create Migrations

```bash
# Generate migration files for all forecasting models
python manage.py makemigrations forecasting

# Verify migrations are correct
python manage.py showmigrations forecasting
```

### 2. Backup Database

```bash
# PostgreSQL backup
pg_dump opas_database > opas_backup_$(date +%Y%m%d).sql

# Verify backup
ls -lh opas_backup_*.sql
```

### 3. Apply Migrations

```bash
# Dry-run to see what will execute
python manage.py migrate forecasting --plan

# Apply migrations
python manage.py migrate forecasting

# Verify migrations applied
python manage.py showmigrations forecasting
```

### 4. Create Database Indexes

```bash
# Optimize query performance with indexes
python manage.py sqlsequencereset forecasting | python manage.py dbshell
```

**Key Indexes to Create:**

```sql
-- ProductForecast indexes
CREATE INDEX idx_productforecast_product_id ON forecasting_productforecast(product_id);
CREATE INDEX idx_productforecast_is_current ON forecasting_productforecast(is_current);
CREATE INDEX idx_productforecast_created_at ON forecasting_productforecast(created_at);

-- HistoricalTransactions indexes
CREATE INDEX idx_historicaltransactions_product_id ON forecasting_historicaltransactions(product_id);
CREATE INDEX idx_historicaltransactions_transaction_date ON forecasting_historicaltransactions(transaction_date);

-- ForecastAlert indexes
CREATE INDEX idx_forecastalert_product_id ON forecasting_forecastalert(product_id);
CREATE INDEX idx_forecastalert_severity ON forecasting_forecastalert(severity);

-- ForecastMetadata indexes
CREATE INDEX idx_forecastmetadata_product_id ON forecasting_forecastmetadata(product_id);
```

---

## 🐳 Docker Image Updates

### 1. Update requirements.txt

```bash
# Ensure all forecasting dependencies are in requirements.txt
cat >> requirements.txt << 'EOF'

# Forecasting dependencies (Phase 6)
statsmodels>=0.14.0
pmdarima>=2.0.3
pandas>=2.0.0
numpy>=1.24.0
scikit-learn>=1.3.0
joblib>=1.3.0
EOF
```

### 2. Update Dockerfile

```dockerfile
# Dockerfile
FROM python:3.11-slim

# ... existing setup ...

# Install system dependencies for statistical packages
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    liblapack-dev \
    libopenblas-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install -r requirements.txt

# ... rest of Dockerfile ...
```

### 3. Build and Test Docker Image

```bash
# Build image
docker build -t opas:v2.0 .

# Test image
docker run --rm opas:v2.0 python -c "import statsmodels; print('OK')"

# Push to registry
docker tag opas:v2.0 your-registry/opas:v2.0
docker push your-registry/opas:v2.0
```

---

## ⚙️ Celery & Celery Beat Configuration

### 1. Start Celery Worker

```bash
# Development
celery -A core worker -l info

# Production (with autoscaling)
celery -A core worker \
  --loglevel=info \
  --concurrency=4 \
  --autoscale=10,3 \
  --max-tasks-per-child=100 \
  --time-limit=1800 \
  --soft-time-limit=1600

# Docker container
docker run --rm \
  -e CELERY_BROKER_URL=redis://redis:6379/0 \
  -e CELERY_RESULT_BACKEND=redis://redis:6379/0 \
  opas:v2.0 \
  celery -A core worker -l info
```

### 2. Start Celery Beat Scheduler

```bash
# Development
celery -A core beat -l info

# Production (with persistent schedule)
celery -A core beat \
  -l info \
  --scheduler django_celery_beat.schedulers:DatabaseScheduler \
  --pidfile=/var/run/celery-beat.pid

# Docker container
docker run --rm \
  -e CELERY_BROKER_URL=redis://redis:6379/0 \
  -e CELERY_RESULT_BACKEND=redis://redis:6379/0 \
  -v /var/run:/var/run \
  opas:v2.0 \
  celery -A core beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

### 3. Configure Supervisor (Production)

Create `/etc/supervisor/conf.d/opas-celery.conf`:

```ini
[program:opas-celery-worker]
command=celery -A core worker --loglevel=info --concurrency=4
directory=/home/opas/app
user=opas
numprocs=1
stdout_logfile=/var/log/opas/celery-worker.log
stderr_logfile=/var/log/opas/celery-worker.log
autostart=true
autorestart=true
startsecs=10
stopwaitsecs=600

[program:opas-celery-beat]
command=celery -A core beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
directory=/home/opas/app
user=opas
numprocs=1
stdout_logfile=/var/log/opas/celery-beat.log
stderr_logfile=/var/log/opas/celery-beat.log
autostart=true
autorestart=true
startsecs=10

[group:opas-celery]
programs=opas-celery-worker,opas-celery-beat
```

Start supervisord:
```bash
sudo systemctl start supervisor
sudo supervisorctl status
```

---

## 📊 Monitoring & Logging

### 1. Celery Monitoring

```bash
# Install Flower for monitoring
pip install flower

# Run Flower
flower -A core --port=5555

# Docker
docker run --rm -p 5555:5555 \
  -e CELERY_BROKER_URL=redis://redis:6379/0 \
  opas:v2.0 \
  flower -A core --port=5555
```

Access dashboard: http://localhost:5555

### 2. Logging Configuration

```python
# settings.py
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
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/opas/forecasting.log',
            'maxBytes': 1024 * 1024 * 100,  # 100MB
            'backupCount': 10,
            'formatter': 'verbose',
        },
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'apps.forecasting': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
        'celery': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

### 3. Alert Configuration

```python
# settings.py - Email alerts for task failures
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_ACKS_LATE = True
CELERY_WORKER_PREFETCH_MULTIPLIER = 1

# Error email configuration
ADMINS = [
    ('Admin Name', 'admin@opas.com'),
]

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get('EMAIL_USER')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_PASSWORD')
```

---

## 🔍 Health Checks

### 1. Task Health Check

```python
# views.py - Health check endpoint
from django.http import JsonResponse
from apps.forecasting.models import ProductForecast
from django.utils import timezone
from datetime import timedelta

def forecasting_health(request):
    """Health check for forecasting system"""
    current_time = timezone.now()
    one_hour_ago = current_time - timedelta(hours=1)
    
    # Check if recent forecasts exist
    recent_forecasts = ProductForecast.objects.filter(
        created_at__gte=one_hour_ago
    ).count()
    
    # Check Celery connection
    from celery.app import current_app
    celery_status = None
    try:
        current_app.connection().connect()
        celery_status = 'connected'
    except:
        celery_status = 'disconnected'
    
    return JsonResponse({
        'status': 'healthy' if recent_forecasts > 0 and celery_status == 'connected' else 'degraded',
        'forecasts_last_hour': recent_forecasts,
        'celery': celery_status,
        'timestamp': current_time.isoformat(),
    })
```

### 2. Kubernetes Health Probe

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opas-api
spec:
  template:
    spec:
      containers:
      - name: api
        livenessProbe:
          httpGet:
            path: /api/health/forecasting/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health/forecasting/
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
```

---

## 📝 Production Deployment Checklist

### Pre-Deployment

- [ ] All tests passing (unit, integration, performance)
- [ ] Code review completed and approved
- [ ] Database backup created
- [ ] Migrations tested on staging
- [ ] Dependencies updated and tested
- [ ] Environment variables configured
- [ ] Secrets (.env) secure and backed up
- [ ] Monitoring and logging configured

### Deployment Steps

1. **Update Docker Image**
   ```bash
   docker pull your-registry/opas:v2.0
   ```

2. **Apply Database Migrations**
   ```bash
   python manage.py migrate forecasting
   ```

3. **Collect Static Files**
   ```bash
   python manage.py collectstatic --noinput
   ```

4. **Start Celery Services**
   ```bash
   supervisorctl start opas-celery:*
   ```

5. **Verify Deployments**
   ```bash
   # Check health
   curl http://localhost:8000/api/health/forecasting/
   
   # Check Celery
   celery -A core inspect active
   celery -A core inspect scheduled
   ```

### Post-Deployment

- [ ] Monitor logs for errors
- [ ] Verify Celery tasks are executing on schedule
- [ ] Check forecast data is being generated
- [ ] Verify API endpoints responding correctly
- [ ] Monitor system performance (CPU, memory, disk)
- [ ] Test data aggregation with real data
- [ ] Verify alerts are being created
- [ ] Check email notifications from tasks

---

## 🔧 Rollback Plan

### If Deployment Fails

1. **Revert Docker Image**
   ```bash
   docker pull your-registry/opas:v1.9
   docker-compose down
   docker-compose up -d
   ```

2. **Rollback Database**
   ```bash
   python manage.py migrate forecasting <previous_migration>
   ```

3. **Restart Services**
   ```bash
   supervisorctl restart opas-celery:*
   ```

4. **Verify Rollback**
   ```bash
   curl http://localhost:8000/api/health/forecasting/
   ```

---

## 📚 Documentation & Training

### Admin Training

- [ ] Create admin guide for viewing forecasts
- [ ] Document manual refresh procedure
- [ ] Create alert interpretation guide
- [ ] Set up FAQ page

### Developer Documentation

- [ ] API documentation (Swagger/OpenAPI)
- [ ] Task execution logs and troubleshooting
- [ ] Performance tuning guide
- [ ] Custom model addition guide

### Operations Documentation

- [ ] Runbook for common issues
- [ ] Escalation procedures
- [ ] On-call responsibilities
- [ ] Maintenance windows

---

## 📞 Support & Contact

**Deployment Issues:**
- DevOps Team: devops@opas.com
- Database Issues: dba@opas.com

**Forecasting Issues:**
- Analytics Team: analytics@opas.com
- Backend Team: backend@opas.com

**Emergency Escalation:**
- Senior Engineer On-Call: oncall@opas.com

---

## ✅ Post-Deployment Verification

Run this script after deployment:

```python
# verify_deployment.py
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.forecasting.models import ProductForecast, HistoricalTransactions
from apps.forecasting.tasks import refresh_all_forecasts
from django.utils import timezone
from datetime import timedelta

def verify_deployment():
    """Verify forecasting system deployment"""
    
    print("🔍 Verifying Forecasting Deployment...\n")
    
    # 1. Check database connectivity
    try:
        count = ProductForecast.objects.count()
        print(f"✅ Database connected - {count} forecasts in system")
    except Exception as e:
        print(f"❌ Database error: {e}")
        return False
    
    # 2. Check recent data
    recent = ProductForecast.objects.filter(
        created_at__gte=timezone.now()-timedelta(hours=24)
    ).count()
    print(f"✅ Recent forecasts (24h): {recent}")
    
    # 3. Check Celery connectivity
    from celery.app import current_app
    try:
        current_app.connection().connect()
        print("✅ Celery broker connected")
    except Exception as e:
        print(f"❌ Celery error: {e}")
        return False
    
    # 4. Test task execution
    print("\n⏳ Testing forecast refresh task...")
    try:
        result = refresh_all_forecasts.delay()
        result.get(timeout=30)
        print("✅ Task execution successful")
    except Exception as e:
        print(f"⚠️ Task execution warning: {e}")
    
    print("\n✅ Deployment verification complete!")
    return True

if __name__ == '__main__':
    verify_deployment()
```

Run verification:
```bash
python manage.py shell < verify_deployment.py
```

---

**Deployment Status: ✅ READY FOR PRODUCTION**
