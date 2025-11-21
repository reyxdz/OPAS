import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.urls import get_resolver

resolver = get_resolver()
patterns = resolver.url_patterns

print("URLs with 'sellers' or 'seller-application':")
for pattern in patterns:
    pattern_str = str(pattern)
    if 'seller' in pattern_str.lower() or 'application' in pattern_str.lower():
        print(f"  {pattern_str}")
