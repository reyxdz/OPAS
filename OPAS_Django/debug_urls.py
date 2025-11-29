#!/usr/bin/env python
"""
Debug URL patterns to see what's actually registered
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, r'c:\BSCS-4B\Thesis\OPAS_Application\OPAS_Django')
django.setup()

from django.urls import get_resolver
from django.urls.resolvers import URLPattern, URLResolver

def show_urls(urlpatterns, prefix=''):
    """Recursively show all URL patterns"""
    for pattern in urlpatterns:
        if isinstance(pattern, URLResolver):
            # This is an include()
            new_prefix = prefix + str(pattern.pattern)
            show_urls(pattern.url_patterns, new_prefix)
        elif isinstance(pattern, URLPattern):
            # This is a direct path()
            full_path = prefix + str(pattern.pattern)
            print(f"  {full_path}")

resolver = get_resolver()
print("=" * 80)
print("Registered URL Patterns")
print("=" * 80)

# Find /api/orders routes
print("\n[/api/orders routes]")
for pattern in resolver.url_patterns:
    if 'api' in str(pattern.pattern):
        if 'orders' in str(pattern):
            print(f"  {pattern.pattern}")

# Show all /api routes
print("\n[All /api routes - first 50]")
count = 0
for pattern in resolver.url_patterns:
    pattern_str = str(pattern.pattern)
    if 'api' in pattern_str:
        if isinstance(pattern, URLResolver):
            print(f"  {pattern_str} -> (includes)")
            # Try to get patterns from includes
            try:
                for sub in pattern.url_patterns[:5]:  # Just first 5
                    print(f"     {str(sub.pattern)}")
            except:
                pass
        else:
            print(f"  {pattern_str}")
        count += 1
        if count > 20:
            break

print("\n[Attempting to resolve /api/orders/create/]")
try:
    match = resolver.resolve('/api/orders/create/')
    print(f"  ✓ FOUND: {match.func}")
except Exception as e:
    print(f"  ✗ NOT FOUND: {e}")

print("\n[Attempting to resolve /api/users/orders/create/]")
try:
    match = resolver.resolve('/api/users/orders/create/')
    print(f"  ✓ FOUND: {match.func}")
except Exception as e:
    print(f"  ✗ NOT FOUND: {e}")
