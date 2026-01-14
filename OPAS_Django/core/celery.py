"""
Celery configuration for OPAS.

Initializes Celery app and autodiscovers tasks from all installed apps.
"""

import os
from celery import Celery
from celery.schedules import crontab

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Create Celery app
app = Celery('opas')

# Load configuration from Django settings
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks from all installed apps
app.autodiscover_tasks()


@app.task(bind=True)
def debug_task(self):
    """
    Debug task for testing Celery integration.
    """
    print(f'Request: {self.request!r}')
