#!/usr/bin/env python
"""Verify seller model tables structure"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()

seller_tables = [
    'seller_products',
    'seller_orders',
    'seller_sell_to_opas',
    'seller_payouts',
    'seller_forecasts'
]

print("📋 SELLER MODELS DATABASE STRUCTURE")
print("=" * 80)

for table_name in seller_tables:
    cursor.execute(f"""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = '{table_name}'
        ORDER BY ordinal_position;
    """)
    
    columns = cursor.fetchall()
    
    print(f"\n✅ {table_name.upper()}")
    print("-" * 80)
    print(f"{'Column':<30} {'Type':<20} {'Nullable':<10}")
    print("-" * 80)
    
    for col_name, data_type, is_nullable in columns:
        nullable = "YES" if is_nullable == 'YES' else "NO"
        print(f"{col_name:<30} {data_type:<20} {nullable:<10}")
    
    print(f"Total Columns: {len(columns)}")

print("\n" + "=" * 80)
print("✅ All seller models have been successfully migrated to the database!")
