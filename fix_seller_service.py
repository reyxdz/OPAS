#!/usr/bin/env python3
"""Fix seller_service.dart endpoint paths"""

import re

# Read the file
file_path = r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Flutter\lib\features\seller_panel\services\seller_service.dart'

with open(file_path, 'r') as f:
    content = f.read()

# Replace all /seller/ with /users/seller/
# But avoid replacing if it's already /users/seller/
content = re.sub(r"('/seller/)", r"('/users/seller/", content)
content = re.sub(r'("/seller/)', r'("/users/seller/', content)

# Write back
with open(file_path, 'w') as f:
    f.write(content)

print("✓ Replacement complete - all /seller/ paths updated to /users/seller/")
