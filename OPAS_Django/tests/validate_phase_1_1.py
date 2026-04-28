#!/usr/bin/env python
"""
Phase 1.1 Implementation Validation Script

Validates that all database migrations and seller models are properly implemented:
1. Migration file exists and contains all models
2. All seller models are defined
3. Migrations are applied to database
4. All database tables exist with correct structure
"""

import os
import django
from pathlib import Path

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection
from django.core.management import call_command
import sys

print("\n" + "=" * 120)
print("✅ PHASE 1.1 IMPLEMENTATION VALIDATION")
print("=" * 120)

# ==================== 1. MIGRATION FILE VALIDATION ====================

print("\n" + "=" * 120)
print("📋 STEP 1: MIGRATION FILE VALIDATION")
print("=" * 120)

migration_file = Path('C:\\BSCS-4B\\Thesis\\OPAS_Application\\OPAS_Django\\apps\\users\\migrations\\0006_seller_models.py')

if migration_file.exists():
    print(f"\n✅ Migration file exists: {migration_file.name}")
    
    # Read migration file
    with open(migration_file, 'r') as f:
        content = f.read()
    
    # Check for all models
    models_to_check = ['SellerProduct', 'SellerOrder', 'SellToOPAS', 'SellerPayout', 'SellerForecast']
    
    print("\n📦 Models in migration file:")
    models_found = {}
    for model in models_to_check:
        if model in content:
            models_found[model] = True
            print(f"  ✅ {model} - Found in migration")
        else:
            models_found[model] = False
            print(f"  ❌ {model} - NOT found in migration")
    
    all_models_in_migration = all(models_found.values())
else:
    print(f"\n❌ Migration file NOT found: {migration_file}")
    all_models_in_migration = False

# ==================== 2. MODEL DEFINITIONS VALIDATION ====================

print("\n" + "=" * 120)
print("📋 STEP 2: MODEL DEFINITIONS VALIDATION")
print("=" * 120)

try:
    from apps.users.seller_models import (
        SellerProduct,
        SellerOrder,
        SellToOPAS,
        SellerPayout,
        SellerForecast
    )
    
    print("\n✅ All seller models successfully imported from apps.users.seller_models\n")
    
    models_info = {
        'SellerProduct': SellerProduct,
        'SellerOrder': SellerOrder,
        'SellToOPAS': SellToOPAS,
        'SellerPayout': SellerPayout,
        'SellerForecast': SellerForecast
    }
    
    print("📦 Model Details:")
    for model_name, model_class in models_info.items():
        field_count = len(model_class._meta.get_fields())
        table_name = model_class._meta.db_table
        print(f"  ✅ {model_name}")
        print(f"     - Table: {table_name}")
        print(f"     - Fields: {field_count}")
    
    all_models_defined = True
    
except ImportError as e:
    print(f"\n❌ Error importing models: {e}")
    all_models_defined = False

# ==================== 3. MIGRATION STATUS VALIDATION ====================

print("\n" + "=" * 120)
print("📋 STEP 3: MIGRATION APPLICATION STATUS")
print("=" * 120)

from django.db.migrations.executor import MigrationExecutor
from django.db import DEFAULT_DB_ALIAS

executor = MigrationExecutor(connection)

print("\n📦 Users App Migrations:")

# Get applied migrations from the recorder
try:
    executor.loader.build_graph()
    applied = executor.loader.graph.leaf_nodes()
    migration_0006_applied = ('users', '0006_seller_models') in executor.loader.applied_migrations
except:
    # Fallback method
    from django.db.migrations.recorder import MigrationRecorder
    recorder = MigrationRecorder(connection)
    applied_migrations = recorder.applied_migrations()
    migration_0006_applied = ('users', '0006_seller_models') in applied_migrations
    users_migrations = [m for m in applied_migrations if m[0] == 'users']
    for app, name in sorted(users_migrations):
        print(f"  ✅ Applied: {name}")

if migration_0006_applied:
    print(f"\n✅ Migration 0006_seller_models is APPLIED")
else:
    print(f"\n❌ Migration 0006_seller_models is NOT applied")

# ==================== 4. DATABASE TABLES VALIDATION ====================

print("\n" + "=" * 120)
print("📋 STEP 4: DATABASE TABLES VALIDATION")
print("=" * 120)

cursor = connection.cursor()

