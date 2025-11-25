// Debug/Test Helper - Add this to any screen where you want to test the API connection
// This helps you manually reset and test the backend URL when switching emulators

import 'package:flutter/material.dart';
import 'package:opas_flutter/core/services/api_service.dart';

class ApiConnectionDebugDialog extends StatelessWidget {
  const ApiConnectionDebugDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('API Connection Debug'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When switching emulators, use this to reset the backend connection:',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text(
            'Current Backend URL:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Text(
              ApiService.baseUrl,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The app will automatically find the correct URL on next login/signup attempt.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            ApiService.resetCachedUrl();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Backend URL cache cleared. Try logging in again.'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Cache'),
        ),
      ],
    );
  }
}
