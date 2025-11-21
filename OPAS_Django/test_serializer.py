import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth.models import User
from apps.users.models import SellerApplication
from apps.users.admin_serializers import SellerApplicationDetailSerializer

# Get pending applications
applications = SellerApplication.objects.filter(status='PENDING').select_related('user')

print(f'Found {applications.count()} pending applications\n')

# Serialize them
serializer = SellerApplicationDetailSerializer(applications, many=True)
print('Serialized data:')
print(json.dumps(serializer.data, indent=2, default=str))