# Get all tables in public schema
cursor.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name;
""")

all_tables = [row[0] for row in cursor.fetchall()]

seller_tables_expected = {
    'seller_products': 18,
    'seller_orders': 17,
    'seller_sell_to_opas': 17,
    'seller_payouts': 17,
    'seller_forecasts': 15
}

print("\n📦 Seller Tables Status:")
tables_status = {}

for table_name, expected_columns in seller_tables_expected.items():
    if table_name in all_tables:
        # Get column count
        cursor.execute(f"""
            SELECT COUNT(*)
            FROM information_schema.columns
            WHERE table_name = '{table_name}';
        """)
        actual_columns = cursor.fetchone()[0]
        
        status_icon = "✅" if actual_columns == expected_columns else "⚠️"
        tables_status[table_name] = actual_columns == expected_columns
        
        print(f"  {status_icon} {table_name}")
        print(f"     - Status: EXISTS in database")
        print(f"     - Columns: {actual_columns} (expected: {expected_columns})")
    else:
        tables_status[table_name] = False
        print(f"  ❌ {table_name}")
        print(f"     - Status: NOT FOUND in database")

all_tables_exist = all(tables_status.values())

# ==================== 5. TABLE STRUCTURE VALIDATION ====================

print("\n" + "=" * 120)
print("📋 STEP 5: TABLE STRUCTURE VALIDATION")
print("=" * 120)

for table_name in seller_tables_expected.keys():
    if table_name in all_tables:
        cursor.execute(f"""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = '{table_name}'
            ORDER BY ordinal_position;
        """)
        
        columns = cursor.fetchall()
        
        print(f"\n✅ {table_name.upper()} Structure:")
        print(f"  Columns: {len(columns)}")
        
        # Show key columns
        for col_name, data_type, is_nullable in columns[:5]:  # Show first 5
            null_str = "(NULL)" if is_nullable == 'YES' else "(NOT NULL)"
            print(f"    - {col_name}: {data_type} {null_str}")
        
        if len(columns) > 5:
            print(f"    ... and {len(columns) - 5} more columns")

# ==================== 6. MODEL-DATABASE CONSISTENCY ====================

print("\n" + "=" * 120)
print("📋 STEP 6: MODEL-DATABASE CONSISTENCY CHECK")
print("=" * 120)

if all_models_defined:
    print("\n📦 ORM Query Tests:")
    
    try:
        # Test each model
        count_tests = {
            'SellerProduct': SellerProduct.objects.count(),
            'SellerOrder': SellerOrder.objects.count(),
            'SellToOPAS': SellToOPAS.objects.count(),
            'SellerPayout': SellerPayout.objects.count(),
            'SellerForecast': SellerForecast.objects.count(),
        }
        
        for model_name, count in count_tests.items():
            print(f"  ✅ {model_name}: {count} records")
        
        orm_working = True
    except Exception as e:
        print(f"  ❌ Error querying models: {e}")
        orm_working = False

# ==================== FINAL VALIDATION REPORT ====================

print("\n" + "=" * 120)
print("📊 FINAL VALIDATION REPORT")
print("=" * 120)

validation_checklist = {
    "1. Migration file 0006_seller_models.py exists": all_models_in_migration,
    "2. All 5 seller models defined in seller_models.py": all_models_defined,
    "3. Migration 0006_seller_models applied to database": migration_0006_applied,
    "4. All 5 seller tables exist in database": all_tables_exist,
    "5. All tables have correct column structure": all(tables_status.values()),
    "6. ORM queries work correctly": orm_working if all_models_defined else False,
}

print("\n✅ VALIDATION CHECKLIST:")
all_passed = True
for check, passed in validation_checklist.items():
    status_icon = "✅" if passed else "❌"
    print(f"  {status_icon} {check}")
    if not passed:
        all_passed = False

print("\n" + "=" * 120)
print("🎯 OVERALL STATUS")
print("=" * 120)

if all_passed:
    print("\n🎉 ✅ PHASE 1.1 VALIDATION COMPLETE - ALL CHECKS PASSED!")
    print("\nPhase 1.1 (Database Migrations) is fully implemented and operational.")
    print("All seller models are properly defined and migrated to the database.")
    print("Ready to proceed to Phase 1.2 (URL Registration).")
    exit_code = 0
else:
    print("\n⚠️  PHASE 1.1 VALIDATION FAILED - SOME CHECKS DID NOT PASS")
    print("\nPlease review the failures above and take corrective action.")
    exit_code = 1

print("\n" + "=" * 120 + "\n")
sys.exit(exit_code)
