#!/usr/bin/env python
"""Verify municipality and barangay fields are in the database"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection
from apps.users.models import User

# Check model fields
print("=" * 70)
print("✓ USER MODEL FIELDS VERIFICATION")
print("=" * 70)

fields = {f.name: f for f in User._meta.get_fields()}
for field_name in ['municipality', 'barangay']:
    if field_name in fields:
        field = fields[field_name]
        print(f"\n✓ {field_name.upper()} field found in model")
        print(f"  Type: {type(field).__name__}")
        print(f"  Max length: {getattr(field, 'max_length', 'N/A')}")
        print(f"  Blank: {field.blank}")
        print(f"  Null: {field.null}")
    else:
        print(f"\n✗ {field_name.upper()} field NOT found in model")

# Check database columns
print("\n" + "=" * 70)
print("✓ DATABASE COLUMNS VERIFICATION")
print("=" * 70)

cursor = connection.cursor()
try:
    # Try PostgreSQL query first
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'users' 
        AND column_name IN ('municipality', 'barangay')
        ORDER BY ordinal_position;
    """)
    columns = cursor.fetchall()
    
    if columns:
        print("\n✓ New columns found in database:")
        for col in columns:
            print(f"  - {col[0]}: {col[1]} (nullable: {col[2]})")
    else:
        print("\n✗ Columns not found in PostgreSQL")
except Exception as e:
    print(f"\n✗ PostgreSQL query failed: {e}")
    
    # Try SQLite as fallback
    try:
        cursor.execute("PRAGMA table_info(users);")
        all_cols = cursor.fetchall()
        target_cols = [c for c in all_cols if c[1] in ['municipality', 'barangay']]
        
        if target_cols:
            print("\n✓ New columns found in SQLite database:")
            for col in target_cols:
                print(f"  - {col[1]}: {col[2]}")
        else:
            print("\n✗ Columns not found in SQLite")
    except Exception as e2:
        print(f"\n✗ SQLite query also failed: {e2}")

print("\n" + "=" * 70)
print("✓ VERIFICATION COMPLETE")
print("=" * 70)
