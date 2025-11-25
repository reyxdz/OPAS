#!/usr/bin/env python
"""Get all columns from the user table"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from apps.users.models import User
from django.db import connection

# Get all fields from the User model
print("=" * 90)
print("USER TABLE COLUMNS - DJANGO MODEL")
print("=" * 90)

fields = User._meta.get_fields()
print(f"\nTotal Fields: {len(fields)}\n")

for i, field in enumerate(sorted(fields, key=lambda f: f.name), 1):
    field_type = type(field).__name__
    nullable = getattr(field, 'null', False)
    blank = getattr(field, 'blank', False)
    max_length = getattr(field, 'max_length', None)
    help_text = getattr(field, 'help_text', '')
    
    col_info = f"{i:2d}. {field.name:<30} ({field_type:<20}"
    
    if max_length:
        col_info += f", max_length={max_length}"
    if nullable:
        col_info += ", nullable=True"
    if blank:
        col_info += ", blank=True"
    
    col_info += ")"
    print(col_info)
    if help_text:
        print(f"     └─ {help_text}")

print("\n" + "=" * 90)
print("DATABASE TABLE STRUCTURE")
print("=" * 90 + "\n")

# Get actual database columns
cursor = connection.cursor()
cursor.execute("""
    SELECT column_name, data_type, is_nullable, character_maximum_length
    FROM information_schema.columns
    WHERE table_name = 'users'
    ORDER BY ordinal_position;
""")

print(f"{'#':<3} {'Column Name':<35} {'Data Type':<20} {'Nullable':<10} {'Max Len':<10}")
print("-" * 90)

for i, col in enumerate(cursor.fetchall(), 1):
    col_name, data_type, is_nullable, max_len = col
    nullable_str = "YES" if is_nullable == "YES" else "NO"
    max_len_str = str(max_len) if max_len else "-"
    print(f"{i:<3} {col_name:<35} {data_type:<20} {nullable_str:<10} {max_len_str:<10}")

print("\n" + "=" * 90)
