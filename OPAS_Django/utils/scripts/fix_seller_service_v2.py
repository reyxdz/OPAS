#!/usr/bin/env python3
"""Fix seller_service.dart endpoint paths - final version"""

import re

# Read the file
file_path = r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Flutter\lib\features\seller_panel\services\seller_service.dart'

with open(file_path, 'r') as f:
    content = f.read()

# Fix all _makeRequest calls with broken syntax
# Pattern: _makeRequest('METHOD', ('/path/, ... -> _makeRequest('METHOD', '/path/, ...
content = re.sub(r"_makeRequest\('([^']+)',\s+\('(/[^']+)/", r"_makeRequest('\1', '/\2/", content)

# Write back
with open(file_path, 'w') as f:
    f.write(content)

print("✓ Fixed endpoint paths in seller_service.dart")
