#!/usr/bin/env python3
"""Comprehensive fix for seller_service.dart"""

# Read the file
file_path = r'C:\BSCS-4B\Thesis\OPAS_Application\OPAS_Flutter\lib\features\seller_panel\services\seller_service.dart'

with open(file_path, 'r') as f:
    lines = f.readlines()

# Process each line
fixed_lines = []
for line in lines:
    # Fix double slashes
    line = line.replace("'//(", "'/")
    line = line.replace("'//users/", "'/users/")
    # Remove extra opening parenthesis before path
    line = line.replace("('//users/", "'/users/")
    line = line.replace("'/(/", "'/")
    # Fix any remaining malformed paths
    line = line.replace("_makeRequest('POST', ('/users/", "_makeRequest('POST', '/users/")
    line = line.replace("_makeRequest('GET', ('/users/", "_makeRequest('GET', '/users/")
    line = line.replace("_makeRequest('PUT', ('/users/", "_makeRequest('PUT', '/users/")
    line = line.replace("_makeRequest('DELETE', ('/users/", "_makeRequest('DELETE', '/users/")
    line = line.replace("_makeRequest('POST', '//users/", "_makeRequest('POST', '/users/")
    line = line.replace("_makeRequest('GET', '//users/", "_makeRequest('GET', '/users/")
    line = line.replace("_makeRequest('PUT', '//users/", "_makeRequest('PUT', '/users/")
    line = line.replace("_makeRequest('DELETE', '//users/", "_makeRequest('DELETE', '/users/")
    fixed_lines.append(line)

# Write back
with open(file_path, 'w') as f:
    f.writelines(fixed_lines)

print("✓ All endpoint paths fixed - double slashes and parentheses removed")
