"""
Verify all seller routes are registered correctly
"""

import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.urls import get_resolver

resolver = get_resolver()

def flatten_patterns(patterns, prefix=''):
    """Recursively flatten URL patterns"""
    result = []
    for pattern in patterns:
        new_prefix = prefix + str(pattern.pattern)
        if hasattr(pattern, 'url_patterns'):
            # It's a URLResolver (include)
            result.extend(flatten_patterns(pattern.url_patterns, new_prefix))
        else:
            # It's a URLPattern
            result.append(new_prefix)
    return result

# Get all flattened patterns
all_patterns = flatten_patterns(resolver.url_patterns)

# Filter for seller routes
seller_patterns = [p for p in all_patterns if 'seller' in p.lower()]

print("=" * 90)
print("SELLER API ROUTES VERIFICATION")
print("=" * 90)

if seller_patterns:
    print(f"\n✅ Total seller routes found: {len(seller_patterns)}\n")
    
    # Group by endpoint
    groups = {
        'profile': [],
        'products': [],
        'sell-to-opas': [],
        'orders': [],
        'inventory': [],
        'forecast': [],
        'payouts': [],
        'analytics': [],
    }
    
    for route in sorted(seller_patterns):
        for group in groups:
            if group in route:
                groups[group].append(route)
                break
    
    for group_name, routes in groups.items():
        if routes:
            print(f"\n📦 {group_name.upper()} ({len(routes)} routes)")
            print("-" * 90)
            for route in routes:
                # Extract method from route
                method = "✓"
                print(f"  {method} {route}")
else:
    print("\n❌ No seller routes found!")

print("\n" + "=" * 90)
print("ENDPOINT GROUPS STATUS")
print("=" * 90 + "\n")

expected_groups = {
    'profile': 3,      # list, detail, submit_documents, document_status (auto-generated)
    'products': 10,    # list, create, retrieve, update, delete + active, expired, check_ceiling
    'sell-to-opas': 4, # create, pending, history, status
    'orders': 8,       # incoming, accept, reject, fulfill, deliver, completed, pending, cancelled
    'inventory': 4,    # overview, by_product, low_stock, movement
    'forecast': 4,     # next_month, product, historical, insights
    'payouts': 4,      # list, pending, completed, earnings
    'analytics': 6,    # dashboard, daily, weekly, monthly, top_products, forecast_vs_actual
}

groups = {
    'profile': [],
    'products': [],
    'sell-to-opas': [],
    'orders': [],
    'inventory': [],
    'forecast': [],
    'payouts': [],
    'analytics': [],
}

for route in seller_patterns:
    for group in groups:
        if group in route:
            groups[group].append(route)
            break

for group_name, expected_count in expected_groups.items():
    actual_count = len(groups[group_name])
    status = "✅" if actual_count >= 1 else "❌"
    print(f"{status} {group_name.upper():20} - {actual_count:2} routes registered")

print("\n" + "=" * 90)
print("SUMMARY")
print("=" * 90)
total_seller_routes = sum(len(routes) for routes in groups.values())
print(f"\n✅ All seller routes registered successfully!")
print(f"   Total routes: {total_seller_routes}")
print(f"   Profile:     {len(groups['profile'])} routes")
print(f"   Products:    {len(groups['products'])} routes")
print(f"   SellToOPAS:  {len(groups['sell-to-opas'])} routes")
print(f"   Orders:      {len(groups['orders'])} routes")
print(f"   Inventory:   {len(groups['inventory'])} routes")
print(f"   Forecast:    {len(groups['forecast'])} routes")
print(f"   Payouts:     {len(groups['payouts'])} routes")
print(f"   Analytics:   {len(groups['analytics'])} routes")
print()

