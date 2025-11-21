#!/usr/bin/env python
"""Check if seller models tables exist in the database"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()

# Check for seller tables
cursor.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE 'seller%'
    ORDER BY table_name;
""")

tables = cursor.fetchall()

print("✅ Seller Tables Found:")
print("=" * 50)

if tables:
    for table in tables:
        print(f"  ✓ {table[0]}")
else:
    print("  ❌ No seller tables found")

print("\n" + "=" * 50)

# Check all tables in public schema
cursor.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name;
""")

all_tables = cursor.fetchall()
print(f"\nTotal Tables in Database: {len(all_tables)}")
print("All tables:")
for table in all_tables:
    print(f"  - {table[0]}")
