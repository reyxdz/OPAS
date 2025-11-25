import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

Future<void> main() async {
  const token = 'YOUR_ADMIN_TOKEN_HERE'; // Get this from your login
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/admin/sellers/pending-approvals/'),
      headers: headers,
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Decoded: $data');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
